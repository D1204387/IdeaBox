# Data Model — 雲端同步與排序體驗

## 想法（Idea）
- **主鍵**: `id: UUID`
- **欄位**:
  - `title: String`（必填，1–80 字元）
  - `detail: String?`（可選，上限 2,000 字元）
  - `isCompleted: Bool`（完成狀態，預設 false）
  - `createdAt: Date`（建立時間，系統自動填入）
  - `updatedAt: Date`（最後更新時間，每次修改時更新）
  - `sortOrder: Double?`（自訂排序序號，利用間距策略便於插入）
- **索引**:
  - `createdAt`（加速依建立日期排序）
  - `updatedAt`（加速依更新日期排序）
  - `sortOrder`（加速自訂排序）
- **關聯**: 無需額外同步設定模型，依賴 SwiftData Container 追蹤變更。

## 資料流程備註
- SwiftData 將以 CloudKit container 共享 `Idea` 記錄，並自動維護變更佇列與衝突資訊（同步狀態由 SwiftData metadata 提供，不在模型中儲存）。
- Reminders 相關設定存放於 `AppStorage`／UserDefaults（欄位：`isEnabled`, `hour`, `minute`, `message`），由通知中心管理觸發狀態。
- `sortOrder` 使用浮點間距（例如在 1 與 2 之間插入 1.5）以降低重新排序成本。
