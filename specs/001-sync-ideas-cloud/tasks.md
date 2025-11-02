```markdown
# Tasks: 雲端同步與排序體驗

**Input**: Documentation in `/specs/001-sync-ideas-cloud/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`

## Phase 0: Project Foundation

- [ ] T001 [P] 建立並提交新的資料夾與群組：`IdeaBox/Services/Sync`, `IdeaBox/Services/Reminders`, `IdeaBox/Features/IdeaSorting`, `IdeaBox/Views/IdeaList`, `IdeaBox/Views/Components`, `IdeaBox/Shared/Localization`，同步更新 `IdeaBox.xcodeproj/project.pbxproj` 以符合計畫結構。
- [ ] T002 [P] 建立 `IdeaBox/Shared/Localization/zh-Hant.strings` 並加入同步錯誤、排序提醒、通知授權等基礎字串，以便後續故事直接使用正體中文文案。

---

## Category 1: Turn Existing Idea Struct to Support SwiftData Locally

**Goal**: 將現有 `Idea` struct 轉換為 SwiftData `@Model`，支援本地持久化與資料查詢。

### Foundational Tasks

- [X] T101 [P] 將 `IdeaBox/Models/Idea.swift` 轉換為 SwiftData `@Model`，按照 `data-model.md` 增加 `detail`, `createdAt`, `updatedAt`, `sortOrder` 欄位並移除舊的 `lastSyncedAt`, `lastSyncError`；加入 UUID 主鍵，保留 `isCompleted`。
- [X] T102 [P] 更新 `IdeaBox/IdeaBoxApp.swift` 以建立本地 `ModelContainer`（暫時不指向 CloudKit），並透過 `@Environment(\.modelContext)` 提供給整體 App。
- [X] T103 [P] 調整 `IdeaBox/ContentView.swift` 與 `IdeaBox/Views/AllIdeasView.swift` 使用 SwiftData 的 `@Query` 與 `ModelContext` 讀寫 `Idea`，替換原本的本地陣列狀態。
- [X] T104 [P] 移除 `IdeaBox/Models/Idea.swift` 中的 mock 資料或遷移至測試檔案 `IdeaBoxTests/Fixtures/MockIdea.swift`。

### Testing

- [X] T105 [P] 先撰寫 Swift Testing：在 `IdeaBoxTests/SwiftData/IdeaModelTests.swift` 驗證 `Idea` 模型的欄位、初始化與屬性存取，確保 SwiftData 轉換後行為正確。
- [X] T106 [P] 先撰寫 Swift Testing：在 `IdeaBoxTests/SwiftData/LocalPersistenceTests.swift` 模擬本地插入、查詢、更新、刪除操作，確保測試初期失敗。

### Integration

- [X] T107 更新 `IdeaBox/Views/AddIdeaSheet.swift` 以使用 `ModelContext` 儲存新想法，確保正確寫入本地資料庫。
- [X] T108 確認 `IdeaBox/Views/IdeaRow.swift` 與 `IdeaBox/Views/SearchView.swift` 可正確顯示與查詢 SwiftData 模型。
- [X] T109 執行本地測試，驗證 App 啟動、新增、編輯、刪除、查詢想法的完整流程。

---

## Category 2: Add Support of iCloud

**Goal**: 整合 SwiftData 與 CloudKit 實現跨裝置同步。

### Setup & Configuration

- [ ] T201 [P] 透過 Swift Package Manager 將 `pointfreeco/swift-dependencies`（與必要時的 `pointfreeco/swiftui-navigation`）加入 `IdeaBox.xcodeproj/project.pbxproj`，更新 `Package.resolved` 以鎖定版本並確保專案可編譯。
- [X] T202 在 `IdeaBox.xcodeproj/project.pbxproj` 啟用 iCloud (CloudKit) 與 Push Notifications 能力，必要時建立 `IdeaBox/IdeaBox.entitlements` 以指向正確的 CloudKit container。
- [X] T203 更新 `IdeaBox/IdeaBoxApp.swift` 中的 `ModelContainer` 配置，改為指向共用 CloudKit container（使用 `.cloud` 配置），啟用自動同步與衝突解決。

### Sync Service Implementation

- [X] T204 [P] 實作 `IdeaBox/Services/Sync/CloudSyncCoordinator.swift`，運用 SwiftData 變更佇列與時間戳處理上行／下行同步、變更追蹤與錯誤紀錄。
- [X] T205 [P] 建立 `IdeaBox/Services/Sync/IdeaSyncService.swift`，封裝同步觸發、重試排程與依賴注入（整合 `swift-dependencies`），監聽 `ModelContext` 變更事件。
- [X] T206 [P] 建立 `IdeaBox/Services/Sync/SyncStatusPresenter.swift` 以產出同步狀態與錯誤訊息，並確保可在 SwiftUI 檢視中監聽更新；暴露 `@Observable` 物件。

### UI Integration

- [ ] T207 將同步服務整合至 `IdeaBox/ContentView.swift`，在清單頂部顯示同步狀態（同步中、成功、失敗）。
- [ ] T208 更新 `IdeaBox/Views/IdeaList/IdeaListView.swift`，於網路恢復時觸發重新整理，顯示最近同步時間與錯誤警示。
- [ ] T209 擴充 `IdeaBox/Models/Idea.swift` 或相關延伸，確保 `lastSyncedAt` 與 `lastSyncError` 可透過 SwiftData metadata 映射並在 UI 顯示最新狀態。

### Testing

- [ ] T210 [P] 先撰寫 Swift Testing：在 `IdeaBoxTests/Sync/SyncCloudTests.swift` 模擬離線新增、雙裝置變更、衝突解決與錯誤回報，確保測試初期失敗。
- [ ] T211 [P] 先撰寫 UI 測試：在 `IdeaBoxUITests/SyncCloudUITests.swift` 建立跨裝置同步情境與狀態提示流程，確保測試初期失敗。
- [ ] T212 執行同步測試，驗證本地變更能正確上傳至 CloudKit、遠端變更能正確下載至本地。

---

## Category 3: Add SPM Support

**Goal**: 整合 Swift Package Manager 以支援模組化開發與依賴管理。

### Package Integration

- [ ] T301 [P] 檢視並審查 `pointfreeco/swift-dependencies` 的安全性與隱私合規性，確保版本相容與功能完整。
- [ ] T302 [P] 檢視並審查 `pointfreeco/swiftui-navigation`（若需要）的安全性與隱私合規性，確認是否應納入專案。
- [ ] T303 在 `IdeaBox.xcodeproj/project.pbxproj` 建立 SPM 依賴項設定，透過 Xcode UI 或 Package.swift 指定版本範圍，自動更新 `Package.resolved`。

### Dependencies Injection Setup

- [ ] T304 建立 `IdeaBox/Services/Dependencies/AppDependencies.swift`，利用 `swift-dependencies` 定義 `IdeaSyncService`, `ReminderScheduler` 等全域依賴。
- [ ] T305 [P] 更新 `IdeaBox/IdeaBoxApp.swift` 與主要檢視，使用 `@Dependency` 或 `@DependencyClient` 注入服務，替換直接初始化。
- [ ] T306 [P] 確保 SwiftData 的 `ModelContext` 可透過依賴注入框架存取，避免直接使用 `@Environment`。

### Testing with Dependencies

- [ ] T307 [P] 在 `IdeaBoxTests/Dependencies/MockDependencies.swift` 建立測試用的 mock 依賴（mock sync service、mock reminder scheduler），支援隔離測試。
- [ ] T308 [P] 先撰寫 Swift Testing：在 `IdeaBoxTests/Integration/ServiceIntegrationTests.swift` 驗證依賴注入與服務互動，確保測試初期失敗。
- [ ] T309 執行依賴注入測試，驗證所有服務能正確透過框架初始化與注入。

---

## Category 4: Schedule Local Notifications

**Goal**: 實現每日本地提醒機制以提升使用者回訪率。

### Setup & Authorization

- [ ] T401 [P] 實作 `IdeaBox/Services/Reminders/ReminderAuthorizationService.swift`，封裝 `UserNotifications` 授權請求、設定檢查與錯誤回報。
- [ ] T402 [P] 更新 `IdeaBox/IdeaBoxApp.swift` 或應用起始流程，於 App 啟動時呼叫 `ReminderAuthorizationService` 檢查權限並提示使用者授權。

### Notification Scheduling

- [ ] T403 [P] 實作 `IdeaBox/Services/Reminders/ReminderScheduler.swift`，使用 `AppStorage`／UserDefaults 儲存提醒設定（啟用、時間、訊息），安排每日 `UNCalendarNotificationTrigger` 通知。
- [ ] T404 [P] 建立 `IdeaBox/Services/Reminders/NotificationDelegate.swift`，實作 `UNUserNotificationCenterDelegate` 以處理通知到達與使用者互動（點擊通知時跳回 App）。

### UI Configuration

- [ ] T405 建立 `IdeaBox/Views/Components/ReminderSettingsView.swift`，提供使用者啟用／停用提醒、設定時間、編輯訊息內容；整合 `@AppStorage` 以即時更新設定。
- [ ] T406 更新或新增 `IdeaBox/Views/SettingsView.swift`（若不存在），將 `ReminderSettingsView` 嵌入其中，提供統一的設定入口。
- [ ] T407 將 `ReminderScheduler` 整合至 `IdeaBox/ContentView.swift` 或應用層，在設定變更時重新排程通知；顯示最近提醒狀態摘要。

### Testing

- [ ] T408 [P] 先撰寫 Swift Testing：在 `IdeaBoxTests/Reminders/DailyReminderTests.swift` 構建提醒授權、排程、停用、時間切換等情境測試，確保測試初期失敗。
- [ ] T409 [P] 先撰寫 UI 測試：在 `IdeaBoxUITests/DailyReminderUITests.swift` 模擬提醒設定流程（啟用 → 設定時間 → 儲存）與通知呈現檢查，確保測試初期失敗。
- [ ] T410 執行提醒測試，驗證授權流程、排程邏輯、通知觸發與使用者互動。

---

## Phase 5: Polish & Cross-Cutting Concerns

- [ ] T501 [P] 更新 `IdeaBox/Shared/Localization/zh-Hant.strings` 與 `IdeaBox/Assets.xcassets` 需要的文案或圖示，完成所有模組的正體中文翻譯與視覺資源。
- [ ] T502 依 `quickstart.md` 驗證完整流程：建立想法 → iCloud 同步 → 排序調整 → 提醒設定，並於 `README.md` 或 `specs/001-sync-ideas-cloud/quickstart.md` 補述實際注意事項。
- [ ] T503 執行並記錄 Swift Testing 與 UI 測試覆蓋率結果，確保各模組（SwiftData、Sync、Sorting、Reminders）測試達到規範，提交結案報告。

---

## Dependency Graph & Parallel Execution Strategy

### Dependency Order

```
Phase 0: Project Foundation
    ↓
Category 1: SwiftData Locally (T101-T109)
    ↓
Category 2: iCloud Support (T201-T212)
    ↓
Category 3: SPM Support (T301-T309) [可與 Category 4 並行]
    ↓
Category 4: Local Notifications (T401-T410)
    ↓
Phase 5: Polish & Completion
```

### Parallel Opportunities Within Categories

- **Category 1**: T101-T104 可並行設定模型與視圖；T105-T106 測試編寫可並行。
- **Category 2**: T204-T206 服務實作可部分並行（需等 T203 完成）；T210-T211 測試編寫可並行。
- **Category 3**: T301-T302 安全審查可並行；T307-T308 測試編寫可並行。
- **Category 4**: T401-T402 授權與排程可部分並行；T408-T409 測試編寫可並行。

### MVP Scope (Recommended Start Point)

**Minimum Viable Product**: 完成 **Category 1** 與 **Category 2 (T201-T209)** 後，應用即可支援本地 SwiftData 儲存與基礎 iCloud 同步，提供核心價值。後續可迭代新增排序與提醒功能。

```
