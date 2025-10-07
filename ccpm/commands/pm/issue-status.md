---
allowed-tools: Bash, Read, LS
---

# Issue Status

Check issue status (open/closed) and current state.

## Usage
```
/pm:issue-status <issue_number>
```

## Instructions

You are checking the current status of a forge issue and providing a quick status report for: **Issue #$ARGUMENTS**

### 0. Initialize Forge Abstraction

```bash
source .claude/scripts/forge/config.sh
forge_init || exit 1
```

### 1. Fetch Issue Status
Use forge abstraction to get current status:
```bash
source .claude/scripts/forge/issue-list.sh
# GitHub uses "number:", Gitea uses "index:" - match either
forge_issue_list --state all | grep -A 10 -E "(number|index): $ARGUMENTS"
```

### 2. Status Display
Show concise status information:
```
🎫 Issue #$ARGUMENTS: {Title}
   
📊 Status: {OPEN/CLOSED}
   Last update: {timestamp}
   Assignee: {assignee or "Unassigned"}
   
🏷️ Labels: {label1}, {label2}, {label3}
```

### 3. Epic Context
If issue is part of an epic:
```
📚 Epic Context:
   Epic: {epic_name}
   Epic progress: {completed_tasks}/{total_tasks} tasks complete
   This task: {task_position} of {total_tasks}
```

### 4. Local Sync Status
Check if local files are in sync:
```
💾 Local Sync:
   Local file: {exists/missing}
   Last local update: {timestamp}
   Sync status: {in_sync/needs_sync/local_ahead/remote_ahead}
```

### 5. Quick Status Indicators
Use clear visual indicators:
- 🟢 Open and ready
- 🟡 Open with blockers  
- 🔴 Open and overdue
- ✅ Closed and complete
- ❌ Closed without completion

### 6. Actionable Next Steps
Based on status, suggest actions:
```
🚀 Suggested Actions:
   - Start work: /pm:issue-start $ARGUMENTS
   - Sync updates: /pm:issue-sync $ARGUMENTS
   - Close issue: /pm:issue-close $ARGUMENTS
   - Reopen issue: /pm:issue-reopen $ARGUMENTS
```

### 7. Batch Status
If checking multiple issues, support comma-separated list:
```
/pm:issue-status 123,124,125
```

Keep the output concise but informative, perfect for quick status checks during development of Issue #$ARGUMENTS.
