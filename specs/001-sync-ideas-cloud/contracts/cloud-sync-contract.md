# Cloud Sync Contract — SwiftData + CloudKit

本文件描述 SwiftData 與 CloudKit 之間的資料合約及同步流程。

## Record Types

### `Idea`
| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | 主鍵，與 SwiftData `@Model` 同步 |
| `title` | String | <= 80 字元，正體中文支援 |
| `detail` | String (optional) | <= 2,000 字元 |
| `createdAt` | Date | ISO8601 UTC |
| `updatedAt` | Date | ISO8601 UTC，衝突決策依此欄位 |
| `sortOrder` | Double (optional) | 以浮點儲存自訂順序 |
| `lastSyncedAt` | Date (optional) | SwiftData 同步完成時間（映射自 metadata） |
| `lastSyncError` | String (optional) | 最近錯誤訊息 |

## Operations

### 上行同步
- **Create/Update**: SwiftData 偵測本地變更後透過 CloudKit 將 `Idea` 記錄推送。`updatedAt` 需在上傳前更新以避免覆蓋。
- **Delete**: 刪除記錄時設置 CloudKit 刪除請求，確保其他裝置同步移除。

### 下行同步
- 透過 `CKFetchDatabaseChangesOperation` 與 change token 取得遠端變更，更新本地 SwiftData `ModelContext`。
- 若發現 `updatedAt` 較新但本地仍有未同步內容，透過 `CloudSyncCoordinator` 進行合併並在 UI 顯示提示。

### 衝突通報
- 合併產生差異時，更新 `Idea.lastSyncError` 提示使用者；同步成功後清除錯誤訊息。

## 錯誤碼對應
| CloudKit Error | 處理策略 |
|----------------|----------|
| `networkUnavailable` | 顯示同步延遲 Banner，排入重試佇列 |
| `limitExceeded` | 暫停同步 15 分鐘並於設定頁面顯示訊息 |
| `notAuthenticated` | 引導使用者登入 iCloud，並暫停自動同步 |
| `partialFailure` | 更新 `Idea.lastSyncError`，下一輪只重試失敗紀錄 |

## 安全 & 隱私
- 所有欄位僅允許在私人 Database 中操作，不建立公共資料庫。
- 資料僅包含個人想法與提醒設定，不儲存敏感個資。
