# CCPM 本地模式

CCPM 可以在本地模式下完美運作，無需任何 Gitea 整合。所有管理都透過本地 markdown 檔案完成。

## 僅本地工作流程

### 1. 建立需求 (PRD)
```bash
/pm:prd-new user-authentication
```
- 建立：`.claude/prds/user-authentication.md`
- 輸出：包含需求和使用者故事的完整 PRD

### 2. 轉換為技術計劃 (Epic)
```bash
/pm:prd-parse user-authentication
```
- 建立：`.claude/epics/user-authentication/epic.md`
- 輸出：技術實施計劃

### 3. 分解為任務
```bash
/pm:epic-decompose user-authentication
```
- 建立：`.claude/epics/user-authentication/001.md`、`002.md` 等
- 輸出：包含驗收標準的個別任務檔案

### 4. 查看您的工作
```bash
/pm:epic-show user-authentication    # 查看 epic 和所有任務
/pm:status                           # 專案儀表板
/pm:prd-list                         # 列出所有 PRD
```

### 5. 處理任務
```bash
# 查看特定任務詳細資訊
cat .claude/epics/user-authentication/001.md

# 手動更新任務狀態
vim .claude/epics/user-authentication/001.md
```

## 本地建立的內容

```text
.claude/
├── prds/
│   └── user-authentication.md      # 需求文件
├── epics/
│   └── user-authentication/
│       ├── epic.md                 # 技術計劃
│       ├── 001.md                  # 任務：資料庫架構
│       ├── 002.md                  # 任務：API 端點
│       └── 003.md                  # 任務：UI 元件
└── context/
    └── README.md                   # 專案上下文
```

## 可在本地運作的命令

### ✅ 完全本地命令
- `/pm:prd-new <name>` - 建立需求
- `/pm:prd-parse <name>` - 產生技術計劃
- `/pm:epic-decompose <name>` - 分解為任務
- `/pm:epic-show <name>` - 查看 epic 和任務
- `/pm:status` - 專案儀表板
- `/pm:prd-list` - 列出 PRD
- `/pm:search <term>` - 搜尋內容
- `/pm:validate` - 檢查檔案完整性

### 🚫 僅 Gitea 命令（跳過這些）
- `/pm:epic-sync <name>` - 推送到 Gitea Issues
- `/pm:issue-sync <id>` - 更新 Gitea Issue
- `/pm:issue-start <id>` - 需要 Gitea Issue ID
- `/pm:epic-oneshot <name>` - 包含 Gitea 同步

## 本地模式的優勢

- **✅ 無外部依賴** - 無需 Gitea 帳號/網路即可運作
- **✅ 完全隱私** - 所有資料保持在本地
- **✅ 版本控制友好** - 所有檔案都是 markdown
- **✅ 團隊協作** - 透過 git 共享 `.claude/` 目錄
- **✅ 可自訂** - 自由編輯範本和工作流程
- **✅ 快速** - 無 API 呼叫或網路延遲

## 手動任務管理

任務儲存為帶有前置內容的 markdown 檔案：

```markdown
---
name: 實作使用者登入 API
status: open          # open, in-progress, completed
created: 2024-01-15T10:30:00Z
updated: 2024-01-15T10:30:00Z
parallel: true
depends_on: [001]
---

# 任務：實作使用者登入 API

## 描述
建立 POST /api/auth/login 端點...

## 驗收標準
- [ ] 端點接受電子郵件/密碼
- [ ] 成功時返回 JWT 令牌
- [ ] 根據資料庫驗證憑證
```

在您工作時手動更新 `status` 欄位：
- `open` → `in-progress` → `completed`

就是這樣！您擁有一個完全離線運作的完整專案管理系統。
