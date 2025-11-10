# 實現計劃：整合 SwiftData 與 iCloud 同步

**分支**: `002-swiftdata-icloud-sync` | **日期**: 2025-11-10 | **規格**: [specs/002-swiftdata-icloud-sync/spec.md](../spec.md)
**輸入**: 功能規格來自 `/specs/002-swiftdata-icloud-sync/spec.md`

## 摘要

IdeaBox 應用從使用模擬數據的 Phase 1 升級到 Phase 2，整合 SwiftData 進行本地持久化，並透過 CloudKit 支援 iCloud 同步。此實現保持 100% 的用戶界面和交互相容性，同時將資料層從記憶體遷移到永久存儲。核心特性包括：

1. **SwiftData 本地持久化** - 將 Idea 模型轉換為 @Model，支援 10,000+ 想法的存儲
2. **iCloud 同步基礎設施** - CloudKit 整合，帳戶檢測，雙向同步
3. **離線支援** - 離線模式下的變更在網路恢復時自動同步
4. **衝突解決** - 毫秒精度時間戳，記錄級別優先策略
5. **自動數據遷移** - 首次啟動時無縫遷移舊模擬數據



## 技術背景

**語言/版本**: Swift 6.2, iOS 26+ (SwiftData 最低需求 iOS 17+，已滿足)  
**主要依賴**: 
- SwiftData（iOS 17+ 系統框架，資料持久化）
- CloudKit（iOS 系統框架，iCloud 同步）
- SwiftUI（已使用最新 API：@Observable, NavigationStack, foregroundStyle()）

**存儲**: 
- 本地：SwiftData（使用 SQLite 後端）
- 遠端：CloudKit（iCloud 專用容器）

**測試**: 
- 單元測試：XCTest（數據模型、同步邏輯、衝突解決）
- UI 測試：XCUITest（用戶流程、持久化、多裝置同步）

**目標平台**: iOS 26+（iPhone 和 iPad）  
**項目類型**: 單一 iOS 應用（Swift Package 架構）

**性能目標**:
- 應用啟動時間 < 2 秒（10,000 想法）
- 同步延遲 P95 < 10 秒（使用者發起）
- 衝突自動解決 > 99%
- 電池消耗增加 < 5%

**約束條件**:
- 離線優先設計（本機存儲優先於雲同步）
- 記錄級別衝突解決（避免複雜的字段級別合併）
- 指數退避重試（1s→2s→4s，最多 3 次）
- 毫秒精度時間戳（版本控制和衝突檢測）

**規模/範圍**:
- 使用者可以儲存 10,000+ 想法
- 支援多裝置同步（5+ 個裝置）
- 維持審計日誌（30 天或更久）



## 憲法檢查

*門檻: 必須在 Phase 0 研究前通過。在 Phase 1 設計後重新檢查。*

### IdeaBox 核心原則對齐

✅ **原則一：最小可行產品優先**
- 規格明確定義了 P1（SwiftData 本地持久化）和 P2（iCloud 同步基礎設施）的分層
- P1 可獨立交付為完整 MVP，不需要 P2 功能
- 決策已做：按需同步 + 背景更新（Q1），衝突在記錄級別解決（Q2）
- **通過**: 符合 MVP 優先策略

✅ **原則二：品質與可測試性為必備條件**
- 功能需求明確列出測試標準（SC-001 至 SC-010，10 個成功標準）
- 每個用戶故事都有明確的驗收情景
- 計劃包含單元測試、UI 測試、集成測試
- 規格要求 80%+ 測試涵蓋率
- **通過**: 可測試性已內建設計

✅ **原則三：遵循 SwiftUI 現代最佳實踐**
- 使用 SwiftData（iOS 17+ 框架）
- 使用 CloudKit API（Apple 官方推薦）
- 現有 UI 保持使用 @Observable、NavigationStack、foregroundStyle()
- 無已棄用 API 使用
- **通過**: 遵循現代 SwiftUI 生態

✅ **原則四：架構清晰，職責分明**
- Models/：Idea @Model 定義、SyncState、CloudKitContainer
- Views/：現有視圖層保持不變
- Services/（新增）：SyncService、CloudKitService、MigrationService
- 單一職責：每個服務有明確邊界
- **通過**: 保持清晰的分層架構

✅ **原則五：簡單勝於複雜（YAGNI 原則）**
- 未實現編輯、分類、標籤等 Phase 3 功能
- 衝突解決採用簡單的時間戳優先（無複雜合併邏輯）
- 指數退避重試是業界標準，非過度設計
- 數據遷移在首次啟動時自動完成
- **通過**: 設計聚焦於必要功能

### 門檻評估

✅ **所有核心原則 PASS** - 無違反項目

**複雜度追蹤**：無需追蹤，未超出預期複雜度



## 項目結構

### 文檔（此特性）

```text
specs/002-swiftdata-icloud-sync/
├── plan.md              # 此文件（實現計劃）
├── research.md          # Phase 0 輸出（已完成 - 所有澄清已在規格中解決）
├── data-model.md        # Phase 1 輸出（數據模型和實體設計）
├── quickstart.md        # Phase 1 輸出（快速開始指南）
├── contracts/           # Phase 1 輸出（CloudKit 合約）
├── checklists/
│   └── requirements.md   # 品質檢查清單
└── spec.md             # 特性規格（已完成並澄清）
```

### 源代碼（倉庫根目錄）

**選定結構: 單一 iOS 應用 + Services 層**

```text
IdeaBox/
├── IdeaBoxApp.swift                  # 應用入口（無變化）
├── ContentView.swift                 # 根視圖協調器（無變化）
│
├── Models/
│   ├── Idea.swift                   # ⚠️ 改: 新增 @Model 註解，SwiftData 支援
│   │                                # 新增字段: createdAt, updatedAt, deviceId
│   │                                # 移除: mock 數據（遷移到 MigrationService）
│   └── SyncState.swift              # 新增: 追蹤同步狀態
│
├── Views/                            # 無變化
│   ├── AllIdeasView.swift
│   ├── SearchView.swift
│   ├── CompletedIdeasView.swift
│   ├── IdeaRow.swift
│   └── AddIdeaSheet.swift
│
├── Services/                         # 新增層級
│   ├── DataService.swift            # 新增: 本地 SwiftData 操作
│   ├── SyncService.swift            # 新增: 同步協調器
│   ├── CloudKitService.swift        # 新增: CloudKit API 封裝
│   ├── MigrationService.swift       # 新增: 舊數據遷移
│   └── ConflictResolver.swift       # 新增: 衝突解決邏輯
│
├── Assets.xcassets/                 # 無變化
│
├── IdeaBox.xcodeproj/               # 項目配置（需更新: CloudKit 容器）
│
└── Tests/
    ├── IdeaBoxTests/
    │   ├── Models/DataModelTests.swift       # 新增
    │   ├── Services/SyncServiceTests.swift   # 新增
    │   ├── Services/ConflictResolverTests.swift # 新增
    │   └── Integration/E2ESyncTests.swift    # 新增
    │
    └── IdeaBoxUITests/
        ├── PersistenceUITests.swift         # 新增
        ├── SyncUITests.swift                # 新增
        └── OfflineModeUITests.swift         # 新增
```

**結構決策**: 
- Services 層管理所有與 SwiftData 和 CloudKit 的交互
- Views 層保持不變，透過依賴注入接收 DataService
- Models 層新增 @Model 註解用於 SwiftData 持久化
- 測試完全覆蓋新增的服務和遷移邏輯

