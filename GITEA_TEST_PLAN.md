# CCPM Gitea Test Plan

**Test Date**: 2025-10-07
**Gitea Server**: http://192.168.100.20:53000
**Test Repo**: ivan/ccpm-forge-test

---

## 🎯 Test Objectives

Validate the complete CCPM workflow in a Gitea environment, ensuring all core functions work properly.

---

## 📋 Test Environment Setup

### 1. Environment Check

```bash
# 1. Check tea CLI
/tmp/tea --version

# 2. Check tea login status
/tmp/tea login list

# 3. Ensure tea is in PATH (or create alias)
export PATH="/tmp:$PATH"
tea --version
```

### 2. Clone Test Repository

```bash
# Clone Gitea test repo
cd /tmp
git clone http://192.168.100.20:53000/ivan/ccpm-forge-test.git
cd ccpm-forge-test

# Copy CCPM integration code
cp -r /home/ivan/code/ccpm-forge/.claude .
```

---

## 🧪 Test Cases

### Test Case 1: Forge Detection and Initialization

**Objective**: Verify automatic Gitea detection and proper initialization

```bash
# Test forge detection
cd /tmp/ccpm-forge-test
source .claude/scripts/forge/detect.sh
forge_type=$(detect_forge)
echo "Detected forge: $forge_type"
# Expected output: gitea

# Test forge initialization
source .claude/scripts/forge/config.sh
forge_init
echo "Forge type: $FORGE_TYPE"
# Expected output: gitea
```

**Acceptance Criteria**:
- [ ] Correctly detected as "gitea"
- [ ] forge_init executes successfully
- [ ] Environment variable FORGE_TYPE set to "gitea"

---

### Test Case 2: Label Creation

**Objective**: Verify forge abstraction layer can create labels

```bash
# Create labels using forge abstraction layer
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

**Acceptance Criteria**:
- [ ] Labels created successfully
- [ ] Labels visible in Gitea web UI
- [ ] Label colors and descriptions correct

---

### Test Case 3: Issue Creation

**Objective**: Verify issue creation through forge abstraction layer

```bash
# Create test epic issue
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

# Create test task issue
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

**Acceptance Criteria**:
- [ ] Epic issue created successfully
- [ ] Task issue created successfully
- [ ] Issues visible in Gitea web UI
- [ ] Labels correctly applied

---

### Test Case 4: Task List Update

**Objective**: Verify epic issue body can be updated with task list

```bash
# Get current epic body
epic_current_body=$(tea issues list --output yaml | grep -A 20 "index: $epic_num" | grep -A 15 "body:" | tail -n +2)

# Create new body with task list
epic_new_body="$epic_current_body

## Tasks
- [ ] #$task_num Task: Setup test environment"

# Update epic issue (using platform-specific method)
# Note: tea CLI may not support body updates, needs verification
echo "Epic body with task list:"
echo "$epic_new_body"
```

**Acceptance Criteria**:
- [ ] Epic body contains task list
- [ ] Task list displays correctly in Gitea web UI
- [ ] Checkboxes are clickable

---

### Test Case 5: Issue Edit and Close

**Objective**: Verify issue editing and status changes

```bash
# Test issue editing
source .claude/scripts/forge/issue-edit.sh

forge_issue_edit $task_num --add-labels "in-progress"

# Test issue closing
forge_issue_edit $task_num --state closed

# Verify status
tea issues list --state closed | grep "#$task_num"
```

**Acceptance Criteria**:
- [ ] Labels added successfully
- [ ] Issue closed successfully
- [ ] Status displays correctly in Gitea

---

### Test Case 6: Issue Comments

**Objective**: Verify comment functionality

```bash
# Test comment feature
source .claude/scripts/forge/issue-comment.sh

forge_issue_comment $task_num --body "✅ Task completed successfully!

This is a test comment from CCPM forge abstraction layer."

# Verify comment
tea issues $task_num
```

**Acceptance Criteria**:
- [ ] Comment posted successfully
- [ ] Comment visible in Gitea web UI
- [ ] Comment format correct

---

### Test Case 7: Complete CCPM Workflow

**Objective**: Test complete Epic → Task → Sync → Close workflow

#### 7.1 Prepare Test Epic

```bash
cd /tmp/ccpm-forge-test

# Create test epic structure
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

# Create test task
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

#### 7.2 Execute Epic Sync (Simulated)

Since this is a test environment, we need to manually execute epic-sync core steps:

```bash
# 1. Create epic issue
epic_title="Epic: Test Feature"
epic_body=$(sed '1,/^---$/d; 1,/^---$/d' .claude/epics/test-feature/epic.md)

source .claude/scripts/forge/issue-create.sh
epic_num=$(forge_issue_create \
  --title "$epic_title" \
  --body "$epic_body" \
  --labels "epic,epic:test-feature,feature" | grep -oP '#\K[0-9]+')

echo "Created epic: #$epic_num"

# 2. Create task issue
task_title="Setup database schema"
task_body=$(sed '1,/^---$/d; 1,/^---$/d' .claude/epics/test-feature/001.md)

task_num=$(forge_issue_create \
  --title "$task_title" \
  --body "$task_body" \
  --labels "task,epic:test-feature" | grep -oP '#\K[0-9]+')

echo "Created task: #$task_num"

# 3. Update epic issue with task list
# (Needs manual update in Gitea web UI, or use API)

# 4. Rename task file and update frontmatter
mv .claude/epics/test-feature/001.md .claude/epics/test-feature/$task_num.md

# Update task frontmatter (simplified)
sed -i "s|github:.*|github: http://192.168.100.20:53000/ivan/ccpm-forge-test/issues/$task_num|" \
  .claude/epics/test-feature/$task_num.md
```

#### 7.3 Verify Workflow

```bash
# Check issues
tea issues list --state all

# Check epic
tea issues $epic_num

# Check task
tea issues $task_num
```

**Acceptance Criteria**:
- [ ] Epic created successfully with correct labels
- [ ] Task created successfully and linked to epic
- [ ] Task list displays in epic (manual verification in web UI)
- [ ] Local files updated correctly (task renamed to issue number)

---

## 📊 Test Results Log

### Environment Information
- Gitea Version: ___________
- tea CLI Version: ___________
- CCPM Version: ___________

### Test Results Summary

| Test Case | Status | Notes |
|-----------|--------|-------|
| 1. Forge Detection and Initialization | ⬜ | |
| 2. Label Creation | ⬜ | |
| 3. Issue Creation | ⬜ | |
| 4. Task List Update | ⬜ | |
| 5. Issue Edit and Close | ⬜ | |
| 6. Issue Comments | ⬜ | |
| 7. Complete Workflow | ⬜ | |

### Issues Found

1. **Issue Description**:
   - **Impact Level**:
   - **Solution**:

2. **Issue Description**:
   - **Impact Level**:
   - **Solution**:

---

## 🔧 Known Limitations

1. **Tea CLI Limitations**:
   - No JSON output support (YAML only)
   - Issue body updates may require manual editing or API
   - Some advanced features may not be supported

2. **Gitea Limitations**:
   - No native sub-issue functionality
   - Relies on markdown task lists
   - Task list status requires manual updates

3. **CCPM Adaptations**:
   - Task list update logic needs further refinement
   - Some operations may require platform-specific handling

---

## ✅ Test Pass Criteria

All test cases must pass, core functionality includes:

1. ✅ Automatic Gitea detection
2. ✅ Create epic and task issues
3. ✅ Labels correctly applied
4. ✅ Task list functionality works
5. ✅ Issue status management
6. ✅ Comment functionality

---

## 📝 Next Steps

After testing:
1. Record all discovered issues
2. Update IMPLEMENTATION_PROGRESS.md
3. Fix critical issues
4. Prepare documentation and user guides
5. Consider contributing back to original project
