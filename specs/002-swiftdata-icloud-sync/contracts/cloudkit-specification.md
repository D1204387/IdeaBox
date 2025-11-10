# CloudKit 容器與記錄定義

**分支**: `002-swiftdata-icloud-sync`  
**日期**: 2025-11-10  
**狀態**: API 合約規格

## 概述

本文檔定義了 IdeaBox 與 iCloud CloudKit 服務的交互合約。包括容器配置、記錄類型、欄位定義、查詢模式和錯誤處理。

---

## CloudKit 容器配置

### 容器 ID
```
iCloud.com.buildwithharry.IdeaBox
```

### 資料庫選擇
- **資料庫類型**: Private Database（私有資料庫）
- **隔離級別**: 按 iCloud 帳戶隔離，用戶只能訪問自己的資料
- **區域**: Default Zone（預設區域，無自訂分區）

### 權限與認證
- **認證方式**: iCloud 帳戶認證（iOS 系統自動處理）
- **訪問控制**: CloudKit 私有資料庫天然支援用戶隔離
- **加密**: 端點間 TLS + 系統存儲加密

---

## 記錄類型定義

### Record Type: Idea

**描述**: 代表使用者建立的想法

**欄位定義**:

| 欄位名稱 | 類型 | 必填 | 說明 |
|---------|------|------|------|
| recordName | String (CloudKit 系統欄位) | 是 | 自動生成，全球唯一 |
| id | String | 是 | UUID，應用側主鍵 |
| title | String | 是 | 想法標題，最大 256 字符 |
| description | String | 否 | 想法描述，最大 4096 字符 |
| isCompleted | Int | 是 | 完成狀態（0 = false, 1 = true） |
| createdAt | DateTime | 是 | UTC 時間戳（毫秒精度） |
| updatedAt | DateTime | 是 | UTC 時間戳（毫秒精度） |
| deviceId | String | 是 | 來源裝置識別符 |
| version | Int | 是 | 版本號，從 0 開始遞增 |
| lastSyncedAt | DateTime | 否 | 最後同步時間 |

**索引策略**:

```
Primary Index: id (UNIQUE)
Secondary Indexes:
  - updatedAt (ASCENDING) → 用於時間排序和增量同步
  - deviceId (ASCENDING) → 用於檢測裝置衝突
  - isCompleted (ASCENDING) → 用於篩選已完成項目
```

**CloudKit Schema (YAML 格式)**:

```yaml
RecordType: Idea
Fields:
  id:
    Type: String
    Unique: true
    Indexed: true
    Description: Application-side primary key (UUID)
  
  title:
    Type: String
    MaxLength: 256
    Required: true
    Indexed: false
    Description: Idea title
  
  description:
    Type: String
    MaxLength: 4096
    Required: false
    Indexed: false
    Description: Idea description
  
  isCompleted:
    Type: Int
    Values: [0, 1]
    Required: true
    Indexed: true
    Description: Completion status (0=false, 1=true)
  
  createdAt:
    Type: DateTime
    Required: true
    Indexed: false
    TimeZone: UTC
    Precision: milliseconds
    Description: Creation timestamp
  
  updatedAt:
    Type: DateTime
    Required: true
    Indexed: true
    TimeZone: UTC
    Precision: milliseconds
    Description: Last update timestamp (used for conflict resolution)
  
  deviceId:
    Type: String
    Required: true
    Indexed: true
    Description: Source device identifier
  
  version:
    Type: Int
    Required: true
    MinValue: 0
    Indexed: false
    Description: Local version number
  
  lastSyncedAt:
    Type: DateTime
    Required: false
    TimeZone: UTC
    Description: Last successful sync time
```

---

## 操作定義

### 1. 建立想法 (CREATE)

**操作**: 使用者在應用中新增想法 → 本地存儲（SwiftData）→ 異步同步到 CloudKit

**CloudKit 操作**:
```
Operation: save(CKRecord)
Record Type: Idea
Input:
  id: UUID (application-generated)
  title: String (user input)
  description: String (user input)
  isCompleted: 0
  createdAt: now (millisecond precision)
  updatedAt: now (millisecond precision)
  deviceId: UIDevice.current.identifierForVendor
  version: 0

Success Response:
  recordName: <CloudKit-generated>
  id: <echoed>
  timestamps: <server-set>

Failure Handling:
  - Network error: Queue for retry (1s, 2s, 4s exponential backoff)
  - Account not available: Queue as offline, retry on account available
  - Quota exceeded: User notification + silent retry
```

### 2. 更新想法 (UPDATE)

**操作**: 使用者編輯想法 → 本地更新 → 異步同步到 CloudKit

**CloudKit 操作**:
```
Operation: update(CKRecord)
Input:
  id: <existing UUID>
  title: <updated>
  description: <updated>
  isCompleted: <updated>
  updatedAt: now (millisecond precision)
  version: local_version + 1

Conflict Detection:
  if (remote_version != local_version - 1):
    → Conflict detected
    → Apply resolution: "last-write-wins"
    → Remote updatedAt > local updatedAt → Keep remote
    → Remote updatedAt < local updatedAt → Keep local update
```

### 3. 刪除想法 (DELETE)

**操作**: 使用者刪除想法 → 本地標記為已刪除 → 異步同步到 CloudKit

**CloudKit 操作**:
```
Operation: delete(recordName)
Input:
  recordName: <CloudKit record identifier>

Soft Delete Strategy:
  - 應用層不實現物理刪除
  - 本地標記 isDeleted=true，設定 deletedAt timestamp
  - 同步到遠端時發送 delete 操作
  - 遠端刪除記錄從 CloudKit 中移除
```

### 4. 查詢想法 (QUERY)

**操作**: 檢索使用者的想法清單

**CloudKit 查詢**:
```
Operation: query(predicate, sortDescriptors)

Queries:
  1. 所有想法
     Predicate: true (all records)
     Sort: updatedAt DESC
     Limit: 100 (pagination)
  
  2. 已完成想法
     Predicate: isCompleted == 1
     Sort: updatedAt DESC
  
  3. 特定時間後的變更（增量同步）
     Predicate: updatedAt > lastSyncTime
     Sort: updatedAt ASC
  
  4. 按 ID 查詢單個
     Predicate: id == "<uuid>"
```

### 5. 多裝置同步 (SYNC)

**操作**: 檢測遠端變更並同步到本地

**CloudKit 操作**:
```
Operation: sync(changeToken)

Process:
  1. 首次同步：changeToken = nil，獲取全部記錄
  2. 增量同步：使用上次的 changeToken，僅獲取新變更
  3. 衝突檢測：比較 updatedAt，應用 "last-write-wins"
  4. 本地更新：將遠端記錄同步到 SwiftData
  5. 保存 changeToken：用於下次增量同步

Response:
  changes: [
    { record: <Idea>, changeType: "inserted" | "modified" | "deleted" },
    ...
  ]
  changeToken: <opaque token for next sync>
```

---

## 錯誤處理

### CloudKit 錯誤代碼

| 錯誤代碼 | 說明 | 應用層處理 |
|---------|------|----------|
| **CKError.NotAuthenticated** | 未登入 iCloud | 提示使用者登入，進入離線模式 |
| **CKError.NetworkFailure** | 網路不可用 | 指數退避重試，離線隊列 |
| **CKError.ServerRecordChanged** | 記錄已被修改 | 應用衝突解決策略（最新 updatedAt 優先） |
| **CKError.QuotaExceeded** | 配額已滿 | 提示使用者清理 iCloud 空間 |
| **CKError.InternalError** | 伺服器內部錯誤 | 指數退避重試 |
| **CKError.ZoneBusy** | 區域繁忙 | 延遲重試（建議 60 秒後） |

### 重試策略

```
Exponential Backoff:
  Attempt 1: Wait 1 second
  Attempt 2: Wait 2 seconds
  Attempt 3: Wait 4 seconds
  After 3 failures: Stop, queue for later retry

Retry Triggers:
  - Network recovered
  - App re-entered foreground
  - User manually requested sync
  - Next scheduled background sync
```

---

## 同步流程

### 按需同步（使用者發起）

```
User Action (create/update/delete)
  ↓
Save to SwiftData (synchronous)
  ↓
Mark SyncState.isPendingSync = true
  ↓
Trigger CloudKit save (asynchronous)
  ↓
On Success:
  Update SyncState (remote version, lastSyncedAt)
  Mark isPendingSync = false
  Update local version
  ↓
On Failure:
  Log error to SyncLog
  Apply retry logic (exponential backoff)
  Keep pending state
```

### 背景同步（系統觸發）

```
iOS Background Task (URLSession + CloudKit)
  ↓
Query: updatedAt > lastSyncTime
  ↓
Fetch changes from CloudKit
  ↓
Detect Conflicts:
  if (remote.updatedAt > local.updatedAt):
    Use remote record
  else:
    Use local record
  ↓
Merge to SwiftData
  ↓
Update SyncState for all affected records
  ↓
Log sync events to SyncLog
```

### 多裝置同步

```
Device A: User creates Idea "X"
  ↓ (1 second)
Device B: CloudKit notifies of new record
  ↓
Device B: Fetches new record
  ↓
Device B: Updates local SwiftData
  ↓
Target: Sync latency P95 < 10 seconds

Conflict Scenario:
  Device A & B both modify Idea "X" simultaneously
  Device A.updatedAt = 12:00:00.100
  Device B.updatedAt = 12:00:00.050
  → Resolution: Keep Device A version (newer timestamp)
```

---

## 數據校驗

### 記錄級別校驗

```
Create/Update operations:
  ✓ id: non-empty UUID string
  ✓ title: non-empty, length <= 256
  ✓ description: length <= 4096
  ✓ isCompleted: 0 or 1
  ✓ createdAt: valid ISO 8601 timestamp
  ✓ updatedAt: valid ISO 8601 timestamp
  ✓ updatedAt >= createdAt
  ✓ deviceId: non-empty string
  ✓ version: non-negative integer
```

### 衝突檢測

```
Before applying remote change:
  if (remote.version <= local.version):
    Check timestamps for conflict resolution
    if (remote.updatedAt > local.updatedAt):
      Accept remote (newer)
    else:
      Keep local (newer or equal)
```

---

## 離線場景

### 離線建立

```
No iCloud account or no network
  ↓
Create Idea locally (SwiftData)
  ↓
Mark as isPendingSync = true
  ↓
On next sync opportunity:
  Attempt CloudKit save with local version
  If success: Update SyncState
  If conflict: Resolve using timestamps
```

### 離線更新

```
同上（使用者無感）
```

### 網路恢復

```
Network became available
  ↓
Query all SyncState where isPendingSync = true
  ↓
Batch sync (max 100 per operation)
  ↓
Apply conflict resolution for any conflicts
  ↓
Update SyncState for all affected records
```

---

## 開發指南

### Xcode CloudKit 容器設置

1. 在 Xcode 中啟用 iCloud 功能
2. 選擇 CloudKit 複選框
3. 容器 ID: `iCloud.com.buildwithharry.IdeaBox`
4. 在 Development 環境中測試

### 測試 CloudKit 操作

```swift
// 模擬網路失敗
let config = CKContainer.default().privateCloudDatabase
config.requestApplicationPermission(.userDiscoverability) { _, _ in }

// 測試衝突解決
// 使用兩個模擬器，同時修改同一記錄
```

### 監控與調試

- CloudKit 儀表板：檢查容器大小、操作日誌
- Xcode Console：CloudKit 框架日誌
- 應用層 SyncLog：記錄所有操作

---

**狀態**: ✅ CloudKit 合約定義完成，準備實現
