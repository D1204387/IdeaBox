# 數據模型設計

**分支**: `002-swiftdata-icloud-sync`  
**日期**: 2025-11-10  
**狀態**: 設計規格

## 概述

本文檔定義了 IdeaBox SwiftData 持久化層的數據模型。所有實體使用 SwiftData @Model 註解，支援自動持久化和 CloudKit 同步。

---

## 核心實體

### 1. Idea（想法）

**用途**: 代表使用者建立的想法，核心業務實體

**SwiftData @Model 定義**:

```swift
@Model
final class Idea: Identifiable {
    @Attribute(.unique) var id: UUID                    // 全球唯一識別符
    var title: String                                    // 想法標題（必填）
    var description: String                              // 想法描述（可選）
    var isCompleted: Bool                                // 完成狀態
    
    // 時間戳（毫秒精度）
    var createdAt: Date                                  // 建立時間
    var updatedAt: Date                                  // 最後更新時間
    
    // 同步元數據
    var deviceId: String                                 // 來源裝置識別符
    var syncState: SyncState?                           // 關聯的同步狀態
    
    // 審計日誌
    var version: Int                                     // 本地版本號
    var lastSyncedAt: Date?                             // 最後成功同步時間
    
    // 初始化器
    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deviceId: String,
        version: Int = 0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deviceId = deviceId
        self.version = version
    }
}
```

**驗證規則**:
- `id`: 全球唯一，UUID 格式，自動生成
- `title`: 必填，非空字符串，最大 256 字符
- `description`: 可選，最大 4096 字符
- `isCompleted`: 布林值，默認 false
- `createdAt`, `updatedAt`: ISO 8601 格式，毫秒精度
- `deviceId`: 裝置識別符，通過 UIDevice.current.identifierForVendor
- `version`: 整數，從 0 開始遞增

**關係**:
- 一對一：Idea → SyncState（當存在同步時）
- 無外鍵（設計為自包含）

**索引策略**:
- 主索引: `id`（唯一索引）
- 輔助索引: `updatedAt`（用於排序和同步查詢）
- 輔助索引: `deviceId`（用於裝置衝突檢測）
- 輔助索引: `isCompleted`（用於篩選）

---

### 2. SyncState（同步狀態）

**用途**: 追蹤每個想法的同步狀態，管理離線變更和衝突

**SwiftData @Model 定義**:

```swift
@Model
final class SyncState {
    @Attribute(.unique) var ideaId: UUID               // 關聯的 Idea 的 UUID
    
    // 同步版本
    var localVersion: Int                              // 本地版本號
    var remoteVersion: Int?                            // 遠端版本號
    var cloudKitRecordName: String?                    // CloudKit 記錄名稱
    
    // 時間戳
    var lastSyncedAt: Date?                            // 最後成功同步時間
    var lastConflictAt: Date?                          // 最後衝突時間
    var lastModifiedAt: Date                           // 最後修改時間（本地）
    
    // 狀態標誌
    var isPendingSync: Bool                            // 等待同步
    var isObsolete: Bool                               // 已過時（30 天未同步）
    var conflictResolutionStrategy: String             // 衝突解決策略："lastWrite"
    
    // 初始化器
    init(
        ideaId: UUID,
        localVersion: Int = 0,
        remoteVersion: Int? = nil,
        lastModifiedAt: Date = Date(),
        isPendingSync: Bool = true,
        conflictResolutionStrategy: String = "lastWrite"
    ) {
        self.ideaId = ideaId
        self.localVersion = localVersion
        self.remoteVersion = remoteVersion
        self.lastModifiedAt = lastModifiedAt
        self.isPendingSync = isPendingSync
        self.isObsolete = false
        self.conflictResolutionStrategy = conflictResolutionStrategy
    }
    
    // 輔助方法
    func markSynced(remoteVersion: Int, recordName: String) {
        self.remoteVersion = remoteVersion
        self.cloudKitRecordName = recordName
        self.lastSyncedAt = Date()
        self.isPendingSync = false
    }
    
    func markConflict() {
        self.lastConflictAt = Date()
    }
    
    func markObsolete() {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        if let lastSynced = lastSyncedAt, lastSynced < thirtyDaysAgo {
            self.isObsolete = true
        }
    }
}
```

**驗證規則**:
- `ideaId`: 必填，與存在的 Idea 的 id 關聯
- `localVersion`: 從 0 開始遞增，每次本地變更 +1
- `remoteVersion`: 可選，首次同步後填入
- `isPendingSync`: 在本地變更後設定為 true
- `conflictResolutionStrategy`: 目前只支援 "lastWrite"（保留以供未來擴展）

**狀態轉遷**:
```
新建立
  ↓ (本地變更)
pendingSync=true
  ↓ (成功同步)
pendingSync=false, lastSyncedAt=now
  ↓ (本地變更)
pendingSync=true, localVersion++
  ↓ (30 天未同步)
isObsolete=true
```

---

### 3. SyncLog（同步日誌）

**用途**: 審計日誌，記錄所有同步、衝突、失敗事件

**SwiftData @Model 定義**:

```swift
@Model
final class SyncLog {
    @Attribute(.unique) var id: UUID
    var ideaId: UUID                                     // 影響的 Idea
    var eventType: String                               // "sync_success", "sync_failure", "conflict", "retry"
    var timestamp: Date                                 // 事件時間
    var details: String?                                // 詳細信息（JSON 格式）
    var deviceId: String                                // 來源裝置
    var errorCode: Int?                                 // 錯誤代碼（如適用）
    
    init(
        id: UUID = UUID(),
        ideaId: UUID,
        eventType: String,
        timestamp: Date = Date(),
        details: String? = nil,
        deviceId: String,
        errorCode: Int? = nil
    ) {
        self.id = id
        self.ideaId = ideaId
        self.eventType = eventType
        self.timestamp = timestamp
        self.details = details
        self.deviceId = deviceId
        self.errorCode = errorCode
    }
}
```

**索引策略**:
- 主索引: `id`
- 輔助索引: `ideaId`（用於特定想法的日誌查詢）
- 輔助索引: `timestamp`（用於時間範圍查詢）
- 輔助索引: `eventType`（用於事件類型篩選）

**保留策略**:
- 保留最後 30 天的日誌
- 每次應用啟動時清理超過 30 天的記錄

---

## 數據遷移策略

### 舊版本→新版本遷移

**觸發時機**: 應用首次啟動，偵測到舊版本模擬數據

**遷移流程**:

1. **偵測舊數據**
   ```
   if (舊 mock 數據存在) {
     執行遷移
   }
   ```

2. **轉換記錄**
   ```
   for each 舊 Idea:
     新 Idea {
       id: 使用舊 ID 或生成新 UUID
       title: 保留
       description: 保留
       isCompleted: 保留
       createdAt: 設定為遷移時間
       updatedAt: 設定為遷移時間
       deviceId: 當前裝置 ID
       version: 0
     }
     新 SyncState {
       ideaId: 新 Idea.id
       localVersion: 0
       isPendingSync: true  // 標記為待同步
     }
   ```

3. **失敗處理**
   ```
   if (遷移失敗) {
     保留舊數據，回退到離線模式
     記錄遷移失敗事件到 SyncLog
     下次啟動時自動重試
   }
   ```

---

## CloudKit 映射

### CloudKit 記錄類型

**Idea 記錄類型**:
```
Record Type: "Idea"
Fields:
  - id (String)                     // 主鍵
  - title (String)
  - description (String)
  - isCompleted (Int, 0/1)
  - createdAt (DateTime)
  - updatedAt (DateTime)
  - deviceId (String)
  - version (Int)
  - lastSyncedAt (DateTime)
```

**CloudKit 容器配置**:
- 容器名稱: `iCloud.com.buildwithharry.IdeaBox`
- 資料庫: 私有資料庫（使用者專用，iCloud 帳戶隔離）
- 區域: 預設區域（無自訂 Zone）

---

## 性能考慮

### 查詢優化

| 常見查詢 | 索引 | 複雜度 |
|---------|------|--------|
| 獲取所有想法 | 無 | O(n) |
| 按 ID 獲取 | 主索引 | O(1) |
| 按完成狀態篩選 | isCompleted 索引 | O(n) |
| 按最後修改時間排序 | updatedAt 索引 | O(n log n) |
| 獲取待同步項目 | SyncState.isPendingSync | O(n) |

### 批量操作

- 單次同步最多 100 筆想法變更
- 批量查詢使用分頁（每頁 50 條）
- 批量刪除使用軟刪除（標記已過時）

### 內存優化

- 避免一次載入所有想法到內存（使用 @FetchRequest 進行分頁）
- 適時清理舊的 SyncLog 記錄

---

## 向後相容性

此設計完全保持向後相容：
- 現有 Idea 屬性（title, description, isCompleted）保留不變
- 新增的時間戳和同步字段為可選或有默認值
- 現有的 UI 代碼無需修改
- 遷移自動在首次啟動時執行

---

**狀態**: ✅ 設計完成，準備進行實現
