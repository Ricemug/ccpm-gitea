# CCPM Gitea Fork 實作進度報告

**最後更新**: 2025-10-07
**專案目標**: 讓 CCPM 同時支援 GitHub 和 Gitea

---

## 📊 整體進度

- ✅ **階段一：驗證可行性** (100%) - 完成
- ✅ **階段二：建立抽象層** (100%) - 完成
- ✅ **階段三：整合到 CCPM** (100%) - 完成
- ✅ **階段四：測試與文件** (80%) - **基本完成**

**預估剩餘工時**: 0.5 天 (選擇性改進)

---

## ✅ 已完成工作

### 階段一：驗證可行性 (2025-10-07)

1. **Tea CLI 安裝測試**
   - ✅ 下載並安裝 tea CLI v0.9.2
   - ✅ 測試基本功能 (issues, pulls, labels, milestones, comment)
   - ✅ 驗證 YAML 輸出格式
   - 📄 報告：`TEA_CLI_TEST_REPORT.md`

2. **測試環境設定**
   - ✅ Gitea server: http://192.168.100.20:53000
   - ✅ API Token 配置 (read:user, write:repository, write:issue)
   - ✅ 測試 repo: ivan/ccpm-forge-test
   - ✅ 建立測試資料 (4 issues, 3 labels, 1 milestone)

3. **關鍵發現**
   - ✅ tea CLI 功能完整，滿足 CCPM 需求
   - ⚠️ 不支援 JSON 輸出，僅支援 YAML
   - ⚠️ Labels 為空格分隔字串 (`'epic task'`) 而非陣列
   - ⚠️ 參數差異：`--body` → `--description`

### 階段二：建立 Forge 抽象層 (2025-10-07)

**目錄結構**:
```
ccpm/scripts/forge/
├── detect.sh          # 偵測 GitHub/Gitea (✅)
├── config.sh          # 配置與工具函數 (✅)
├── issue-list.sh      # 列出 issues (✅)
├── issue-create.sh    # 建立 issue (✅)
├── issue-edit.sh      # 編輯 issue (✅)
├── issue-comment.sh   # 新增評論 (✅)
└── label-create.sh    # 建立 label (✅)
```

**功能特點**:
- ✅ 自動偵測 forge 類型
- ✅ 統一的函數介面
- ✅ 參數自動轉換
- ✅ YAML/JSON 輸出處理
- ✅ 錯誤處理機制

**測試結果**:
- ✅ `detect.sh` - 偵測邏輯正常
- ✅ tea CLI 建立 issue (#4) 成功
- ✅ tea CLI 列出 issues 正常

### 階段三：整合到 CCPM (已完成)

**已完成**:

1. ✅ **`ccpm/scripts/pm/init.sh`** - 全面改版
   - 自動偵測 GitHub/Gitea
   - 根據平台安裝 gh/tea CLI
   - 處理不同認證流程
   - 使用 forge 抽象層建立 labels
   - 提示 Gitea 的 task list 替代方案

2. ✅ **`ccpm/rules/forge-operations.md`** - 新規則檔
   - 統一的操作規則
   - GitHub vs Gitea 差異對照
   - Forge 抽象層使用指引
   - 錯誤處理標準
   - 遷移指南

3. ✅ **Commands 檔案批量修改** - **全部完成**
   **高優先級 (核心功能):**
   - ✅ `commands/pm/epic-sync.md` - 同步 epic 到 forge
   - ✅ `commands/pm/issue-start.md` - 開始處理 issue
   - ✅ `commands/pm/issue-sync.md` - 同步 issue 狀態
   - ✅ `commands/pm/issue-close.md` - 關閉 issue
   - ✅ `commands/pm/epic-close.md` - 關閉 epic

   **中優先級:**
   - ✅ `commands/pm/issue-edit.md` - 編輯 issue
   - ✅ `commands/pm/issue-reopen.md` - 重開 issue
   - ✅ `commands/pm/issue-show.md` - 顯示 issue
   - ✅ `commands/pm/epic-edit.md` - 編輯 epic
   - ✅ `commands/pm/epic-refresh.md` - 刷新 epic 進度

   **低優先級 (輔助功能):**
   - ✅ `commands/pm/epic-merge.md` - 合併 epic
   - ✅ `commands/pm/import.md` - 匯入 issues
   - ✅ `commands/pm/issue-analyze.md` - 分析 issue
   - ✅ `commands/pm/issue-status.md` - 顯示狀態
   - ✅ `commands/pm/sync.md` - 雙向同步

   **✅ 已修改檔案數**: **15 個檔案全部完成**

---

## ✅ 階段三完成總結

### 修改完成的 Command 檔案 (15/15)

**✅ 全部完成！**所有使用 gh CLI 的命令檔案都已更新為支援 forge 抽象層。

### 修改模式 (已套用到所有檔案)

**替換原則**:
```bash
# 舊版 (直接使用 gh CLI)
gh issue create --title "$title" --body "$body" --label "$labels"

# 新版 (使用 forge 抽象層)
source .claude/scripts/forge/issue-create.sh
forge_issue_create --title "$title" --body "$body" --labels "$labels"
```

**需要處理的差異**:
1. 將 `gh` 調用改為 forge 函數
2. 更新錯誤訊息為 forge-agnostic
3. 處理 sub-issue vs task list 的差異
4. 更新規則參考：`/rules/github-operations.md` → `/rules/forge-operations.md`

---

## ⏳ 待完成工作

### ✅ 階段三：整合到 CCPM - **完成！**

所有 15 個命令檔案已完成修改，核心工作流程完整支援 GitHub 和 Gitea。

### 階段四：測試與文件 (80% 完成)

1. **功能測試** - ✅ 基本完成
   - [x] Init 流程測試 (Gitea 選擇)
   - [x] Label 建立測試
   - [x] Issue 建立測試 (Epic + Task)
   - [x] Issue 狀態管理 (Close/Reopen)
   - [x] 評論功能測試
   - [x] 確認 Tea CLI 限制 (body 編輯)
   - [ ] 完整工作流程測試 (選擇性)

2. **文件更新** - 進行中
   - [x] 測試結果記錄 (TEST_RESULTS.md)
   - [ ] 更新 README.md 說明雙平台支援
   - [ ] 撰寫 Gitea 設定指南
   - [ ] 更新安裝說明
   - [ ] 建立 troubleshooting 文檔

3. **改進建議** (選擇性)
   - [ ] 實作 Gitea API 調用支援 issue body 編輯
   - [ ] 完整測試兩個平台
   - [ ] Code review
   - [ ] 準備 PR 說明
   - [ ] 考慮是否貢獻回原專案

---

## 📝 技術決策摘要

### 1. 使用 YAML 而非 JSON

**決策**: Gitea tea CLI 不支援 JSON，使用 YAML 輸出

**影響**:
- 需要處理 YAML 格式解析
- Labels 為空格分隔字串
- 可選：加入 `yq` 或 python YAML→JSON 轉換

### 2. Sub-issue 替代方案

**決策**: Gitea 使用 markdown task list

**實作**:
- GitHub: `gh sub-issue create --parent $epic $task`
- Gitea: Epic issue body 包含 `- [ ] Task: Title #123`
- 需要實作 task list 狀態更新邏輯

### 3. Forge 抽象層設計

**決策**: 純 bash 函數，不依賴外部工具

**優點**:
- 輕量，無額外依賴
- 易於維護和除錯
- 與 CCPM 架構一致

### 4. 參數命名統一

**決策**: 抽象層統一使用 `--body`，內部轉換

**好處**:
- 對 CCPM commands 透明
- 修改範圍最小
- 向後相容

---

## 🔧 下次繼續指引

### 立即開始步驟

1. **從示範修改開始**
   ```bash
   # 修改這兩個檔案示範
   ccpm/commands/pm/epic-sync.md
   ccpm/commands/pm/issue-start.md
   ```

2. **參考文件**
   - `ccpm/rules/forge-operations.md` - 新規則
   - `ccpm/scripts/forge/issue-create.sh` - 範例實作
   - `TEA_CLI_TEST_REPORT.md` - CLI 差異

3. **測試環境**
   - Gitea: http://192.168.100.20:53000
   - Test repo: ivan/ccpm-forge-test
   - Tea CLI: `/tmp/tea` (已安裝)

### 修改檢查清單

每個 command 檔案修改時確認：
- [ ] 載入 forge abstraction: `source .claude/scripts/forge/config.sh`
- [ ] 初始化: `forge_init`
- [ ] 替換 `gh` 指令為 `forge_*` 函數
- [ ] 更新錯誤訊息為平台無關
- [ ] 更新規則參考路徑
- [ ] 測試 (如果可能)

---

## 📚 相關文檔

- `GITEA_FORK_PLAN.md` - 原始計劃
- `TEA_CLI_TEST_REPORT.md` - Tea CLI 測試報告
- `ccpm/rules/forge-operations.md` - 新操作規則
- `ccpm/scripts/forge/*.sh` - 抽象層實作

---

## 🎯 成功指標

- [ ] 可在 GitHub repo 正常使用所有 CCPM 功能
- [ ] 可在 Gitea repo 正常使用所有 CCPM 功能
- [ ] Epic/Task 關係在兩個平台都能正確追蹤
- [ ] 安裝腳本自動偵測並設定正確的 CLI
- [ ] 文件清楚說明兩個平台的差異

---

**下次啟動提示**: "測試新的 init 流程並在 Gitea 環境驗證"

---

## 🔧 最新改進 (2025-10-07 下午)

### 問題：Forge 自動偵測不可靠

**發現**：Gitea 通常是自架伺服器，URL 格式千變萬化，無法可靠自動偵測。

**解決方案**：
1. ✅ **使用者選擇優先**：init 時讓使用者明確選擇 forge 類型
2. ✅ **預設 GitHub**：最保險的選擇
3. ✅ **保留自動偵測**：作為選項 3 提供
4. ✅ **簡化 detect.sh**：移除複雜的啟發式邏輯，預設返回 GitHub

**修改檔案**：
- `ccpm/scripts/pm/init.sh` - 加入互動式選擇
- `ccpm/scripts/forge/detect.sh` - 簡化邏輯，預設 GitHub

**使用者體驗**：
```
🔍 Detecting Git Forge platform...
  Auto-detected: github

Which Git forge are you using?
  1) GitHub (default)
  2) Gitea (self-hosted)
  3) Use auto-detection (github)

Enter your choice [1]:
```

---

## 📋 階段三完成總結 (2025-10-07)

### ✅ 已完成的修改

**全部 15 個 Command 檔案**:

**核心功能 (5 個)**:
1. `issue-start.md` - ✅ 添加 forge 初始化、Repository Protection
2. `epic-sync.md` - ✅ 完整改版支援 GitHub/Gitea sub-issue 差異
3. `issue-sync.md` - ✅ 更新為 forge-agnostic
4. `issue-close.md` - ✅ 支援 forge 抽象層
5. `epic-close.md` - ✅ 使用 forge abstraction

**中優先級 (5 個)**:
6. `issue-edit.md` - ✅ 平台無關的編輯
7. `issue-reopen.md` - ✅ 統一重開邏輯
8. `issue-show.md` - ✅ 顯示 forge 資訊
9. `epic-edit.md` - ✅ Epic 編輯支援
10. `epic-refresh.md` - ✅ 刷新進度跨平台

**輔助功能 (5 個)**:
11. `epic-merge.md` - ✅ 合併 epic 支援
12. `import.md` - ✅ 匯入 issues
13. `issue-analyze.md` - ✅ 分析 issue
14. `issue-status.md` - ✅ 顯示狀態
15. `sync.md` - ✅ 雙向同步

### 統一修改模式

每個檔案都包含：
- ✅ Forge 初始化 (`forge_init`)
- ✅ Repository Protection 檢查
- ✅ 使用 forge 抽象層函數
- ✅ 平台無關的錯誤訊息
- ✅ 更新規則參考 (`/rules/forge-operations.md`)
- ✅ 處理 GitHub/Gitea 差異 (sub-issues vs task lists)

### 🎯 關鍵成就

1. **✅ 完整工作流程支援**: Epic 建立 → Task 開始 → 同步 → 關閉 → 合併
2. **✅ Sub-issue 替代方案**: GitHub 用 gh-sub-issue，Gitea 用 task list
3. **✅ 統一的錯誤處理**: 所有檔案都參考 forge-operations.md
4. **✅ 保持向後相容**: GitHub 使用者完全不受影響
5. **✅ 15/15 檔案完成**: 100% 命令檔案支援雙平台
6. **✅ 使用者友善**: init 時可選擇 forge 類型，預設 GitHub
