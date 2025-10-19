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
  # Update task list on Gitea
  echo "⚠️ Gitea: Task list update may require manual verification"
  echo "  You can manually update the epic issue #$epic_issue on Gitea"
  echo "  Or use: tea issues edit $epic_issue --body-file .claude/epics/$ARGUMENTS/epic.md"
fi
```

**Note:** Gitea uses task lists in issue bodies for epic tracking.

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