# Gitea Operations Rule

Standard patterns for Gitea operations across all commands.

## CRITICAL: Repository Protection

**Before ANY operation that creates/modifies issues or PRs:**

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
  echo "  1. Create your own repository on your Gitea instance"
  echo "  2. Update your remote origin:"
  echo "     git remote set-url origin <your-gitea-repo-url>"
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

## Forge Initialization

**Always use the forge abstraction layer:**

```bash
# Load forge abstraction
SCRIPT_DIR=".claude/scripts/forge"
source "$SCRIPT_DIR/config.sh"

# Initialize (checks for tea CLI)
forge_init || exit 1
```

## Authentication

**Don't pre-check authentication.** Just run the command and handle failure:

```bash
# The forge scripts handle authentication internally
# If authentication fails, they will provide error messages
# User should run: tea login add --name <name> --url <url> --token <token>
```

## Common Operations

### Get Issue Details

Use forge abstraction:
```bash
# Works with Gitea
source .claude/scripts/forge/issue-list.sh
forge_issue_list --state all | grep "index: $ISSUE_NUMBER"
```

Or use tea CLI directly (not recommended):
```bash
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
tea issues close {number}
tea issues reopen {number}
tea issues edit {number} --add-labels "{label}"
```

### Add Comment

**Always use the forge abstraction:**
```bash
source .claude/scripts/forge/issue-comment.sh
forge_issue_comment {number} --body "{comment text}"
```

Native CLI (for reference only):
```bash
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

## Task Tracking with Gitea

**Gitea uses markdown task lists for epic tracking:**

- Epic issues contain task lists in the issue body
- Format: `- [ ] Task: {task_title} #123`
- Update status: Edit issue body to change `[ ]` to `[x]`
- Task lists are checked/unchecked via web UI or API

Example epic issue body:
```markdown
## Epic: User Authentication

### Tasks
- [ ] #45 Implement login page
- [x] #46 Add JWT token generation
- [ ] #47 Create password reset flow
```

## Error Handling

If any forge operation fails:
1. Show clear error: "❌ Forge operation failed: {operation}"
2. Suggest authentication check: `tea logins list`
3. Don't retry automatically

Example:
```bash
if ! forge_issue_create --title "Test" --body "Test"; then
  echo "❌ Failed to create issue"
  echo "Check authentication: tea logins list"
  exit 1
fi
```

## Important Notes

- **ALWAYS** check remote origin before ANY write operation
- **ALWAYS** use forge abstraction layer instead of direct CLI calls
- Trust that tea CLI is installed (init.sh handles this)
- Keep operations atomic - one operation per action
- Don't check rate limits preemptively
- Handle YAML output via forge scripts
