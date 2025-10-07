---
allowed-tools: Bash, Read, Write, LS
---

# Epic Close

Mark an epic as complete when all tasks are done.

## Usage
```
/pm:epic-close <epic_name>
```

## Instructions

### 0. Initialize Forge Abstraction

```bash
source .claude/scripts/forge/config.sh
forge_init || exit 1
```

### 1. Verify All Tasks Complete

Check all task files in `.claude/epics/$ARGUMENTS/`:
- Verify all have `status: closed` in frontmatter
- If any open tasks found: "❌ Cannot close epic. Open tasks remain: {list}"

### 2. Update Epic Status

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update epic.md frontmatter:
```yaml
status: completed
progress: 100%
updated: {current_datetime}
completed: {current_datetime}
```

### 3. Update PRD Status

If epic references a PRD, update its status to "complete".

### 4. Close Epic on Forge

If epic has forge issue:
```bash
# Add completion comment
source .claude/scripts/forge/issue-comment.sh
forge_issue_comment {epic_issue_number} --body "✅ Epic completed - all tasks done"

# Close the epic issue
source .claude/scripts/forge/issue-edit.sh
forge_issue_edit {epic_issue_number} --state closed
```

### 5. Archive Option

Ask user: "Archive completed epic? (yes/no)"

If yes:
- Move epic directory to `.claude/epics/.archived/{epic_name}/`
- Create archive summary with completion date

### 6. Output

```
✅ Epic closed: $ARGUMENTS
  Tasks completed: {count}
  Duration: {days_from_created_to_completed}
  
{If archived}: Archived to .claude/epics/.archived/

Next epic: Run /pm:next to see priority work
```

## Important Notes

- Only close epics with all tasks complete
- Preserve all data when archiving
- Update related PRD status
- Follow `/rules/forge-operations.md` for forge abstraction usage