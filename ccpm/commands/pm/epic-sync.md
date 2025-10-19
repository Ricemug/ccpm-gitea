---
allowed-tools: Bash, Read, Write, LS, Task
---

# Epic Sync (Gitea Edition)

Push epic and tasks to Gitea as issues with task list.

## Usage
```
/pm:epic-sync <feature_name>
```

## Quick Check

```bash
# Verify epic exists
test -f .claude/epics/$ARGUMENTS/epic.md || echo "L Epic not found. Run: /pm:prd-parse $ARGUMENTS"

# Count task files
ls .claude/epics/$ARGUMENTS/*.md 2>/dev/null | grep -v epic.md | wc -l
```

If no tasks found: "L No tasks to sync. Run: /pm:epic-decompose $ARGUMENTS"

## Instructions

### 0. Initialize Forge Abstraction

```bash
# Load forge abstraction
source .claude/scripts/forge/config.sh
forge_init || exit 1

echo "Syncing to Gitea..."
```

### 1. Check Remote Repository

Follow `/rules/forge-operations.md` to ensure we're not syncing to the CCPM template:

```bash
# Check if remote origin is the CCPM Gitea Edition template repository
remote_url=$(git remote get-url origin 2>/dev/null || echo "")
if [[ "$remote_url" == *"Ricemug/ccpm-gitea"* ]]; then
  echo "❌ ERROR: You're trying to sync with the CCPM Gitea Edition template repository!"
  echo ""
  echo "This repository (Ricemug/ccpm-gitea) is a template for others to use."
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

### 2. Create Epic Issue

Strip frontmatter and prepare epic body:

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

# Get repository name from git remote
remote_url=$(git remote get-url origin 2>/dev/null || echo "")
if [[ "$remote_url" =~ ([^/:]+/[^/]+)(\.git)?$ ]]; then
  REPO="${BASH_REMATCH[1]}"
else
  echo "❌ Could not detect repository from remote URL: $remote_url"
  exit 1
fi

# Create epic issue with labels using forge abstraction
source .claude/scripts/forge/issue-create.sh
epic_body=$(cat /tmp/epic-body.md)
epic_number=$(forge_issue_create \
  --title "Epic: $ARGUMENTS" \
  --body "$epic_body" \
  --labels "epic,epic:$ARGUMENTS,$epic_type" \
  --repo "$REPO" | grep -oP '#\K[0-9]+')

echo "✅ Created epic issue #$epic_number in $REPO"
```

### 3. Create Task Issues

For each task file, create a separate issue on Gitea:

```bash
# Initialize task mapping file
> /tmp/task-mapping.txt

# Count tasks
task_count=$(ls .claude/epics/$ARGUMENTS/[0-9][0-9][0-9].md 2>/dev/null | wc -l)
echo "Creating $task_count task issues..."

# Create each task as a separate issue
for task_file in .claude/epics/$ARGUMENTS/[0-9][0-9][0-9].md; do
  [ -f "$task_file" ] || continue

  # Extract task name from frontmatter
  task_name=$(grep '^name:' "$task_file" | sed 's/^name: *//')

  # Strip frontmatter from task content
  sed '1,/^---$/d; 1,/^---$/d' "$task_file" > /tmp/task-body.md

  # Create issue with labels
  task_body=$(cat /tmp/task-body.md)
  task_number=$(forge_issue_create \
    --title "$task_name" \
    --body "$task_body" \
    --labels "task,epic:$ARGUMENTS" \
    --repo "$REPO" | grep -oP '#\K[0-9]+')

  echo "  ✓ Created task #$task_number: $task_name"

  # Record mapping for later file renaming
  echo "$task_file:$task_number" >> /tmp/task-mapping.txt
done

echo "✅ Created all task issues"
```

### 4. Update Epic with Task List

Add a task list to the epic issue body showing all tasks:

```bash
# Build task list for epic body
task_list_section="## Tasks\n\n"

while IFS=: read -r task_file task_number; do
  # Get task name and status
  task_name=$(grep '^name:' "$task_file" | sed 's/^name: *//')
  task_status=$(grep '^status:' "$task_file" | sed 's/^status: *//')

  # Add checkbox (checked if closed, unchecked otherwise)
  if [ "$task_status" = "closed" ]; then
    task_list_section="${task_list_section}- [x] #${task_number} - ${task_name}\n"
  else
    task_list_section="${task_list_section}- [ ] #${task_number} - ${task_name}\n"
  fi
done < /tmp/task-mapping.txt

# Get current epic body and add task list
tea issues show "$epic_number" --repo "$REPO" --output simple > /tmp/epic-current.md

# Append task list to epic body
{
  cat /tmp/epic-current.md
  echo ""
  echo -e "$task_list_section"
} > /tmp/epic-updated.md

# Update epic issue with task list
tea issues edit "$epic_number" \
  --description "$(cat /tmp/epic-updated.md)" \
  --repo "$REPO"

echo "✅ Updated epic #$epic_number with task list"
```

### 5. Rename Task Files and Update References

Build ID mapping and rename files to match issue numbers:

```bash
# Create mapping from old task numbers (001, 002, etc.) to new issue IDs
> /tmp/id-mapping.txt
while IFS=: read -r task_file task_number; do
  old_num=$(basename "$task_file" .md)
  echo "$old_num:$task_number" >> /tmp/id-mapping.txt
done < /tmp/task-mapping.txt

# Get Gitea URL for issue links
remote_url=$(git remote get-url origin 2>/dev/null)
# Extract base URL (remove .git and username/repo)
gitea_base=$(echo "$remote_url" | sed 's|\.git$||' | sed 's|'$REPO'$||' | sed 's|/$||')

# Process each task file
while IFS=: read -r task_file task_number; do
  new_name="$(dirname "$task_file")/${task_number}.md"

  # Read the file content
  content=$(cat "$task_file")

  # Update depends_on and conflicts_with references
  while IFS=: read -r old_num new_num; do
    # Update arrays like ["001", "002"] to use new issue numbers
    content=$(echo "$content" | sed "s/\"$old_num\"/\"$new_num\"/g")
  done < /tmp/id-mapping.txt

  # Write updated content to new file
  echo "$content" > "$new_name"

  # Remove old file if different from new
  [ "$task_file" != "$new_name" ] && rm "$task_file"

  # Update gitea field in frontmatter
  gitea_url="${gitea_base}${REPO}/issues/$task_number"
  current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Use perl for cross-platform sed compatibility
  perl -pi -e "s|^gitea:.*|gitea: $gitea_url|" "$new_name"
  perl -pi -e "s|^updated:.*|updated: $current_date|" "$new_name"

  echo "  ✓ Renamed $(basename $task_file) → $(basename $new_name)"
done < /tmp/task-mapping.txt

echo "✅ Renamed all task files"
```

### 6. Update Epic File

Update epic.md frontmatter with Gitea URL:

```bash
# Get Gitea URL for epic
epic_url="${gitea_base}${REPO}/issues/$epic_number"
current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Update epic.md frontmatter
perl -pi -e "s|^gitea:.*|gitea: $epic_url|" .claude/epics/$ARGUMENTS/epic.md
perl -pi -e "s|^status:.*|status: synced|" .claude/epics/$ARGUMENTS/epic.md
perl -pi -e "s|^updated:.*|updated: $current_date|" .claude/epics/$ARGUMENTS/epic.md

echo "✅ Updated epic.md frontmatter"
```

### 7. Create Mapping File

Store the mapping for future reference:

```bash
# Create .mapping file in epic directory
cat > .claude/epics/$ARGUMENTS/.mapping << EOF
# Epic: $ARGUMENTS
# Synced: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Epic Issue: #$epic_number
# Repository: $REPO

# Task Mappings (local_file:issue_number)
EOF

cat /tmp/task-mapping.txt >> .claude/epics/$ARGUMENTS/.mapping

echo "✅ Created mapping file"
```

### 8. Output

```
✨ Epic Sync Complete!
========================

Epic: $ARGUMENTS
Epic Issue: #$epic_number
Tasks: $task_count issues created

View on Gitea:
  ${gitea_base}${REPO}/issues/$epic_number

Next steps:
  1. Start work: /pm:issue-start <task_number>
  2. View progress: /pm:status
  3. Check epic: /pm:epic-show $ARGUMENTS
```

