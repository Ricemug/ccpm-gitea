---
allowed-tools: Read, Write, LS
---

# Epic Refresh

Update epic progress based on task states.

## Usage
```
/pm:epic-refresh <epic_name>
```

## Instructions

### 0. Initialize Forge Abstraction

```bash
source .claude/scripts/forge/config.sh
forge_init || exit 1
```

### 1. Count Task Status

Scan all task files in `.claude/epics/$ARGUMENTS/`:
- Count total tasks
- Count tasks with `status: closed`
- Count tasks with `status: open`
- Count tasks with work in progress

### 2. Calculate Progress

```
progress = (closed_tasks / total_tasks) * 100
```

Round to nearest integer.

### 3. Update Forge Task List

For Gitea and fallback mode, sync task checkboxes:

```bash
# Get epic issue number from epic.md frontmatter
epic_issue={extract_from_github_field}

if [ ! -z "$epic_issue" ]; then
  # Only update task list if NOT using GitHub sub-issues
  if [[ "$FORGE_TYPE" == "gitea" ]] || ! gh extension list | grep -q "yahsan2/gh-sub-issue"; then
    # Platform-specific body update
    if [[ "$FORGE_TYPE" == "github" ]]; then
      gh issue view $epic_issue --json body -q .body > /tmp/epic-body.md

      # For each task, check its status and update checkbox
      for task_file in .claude/epics/$ARGUMENTS/[0-9]*.md; do
        task_github_line=$(grep 'github:' "$task_file" 2>/dev/null || true)
        if [ -n "$task_github_line" ]; then
          task_issue=$(echo "$task_github_line" | grep -oE '[0-9]+$' || true)
        else
          task_issue=""
        fi
        task_status=$(grep 'status:' $task_file | cut -d: -f2 | tr -d ' ')

        if [ "$task_status" = "closed" ]; then
          perl -pi -e "s/- \[ \] #$task_issue/- [x] #$task_issue/" /tmp/epic-body.md
        else
          perl -pi -e "s/- \[x\] #$task_issue/- [ ] #$task_issue/" /tmp/epic-body.md
        fi
      done

      gh issue edit $epic_issue --body-file /tmp/epic-body.md
    elif [[ "$FORGE_TYPE" == "gitea" ]]; then
      echo "⚠️ Gitea: Task list update may require manual verification"
      # TODO: Implement if tea CLI supports body updates
    fi
  fi
fi
```

**Note:** GitHub with gh-sub-issue automatically tracks task status.

### 4. Determine Epic Status

- If progress = 0% and no work started: `backlog`
- If progress > 0% and < 100%: `in-progress`
- If progress = 100%: `completed`

### 5. Update Epic

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update epic.md frontmatter:
```yaml
status: {calculated_status}
progress: {calculated_progress}%
updated: {current_datetime}
```

### 6. Output

```
🔄 Epic refreshed: $ARGUMENTS

Tasks:
  Closed: {closed_count}
  Open: {open_count}
  Total: {total_count}
  
Progress: {old_progress}% → {new_progress}%
Status: {old_status} → {new_status}
Forge: Task list updated ✓

{If complete}: Run /pm:epic-close $ARGUMENTS to close epic
{If in progress}: Run /pm:next to see priority tasks
```

## Important Notes

- This is useful after manual task edits or forge sync
- Don't modify task files, only epic status
- Preserve all other frontmatter fields
- Follow `/rules/forge-operations.md`