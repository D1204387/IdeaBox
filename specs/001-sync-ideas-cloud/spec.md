# Feature Specification: 雲端同步與排序體驗

**Feature Branch**: `001-sync-ideas-cloud`  
**Created**: 2025-10-29  
**Status**: Draft  
**Input**: User description: "收集並儲存 Ideas 到數據庫中，並能同步至雲端\n可以在多個個人設備中共享\nIdeas 有不同的排序方式，例如按照建立日期、修改日期、英文字母、或可自行拖拉調整\n一但進行拖拉，便會覆蓋之前的自定義排序\n將會使用第三方程式碼庫提供額外功能\n建立本地提醒功能，每天給予一個提示"

## User Scenarios & Testing *(mandatory)*

> 所有敘述、驗收條件與測試說明必須使用正體中文；每個故事需對應至少一個以 Swift Testing 撰寫的自動化測試案例，並標示對應 UI 測試（若有）。

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
  
  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - 多裝置同步想法 (Priority: P1)

身為重度使用者，我想在任何個人裝置上開啟 IdeaBox 時都能看到最新的想法清單，並可離線瀏覽與稍後自動同步，確保靈感不會遺失。

**Why this priority**: 沒有可靠的跨裝置同步，資料儲存到雲端的核心價值即不存在，會直接影響使用者留存與信任。

**Independent Test**: Swift Testing：`IdeaBoxTests/SyncCloudTests.swift` 模擬本地與雲端資料差異並驗證合併結果；UI 測試：`IdeaBoxUITests/SyncCloudUITests.swift` 檢查在第二台裝置登入後清單即時更新。

**Acceptance Scenarios**:

1. **Given** 使用者在裝置 A 新增想法且網路暫時中斷，**When** 網路恢復，**Then** 該想法會自動同步到雲端並於裝置 B 顯示。
2. **Given** 裝置 A 與 B 同時開啟，**When** 裝置 B 編輯既有想法描述，**Then** 裝置 A 在 5 秒內收到更新並顯示最新內容。

---

### User Story 2 - 彈性排序控管 (Priority: P2)

身為想法整理者，我希望能以建立日期、更新日期、英文字母或自訂拖拉的方式快速重排清單，並確保拖拉後的順序會覆蓋先前自訂設定，讓我能維持心智整理邏輯。

**Why this priority**: 排序是資訊管理的主要工具，可直接提升瀏覽效率並減少尋找成本。

**Independent Test**: Swift Testing：`IdeaBoxTests/IdeaSortingTests.swift` 驗證各排序規則與自訂順序覆蓋行為；UI 測試：`IdeaBoxUITests/IdeaSortingUITests.swift` 模擬拖拉動作後檢查清單顯示順序。

**Acceptance Scenarios**:

1. **Given** 使用者選擇「建立日期」排序，**When** 新增一筆想法，**Then** 清單以最新建立時間重新排列。
2. **Given** 清單套用自訂排序，**When** 使用者拖拉任意兩筆想法交換位置，**Then** 系統儲存新的自訂順序並覆蓋舊設定。

---

### User Story 3 - 每日提醒靈感 (Priority: P3)

身為需要持續紀錄靈感的使用者，我希望每天在固定時間收到提醒，提示我檢視或新增想法，以避免遺漏重要點子。

**Why this priority**: 穩定的提醒機制可提升活躍度與資料完整性，支援長期使用。

**Independent Test**: Swift Testing：`IdeaBoxTests/DailyReminderTests.swift` 驗證提醒排程與狀態儲存；UI 測試：`IdeaBoxUITests/DailyReminderUITests.swift` 確認提醒設定流程與通知呈現。

**Acceptance Scenarios**:

1. **Given** 使用者設定每日提醒時間為上午九點，**When** 到達指定時間，**Then** 裝置會顯示含自訂提示文字的本地通知。
2. **Given** 使用者暫停提醒，**When** 過了下一個排程時間，**Then** 系統不會推送通知且於設定頁面顯示暫停狀態。

---

[Add more user stories as needed, each with an assigned priority]

### Edge Cases

- 離線期間在多個裝置上同時新增或編輯同一筆想法時的衝突合併策略與提示呈現。
- 使用者拖拉排序後立即切換至其他排序方式，再切回自訂時應保留最近一次拖拉結果。
- 雲端同步時第三方程式碼庫發生錯誤或 API 速率限制，需提供重試與使用者告知機制。
- 使用者停用每日提醒後重新開啟時，需確認裝置權限仍有效並引導授權流程。

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Functional Requirements

- **FR-001**: 系統必須將所有想法與相關欄位持久化至可靠的雲端儲存，並在本地保留快取以支援離線瀏覽。
- **FR-002**: 使用者於任一已登入裝置新增、編輯或刪除想法時，其他裝置需於 5 秒內同步更新內容或提供同步中提示。
- **FR-003**: 使用者可於列表中選擇「建立日期」、「修改日期」、「英文字母」或「自訂拖拉」四種排序方式，並立即看到排序結果。
- **FR-004**: 當使用者在「自訂拖拉」模式下更改順序時，系統需覆蓋先前自訂排序，並在其他裝置套用相同順序。
- **FR-005**: 系統需記錄每筆想法的最後同步狀態與時間戳，以便顯示同步失敗警示並支援再次嘗試。
- **FR-006**: 每日提醒須允許使用者設定提醒時間、訊息內容與啟用狀態，並在指定時間提供本地通知。
- **FR-007**: 系統需整合經評估的第三方程式碼庫以提供雲端同步或提醒所需的額外功能，並確保符合隱私與資料保護政策。
- **FR-008**: 使用者需可檢視最近同步記錄與提醒發送歷史，以便追蹤狀態與問題排查。

### Key Entities *(include if feature involves data)*

- **想法（Idea）**: 包含標題、內文、建立時間、更新時間、排序序號、自訂排序群組、同步狀態旗標。
- **同步設定（SyncProfile）**: 紀錄使用者識別資訊、最近同步時間、第三方程式碼庫權杖、同步錯誤訊息。
- **提醒排程（ReminderSchedule）**: 儲存提醒時間、訊息內容、啟用狀態、最近發送時間與授權狀態。

## Success Criteria *(mandatory)*

<!--
  ACTION REQUIRED: Define measurable success criteria.
  These must be technology-agnostic and measurable.
-->

### Measurable Outcomes

- **SC-001**: 95% 的跨裝置更新在 5 秒內完成同步，超過時間需提示狀態。
- **SC-002**: 90% 的使用者可在 2 次點擊內切換排序並獲得正確結果。
- **SC-003**: 每日提醒啟用使用者中，70% 在提醒後 10 分鐘內回到 App 並新增或更新至少一筆想法。
- **SC-004**: 雲端同步相關的客服回報率較導入前降低 40%，顯示穩定性提升。

## Assumptions

- 多裝置共享指同一使用者於個人裝置間透過相同帳號同步，非多人協作情境。
- 使用者願意授權必要的雲端與通知權限，如權限被拒系統須引導重新授權。
- 第三方程式碼庫將通過安全與隱私審查，並提供可離線暫存與重試機制。

## Dependencies

- 需選定可支援雙向同步與衝突解決的第三方雲端同步服務。
- iOS 通知權限與排程能力需可用以實現每日提醒功能。
