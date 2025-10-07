# Tea CLI 測試報告

**日期**: 2025-10-07
**測試版本**: tea CLI v0.9.2
**測試環境**: Gitea Server @ http://192.168.100.20:53000
**測試 Repo**: ivan/ccpm-forge-test

---

## ✅ 測試結果摘要

### 核心功能驗證

| 功能 | 狀態 | 說明 |
|------|------|------|
| 認證 (Login) | ✅ | `tea login add` 成功 |
| Issue 建立 | ✅ | `tea issues create` 正常運作 |
| Issue 列表 | ✅ | `tea issues list` 正常運作 |
| Labels 管理 | ✅ | 建立、查詢正常 |
| Milestones 管理 | ✅ | 建立、查詢正常 |
| Comment 功能 | ✅ | `tea comment` 正常運作 |
| YAML 輸出 | ✅ | `--output yaml` 正常運作 |

---

## 🔍 YAML 輸出格式分析

### Issue List 輸出格式

```yaml
-
    index: 3
    title: 'Feature: User Login'
    state: 'open'
    author: 'ivan'
    milestone: 'v1.0'
    labels: 'in-progress task'
    comments: 1
    created: '2025-10-07T01:28:00Z'
    updated: '2025-10-07T01:29:00Z'
    body: 'Implement user login functionality'
    url: 'http://192.168.100.20:53000/ivan/ccpm-forge-test/issues/3'
```

### 欄位說明

| 欄位 | 類型 | 說明 | 範例 |
|------|------|------|------|
| `index` | 整數 | Issue 編號 | `3` |
| `title` | 字串 | Issue 標題 | `'Feature: User Login'` |
| `state` | 字串 | 狀態 | `'open'` / `'closed'` |
| `author` | 字串 | 建立者用戶名 | `'ivan'` |
| `milestone` | 字串 | Milestone 名稱 | `'v1.0'` (空值為 `''`) |
| `labels` | 字串 | **空格分隔**的 label 列表 | `'epic task'` |
| `comments` | 整數 | Comment 數量 | `1` |
| `created` | ISO 時間 | 建立時間 | `'2025-10-07T01:28:00Z'` |
| `updated` | ISO 時間 | 更新時間 | `'2025-10-07T01:29:00Z'` |
| `body` | 字串 | Issue 內容 | `'Description...'` |
| `url` | 字串 | Issue URL | `'http://...'` |

---

## ⚠️ 重要發現與差異

### 1. **輸出格式限制**

❌ **不支援 JSON 輸出**
- tea CLI 不支援 `--output json`
- 支援格式：`csv, simple, table, tsv, yaml`

✅ **解決方案**：
- 使用 `--output yaml`
- YAML 格式結構清楚，易於解析
- 可用 `yq` 或簡單的文字處理工具解析

### 2. **Labels 格式差異**

⚠️ **Labels 為空格分隔字串**，不是陣列

GitHub CLI (JSON):
```json
"labels": ["epic", "task"]
```

Tea CLI (YAML):
```yaml
labels: 'epic task'
```

**影響**：
- 抽象層需要處理字串分割 (`split(' ')`)
- 需要處理空值 (`''`)

### 3. **參數名稱差異**

| GitHub CLI | Tea CLI |
|------------|---------|
| `--body` | `--description` |
| `--title` | `--title` ✅ (相同) |
| `--label` | `--labels` |

### 4. **認證要求**

Tea CLI 需要的最小權限：
```
read:user           # 必須！用於認證
write:repository    # PR 操作
write:issue         # Issue 操作
```

### 5. **Comments 欄位**

- `comments` 欄位只顯示**數量**，不包含實際內容
- 要取得 comment 內容需要額外查詢

---

## 📋 命令對應表

| 功能 | GitHub CLI | Tea CLI | 差異 |
|------|-----------|---------|------|
| 建立 Issue | `gh issue create --title "..." --body "..."` | `tea issues create --title "..." --description "..."` | 參數名 |
| 列出 Issue | `gh issue list --json fields` | `tea issues list --output yaml --fields ...` | 輸出格式 |
| 新增 Comment | `gh issue comment 123 --body "..."` | `tea comment 123 "..."` | 參數簡化 |
| 建立 Label | `gh label create --name "..." --color "..."` | `tea labels create --name "..." --color "..."` | ✅ 相同 |
| 建立 Milestone | `gh api ... (需用 API)` | `tea milestones create --title "..."` | ✅ Tea 更簡單 |
| 新增 Label 到 Issue | `gh issue edit 123 --add-label "..."` | `tea issues edit 123 --add-labels "..."` | 參數名 |

---

## ✅ 可行性結論

### 完全可行！

1. **核心功能完整** - 所有 CCPM 需要的功能都支援
2. **YAML 格式易於解析** - 比 JSON 更易讀，Shell script 友善
3. **命令結構相似** - 轉換成本低
4. **功能更豐富** - Milestones 支援比 gh CLI 更好

### 建議抽象層設計

```bash
# 統一輸出格式處理
forge_parse_issue_list() {
  local forge_type="$1"

  if [[ "$forge_type" == "github" ]]; then
    gh issue list --json index,title,state,labels --jq '.[]'
  else
    # 處理 YAML → JSON 轉換或直接處理 YAML
    tea issues list --output yaml --fields index,title,state,labels
  fi
}

# 統一 labels 格式
forge_parse_labels() {
  local labels_str="$1"  # 'epic task' or '["epic","task"]'

  if [[ "$labels_str" =~ ^\[ ]]; then
    # JSON array from GitHub
    echo "$labels_str" | jq -r '.[]'
  else
    # Space-separated string from Gitea
    echo "$labels_str" | tr ' ' '\n'
  fi
}
```

---

## 🚀 下一步行動

1. ✅ 階段一驗證 - **完成**
2. ⏭️ 階段二：建立抽象層
   - 實作 `forge/detect.sh` - 偵測 GitHub/Gitea
   - 實作 `forge/issue-*.sh` - 統一 Issue 操作
   - 處理 YAML/JSON 輸出差異
3. ⏳ 階段三：整合到 CCPM
4. ⏳ 階段四：測試與文件

---

## 📝 測試資料

測試過程建立了以下資料：

- **Issues**: 3 個
  - #1: Test Issue #1 (無 labels)
  - #2: Test Epic with Labels (labels: epic, task)
  - #3: Feature: User Login (labels: task, in-progress, milestone: v1.0, 1 comment)

- **Labels**: 3 個
  - epic (紅色)
  - task (綠色)
  - in-progress (藍色)

- **Milestones**: 1 個
  - v1.0

- **測試 Repo**: http://192.168.100.20:53000/ivan/ccpm-forge-test

---

## 結論

Tea CLI **完全滿足 CCPM 的需求**，可以安心進入階段二開發抽象層。主要工作是處理 YAML 格式和參數名稱的轉換，技術難度低。
