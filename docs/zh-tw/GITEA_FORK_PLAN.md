# CCPM Gitea Fork 開發計劃

**日期**: 2025-10-07
**目標**: 建立通用版本，同時支援 GitHub 和 Gitea

## 決策摘要

### 選擇方案：選項 B - 建立通用版本 ✅

**理由**:
- Gitea 是 GitHub 的開源替代，使用者可能同時使用兩者
- 可貢獻回原專案，造福開源社群
- tea CLI 與 gh CLI 命令結構相似，轉換成本低
- 技術上只需建立抽象層，複雜度可控

**預估工時**: 15-20 天

---

## 技術分析

### ✅ 有利因素

1. **tea CLI 功能完整**
   - issues: create, edit, close, reopen, list
   - pull requests: create, merge, close, checkout
   - labels, milestones, releases 完整支援
   - comment 功能可用

2. **架構相容性高**
   - CCPM 核心是 markdown + shell scripts
   - 邏輯與 Git forge 平台無關
   - 工作流程設計通用

3. **命令映射清楚**
   ```bash
   GitHub CLI          →  Gitea tea CLI
   ──────────────────────────────────────
   gh issue create     →  tea issue create
   gh issue edit       →  tea issue edit
   gh issue comment    →  tea issue comment
   gh pr create        →  tea pull create
   gh auth login       →  tea login add
   ```

### ⚠️ 主要挑戰

1. **gh-sub-issue 擴充功能缺失**
   - CCPM 依賴此功能建立 parent-child issue 關係
   - Gitea/tea **無對應功能**
   - **解決方案**: 使用 task list (`- [ ] #123`) 替代

2. **JSON 輸出格式差異**
   - 需驗證 tea CLI 的 `--output json` 格式
   - 可能需調整解析邏輯

3. **認證機制不同**
   - GitHub: OAuth/Token 自動化
   - Gitea: 需手動設定 server URL + token

4. **Repository 探測邏輯**
   - GitHub: `gh repo view --json nameWithOwner`
   - Gitea: tea 使用當前目錄的 git config
   - 需重寫 repository 偵測

---

## 開發階段規劃

### 階段一：驗證可行性 (1-2 天)
- [ ] 安裝並測試 tea CLI 所有必要指令
- [ ] 建立 Gitea 測試 repository
- [ ] 驗證 JSON 輸出格式
- [ ] 測試認證流程

### 階段二：建立抽象層 (3-5 天)

建立統一的 git forge 介面：

```bash
.claude/scripts/forge/
├── detect.sh         # 偵測 GitHub vs Gitea
├── init.sh           # 初始化對應的 CLI
├── issue-create.sh   # 統一的 issue 建立
├── issue-edit.sh     # 統一的 issue 編輯
├── issue-comment.sh  # 統一的 issue 評論
├── pr-create.sh      # 統一的 PR 建立
└── repo-info.sh      # 統一的 repo 資訊
```

**設計原則**:
- 對外提供一致的介面
- 內部根據 forge 類型調用對應 CLI
- 錯誤處理統一化

### 階段三：實作 Gitea 支援 (5-7 天)

#### 核心檔案修改

| 檔案 | 改動程度 | 說明 |
|------|---------|------|
| `scripts/pm/init.sh` | 大幅 | 支援 tea CLI 安裝與設定 |
| `commands/pm/epic-sync.md` | 大幅 | 使用 forge 抽象層 |
| `rules/github-operations.md` | 重寫 | 改為 `forge-operations.md` |
| `commands/pm/issue-*.md` | 中度 | 替換 CLI 調用 |
| `commands/pm/epic-*.md` | 中度 | 替換 CLI 調用 |

#### Sub-issue 替代方案實作
- epic issue 使用 task list 追蹤 sub-tasks
- 自動更新 task list 狀態
- 保持視覺化進度追蹤

### 階段四：測試與文件 (2-3 天)
- [ ] 完整工作流程測試（GitHub + Gitea）
- [ ] 撰寫 Gitea 設定文件
- [ ] 更新 README 說明雙平台支援
- [ ] 建立範例與教學

---

## 需要修改的核心檔案清單

### 高優先級（必須修改）
1. `ccpm/scripts/pm/init.sh` - 初始化流程
2. `ccpm/commands/pm/epic-sync.md` - Epic 同步
3. `ccpm/rules/github-operations.md` - 平台操作規則
4. `ccpm/commands/pm/issue-start.md` - Issue 啟動
5. `ccpm/commands/pm/issue-sync.md` - Issue 同步

### 中優先級（需調整）
6. `ccpm/commands/pm/issue-edit.md`
7. `ccpm/commands/pm/issue-close.md`
8. `ccpm/commands/pm/epic-close.md`
9. 其他 pm commands (~15 個)

### 低優先級（可選）
10. 文檔與範例更新

---

## 技術筆記

### tea CLI 重要指令

```bash
# 認證
tea login add --name myserver --url https://gitea.example.com --token abc123

# Issue 操作
tea issue create --title "Title" --body "Body" --labels "epic,task"
tea issue edit 123 --add-labels "in-progress"
tea issue close 123

# PR 操作
tea pull create --title "PR Title" --body "Description"
tea pull merge 123

# 查詢
tea issue list --output json
tea repo show
```

### 抽象層設計範例

```bash
# .claude/scripts/forge/detect.sh
detect_forge() {
  remote_url=$(git remote get-url origin 2>/dev/null || echo "")

  if [[ "$remote_url" == *"github.com"* ]]; then
    echo "github"
  elif [[ "$remote_url" == *"gitea"* ]] || command -v tea &>/dev/null; then
    echo "gitea"
  else
    echo "unknown"
  fi
}
```

---

## 下一步行動

1. ✅ 記錄對話內容（本文檔）
2. 🔄 重命名專案目錄
3. ⏳ 建立 Gitea 測試 repository
4. ⏳ 開始階段一：驗證 tea CLI 功能

---

## 參考資源

- CCPM 原專案: https://github.com/automazeio/ccpm
- Gitea tea CLI: https://gitea.com/gitea/tea
- Gitea CLI 文檔: https://docs.gitea.com/administration/command-line
- tea CLI 命令參考: https://gitea.com/gitea/tea/src/branch/main/docs/CLI.md
