# CCPM Gitea 测试计划

**测试日期**: 2025-10-07
**Gitea Server**: http://192.168.100.20:53000
**Test Repo**: ivan/ccpm-forge-test

---

## 🎯 测试目标

验证 CCPM 在 Gitea 环境中的完整工作流程，确保所有核心功能正常运作。

---

## 📋 测试环境准备

### 1. 环境检查

```bash
# 1. 检查 tea CLI
/tmp/tea --version

# 2. 检查 tea login 状态
/tmp/tea login list

# 3. 确认 tea 在 PATH 中 (或创建 alias)
export PATH="/tmp:$PATH"
tea --version
```

### 2. Clone Test Repository

```bash
# Clone Gitea test repo
cd /tmp
git clone http://192.168.100.20:53000/ivan/ccpm-forge-test.git
cd ccpm-forge-test

# 复制 CCPM 整合代码
cp -r /home/ivan/code/ccpm-forge/.claude .
```

---

## 🧪 测试案例

### 测试案例 1: Forge 侦测与初始化

**目标**: 验证自动侦测 Gitea 并正确初始化

```bash
# 测试 forge 侦测
cd /tmp/ccpm-forge-test
source .claude/scripts/forge/detect.sh
forge_type=$(detect_forge)
echo "Detected forge: $forge_type"
# 预期输出: gitea

# 测试 forge 初始化
source .claude/scripts/forge/config.sh
forge_init
echo "Forge type: $FORGE_TYPE"
# 预期输出: gitea
```

**验收标准**:
- [ ] 正确侦测为 "gitea"
- [ ] forge_init 成功执行
- [ ] 环境变量 FORGE_TYPE 设为 "gitea"

---

### 测试案例 2: Label 建立

**目标**: 验证 forge 抽象层可以建立 labels

```bash
# 使用 forge 抽象层建立 label
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

**验收标准**:
- [ ] Labels 成功建立
- [ ] 可在 Gitea web UI 看到 labels
- [ ] Label 颜色和描述正确

---

### 测试案例 3: Issue 建立

**目标**: 验证可以透过 forge 抽象层建立 issues

```bash
# 建立测试 epic issue
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

# 建立测试 task issue
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

**验收标准**:
- [ ] Epic issue 成功建立
- [ ] Task issue 成功建立
- [ ] Issues 在 Gitea web UI 可见
- [ ] Labels 正确套用

---

### 测试案例 4: Task List 更新

**目标**: 验证可以更新 epic issue body 加入 task list

```bash
# 获取当前 epic body
epic_current_body=$(tea issues list --output yaml | grep -A 20 "index: $epic_num" | grep -A 15 "body:" | tail -n +2)

# 建立包含 task list 的新 body
epic_new_body="$epic_current_body

## Tasks
- [ ] #$task_num Task: Setup test environment"

# 更新 epic issue (需要使用平台特定的方式)
# 注意: tea CLI 可能不支持 body 更新，需要确认
echo "Epic body with task list:"
echo "$epic_new_body"
```

**验收标准**:
- [ ] Epic body 包含 task list
- [ ] Task list 在 Gitea web UI 正确显示
- [ ] Checkbox 可以勾选

---

### 测试案例 5: Issue 编辑与关闭

**目标**: 验证 issue 编辑和状态变更

```bash
# 测试 issue 编辑
source .claude/scripts/forge/issue-edit.sh

forge_issue_edit $task_num --add-labels "in-progress"

# 测试 issue 关闭
forge_issue_edit $task_num --state closed

# 验证状态
tea issues list --state closed | grep "#$task_num"
```

**验收标准**:
- [ ] Labels 成功新增
- [ ] Issue 成功关闭
- [ ] 状态在 Gitea 正确显示

---

### 测试案例 6: Issue 评论

**目标**: 验证可以新增评论

```bash
# 测试评论功能
source .claude/scripts/forge/issue-comment.sh

forge_issue_comment $task_num --body "✅ Task completed successfully!

This is a test comment from CCPM forge abstraction layer."

# 验证评论
tea issues $task_num
```

**验收标准**:
- [ ] 评论成功发布
- [ ] 评论在 Gitea web UI 可见
- [ ] 评论格式正确

---

### 测试案例 7: 完整 CCPM 工作流程

**目标**: 测试完整的 Epic → Task → Sync → Close 流程

#### 7.1 准备测试 Epic

```bash
cd /tmp/ccpm-forge-test

# 创建测试 epic 结构
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

# 创建测试 task
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

#### 7.2 执行 Epic Sync (模拟)

由于是测试环境，我们需要手动执行 epic-sync 的核心步骤：

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
# (需要在 Gitea web UI 手动更新，或使用 API)

# 4. 重新命名 task 文件并更新 frontmatter
mv .claude/epics/test-feature/001.md .claude/epics/test-feature/$task_num.md

# 更新 task frontmatter (简化版)
sed -i "s|github:.*|github: http://192.168.100.20:53000/ivan/ccpm-forge-test/issues/$task_num|" \
  .claude/epics/test-feature/$task_num.md
```

#### 7.3 验证工作流程

```bash
# 检查 issues
tea issues list --state all

# 检查 epic
tea issues $epic_num

# 检查 task
tea issues $task_num
```

**验收标准**:
- [ ] Epic 成功建立并包含正确的 labels
- [ ] Task 成功建立并关联到 epic
- [ ] Task list 在 epic 中显示 (需手动验证 web UI)
- [ ] Local 文件正确更新 (task 重新命名为 issue number)

---

## 📊 测试结果记录

### 环境信息
- Gitea 版本: ___________
- tea CLI 版本: ___________
- CCPM 版本: ___________

### 测试结果总览

| 测试案例 | 状态 | 备注 |
|---------|------|------|
| 1. Forge 侦测与初始化 | ⬜ | |
| 2. Label 建立 | ⬜ | |
| 3. Issue 建立 | ⬜ | |
| 4. Task List 更新 | ⬜ | |
| 5. Issue 编辑与关闭 | ⬜ | |
| 6. Issue 评论 | ⬜ | |
| 7. 完整工作流程 | ⬜ | |

### 发现的问题

1. **问题描述**:
   - **影响程度**:
   - **解决方案**:

2. **问题描述**:
   - **影响程度**:
   - **解决方案**:

---

## 🔧 已知限制

1. **Tea CLI 限制**:
   - 不支持 JSON 输出 (仅 YAML)
   - Issue body 更新可能需要手动或 API
   - 某些进阶功能可能不支持

2. **Gitea 限制**:
   - 没有原生的 sub-issue 功能
   - 依赖 markdown task list
   - Task list 状态需手动更新

3. **CCPM 适配**:
   - Task list 更新逻辑需要进一步完善
   - 某些操作可能需要平台特定处理

---

## ✅ 测试通过标准

所有测试案例都必须通过，核心功能包括：

1. ✅ 自动侦测 Gitea
2. ✅ 建立 epic 和 task issues
3. ✅ Labels 正确套用
4. ✅ Task list 功能运作
5. ✅ Issue 状态管理
6. ✅ 评论功能

---

## 📝 下一步

测试完成后：
1. 记录所有发现的问题
2. 更新 IMPLEMENTATION_PROGRESS.md
3. 修复关键问题
4. 准备文档和使用指南
5. 考虑是否贡献回原项目
