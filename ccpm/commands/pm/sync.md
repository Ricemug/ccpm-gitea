---
allowed-tools: Bash, Read, Write, LS
---

# Sync

Full bidirectional sync between local and forge.

## Usage
```
/pm:sync [epic_name]
```

If epic_name provided, sync only that epic. Otherwise sync all.

## Instructions

### 0. Initialize Forge Abstraction

```bash
source .claude/scripts/forge/config.sh
forge_init || exit 1
```

### 1. Pull from Forge

Get current state of all issues:
```bash
# Use forge abstraction to get all issues
source .claude/scripts/forge/issue-list.sh
forge_issue_list --state all
```

Note: Label filtering and detailed output may require platform-specific handling.

### 2. Update Local from Forge

For each forge issue:
- Find corresponding local file by issue number
- Compare states:
  - If forge state newer (updatedAt > local updated), update local
  - If forge closed but local open, close local
  - If forge reopened but local closed, reopen local
- Update frontmatter to match forge state

### 3. Push Local to Forge

For each local task/epic:
- If has forge URL but forge issue not found, it was deleted - mark local as archived
- If no forge URL, create new issue (like epic-sync)
- If local updated > forge updatedAt, push changes using forge abstraction

Note: Body updates may require platform-specific handling.

### 4. Handle Conflicts

If both changed (local and forge updated since last sync):
- Show both versions
- Ask user: "Local and forge both changed. Keep: (local/forge/merge)?"
- Apply user's choice

### 5. Update Sync Timestamps

Update all synced files with last_sync timestamp.

### 6. Output

```
🔄 Sync Complete

Pulled from GitHub:
  Updated: {count} files
  Closed: {count} issues
  
Pushed to GitHub:
  Updated: {count} issues
  Created: {count} new issues
  
Conflicts resolved: {count}

Status:
  ✅ All files synced
  {or list any sync failures}
```

## Important Notes

Follow `/rules/github-operations.md` for GitHub commands.
Follow `/rules/frontmatter-operations.md` for local updates.
Always backup before sync in case of issues.