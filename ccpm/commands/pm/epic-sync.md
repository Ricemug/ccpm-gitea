---
allowed-tools: Bash, Read, Write, LS, Task
---

# Epic Sync

Push epic and tasks to forge as issues.

## Usage
```
/pm:epic-sync <feature_name>
```

## Quick Check

```bash
# Verify epic exists
test -f .claude/epics/$ARGUMENTS/epic.md || echo "❌ Epic not found. Run: /pm:prd-parse $ARGUMENTS"

# Count task files
ls .claude/epics/$ARGUMENTS/*.md 2>/dev/null | grep -v epic.md | wc -l
```

If no tasks found: "❌ No tasks to sync. Run: /pm:epic-decompose $ARGUMENTS"

## Instructions

### 0. Initialize Forge Abstraction

```bash
# Load forge abstraction
source .claude/scripts/forge/config.sh
forge_init || exit 1

# FORGE_TYPE is now set to "github" or "gitea"
echo "Syncing to $FORGE_TYPE forge..."
```

### 1. Check Remote Repository

Follow `/rules/forge-operations.md` to ensure we're not syncing to the CCPM template:

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
  echo "1. Fork this repository to your own GitHub account"
  echo "2. Update your remote origin:"
  echo "   git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
  echo ""
  echo "Or if this is a new project:"
  echo "1. Create a new repository on GitHub"
  echo "2. Update your remote origin:"
  echo "   git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
  echo ""
  echo "Current remote: $remote_url"
  exit 1
fi
```

### 2. Create Epic Issue

#### First, detect the repository:
```bash
# Get the current repository from git remote
remote_url=$(git remote get-url origin 2>/dev/null || echo "")
REPO=$(echo "$remote_url" | sed 's|.*github.com[:/]||' | sed 's|\.git$||')
[ -z "$REPO" ] && REPO="user/repo"
echo "Creating issues in repository: $REPO"
```

Strip frontmatter and prepare GitHub issue body:
```bash
# Extract content without frontmatter
sed '1,/^---$/d; 1,/^---$/d' .claude/epics/$ARGUMENTS/epic.md > /tmp/epic-body-raw.md

# Remove "## Tasks Created" section and replace with Stats
awk '
  /^## Tasks Created/ {
    in_tasks=1
    next
  }
  /^## / && in_tasks {
    in_tasks=0
    # When we hit the next section after Tasks Created, add Stats
    if (total_tasks) {
      print "## Stats"
      print ""
      print "Total tasks: " total_tasks
      print "Parallel tasks: " parallel_tasks " (can be worked on simultaneously)"
      print "Sequential tasks: " sequential_tasks " (have dependencies)"
      if (total_effort) print "Estimated total effort: " total_effort " hours"
      print ""
    }
  }
  /^Total tasks:/ && in_tasks { total_tasks = $3; next }
  /^Parallel tasks:/ && in_tasks { parallel_tasks = $3; next }
  /^Sequential tasks:/ && in_tasks { sequential_tasks = $3; next }
  /^Estimated total effort:/ && in_tasks {
    gsub(/^Estimated total effort: /, "")
    total_effort = $0
    next
  }
  !in_tasks { print }
  END {
    # If we were still in tasks section at EOF, add stats
    if (in_tasks && total_tasks) {
      print "## Stats"
      print ""
      print "Total tasks: " total_tasks
      print "Parallel tasks: " parallel_tasks " (can be worked on simultaneously)"
      print "Sequential tasks: " sequential_tasks " (have dependencies)"
      if (total_effort) print "Estimated total effort: " total_effort
    }
  }
' /tmp/epic-body-raw.md > /tmp/epic-body.md

# Determine epic type (feature vs bug) from content
if grep -qi "bug\|fix\|issue\|problem\|error" /tmp/epic-body.md; then
  epic_type="bug"
else
  epic_type="feature"
fi

# Create epic issue with labels using forge abstraction
source .claude/scripts/forge/issue-create.sh
epic_body=$(cat /tmp/epic-body.md)
epic_number=$(forge_issue_create \
  --title "Epic: $ARGUMENTS" \
  --body "$epic_body" \
  --labels "epic,epic:$ARGUMENTS,$epic_type" | grep -oP '#\K[0-9]+')
```

Store the returned issue number for epic frontmatter update.

### 3. Create Task Sub-Issues

Check sub-issue support based on forge type:
```bash
# GitHub: Check if gh-sub-issue is available
# Gitea: Always use task list in epic body
if [[ "$FORGE_TYPE" == "github" ]] && gh extension list | grep -q "yahsan2/gh-sub-issue"; then
  use_subissues=true
  echo "Using GitHub sub-issues extension"
elif [[ "$FORGE_TYPE" == "gitea" ]]; then
  use_subissues=false
  echo "Using Gitea task list in epic body"
else
  use_subissues=false
  echo "⚠️ Using fallback mode: task list in epic body"
fi
```

Count task files to determine strategy:
```bash
task_count=$(ls .claude/epics/$ARGUMENTS/[0-9][0-9][0-9].md 2>/dev/null | wc -l)
```

### For Small Batches (< 5 tasks): Sequential Creation

```bash
if [ "$task_count" -lt 5 ]; then
  # Create sequentially for small batches
  for task_file in .claude/epics/$ARGUMENTS/[0-9][0-9][0-9].md; do
    [ -f "$task_file" ] || continue

    # Extract task name from frontmatter
    task_name=$(grep '^name:' "$task_file" | sed 's/^name: *//')

    # Strip frontmatter from task content
    sed '1,/^---$/d; 1,/^---$/d' "$task_file" > /tmp/task-body.md

    # Create sub-issue with labels
    if [ "$use_subissues" = true ]; then
      # GitHub with sub-issue extension
      task_number=$(gh sub-issue create \
        --parent "$epic_number" \
        --title "$task_name" \
        --body-file /tmp/task-body.md \
        --label "task,epic:$ARGUMENTS" \
        --json number -q .number)
    else
      # Fallback or Gitea: create regular issue
      task_body=$(cat /tmp/task-body.md)
      task_number=$(forge_issue_create \
        --title "$task_name" \
        --body "$task_body" \
        --labels "task,epic:$ARGUMENTS" | grep -oP '#\K[0-9]+')
    fi

    # Record mapping for renaming
    echo "$task_file:$task_number" >> /tmp/task-mapping.txt
  done

  # After creating all issues, update references and rename files
  # This follows the same process as step 3 below
fi
```

### For Larger Batches: Parallel Creation

```bash
if [ "$task_count" -ge 5 ]; then
  echo "Creating $task_count sub-issues in parallel..."

  # Check if gh-sub-issue is available for parallel agents
  if gh extension list | grep -q "yahsan2/gh-sub-issue"; then
    subissue_cmd="gh sub-issue create --parent $epic_number"
  else
    subissue_cmd="gh issue create --repo \"$REPO\""
  fi

  # Batch tasks for parallel processing
  # Spawn agents to create sub-issues in parallel with proper labels
  # Each agent must use: --label "task,epic:$ARGUMENTS"
fi
```

Use Task tool for parallel creation:
```yaml
Task:
  description: "Create GitHub sub-issues batch {X}"
  subagent_type: "general-purpose"
  prompt: |
    Create GitHub sub-issues for tasks in epic $ARGUMENTS
    Parent epic issue: #$epic_number

    Tasks to process:
    - {list of 3-4 task files}

    For each task file:
    1. Extract task name from frontmatter
    2. Strip frontmatter using: sed '1,/^---$/d; 1,/^---$/d'
    3. Create sub-issue using:
       - If gh-sub-issue available:
         gh sub-issue create --parent $epic_number --title "$task_name" \
           --body-file /tmp/task-body.md --label "task,epic:$ARGUMENTS"
       - Otherwise: 
         gh issue create --repo "$REPO" --title "$task_name" --body-file /tmp/task-body.md \
           --label "task,epic:$ARGUMENTS"
    4. Record: task_file:issue_number

    IMPORTANT: Always include --label parameter with "task,epic:$ARGUMENTS"

    Return mapping of files to issue numbers.
```

Consolidate results from parallel agents:
```bash
# Collect all mappings from agents
cat /tmp/batch-*/mapping.txt >> /tmp/task-mapping.txt

# IMPORTANT: After consolidation, follow step 3 to:
# 1. Build old->new ID mapping
# 2. Update all task references (depends_on, conflicts_with)
# 3. Rename files with proper frontmatter updates
```

### 3. Rename Task Files and Update References

First, build a mapping of old numbers to new issue IDs:
```bash
# Create mapping from old task numbers (001, 002, etc.) to new issue IDs
> /tmp/id-mapping.txt
while IFS=: read -r task_file task_number; do
  # Extract old number from filename (e.g., 001 from 001.md)
  old_num=$(basename "$task_file" .md)
  echo "$old_num:$task_number" >> /tmp/id-mapping.txt
done < /tmp/task-mapping.txt
```

Then rename files and update all references:
```bash
# Process each task file
while IFS=: read -r task_file task_number; do
  new_name="$(dirname "$task_file")/${task_number}.md"

  # Read the file content
  content=$(cat "$task_file")

  # Update depends_on and conflicts_with references
  while IFS=: read -r old_num new_num; do
    # Update arrays like [001, 002] to use new issue numbers
    content=$(echo "$content" | sed "s/\b$old_num\b/$new_num/g")
  done < /tmp/id-mapping.txt

  # Write updated content to new file
  echo "$content" > "$new_name"

  # Remove old file if different from new
  [ "$task_file" != "$new_name" ] && rm "$task_file"

  # Update github field in frontmatter
  # Add the GitHub URL to the frontmatter
  repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
  github_url="https://github.com/$repo/issues/$task_number"

  # Update frontmatter with GitHub URL and current timestamp
  current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Use sed to update the github and updated fields
  sed -i.bak "/^github:/c\github: $github_url" "$new_name"
  sed -i.bak "/^updated:/c\updated: $current_date" "$new_name"
  rm "${new_name}.bak"
done < /tmp/task-mapping.txt
```

### 4. Update Epic with Task List (For Gitea and Fallback)

If NOT using gh-sub-issue, add task list to epic:

```bash
if [ "$use_subissues" = false ]; then
  # Build task list from mapping file
  task_list=""
  while IFS=: read -r task_file task_number; do
    task_name=$(grep '^name:' "$task_file" | sed 's/^name: *//')
    task_list="${task_list}\n- [ ] #${task_number} ${task_name}"
  done < /tmp/task-mapping.txt

  # Get current epic body and append task list
  cat /tmp/epic-body.md > /tmp/epic-body-with-tasks.md
  cat >> /tmp/epic-body-with-tasks.md << EOF

## Tasks
${task_list}
EOF

  # Update epic issue using forge abstraction
  source .claude/scripts/forge/issue-edit.sh
  epic_body_final=$(cat /tmp/epic-body-with-tasks.md)

  # Note: This requires implementing --body parameter in forge_issue_edit
  # For now, may need platform-specific handling
  if [[ "$FORGE_TYPE" == "github" ]]; then
    gh issue edit ${epic_number} --body-file /tmp/epic-body-with-tasks.md
  elif [[ "$FORGE_TYPE" == "gitea" ]]; then
    # Gitea: Update via tea CLI
    # Note: tea may not support body update, need to verify
    echo "⚠️ Gitea: Task list added to epic #${epic_number}. May need manual verification."
  fi
fi
```

**GitHub with gh-sub-issue**: Task relationships are automatic!
**Gitea/Fallback**: Tasks are tracked via markdown checklist in epic body.

### 5. Update Epic File

Update the epic file with forge URL, timestamp, and real task IDs:

#### 5a. Update Frontmatter
```bash
# Get repo info
remote_url=$(git remote get-url origin 2>/dev/null || echo "")

# Extract repo path and construct issue URL based on forge type
if [[ "$FORGE_TYPE" == "github" ]]; then
  repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
  epic_url="https://github.com/$repo/issues/$epic_number"
elif [[ "$FORGE_TYPE" == "gitea" ]]; then
  # Extract Gitea URL from remote
  gitea_host=$(echo "$remote_url" | sed -E 's|^.*://([^/]+)/.*|\1|')
  repo_path=$(echo "$remote_url" | sed -E 's|^.*://[^/]+/(.*)\.git$|\1|')
  epic_url="https://${gitea_host}/${repo_path}/issues/${epic_number}"
fi

current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Update epic frontmatter
sed -i.bak "/^github:/c\github: $epic_url" .claude/epics/$ARGUMENTS/epic.md
sed -i.bak "/^updated:/c\updated: $current_date" .claude/epics/$ARGUMENTS/epic.md
rm .claude/epics/$ARGUMENTS/epic.md.bak
```

#### 5b. Update Tasks Created Section
```bash
# Create a temporary file with the updated Tasks Created section
cat > /tmp/tasks-section.md << 'EOF'
## Tasks Created
EOF

# Add each task with its real issue number
for task_file in .claude/epics/$ARGUMENTS/[0-9]*.md; do
  [ -f "$task_file" ] || continue

  # Get issue number (filename without .md)
  issue_num=$(basename "$task_file" .md)

  # Get task name from frontmatter
  task_name=$(grep '^name:' "$task_file" | sed 's/^name: *//')

  # Get parallel status
  parallel=$(grep '^parallel:' "$task_file" | sed 's/^parallel: *//')

  # Add to tasks section
  echo "- [ ] #${issue_num} - ${task_name} (parallel: ${parallel})" >> /tmp/tasks-section.md
done

# Add summary statistics
total_count=$(ls .claude/epics/$ARGUMENTS/[0-9]*.md 2>/dev/null | wc -l)
parallel_count=$(grep -l '^parallel: true' .claude/epics/$ARGUMENTS/[0-9]*.md 2>/dev/null | wc -l)
sequential_count=$((total_count - parallel_count))

cat >> /tmp/tasks-section.md << EOF

Total tasks: ${total_count}
Parallel tasks: ${parallel_count}
Sequential tasks: ${sequential_count}
EOF

# Replace the Tasks Created section in epic.md
# First, create a backup
cp .claude/epics/$ARGUMENTS/epic.md .claude/epics/$ARGUMENTS/epic.md.backup

# Use awk to replace the section
awk '
  /^## Tasks Created/ {
    skip=1
    while ((getline line < "/tmp/tasks-section.md") > 0) print line
    close("/tmp/tasks-section.md")
  }
  /^## / && !/^## Tasks Created/ { skip=0 }
  !skip && !/^## Tasks Created/ { print }
' .claude/epics/$ARGUMENTS/epic.md.backup > .claude/epics/$ARGUMENTS/epic.md

# Clean up
rm .claude/epics/$ARGUMENTS/epic.md.backup
rm /tmp/tasks-section.md
```

### 6. Create Mapping File

Create `.claude/epics/$ARGUMENTS/forge-mapping.md`:
```bash
# Create mapping file
cat > .claude/epics/$ARGUMENTS/forge-mapping.md << EOF
# Forge Issue Mapping

Forge Type: ${FORGE_TYPE}
Epic: #${epic_number} - ${epic_url}

Tasks:
EOF

# Add each task mapping
for task_file in .claude/epics/$ARGUMENTS/[0-9]*.md; do
  [ -f "$task_file" ] || continue

  issue_num=$(basename "$task_file" .md)
  task_name=$(grep '^name:' "$task_file" | sed 's/^name: *//')

  # Construct issue URL
  if [[ "$FORGE_TYPE" == "github" ]]; then
    task_url="https://github.com/${repo}/issues/${issue_num}"
  elif [[ "$FORGE_TYPE" == "gitea" ]]; then
    task_url="https://${gitea_host}/${repo_path}/issues/${issue_num}"
  fi

  echo "- #${issue_num}: ${task_name} - ${task_url}" >> .claude/epics/$ARGUMENTS/forge-mapping.md
done

# Add sync timestamp
echo "" >> .claude/epics/$ARGUMENTS/forge-mapping.md
echo "Synced: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> .claude/epics/$ARGUMENTS/forge-mapping.md
```

### 7. Create Worktree

Follow `/rules/worktree-operations.md` to create development worktree:

```bash
# Ensure main is current
git checkout main
git pull origin main

# Create worktree for epic
git worktree add ../epic-$ARGUMENTS -b epic/$ARGUMENTS

echo "✅ Created worktree: ../epic-$ARGUMENTS"
```

### 8. Output

```
✅ Synced to ${FORGE_TYPE}
  - Forge: ${FORGE_TYPE}
  - Epic: #{epic_number} - {epic_title}
  - Tasks: {count} issues created
  - Sub-issue mode: {use_subissues ? "GitHub sub-issues" : "Task list in epic"}
  - Labels applied: epic, task, epic:{name}
  - Files renamed: 001.md → {issue_id}.md
  - References updated: depends_on/conflicts_with now use issue IDs
  - Worktree: ../epic-$ARGUMENTS

Next steps:
  - Start parallel execution: /pm:epic-start $ARGUMENTS
  - Or work on single issue: /pm:issue-start {issue_number}
  - View epic: ${epic_url}
```

## Error Handling

Follow `/rules/forge-operations.md` for forge operation errors.

If any issue creation fails:
- Report what succeeded
- Note what failed
- Don't attempt rollback (partial sync is fine)

## Important Notes

- Trust forge CLI authentication (handled by /pm:init)
- Don't pre-check for duplicates
- Update frontmatter only after successful creation
- Keep operations simple and atomic
- GitHub and Gitea handle sub-issues differently (sub-issues vs task lists)
