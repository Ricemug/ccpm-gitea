---
allowed-tools: Bash, Read, Write, LS
---

# Issue Edit

Edit issue details locally and on forge.

## Usage
```
/pm:issue-edit <issue_number>
```

## Instructions

### 0. Initialize Forge Abstraction

```bash
source .claude/scripts/forge/config.sh
forge_init || exit 1
```

### 1. Get Current Issue State

```bash
# Get from forge using abstraction
source .claude/scripts/forge/issue-list.sh
# GitHub uses "number:", Gitea uses "index:" - match either
forge_issue_list --state all | grep -A 10 -E "(number|index): $ARGUMENTS"

# Find local task file
# Search for file with github:.*issues/$ARGUMENTS
```

### 2. Interactive Edit

Ask user what to edit:
- Title
- Description/Body
- Labels
- Acceptance criteria (local only)
- Priority/Size (local only)

### 3. Update Local File

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update task file with changes:
- Update frontmatter `name` if title changed
- Update body content if description changed
- Update `updated` field with current datetime

### 4. Update Forge

Use forge abstraction for updates:

If title or labels changed:
```bash
source .claude/scripts/forge/issue-edit.sh

# Update title
[ -n "{new_title}" ] && forge_issue_edit $ARGUMENTS --title "{new_title}"

# Update labels
[ -n "{new_labels}" ] && forge_issue_edit $ARGUMENTS --add-labels "{new_labels}"
```

Note: Body updates require platform-specific handling.
For critical body updates, use native CLI:
- GitHub: `gh issue edit $ARGUMENTS --body-file {file}`
- Gitea: May require manual update via web UI

### 5. Output

```
✅ Updated issue #$ARGUMENTS
  Forge: ${FORGE_TYPE}
  Changes:
    {list_of_changes_made}

Synced to forge: ✅
```

## Important Notes

- Always update local first, then forge
- Preserve frontmatter fields not being edited
- Follow `/rules/frontmatter-operations.md`
- Follow `/rules/forge-operations.md`