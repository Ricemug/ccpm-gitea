# CCPM Gitea 測試計劃

**測試日期**: 2025-10-07
**Gitea Server**: http://192.168.100.20:53000
**Test Repo**: ivan/ccpm-forge-test

---

## 🎯 測試目標

驗證 CCPM 在 Gitea 環境中的完整工作流程，確保所有核心功能正常運作。

---

## 📋 測試環境準備

### 1. 環境檢查

```bash
# 1. 檢查 tea CLI
/tmp/tea --version

# 2. 檢查 tea login 狀態
/tmp/tea login list

# 3. 確認 tea 在 PATH 中 (或創建 alias)
export PATH="/tmp:$PATH"
tea --version
```

### 2. Clone Test Repository

```bash
# Clone Gitea test repo
cd /tmp
git clone http://192.168.100.20:53000/ivan/ccpm-forge-test.git
cd ccpm-forge-test

# 複製 CCPM 整合代碼
cp -r /home/ivan/code/ccpm-forge/.claude .
```

---

## 🧪 測試案例

### 測試案例 1: Forge 偵測與初始化

**目標**: 驗證自動偵測 Gitea 並正確初始化

```bash
# 測試 forge 偵測
cd /tmp/ccpm-forge-test
source .claude/scripts/forge/detect.sh
forge_type=$(detect_forge)
echo "Detected forge: $forge_type"
# 預期輸出: gitea

# 測試 forge 初始化
source .claude/scripts/forge/config.sh
forge_init
echo "Forge type: $FORGE_TYPE"
# 預期輸出: gitea
```

**驗收標準**:
- [ ] 正確偵測為 "gitea"
- [ ] forge_init 成功執行
- [ ] 環境變量 FORGE_TYPE 設為 "gitea"

---

### 測試案例 2: Label 建立

**目標**: 驗證 forge 抽象層可以建立 labels

```bash
# 使用 forge 抽象層建立 label
source .claude/scripts/forge/label-create.sh

forge_label_create \
  --name "epic" \
  --color "8B5CF6" \
  --description "Epic tracking issue"

forge_label_create \
  --name "task" \
  --color "10B981" \
  --description "Task issue"
```

**驗收標準**:
- [ ] Labels 成功建立
- [ ] 可在 Gitea web UI 看到 labels
- [ ] Label 顏色和描述正確

---

### 測試案例 3: Issue 建立

**目標**: 驗證可以透過 forge 抽象層建立 issues

```bash
# 建立測試 epic issue
source .claude/scripts/forge/issue-create.sh

epic_body="# Test Epic

## Overview
This is a test epic for CCPM Gitea integration.

## Goals
- Test epic creation
- Test task creation
- Test task list functionality"

epic_num=$(forge_issue_create \
  --title "Epic: Test CCPM Integration" \
  --body "$epic_body" \
  --labels "epic" | grep -oP '#\K[0-9]+')

echo "Created epic: #$epic_num"

# 建立測試 task issue
task_body="# Test Task 1

## Description
First test task for the epic.

## Acceptance Criteria
- [ ] Task created successfully
- [ ] Linked to epic via task list"

task_num=$(forge_issue_create \
  --title "Task: Setup test environment" \
  --body "$task_body" \
  --labels "task" | grep -oP '#\K[0-9]+')

echo "Created task: #$task_num"
```

**驗收標準**:
- [ ] Epic issue 成功建立
- [ ] Task issue 成功建立
- [ ] Issues 在 Gitea web UI 可見
- [ ] Labels 正確套用

---

### 測試案例 4: Task List 更新

**目標**: 驗證可以更新 epic issue body 加入 task list

```bash
# 獲取當前 epic body
epic_current_body=$(tea issues list --output yaml | grep -A 20 "index: $epic_num" | grep -A 15 "body:" | tail -n +2)

# 建立包含 task list 的新 body
epic_new_body="$epic_current_body

## Tasks
- [ ] #$task_num Task: Setup test environment"

# 更新 epic issue (需要使用平台特定的方式)
# 注意: tea CLI 可能不支援 body 更新，需要確認
echo "Epic body with task list:"
echo "$epic_new_body"
```

**驗收標準**:
- [ ] Epic body 包含 task list
- [ ] Task list 在 Gitea web UI 正確顯示
- [ ] Checkbox 可以勾選

---

### 測試案例 5: Issue 編輯與關閉

**目標**: 驗證 issue 編輯和狀態變更

```bash
# 測試 issue 編輯
source .claude/scripts/forge/issue-edit.sh

forge_issue_edit $task_num --add-labels "in-progress"

# 測試 issue 關閉
forge_issue_edit $task_num --state closed

# 驗證狀態
tea issues list --state closed | grep "#$task_num"
```

**驗收標準**:
- [ ] Labels 成功新增
- [ ] Issue 成功關閉
- [ ] 狀態在 Gitea 正確顯示

---

### 測試案例 6: Issue 評論

**目標**: 驗證可以新增評論

```bash
# 測試評論功能
source .claude/scripts/forge/issue-comment.sh

forge_issue_comment $task_num --body "✅ Task completed successfully!

This is a test comment from CCPM forge abstraction layer."

# 驗證評論
tea issues $task_num
```

**驗收標準**:
- [ ] 評論成功發布
- [ ] 評論在 Gitea web UI 可見
- [ ] 評論格式正確

---

### 測試案例 7: 完整 CCPM 工作流程

**目標**: 測試完整的 Epic → Task → Sync → Close 流程

#### 7.1 準備測試 Epic

```bash
cd /tmp/ccpm-forge-test

# 創建測試 epic 結構
mkdir -p .claude/epics/test-feature

cat > .claude/epics/test-feature/epic.md << 'EOF'
---
name: Test Feature
type: feature
status: backlog
created: 2025-10-07T10:00:00Z
updated: 2025-10-07T10:00:00Z
prd: none
github:
---

# Epic: Test Feature

## Overview
Test epic for CCPM Gitea integration validation.

## Goals
- Validate epic sync to Gitea
- Test task list creation
- Verify task workflow

## Tasks Created
<!-- Will be populated by epic-sync -->
EOF

# 創建測試 task
cat > .claude/epics/test-feature/001.md << 'EOF'
---
name: Setup database schema
type: task
status: open
created: 2025-10-07T10:00:00Z
updated: 2025-10-07T10:00:00Z
parallel: true
depends_on: []
github:
---

# Task: Setup database schema

## Description
Create initial database schema for the feature.

## Acceptance Criteria
- [ ] Schema designed
- [ ] Migration scripts created
- [ ] Tests passing
EOF
```

#### 7.2 執行 Epic Sync (模擬)

由於是測試環境，我們需要手動執行 epic-sync 的核心步驟：

```bash
# 1. 建立 epic issue
epic_title="Epic: Test Feature"
epic_body=$(sed '1,/^---$/d; 1,/^---$/d' .claude/epics/test-feature/epic.md)

source .claude/scripts/forge/issue-create.sh
epic_num=$(forge_issue_create \
  --title "$epic_title" \
  --body "$epic_body" \
  --labels "epic,epic:test-feature,feature" | grep -oP '#\K[0-9]+')

echo "Created epic: #$epic_num"

# 2. 建立 task issue
task_title="Setup database schema"
task_body=$(sed '1,/^---$/d; 1,/^---$/d' .claude/epics/test-feature/001.md)

task_num=$(forge_issue_create \
  --title "$task_title" \
  --body "$task_body" \
  --labels "task,epic:test-feature" | grep -oP '#\K[0-9]+')

echo "Created task: #$task_num"

# 3. 更新 epic issue 加入 task list
# (需要在 Gitea web UI 手動更新，或使用 API)

# 4. 重新命名 task 檔案並更新 frontmatter
mv .claude/epics/test-feature/001.md .claude/epics/test-feature/$task_num.md

# 更新 task frontmatter (簡化版)
sed -i "s|github:.*|github: http://192.168.100.20:53000/ivan/ccpm-forge-test/issues/$task_num|" \
  .claude/epics/test-feature/$task_num.md
```

#### 7.3 驗證工作流程

```bash
# 檢查 issues
tea issues list --state all

# 檢查 epic
tea issues $epic_num

# 檢查 task
tea issues $task_num
```

**驗收標準**:
- [ ] Epic 成功建立並包含正確的 labels
- [ ] Task 成功建立並關聯到 epic
- [ ] Task list 在 epic 中顯示 (需手動驗證 web UI)
- [ ] Local 檔案正確更新 (task 重新命名為 issue number)

---

## 📊 測試結果記錄

### 環境資訊
- Gitea 版本: ___________
- tea CLI 版本: ___________
- CCPM 版本: ___________

### 測試結果總覽

| 測試案例 | 狀態 | 備註 |
|---------|------|------|
| 1. Forge 偵測與初始化 | ⬜ | |
| 2. Label 建立 | ⬜ | |
| 3. Issue 建立 | ⬜ | |
| 4. Task List 更新 | ⬜ | |
| 5. Issue 編輯與關閉 | ⬜ | |
| 6. Issue 評論 | ⬜ | |
| 7. 完整工作流程 | ⬜ | |

### 發現的問題

1. **問題描述**:
   - **影響程度**:
   - **解決方案**:

2. **問題描述**:
   - **影響程度**:
   - **解決方案**:

---

## 🔧 已知限制

1. **Tea CLI 限制**:
   - 不支援 JSON 輸出 (僅 YAML)
   - Issue body 更新可能需要手動或 API
   - 某些進階功能可能不支援

2. **Gitea 限制**:
   - 沒有原生的 sub-issue 功能
   - 依賴 markdown task list
   - Task list 狀態需手動更新

3. **CCPM 適配**:
   - Task list 更新邏輯需要進一步完善
   - 某些操作可能需要平台特定處理

---

## ✅ 測試通過標準

所有測試案例都必須通過，核心功能包括：

1. ✅ 自動偵測 Gitea
2. ✅ 建立 epic 和 task issues
3. ✅ Labels 正確套用
4. ✅ Task list 功能運作
5. ✅ Issue 狀態管理
6. ✅ 評論功能

---

## 📝 下一步

測試完成後：
1. 記錄所有發現的問題
2. 更新 IMPLEMENTATION_PROGRESS.md
3. 修復關鍵問題
4. 準備文檔和使用指南
5. 考慮是否貢獻回原專案
