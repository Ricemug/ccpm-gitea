---
allowed-tools: Read, Write, LS
---

# Epic Edit

Edit epic details after creation.

## Usage
```
/pm:epic-edit <epic_name>
```

## Instructions

### 0. Initialize Forge Abstraction

```bash
source .claude/scripts/forge/config.sh
forge_init || exit 1
```

### 1. Read Current Epic

Read `.claude/epics/$ARGUMENTS/epic.md`:
- Parse frontmatter
- Read content sections

### 2. Interactive Edit

Ask user what to edit:
- Name/Title
- Description/Overview
- Architecture decisions
- Technical approach
- Dependencies
- Success criteria

### 3. Update Epic File

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update epic.md:
- Preserve all frontmatter except `updated`
- Apply user's edits to content
- Update `updated` field with current datetime

### 4. Option to Update Forge

If epic has forge URL in frontmatter:
Ask: "Update forge issue? (yes/no)"

If yes:
```bash
# Update issue using tea CLI
tea issues edit {issue_number} --body "$(cat .claude/epics/$ARGUMENTS/epic.md)"
```

### 5. Output

```
✅ Updated epic: $ARGUMENTS
  Forge: Gitea
  Changes made to: {sections_edited}

{If forge updated}: Forge issue updated ✅

View epic: /pm:epic-show $ARGUMENTS
```

## Important Notes

- Preserve frontmatter history (created, github URL, etc.)
- Don't change task files when editing epic
- Follow `/rules/frontmatter-operations.md`
- Follow `/rules/forge-operations.md`