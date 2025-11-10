# 快速開始指南

**分支**: `002-swiftdata-icloud-sync`  
**日期**: 2025-11-10  
**適用**: 開發者快速上手和本地測試設置

---

## 開發環境設置

### 前置要求

- Xcode 15.0+（支援 Swift 6.2）
- macOS 14.0+
- iOS 26 模擬器或裝置
- Apple 開發者帳戶

### 1. 克隆並切換分支

```bash
cd /Users/yijouchen/Documents/GitHub/IdeaBox
git fetch origin
git checkout 002-swiftdata-icloud-sync
```

### 2. 開啟 Xcode 專案

```bash
open IdeaBox.xcodeproj
```

### 3. 配置開發團隊

1. 選擇 IdeaBox 專案
2. 選擇 IdeaBox target
3. 在 "Signing & Capabilities" 選項卡中：
   - 選擇開發團隊
   - Bundle ID: `com.buildwithharry.IdeaBox`

### 4. 啟用 CloudKit 功能

1. 在 "Signing & Capabilities" 選項卡中點擊 "+ Capability"
2. 搜尋並選擇 "iCloud"
3. 勾選 "CloudKit"
4. 選擇或建立容器：`iCloud.com.buildwithharry.IdeaBox`
5. 確保使用 "Private Database"

### 5. SwiftData 配置

SwiftData 將自動使用 @Model 註解進行配置。無需額外設置。

---

## 項目結構

```
IdeaBox/
├── IdeaBoxApp.swift              # 應用入口
├── ContentView.swift             # 根視圖
│
├── Models/
│   ├── Idea.swift               # @Model 定義（已更新）
│   ├── SyncState.swift          # 同步狀態追蹤
│   └── SyncLog.swift            # 審計日誌
│
├── Views/                        # UI 層（現有結構保持不變）
│   ├── AllIdeasView.swift
│   ├── SearchView.swift
│   ├── CompletedIdeasView.swift
│   ├── IdeaRow.swift
│   └── AddIdeaSheet.swift
│
├── Services/                     # 新增：業務邏輯層
│   ├── DataService.swift        # SwiftData 本地操作
│   ├── SyncService.swift        # 同步協調器
│   ├── CloudKitService.swift    # CloudKit API 封裝
│   ├── MigrationService.swift   # 舊數據遷移
│   └── ConflictResolver.swift   # 衝突解決
│
└── IdeaBox.xcodeproj
    └── IdeaBox.entitlements    # iCloud 權限配置
```

---

## 開發工作流

### 本地開發（單模擬器）

1. **選擇模擬器**
   ```
   選擇模擬器: iPhone 16 (iOS 26)
   確保已登入 iCloud（模擬器設置）
   ```

2. **構建和運行**
   ```bash
   Cmd + R  # 在 Xcode 中執行
   # 或從終端執行
   xcodebuild -scheme IdeaBox -destination "platform=iOS Simulator,name=iPhone 16" -configuration Debug run
   ```

3. **測試持久化（本地 SwiftData）**
   ```
   1. 應用啟動，應該看到 7 個遷移的示例想法
   2. 新增一個想法: 點擊 "+" 按鈕
   3. 關閉應用: Cmd + Q 或點擊設備主頁鍵
   4. 重新啟動應用
   5. 驗證: 新增的想法仍然存在 ✓
   ```

### 多裝置同步測試

1. **啟動兩個模擬器**
   ```bash
   # 終端 1
   xcrun simctl list devices | grep "iPhone 16"  # 取得 UDID
   xcrun simctl boot <UDID>
   
   # 終端 2（另一個 iPhone 16）
   xcrun simctl boot <另一個 UDID>
   ```

2. **在兩個模擬器上構建應用**
   ```bash
   xcodebuild -scheme IdeaBox \
     -destination "platform=iOS Simulator,name=iPhone 16,id=<UDID1>" \
     -configuration Debug run &
   
   xcodebuild -scheme IdeaBox \
     -destination "platform=iOS Simulator,name=iPhone 16,id=<UDID2>" \
     -configuration Debug run &
   ```

3. **測試同步**
   ```
   模擬器 A:
     1. 新增想法 "Test Sync"
     2. 等待 1-2 秒
   
   模擬器 B:
     1. 下拉刷新（如適用）
     2. 驗證想法 "Test Sync" 出現 ✓
   ```

### 離線模式測試

1. **禁用網路（模擬器）**
   ```
   Xcode Debug → Simulate → Network: Off
   ```

2. **新增想法（離線）**
   ```
   1. 禁用網路
   2. 新增想法
   3. 關閉應用，重新啟動
   4. 驗證想法仍存在 ✓
   ```

3. **恢復網路並同步**
   ```
   1. 啟用網路
   2. 應用應自動嘗試同步
   3. 檢查 Xcode Console 日誌
   4. 驗證同步成功 ✓
   ```

### 衝突解決測試

1. **模擬衝突**
   ```
   模擬器 A:
     1. 新增想法 "Conflict Test"
     2. 禁用網路（模擬器 A）
     3. 編輯想法標題 → "Conflict Test - A"
   
   模擬器 B:
     1. 網路保持啟用
     2. 獲取同一想法
     3. 編輯想法標題 → "Conflict Test - B"
     4. 驗證同步成功
   
   模擬器 A:
     1. 啟用網路
     2. 應用自動同步
     3. 檢查衝突解決結果
     4. 應該是較新時間戳的版本 ✓
   ```

---

## 構建和測試命令

### 構建

```bash
# Debug 構建
xcodebuild -scheme IdeaBox -configuration Debug build

# Release 構建
xcodebuild -scheme IdeaBox -configuration Release build

# 清理
xcodebuild -scheme IdeaBox clean
```

### 運行測試

```bash
# 全部測試
xcodebuild -scheme IdeaBox test -destination "platform=iOS Simulator,name=iPhone 16"

# 單元測試
xcodebuild -scheme IdeaBoxTests test -destination "platform=iOS Simulator,name=iPhone 16"

# UI 測試
xcodebuild -scheme IdeaBoxUITests test -destination "platform=iOS Simulator,name=iPhone 16"

# 特定測試類
xcodebuild -scheme IdeaBox test -destination "platform=iOS Simulator,name=iPhone 16" \
  -only-testing IdeaBoxTests/DataServiceTests

# 覆蓋率報告
xcodebuild -scheme IdeaBox \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -enableCodeCoverage YES \
  test
```

---

## 調試與日誌

### Xcode 控制台日誌

```bash
# 篩選 SwiftData 日誌
po NSLog("SwiftData: %@", message)

# 篩選 CloudKit 日誌
# 在 Xcode → Product → Scheme → Edit Scheme → Run → Arguments
# 添加環境變數: OS_ACTIVITY_MODE = default
# 添加啟動參數: -com.apple.CoreData.Logging.stderr 1
```

### 本地檔案瀏覽

```bash
# 模擬器應用沙箱路徑
~/Library/Developer/CoreSimulator/Devices/<DEVICE_ID>/data/Containers/Data/Application/<APP_ID>/

# 或使用 Xcode 窗口
# Windows → Devices and Simulators → 選擇模擬器 → 選擇應用 → 齒輪 → Download Container
```

### 清除模擬器資料

```bash
# 完全重置模擬器
xcrun simctl erase all

# 或重置特定模擬器
xcrun simctl erase <UDID>

# 清除應用資料（保留應用）
xcrun simctl uninstall <UDID> com.buildwithharry.IdeaBox
```

---

## CloudKit 調試

### CloudKit 儀表板

1. 訪問 https://icloud.developer.apple.com/cloudkit/
2. 登入 Apple 開發者帳戶
3. 選擇容器: `iCloud.com.buildwithharry.IdeaBox`
4. 查看：
   - Records：檢查同步的想法記錄
   - Activity：檢查所有操作日誌
   - Errors：檢查同步錯誤

### 本地測試容器（開發）

CloudKit 在開發環境中使用本地測試容器，無需聯網。

---

## 常見問題

### Q1: "Unable to authenticate with iCloud account"

**原因**: 模擬器未登入 iCloud

**解決**:
```
1. 打開模擬器設置
2. Settings → iCloud → 使用 Apple ID 登入
3. 在應用中，應該自動檢測到帳戶
```

### Q2: "CloudKit operation failed: Network unavailable"

**原因**: 模擬器網路已禁用

**解決**:
```
1. Xcode → Debug → Simulate Location / Network
2. 確保網路已啟用
3. 或故意禁用以測試離線模式
```

### Q3: 遷移舊數據後出現重複想法

**原因**: 遷移執行了多次

**解決**:
```
1. 清除模擬器資料: xcrun simctl erase <UDID>
2. 清除 Xcode 構建文件夾: Cmd + Shift + K
3. 重新構建和運行
```

### Q4: 同步延遲超過 10 秒

**原因**: 網路延遲或 CloudKit 配額限制

**排查**:
```
1. 檢查 Xcode Console 中的 CloudKit 日誌
2. 檢查 CloudKit Dashboard 中的操作日誌
3. 如果頻繁超時，檢查批次大小（不超過 100）
4. 考慮減少同步頻率或使用後台任務
```

---

## 部署清單

### 準備發佈前的驗證

- [ ] 所有測試通過（> 80% 涵蓋率）
- [ ] 本地持久化正常（重啟後數據保持）
- [ ] iCloud 同步正常（多裝置測試通過）
- [ ] 離線模式正常（網路禁用時功能保持）
- [ ] 衝突解決正常（時間戳優先邏輯驗證）
- [ ] 數據遷移正常（舊資料自動遷移，無丟失）
- [ ] 無記憶體洩漏（Xcode Instruments 檢查）
- [ ] 無已棄用 API（Xcode 警告檢查）

### 發佈步驟

```bash
# 1. 更新版本號
# Xcode: IdeaBox target → General → Version

# 2. 構建 Archive
xcodebuild -scheme IdeaBox -configuration Release archive

# 3. 驗證簽名
codesign -v -v IdeaBox.ipa

# 4. 提交到 App Store Connect
# 使用 Xcode 或 Transporter
```

---

## 進一步學習

### 官方文檔

- [CloudKit 文檔](https://developer.apple.com/cloudkit/)
- [SwiftData 文檔](https://developer.apple.com/swiftdata/)
- [SwiftUI 最佳實踐](https://developer.apple.com/documentation/swiftui/)

### 相關規格

- [特性規格](../spec.md) - 完整需求
- [數據模型設計](../data-model.md) - 實體定義
- [CloudKit 合約](../contracts/cloudkit-specification.md) - API 詳情
- [研究報告](../research.md) - 技術決策

### 聯繫方式

如遇問題或有疑問，請參考專案 README 或聯繫維護者。

---

**狀態**: ✅ 快速開始指南完成，開發可即刻開始
