# 實現計劃：整合 SwiftData 與 iCloud 同步

**分支**: `002-swiftdata-icloud-sync` | **日期**: 2025-11-10 | **規格**: [specs/002-swiftdata-icloud-sync/spec.md](../spec.md)
**輸入**: 功能規格來自 `/specs/002-swiftdata-icloud-sync/spec.md`

**註記**: 此計劃由 `/speckit.plan` 命令填寫。工作流程見 `.specify/templates/commands/plan.md`。

## 摘要

IdeaBox 應用從使用模擬數據的 Phase 1 升級到 Phase 2，整合 SwiftData 進行本地持久化，並透過 CloudKit 支援 iCloud 同步。此實現保持 100% 的用戶界面和交互相容性，同時將資料層從記憶體遷移到永久存儲。

核心特性包括：
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
- Models/ 層：數據模型 (@Model)、驗證規則、版本控制
- Views/ 層：現有 UI 組件保持不變
- Services/ 層（新增）：DataService、SyncService、CloudKitService、ConflictResolver
- Tests/ 層（新增）：單元測試、UI 測試、集成測試
- **通過**: 三層清晰分離

✅ **原則五：簡單勝於複雜 (YAGNI)**
- 不實現 P3 高級功能（編輯、分類、排序等）
- 專注 P1-P2 核心同步功能
- 決策已做：毫秒精度時間戳足夠解決衝突（不實現複雜合併邏輯）
- **通過**: 以現有需求為準，無過度設計

**檢查結果**: 5/5 原則通過 ✅ 可進行 Phase 0 研究

## 項目結構

### 文檔 (本特性)

```text
specs/002-swiftdata-icloud-sync/
├── plan.md                           # 實現計劃 (本檔案)
├── spec.md                           # 功能規格 (已完成)
├── research.md                       # Phase 0 研究報告 (待生成)
├── data-model.md                     # Phase 1 數據模型 (待生成)
├── quickstart.md                     # Phase 1 快速開始 (待生成)
├── checklists/
│   └── requirements.md               # 規格驗收清單 (待生成)
├── contracts/
│   └── cloudkit-specification.md     # CloudKit 合約 (待生成)
└── tasks.md                          # Phase 2 任務分解 (由 /speckit.tasks 生成)
```

### 源代碼 (iOS 應用)

#### 現有結構

```text
IdeaBox/
├── IdeaBoxApp.swift                  # 應用入口
├── ContentView.swift                 # 根視圖協調器
├── Models/
│   └── Idea.swift                    # 想法模型 (升級為 @Model)
└── Views/
    ├── AllIdeasView.swift            # 全部想法視圖
    ├── SearchView.swift              # 搜尋視圖
    ├── CompletedIdeasView.swift       # 已完成視圖
    ├── IdeaRow.swift                 # 想法行組件
    └── AddIdeaSheet.swift            # 新增想法表單
```

#### 新增結構

```text
Models/
├── SyncState.swift                   # 同步狀態追蹤 (新增)
└── SyncLog.swift                     # 審計日誌 (新增)

Services/                             # 業務邏輯層 (新增)
├── DataService.swift                 # SwiftData 本地操作
├── SyncService.swift                 # 同步協調器
├── CloudKitService.swift             # CloudKit API 封裝
├── MigrationService.swift            # 舊數據遷移
└── ConflictResolver.swift            # 衝突解決邏輯

IdeaBoxTests/                         # 單元測試 (新增)
├── Models/
│   └── DataModelTests.swift
├── Services/
│   ├── SyncServiceTests.swift
│   ├── CloudKitServiceTests.swift
│   ├── MigrationServiceTests.swift
│   └── ConflictResolverTests.swift
└── Integration/
    └── E2ESyncTests.swift

IdeaBoxUITests/                       # UI 測試 (新增)
├── PersistenceUITests.swift          # 本地持久化 UI 測試
├── SyncUITests.swift                 # 多裝置同步 UI 測試
└── OfflineModeUITests.swift          # 離線模式 UI 測試
```

### 技術決策

| 決策 | 選項 | 依據 |
|------|------|------|
| **同步策略** | 按需同步 + 背景更新 | 平衡電池效率與即時性 |
| **衝突解決** | 記錄級別、時間戳優先 | 符合 MVP、足以解決 99%+ 衝突 |
| **數據遷移** | 首次啟動自動遷移 | 無使用者中斷、失敗回退離線 |
| **重試機制** | 指數退避 (1s→2s→4s) | 業界標準、平衡快速恢復 |
| **時間戳精度** | 毫秒精度 | 足以區分並發修改 |
| **批次大小** | 100 筆記錄 | CloudKit 限制平衡 |

### 工作計劃

#### Phase 0 - 研究 (1 天)
- [ ] 分析 5 個技術澄清點
- [ ] 評估 SwiftData vs CoreData 權衡
- [ ] 研究 CloudKit 原生同步機制
- [ ] 產出 research.md

#### Phase 1 - 設計與規範 (3 天)
- [ ] 定義 3 個核心實體 (Idea, SyncState, SyncLog)
- [ ] 設計 CloudKit 容器配置
- [ ] 建立 5 種操作合約 (CREATE/UPDATE/DELETE/QUERY/SYNC)
- [ ] 編寫環境設置指南
- [ ] 產出 data-model.md, quickstart.md, contracts/

#### Phase 2 - 任務分解 (1 天)
- [ ] 將 P1-P4 用戶故事分解為可執行任務
- [ ] 估算每個任務工作量
- [ ] 產出 tasks.md

#### Phase 3 - 實現 (6-8 週)
- [ ] 實現 Services 層 (2 週)
- [ ] 實現數據層升級 (1 週)
- [ ] 實現數據遷移 (1 週)
- [ ] 實現 iCloud 同步 (2 週)
- [ ] 完整測試覆蓋 (2 週)

#### Phase 4 - 驗證與發佈 (1 週)
- [ ] 所有測試通過 (> 80% 涵蓋率)
- [ ] 性能測試達成目標
- [ ] 用戶驗收測試 (UAT)
- [ ] 發佈到生產環境
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
