# IdeaBox

IdeaBox 是一款以 SwiftUI 打造的 iOS 應用程式，提供快速、簡單的靈感紀錄體驗。專案遵循正體中文文件與測試優先原則，確保每次迭代都具備穩定品質與清晰結構。

## SpecKit 活動紀錄

### 1. 執行 `/speckit.constitution` 工作流，制定《IdeaBox 憲章》v1.0.0，並同步更新 SpecKit 計畫、規格、任務、檢查清單模板以符合新原則。

```
/speckit.constitution
建立簡單易用的 iOS App，需要可測試，資料夾結構分明，減少單一文件的程式碼行數，在程式中附帶註解，使用正體中文
```

### 2. 執行 `/speckit.specify` 建立「雲端同步與排序體驗」規格，分支 `001-sync-ideas-cloud`。

```
/speckit.specify
收集並儲存 Ideas 到數據庫中，並能同步至雲端
可以在多個個人設備中共享
Ideas 有不同的排序方式，例如按照建立日期、修改日期、英文字母、或可自行拖拉調整
一但進行拖拉，便會覆蓋之前的自定義排序
將會使用第三方程式碼庫提供額外功能
建立本地提醒功能，每天給予一個提示
```

### 3. 執行 `/speckit.plan` 為「雲端同步與排序體驗」制定實作計畫，運用 SwiftData with iCloud、AppStorage 通知設定以及 Swift Testing 覆蓋策略。

```
/speckit.plan
使用 SwiftData with iCloud
使用預設的 SwiftUI Drag & Drop
如通過拖拉觸發切換排序方式至自定義時，需要先由彈窗提醒
有機會使用 Pointfree 提供的第三方庫，如 Navigation 及 Dependencies
Search for SwiftData + CloudKit
No need to manage user sync profile manually, let SwiftData do the work
Use local notifications without maintaining ReminderSchedule table
Remove sortGroupToken and syncState related properties as SwiftData will take care of them
```

### 4. 執行 `/speckit.tasks` 產出「雲端同步與排序體驗」的分階段任務清單，涵蓋同步、排序、
提醒三大使用者故事與測試計畫，輸出至 `specs/001-sync-ideas-cloud/tasks.md`。              
```
/speckit.tasks
```

### 5. 執行 `/speckit.implement` 實作 Category 2 - iCloud 同步基礎建設 (部分完成: T202-T206)
```
/speckit.implement
Continue Category 2 implementation
```

**完成項目**:
- ✅ T202: 新增 iCloud 與 Push Notifications 權限到 `IdeaBox.entitlements`
  - 啟用 `com.apple.developer.icloud-container-identifiers`
  - 啟用 `com.apple.developer.ubiquity-kvstore-identifier`
  - 新增 `aps-environment: development`
- ✅ T203: 更新 `IdeaBoxApp.swift` 的 `ModelContainer` 配置為 CloudKit 自動同步
  - 使用 `ModelConfiguration(cloudKitDatabase: .automatic)` 啟用 iCloud 同步
  - 保持本地持久化與雲端同步並行運作
- ✅ T204: 實作 `CloudSyncCoordinator` 服務 (`IdeaBox/Services/Sync/CloudSyncCoordinator.swift`)
  - 提供 `triggerSync()` 與 `retrySync()` 方法
  - 簡化架構：SwiftData 自動處理同步狀態，無需手動追蹤
- ✅ T205: 實作 `IdeaSyncService` (`IdeaBox/Services/Sync/IdeaSyncService.swift`)
  - 封裝同步觸發與重試邏輯
  - 自動重試機制：30 秒後重試失敗的同步操作
  - 準備整合 `swift-dependencies` 以提升測試性
- ✅ T206: 實作 `SyncStatusPresenter` (`IdeaBox/Services/Sync/SyncStatusPresenter.swift`)
  - 使用 `@Observable` 提供 UI 同步狀態
  - 顯示中文時間格式（剛剛、N分鐘前、N小時前、昨天、N天前）
  - 提供 `statusText`, `statusIcon`, `statusColor` 給 SwiftUI 視圖

**技術重點**:
- CloudKit 整合透過 SwiftData 原生支援（`.automatic` 配置）
- 移除 `Idea` 模型中的 `lastSyncedAt` 與 `lastSyncError` 欄位
  - SwiftData metadata 自動管理同步狀態
  - 簡化資料模型，避免冗餘追蹤
- 模組化架構：Sync 服務分層（Coordinator → Service → Presenter）
- 準備整合 Point-Free `swift-dependencies` 以提升依賴注入與測試能力

**待完成項目** (T201, T207-T212):
- T201: 透過 SPM 新增 `swift-dependencies`
- T207-T212: UI 整合（同步狀態視圖、手動觸發、錯誤處理、測試）

**下一步**: 整合 `swift-dependencies` (T201) 並完成同步 UI 與測試 (T207-T212)

---

### 6. 執行 `/speckit.implement` 實作 SwiftData 本地持久化支援 (Category 1: T101-T109)
```
/speckit.implement
Keep the existing views as much as possible
Add SwiftData support to the model
```

**完成項目**:
- ✅ T101: 將 `Idea` struct 轉換為 SwiftData `@Model` 類別
  - 新增欄位：`detail`, `createdAt`, `updatedAt`, `sortOrder`
  - 保留 `isCompleted` 欄位以維持現有功能
  - 使用 `@Attribute(.unique)` 標記 `id` 欄位
  - 移除 `lastSyncedAt` 和 `lastSyncError`（同步狀態由 SwiftData metadata 自動管理）
- ✅ T102: 更新 `IdeaBoxApp.swift` 建立本地 `ModelContainer`
- ✅ T103: 調整所有視圖使用 SwiftData `@Query` 與 `ModelContext`
  - `AllIdeasView`: 使用 `@Query` 按建立日期排序
  - `CompletedIdeasView`: 使用 `@Query` 與 `#Predicate` 篩選已完成想法
  - `SearchView`: 使用 `@Query` 查詢所有想法並客戶端篩選
- ✅ T104: 將 mock 資料遷移至 `IdeaBoxTests/Fixtures/MockIdea.swift`
- ✅ T105: 撰寫 Swift Testing - `IdeaBoxTests/SwiftData/IdeaModelTests.swift`
  - 測試模型欄位初始化與屬性存取（7 個測試案例）
  - 測試時間戳自動設定
  - 測試完成狀態切換、自訂排序索引
- ✅ T106: 撰寫 Swift Testing - `IdeaBoxTests/SwiftData/LocalPersistenceTests.swift`
  - 測試本地插入、查詢、更新、刪除操作（10 個測試案例）
  - 測試依照 createdAt 排序查詢
  - 測試篩選已完成想法與搜尋功能
  - 測試批次插入與完成狀態切換
- ✅ T107: 更新 `AddIdeaSheet` 使用 `ModelContext` 儲存新想法
- ✅ T108: 更新 `IdeaRow` 與 `SearchView` 顯示與查詢 SwiftData 模型
  - 使用 `@Bindable` 允許直接修改 SwiftData 物件
  - 切換完成狀態時自動更新 `updatedAt` 時間戳
- ✅ T109: 本地測試準備完成（測試檔案已建立，共 17 個測試案例）

**技術重點**:
- 從 struct 轉換為 `@Model` class 以支援 SwiftData 持久化
- 使用 `@Query` 與 `@Environment(\.modelContext)` 取代 `@State` 陣列
- 保持現有視圖結構與使用者體驗不變
- 欄位名稱從 `description` 改為 `detail` 以符合資料模型規格
- `customOrderIndex` 重新命名為 `sortOrder` 提升語意清晰度
- 移除手動同步狀態追蹤，依賴 SwiftData 原生 CloudKit 整合
- 使用 Swift Testing 框架撰寫模型與持久化測試（共 17 個測試案例）

**下一步**: 整合 iCloud 同步 (Category 2: T201-T212) 與 SPM 依賴管理 (Category 3: T301-T309)
