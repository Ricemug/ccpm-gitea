---
allowed-tools: Bash, Read, Write, LS, Task
---

# Issue Start

Begin work on an issue with parallel agents based on work stream analysis.

## Usage
```
/pm:issue-start <issue_number>
```

## Quick Check

0. **Repository Protection:**
   ```bash
   # Check if remote origin is the CCPM template repository
   remote_url=$(git remote get-url origin 2>/dev/null || echo "")
   if [[ "$remote_url" == *"automazeio/ccpm"* ]] || [[ "$remote_url" == *"automazeio/ccpm.git"* ]]; then
     echo "❌ ERROR: You're trying to sync with the CCPM template repository!"
     echo ""
     echo "This repository (automazeio/ccpm) is a template for others to use."
     echo "You should NOT create issues or PRs here."
     echo ""
     echo "To fix this:"
     echo "  1. Fork this repository to your own account"
     echo "  2. Update your remote origin:"
     echo "     git remote set-url origin <your-repo-url>"
     echo ""
     echo "Current remote: $remote_url"
     exit 1
   fi
   ```

1. **Initialize forge abstraction:**
   ```bash
   source .claude/scripts/forge/config.sh
   forge_init || exit 1
   ```

2. **Get issue details:**
   ```bash
   source .claude/scripts/forge/issue-list.sh
   # GitHub uses "number:", Gitea uses "index:" - match either
   forge_issue_list --state all | grep -E "(number|index):[[:space:]]*${ARGUMENTS}([[:space:]]|$)" || echo "❌ Cannot access issue #$ARGUMENTS. Check number or authentication."
   ```
   If it fails: "❌ Cannot access issue #$ARGUMENTS. Run /pm:init to configure authentication."

3. **Find local task file:**
   - First check if `.claude/epics/*/$ARGUMENTS.md` exists (new naming)
   - If not found, search for file containing `github:.*issues/$ARGUMENTS` in frontmatter (old naming)
   - If not found: "❌ No local task for issue #$ARGUMENTS. This issue may have been created outside the PM system."

4. **Check for analysis:**
   ```bash
   test -f .claude/epics/*/$ARGUMENTS-analysis.md || echo "❌ No analysis found for issue #$ARGUMENTS
   
   Run: /pm:issue-analyze $ARGUMENTS first
   Or: /pm:issue-start $ARGUMENTS --analyze to do both"
   ```
   If no analysis exists and no --analyze flag, stop execution.

## Instructions

### 1. Ensure Worktree Exists

Check if epic worktree exists:
```bash
# Find epic name from task file
epic_name={extracted_from_path}

# Check worktree
if ! git worktree list | grep -q "epic-$epic_name"; then
  echo "❌ No worktree for epic. Run: /pm:epic-start $epic_name"
  exit 1
fi
```

### 2. Read Analysis

Read `.claude/epics/{epic_name}/$ARGUMENTS-analysis.md`:
- Parse parallel streams
- Identify which can start immediately
- Note dependencies between streams

### 3. Setup Progress Tracking

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Create workspace structure:
```bash
mkdir -p .claude/epics/{epic_name}/updates/$ARGUMENTS
```

Update task file frontmatter `updated` field with current datetime.

### 4. Launch Parallel Agents

For each stream that can start immediately:

Create `.claude/epics/{epic_name}/updates/$ARGUMENTS/stream-{X}.md`:
```markdown
---
issue: $ARGUMENTS
stream: {stream_name}
agent: {agent_type}
started: {current_datetime}
status: in_progress
---

# Stream {X}: {stream_name}

## Scope
{stream_description}

## Files
{file_patterns}

## Progress
- Starting implementation
```

Launch agent using Task tool:
```yaml
Task:
  description: "Issue #$ARGUMENTS Stream {X}"
  subagent_type: "{agent_type}"
  prompt: |
    You are working on Issue #$ARGUMENTS in the epic worktree.
    
    Worktree location: ../epic-{epic_name}/
    Your stream: {stream_name}
    
    Your scope:
    - Files to modify: {file_patterns}
    - Work to complete: {stream_description}
    
    Requirements:
    1. Read full task from: .claude/epics/{epic_name}/{task_file}
    2. Work ONLY in your assigned files
    3. Commit frequently with format: "Issue #$ARGUMENTS: {specific change}"
    4. Update progress in: .claude/epics/{epic_name}/updates/$ARGUMENTS/stream-{X}.md
    5. Follow coordination rules in /rules/agent-coordination.md
    
    If you need to modify files outside your scope:
    - Check if another stream owns them
    - Wait if necessary
    - Update your progress file with coordination notes
    
    Complete your stream's work and mark as completed when done.
```

### 5. Issue Assignment

```bash
# Assign to self and mark in-progress
source .claude/scripts/forge/issue-edit.sh
forge_issue_edit $ARGUMENTS --add-labels "in-progress"

# Note: Assignee functionality depends on forge type
# GitHub: supports --add-assignee @me
# Gitea: may require manual assignment through web UI
```

### 6. Output

```
✅ Started parallel work on issue #$ARGUMENTS

Epic: {epic_name}
Worktree: ../epic-{epic_name}/

Launching {count} parallel agents:
  Stream A: {name} (Agent-1) ✓ Started
  Stream B: {name} (Agent-2) ✓ Started
  Stream C: {name} - Waiting (depends on A)

Progress tracking:
  .claude/epics/{epic_name}/updates/$ARGUMENTS/

Monitor with: /pm:epic-status {epic_name}
Sync updates: /pm:issue-sync $ARGUMENTS
```

## Error Handling

If any step fails, report clearly:
- "❌ {What failed}: {How to fix}"
- Continue with what's possible
- Never leave partial state

## Important Notes

- Follow `/rules/datetime.md` for timestamps
- Follow `/rules/forge-operations.md` for forge abstraction usage
- Keep it simple - trust that forge operations work