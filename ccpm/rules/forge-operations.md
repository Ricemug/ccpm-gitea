# Git Forge Operations Rule

Standard patterns for Git Forge operations across all commands. Supports both GitHub and Gitea.

## CRITICAL: Repository Protection

**Before ANY forge operation that creates/modifies issues or PRs:**

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

This check MUST be performed in ALL commands that:
- Create issues
- Edit issues
- Comment on issues
- Create PRs
- Any other operation that modifies the repository

## Forge Detection & Initialization

**Always use the forge abstraction layer:**

```bash
# Load forge abstraction
SCRIPT_DIR=".claude/scripts/forge"
source "$SCRIPT_DIR/config.sh"

# Initialize and detect forge type
forge_init || exit 1

# FORGE_TYPE is now set to "github" or "gitea"
```

## Authentication

**Don't pre-check authentication.** Just run the command and handle failure:

```bash
# The forge scripts handle authentication internally
# If authentication fails, they will provide appropriate error messages
```

## Common Operations

### Get Issue Details

Use forge abstraction:
```bash
# This works for both GitHub and Gitea
source .claude/scripts/forge/issue-list.sh
forge_issue_list --state all | grep "index: $ISSUE_NUMBER"
```

Or use native CLI directly (not recommended):
```bash
# GitHub
gh issue view {number} --json state,title,labels,body

# Gitea
tea issues list --output yaml | grep -A 10 "index: {number}"
```

### Create Issue

**Always use the forge abstraction:**
```bash
source .claude/scripts/forge/issue-create.sh
forge_issue_create \
  --title "{title}" \
  --body "{body}" \
  --labels "{labels}" \
  --milestone "{milestone}"
```

Native CLI (for reference only):
```bash
# GitHub
gh issue create --title "{title}" --body-file {file} --label "{labels}"

# Gitea
tea issues create --title "{title}" --description "{body}" --labels "{labels}"
```

### Update Issue

**Always use the forge abstraction:**
```bash
source .claude/scripts/forge/issue-edit.sh
forge_issue_edit {number} \
  --add-labels "{label}" \
  --state "open|closed"
```

Native CLI (for reference only):
```bash
# GitHub
gh issue edit {number} --add-label "{label}" --add-assignee @me

# Gitea
tea issues close {number}
tea issues reopen {number}
```

### Add Comment

**Always use the forge abstraction:**
```bash
source .claude/scripts/forge/issue-comment.sh
forge_issue_comment {number} --body "{comment text}"
```

Native CLI (for reference only):
```bash
# GitHub
gh issue comment {number} --body-file {file}

# Gitea
tea comment {number} "{comment text}"
```

### Create Labels

**Always use the forge abstraction:**
```bash
source .claude/scripts/forge/label-create.sh
forge_label_create \
  --name "{label-name}" \
  --color "{hex-color}" \
  --description "{description}"
```

## Key Differences: GitHub vs Gitea

### Sub-Issues / Task Tracking

**GitHub:**
- Uses `gh-sub-issue` extension for parent-child relationships
- Command: `gh sub-issue create --parent {epic_number} {task_file}`

**Gitea:**
- Uses markdown task lists in epic issue body
- Format: `- [ ] Task: {task_title} #123`
- Update status: Edit issue body to change `[ ]` to `[x]`

### CLI Parameter Differences

| Operation | GitHub | Gitea |
|-----------|--------|-------|
| Issue body | `--body` | `--description` |
| Assignees | `--assignee` | `--assignees` |
| Labels | `--label` | `--labels` |
| Output format | `--json` | `--output yaml` |

## Error Handling

If any forge operation fails:
1. Show clear error: "❌ Forge operation failed: {operation}"
2. Suggest fix based on forge type
3. Don't retry automatically

Example:
```bash
if ! forge_issue_create --title "Test" --body "Test"; then
  echo "❌ Failed to create issue"
  if [[ "$FORGE_TYPE" == "github" ]]; then
    echo "Run: gh auth login"
  else
    echo "Check: tea logins list"
  fi
  exit 1
fi
```

## Important Notes

- **ALWAYS** check remote origin before ANY write operation
- **ALWAYS** use forge abstraction layer instead of direct CLI calls
- Trust that CLIs are installed (init.sh handles this)
- Keep operations atomic - one operation per action
- Don't check rate limits preemptively
- Handle YAML/JSON differences transparently via forge scripts

## Migration from github-operations.md

If you see code using `gh` commands directly:
1. Replace with forge abstraction layer
2. Update error messages to be forge-agnostic
3. Test with both GitHub and Gitea repositories
