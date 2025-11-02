# Quickstart — 雲端同步與排序體驗

## 前置作業
1. 於 Xcode 的 Signing & Capabilities 啟用 **iCloud**（CloudKit）與 **Push Notifications**（若已開啟則確認容器一致）。
2. 更新 `IdeaBoxApp.swift`：初始化 `ModelContainer` 並指定共享的 CloudKit container identifier。
3. 透過 Swift Package Manager 新增必要套件：
   - `pointfreeco/swift-dependencies`（必要）
   - `pointfreeco/swiftui-navigation`（若規劃多層導覽時導入）
4. 檢查 `Info.plist` 是否包含 `NSUserTrackingUsageDescription` 以外的通知說明；若無則新增 `UNUserNotificationCenter` 權限描述。

## 建立資料模型
1. 在 `IdeaBox/Models/` 中使用 `@Model` 定義 `Idea`（同步資料源），提醒設定改採 `AppStorage`／UserDefaults 紀錄。
2. 為 `sortOrder` 設定 `Double` 預設值（例如透過初始化器動態賦值）。
3. 在 `IdeaBox/Services/Sync` 建立 `IdeaSyncService`：注入 `ModelContext` 與 `CloudSyncCoordinator`，讀取 SwiftData 變更佇列。

## 雲端同步
1. 實作 `CloudSyncAdapter` 負責 SwiftData 與 CloudKit 之間的同步觸發（利用 `ModelContext.persist()` 後的 `.processPendingChanges()`）。
2. 在 `SyncStatusPresenter` 中採用時間戳比較更新欄位，必要時記錄錯誤訊息於 Idea 的狀態欄位。
3. 於 App 啟動時監測網路與 CloudKit 帳號狀態，若不可用則提示使用者並等待 SwiftData 自動重試。

## 排序與拖拉
1. 在 `IdeaSortingViewModel` 暴露 `sortMode` 狀態（枚舉：建立、更新、字母、自訂）。
2. 切換至自訂模式時呼叫 `AlertState`（或內建 `Alert`）提醒「自訂排序會覆蓋既有順序」。
3. 使用 `List` + `.onMove` 實作拖拉，將更新後的順序透過 `sortOrder` 儲存並同步。

## 每日提醒
1. 在 `ReminderAuthorizationService` 實作授權流程，於首次使用時提示授權。
2. `ReminderScheduler` 建立 `UNCalendarNotificationTrigger`，每日固定時間推播。
3. 將提醒狀態存放於 `AppStorage`／UserDefaults，並同步更新 UI 顯示（無需 SwiftData 資料表）。

## 測試策略
1. Swift Testing：
   - `SyncCloudTests` 模擬離線新增、衝突合併、同步錯誤。
   - `IdeaSortingTests` 驗證各排序結果與自訂順序覆蓋邏輯。
   - `DailyReminderTests` 測試提醒排程與授權狀態切換。
2. UI 測試：
   - 在 `SyncCloudUITests` 中使用兩組模擬資料檢查同步提示。
   - `IdeaSortingUITests` 演練彈窗確認與拖拉手勢。
   - `DailyReminderUITests` 驗證設定流程與通知產生。
3. 目標覆蓋率：`IdeaBoxTests` ≥ 85%，UI 測試聚焦於關鍵流程。

## 驗收清單
- ✅ 跨裝置新增／編輯的資料可於 5 秒內同步（模擬器 + 實機驗證）。
- ✅ 排序選單與自訂拖拉皆以正體中文提示，彈窗文字與本地化資源同步。
- ✅ 使用者可在設定頁面啟用／停用提醒，停用後不再出現通知。
- ✅ SwiftData 模型與 CloudKit schema 維持一致，資料更新不會產生重複紀錄。
