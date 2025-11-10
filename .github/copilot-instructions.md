# IdeaBox 開發指南

由所有功能計劃自動生成。最後更新: 2025-11-10

## 當前活躍技術與特性

### 002-swiftdata-icloud-sync（SwiftData + iCloud 同步）
- **狀態**: 規劃完成，Phase 0-1 設計完成
- **核心技術**: SwiftData (iOS 17+), CloudKit, iCloud 同步
- **主要目標**: 
  - 本地數據持久化（替代模擬數據）
  - iCloud 跨裝置同步
  - 離線支援與自動衝突解決
  - 毫秒精度時間戳版本控制
  - 指數退避重試機制
- **分支**: `002-swiftdata-icloud-sync`
- **規格**: `/specs/002-swiftdata-icloud-sync/spec.md`
- **計劃**: `/specs/002-swiftdata-icloud-sync/plan.md`

## 項目結構

```text
IdeaBox/
├── IdeaBoxApp.swift                    # 應用入口
├── ContentView.swift                   # 根視圖協調器
├── Models/
│   ├── Idea.swift                     # @Model 定義（SwiftData）
│   ├── SyncState.swift                # 同步狀態追蹤
│   └── SyncLog.swift                  # 審計日誌
├── Views/                              # UI 層（現有結構保持不變）
│   ├── AllIdeasView.swift
│   ├── SearchView.swift
│   ├── CompletedIdeasView.swift
│   ├── IdeaRow.swift
│   └── AddIdeaSheet.swift
├── Services/                           # 業務邏輯層（新增）
│   ├── DataService.swift              # SwiftData 本地操作
│   ├── SyncService.swift              # 同步協調器
│   ├── CloudKitService.swift          # CloudKit API 封裝
│   ├── MigrationService.swift         # 舊數據遷移
│   └── ConflictResolver.swift         # 衝突解決邏輯
├── IdeaBoxTests/                       # 單元測試（新增）
│   ├── Models/DataModelTests.swift
│   ├── Services/SyncServiceTests.swift
│   ├── Services/ConflictResolverTests.swift
│   └── Integration/E2ESyncTests.swift
└── IdeaBoxUITests/                     # UI 測試（新增）
    ├── PersistenceUITests.swift
    ├── SyncUITests.swift
    └── OfflineModeUITests.swift
```

## 命令與工作流

### 構建與運行
```bash
# Debug 構建
xcodebuild -scheme IdeaBox -configuration Debug build

# 在模擬器上運行
xcodebuild -scheme IdeaBox -destination "platform=iOS Simulator,name=iPhone 16" run

# 運行所有測試
xcodebuild -scheme IdeaBox test -destination "platform=iOS Simulator,name=iPhone 16"
```

### 特性相關指令
```bash
# 查看規劃文檔
cat specs/002-swiftdata-icloud-sync/plan.md

# 查看快速開始指南
cat specs/002-swiftdata-icloud-sync/quickstart.md

# 運行衝突解決測試
xcodebuild -scheme IdeaBoxTests test \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -only-testing IdeaBoxTests/ConflictResolverTests
```

## 代碼風格與最佳實踐

### SwiftUI 規範（IdeaBox 憲法原則三）
- ✅ 必須使用 `@Observable` 宏（不用 `ObservableObject`）
- ✅ 必須使用 `NavigationStack`（不用 `NavigationView`）
- ✅ 必須使用 `foregroundStyle()`（不用 `foregroundColor()`）
- ✅ 必須使用新版二參數 `onChange(of:)`
- ❌ 禁止使用已棄用的 API

### 數據層規範（002-swiftdata-icloud-sync 特性）
- **@Model 定義**: 所有數據模型使用 SwiftData @Model 宏
- **時間戳精度**: 所有時間戳使用毫秒精度 (Date 類型，millisecond precision)
- **衝突解決**: 記錄級別，時間戳優先策略（updatedAt 較新者獲勝）
- **版本控制**: 每個 Idea 包含 `version: Int`，從 0 開始遞增

### 同步層規範
- **按需同步 + 背景更新**: 使用者動作立即觸發，背景更新由 iOS 系統管理
- **批次大小**: CloudKit 單次操作最多 100 筆想法變更
- **重試機制**: 指數退避（1s→2s→4s），最多 3 次重試
- **離線優先**: 本地 SwiftData 優先存儲，異步同步到 CloudKit

### 測試要求
- **涵蓋率**: 所有新代碼必須 > 80% 單元測試涵蓋
- **UI 測試**: 主要用戶流程必須包含 UI 測試（持久化、多裝置同步、離線模式）
- **集成測試**: 衝突解決、數據遷移、同步恢復邏輯必須通過集成測試

### 架構規範（IdeaBox 憲法原則四）
- **Models/**: 數據模型（@Model）、業務邏輯、驗證規則
- **Views/**: UI 組件，保持 SwiftUI 最佳實踐
- **Services/**: 業務邏輯層，與外部系統（SwiftData、CloudKit）交互
- **無直接 DB 訪問**: Views 層必須通過 Services 層訪問數據

## 近期變更

### 002-swiftdata-icloud-sync 新增項目
- 新增 Services 層（DataService, SyncService, CloudKitService 等）
- Idea.swift 新增 @Model 宏和新字段（createdAt, updatedAt, deviceId, version）
- 新增 SyncState.swift 和 SyncLog.swift 數據模型
- 新增單元測試和 UI 測試套件
- CloudKit 容器配置（iCloud.com.buildwithharry.IdeaBox）

## 文檔參考

- **憲法**: `.specify/memory/constitution.md` - 項目核心原則
- **規格**: `specs/002-swiftdata-icloud-sync/spec.md` - 完整需求文檔
- **計劃**: `specs/002-swiftdata-icloud-sync/plan.md` - 實現計劃
- **研究**: `specs/002-swiftdata-icloud-sync/research.md` - 技術決策文檔
- **數據模型**: `specs/002-swiftdata-icloud-sync/data-model.md` - 實體和關係
- **CloudKit 合約**: `specs/002-swiftdata-icloud-sync/contracts/cloudkit-specification.md` - 雲同步接口
- **快速開始**: `specs/002-swiftdata-icloud-sync/quickstart.md` - 開發環境設置

## 常見問題

**Q: Idea 模型中新增的字段是什麼？**
A: 新增字段包括 createdAt (Date)、updatedAt (Date)、deviceId (String)、version (Int)，用於支持時間戳版本控制和衝突解決。

**Q: 如何測試多裝置同步？**
A: 啟動兩個 iPhone 16 模擬器，在一個上新增想法，應在 10 秒內出現在另一個上。詳見 quickstart.md。

**Q: 離線時想法如何保存？**
A: SwiftData 本地優先存儲，網路恢復時自動同步。使用 Xcode Debug 禁用網路進行測試。

**Q: 衝突如何自動解決？**
A: 記錄級別，最新的 updatedAt 時間戳版本覆寫舊版本，由 ConflictResolver.swift 實現。

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->

