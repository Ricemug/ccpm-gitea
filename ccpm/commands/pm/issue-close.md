---
allowed-tools: Bash, Read, Write, LS
---

# Issue Close

Mark an issue as complete and close it on forge.

## Usage
```
/pm:issue-close <issue_number> [completion_notes]
```

## Instructions

### 0. Initialize Forge Abstraction

```bash
source .claude/scripts/forge/config.sh
forge_init || exit 1
```

### 1. Find Local Task File

First check if `.claude/epics/*/$ARGUMENTS.md` exists (new naming).
If not found, search for task file with `github:.*issues/$ARGUMENTS` in frontmatter (old naming).
If not found: "❌ No local task for issue #$ARGUMENTS"

### 2. Update Local Status

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update task file frontmatter:
```yaml
status: closed
updated: {current_datetime}
```

### 3. Update Progress File

If progress file exists at `.claude/epics/{epic}/updates/$ARGUMENTS/progress.md`:
- Set completion: 100%
- Add completion note with timestamp
- Update last_sync with current datetime

### 4. Close on Forge

Add completion comment and close:
```bash
# Add final comment
source .claude/scripts/forge/issue-comment.sh
comment_body="✅ Task completed

$ARGUMENTS

---
Closed at: {timestamp}"
forge_issue_comment $ARGUMENTS --body "$comment_body"

# Close the issue
source .claude/scripts/forge/issue-edit.sh
forge_issue_edit $ARGUMENTS --state closed
```

### 5. Update Epic Task List on Forge

For Gitea and fallback mode, check the task checkbox in epic issue:

```bash
# Get epic name from local task file path
epic_name={extract_from_path}

# Get epic issue number from epic.md
epic_issue=$(grep 'github:' .claude/epics/$epic_name/epic.md | grep -oE '[0-9]+$')

if [ ! -z "$epic_issue" ]; then
  # Only update task list if NOT using GitHub sub-issues
  if [[ "$FORGE_TYPE" == "gitea" ]] || ! gh extension list | grep -q "yahsan2/gh-sub-issue"; then
    # Platform-specific body update
    # Note: This requires platform-specific handling until forge abstraction supports body updates
    if [[ "$FORGE_TYPE" == "github" ]]; then
      gh issue view $epic_issue --json body -q .body > /tmp/epic-body.md
      sed -i "s/- \[ \] #$ARGUMENTS/- [x] #$ARGUMENTS/" /tmp/epic-body.md
      gh issue edit $epic_issue --body-file /tmp/epic-body.md
      echo "✓ Updated epic progress on GitHub"
    elif [[ "$FORGE_TYPE" == "gitea" ]]; then
      echo "⚠️ Gitea: Epic task list update may require manual verification"
      # TODO: Implement tea CLI body update if supported
    fi
  fi
fi
```

**Note:** GitHub with gh-sub-issue automatically tracks task completion.

### 6. Update Epic Progress

- Count total tasks in epic
- Count closed tasks
- Calculate new progress percentage
- Update epic.md frontmatter progress field

### 7. Output

```
✅ Closed issue #$ARGUMENTS
  Forge: ${FORGE_TYPE}
  Local: Task marked complete
  Forge: Issue closed & epic updated
  Epic progress: {new_progress}% ({closed}/{total} tasks complete)

Next: Run /pm:next for next priority task
```

## Important Notes

- Follow `/rules/frontmatter-operations.md` for updates
- Follow `/rules/forge-operations.md` for forge commands
- Always sync local state before forge operations