---
allowed-tools: Bash, Read, Write
---

# Spec Validate

Validate that epic implementation meets specification criteria.

## Usage
```
/pm:spec-validate <epic_name>
```

## What This Does

Reads the epic specification and verifies:
1. All tasks are accounted for
2. Acceptance criteria from PRD are addressed
3. Constitution alignment (if constitution exists)
4. Implementation completeness

## Instructions

### 1. Verify Epic Exists

```bash
epic_dir=".claude/epics/$ARGUMENTS"

if [ ! -d "$epic_dir" ]; then
  echo "❌ Epic not found: $ARGUMENTS"
  echo "Available epics:"
  ls -1 .claude/epics/ 2>/dev/null | grep -v '^\.' || echo "  (none)"
  exit 1
fi

if [ ! -f "$epic_dir/epic.md" ]; then
  echo "❌ Epic file missing: $epic_dir/epic.md"
  exit 1
fi

echo "🔍 Validating epic: $ARGUMENTS"
echo ""
```

### 2. Load Epic and PRD

Use Read tool to read:
1. `.claude/epics/$ARGUMENTS/epic.md` - The epic specification
2. `.claude/prds/$ARGUMENTS.md` - The original PRD (if exists)

```bash
# Check if PRD exists
prd_file=".claude/prds/$ARGUMENTS.md"
if [ -f "$prd_file" ]; then
  has_prd=true
  echo "📄 Found PRD: $prd_file"
else
  has_prd=false
  echo "⚠️  No PRD found (epic created without PRD)"
fi
echo ""
```

### 3. Task Completeness Check

```bash
echo "## Task Completeness"
echo ""

# Count tasks
total_tasks=$(ls -1 "$epic_dir"/*.md 2>/dev/null | grep -v epic.md | wc -l)
closed_tasks=$(grep -l "^status: closed" "$epic_dir"/*.md 2>/dev/null | grep -v epic.md | wc -l)
open_tasks=$((total_tasks - closed_tasks))

echo "Total tasks: $total_tasks"
echo "Closed: $closed_tasks"
echo "Open: $open_tasks"
echo ""

if [ "$open_tasks" -gt 0 ]; then
  echo "⚠️  Epic has open tasks:"
  for task_file in "$epic_dir"/*.md; do
    [ -f "$task_file" ] || continue
    [ "$(basename "$task_file")" = "epic.md" ] && continue

    status=$(grep "^status:" "$task_file" | head -1 | sed 's/^status: *//')
    if [ "$status" = "open" ]; then
      name=$(grep "^name:" "$task_file" | head -1 | sed 's/^name: *//')
      echo "  - [ ] $(basename "$task_file" .md): $name"
    fi
  done
  echo ""
fi
```

### 4. Constitution Alignment Check

```bash
echo "## Constitution Alignment"
echo ""

if [ -f ".claude/CONSTITUTION.md" ]; then
  echo "Checking against project constitution..."
  echo ""

  # Read constitution (use Read tool)
  # Read epic (use Read tool)

  # Check for common constitution requirements:

  # 4a. Code Quality
  echo "### Code Quality"
  has_tests=$(grep -ri "test" "$epic_dir" | wc -l)
  if [ "$has_tests" -gt 0 ]; then
    echo "✓ Testing mentioned in tasks"
  else
    echo "⚠️  No testing mentioned in tasks"
  fi

  # 4b. Documentation
  has_docs=$(grep -ri "documentation\|readme\|docs" "$epic_dir" | wc -l)
  if [ "$has_docs" -gt 0 ]; then
    echo "✓ Documentation mentioned in tasks"
  else
    echo "⚠️  No documentation mentioned in tasks"
  fi

  # 4c. Security
  has_security=$(grep -ri "security\|auth\|validation\|sanitize" "$epic_dir" | wc -l)
  if [ "$has_security" -gt 0 ]; then
    echo "✓ Security considerations mentioned"
  else
    echo "ℹ️  No explicit security considerations (may not be needed)"
  fi

  echo ""
else
  echo "ℹ️  No constitution file found (.claude/CONSTITUTION.md)"
  echo "   Run /pm:constitution-create to establish standards"
  echo ""
fi
```

### 5. PRD Acceptance Criteria Check

If PRD exists, check that all acceptance criteria are addressed:

```bash
if [ "$has_prd" = true ]; then
  echo "## PRD Acceptance Criteria"
  echo ""

  # Extract acceptance criteria from PRD (use Read tool)
  # This section requires AI to:
  # 1. Read PRD and identify acceptance criteria
  # 2. Read epic tasks
  # 3. Map criteria to tasks
  # 4. Report which criteria are covered

  echo "Analyzing PRD acceptance criteria..."
  echo ""

  # Use AI to analyze:
  # - Read .claude/prds/$ARGUMENTS.md
  # - Find "Success Criteria" or "Acceptance Criteria" sections
  # - Compare with task descriptions in epic
  # - Report coverage

  echo "📋 Checking if epic tasks cover PRD requirements..."
  echo ""

  # This is where Claude analyzes the PRD and epic
  # and provides a report like:
  #
  # ✓ User authentication
  # ✓ Password reset flow
  # ⚠️  Two-factor authentication (mentioned but no dedicated task)
  # ✗ Social login (not addressed)

fi
```

**Implementation note:** This step requires AI analysis. Use the Read tool to:
1. Read PRD and extract acceptance criteria from "Success Criteria" section
2. Read all task files in epic
3. For each criterion, determine if it's addressed in tasks
4. Report: ✓ (covered), ⚠️  (partially covered), ✗ (not covered)

### 6. Dependency Validation

```bash
echo "## Dependency Validation"
echo ""

# Check for circular dependencies
echo "Checking for circular dependencies..."

# Build dependency graph
> /tmp/dep-graph.txt
for task_file in "$epic_dir"/*.md; do
  [ -f "$task_file" ] || continue
  [ "$(basename "$task_file")" = "epic.md" ] && continue

  task_num=$(basename "$task_file" .md)
  deps=$(grep "^depends_on:" "$task_file" | sed 's/^depends_on: *//')

  if [ -n "$deps" ] && [ "$deps" != "[]" ]; then
    echo "$task_num: $deps" >> /tmp/dep-graph.txt
  fi
done

# Simple circular dependency check (basic implementation)
# For more advanced cycle detection, would need graph algorithm

if [ -s /tmp/dep-graph.txt ]; then
  echo "Dependencies found:"
  cat /tmp/dep-graph.txt
  echo ""
  echo "⚠️  Manual review recommended for complex dependency chains"
else
  echo "✓ No task dependencies (all tasks can run in parallel)"
fi

echo ""
```

### 7. Validation Summary

```bash
echo "## Validation Summary"
echo ""

# Calculate overall status
issues_found=0

if [ "$open_tasks" -gt 0 ]; then
  issues_found=$((issues_found + 1))
fi

if [ "$has_tests" -eq 0 ]; then
  issues_found=$((issues_found + 1))
fi

if [ "$has_docs" -eq 0 ]; then
  issues_found=$((issues_found + 1))
fi

if [ "$issues_found" -eq 0 ]; then
  echo "✅ Epic validation passed!"
  echo ""
  echo "The epic appears to meet specification requirements."
  echo ""
  echo "Next steps:"
  echo "  - Review implementation details"
  echo "  - Run tests if available"
  echo "  - Merge epic: /pm:epic-merge $ARGUMENTS"
else
  echo "⚠️  Found $issues_found potential issues"
  echo ""
  echo "Please review the validation results above and:"
  echo "  - Address any missing requirements"
  echo "  - Complete open tasks"
  echo "  - Ensure all acceptance criteria are met"
  echo ""
  echo "Re-run validation: /pm:spec-validate $ARGUMENTS"
fi

echo ""
echo "---"
echo ""
echo "💡 Tip: Validation helps ensure implementation matches specification."
echo "   Update tasks as needed and re-validate before merging."
```

## Validation Criteria

### What Gets Checked

**Completeness:**
- All tasks are defined
- All tasks reference PRD requirements
- No orphan tasks (tasks not related to requirements)

**Quality:**
- Tests are mentioned
- Documentation is included
- Security considerations (if applicable)

**Consistency:**
- Task dependencies are valid
- No circular dependencies
- Acceptance criteria from PRD are addressed

**Constitution:**
- Follows architectural principles (if constitution exists)
- Meets quality standards
- Uses approved technologies

### What This Doesn't Check

- Actual code quality (use code review)
- Test coverage (use test runners)
- Runtime behavior (use QA testing)

This validation checks **specification completeness**, not implementation quality.

## Integration

**Automatic validation:**
- `/pm:epic-close` can call this before marking epic complete
- `/pm:epic-merge` can require validation before merge

**Manual validation:**
- Run anytime to check epic status
- Run before submitting for review
- Run after making significant changes

## See Also

- `/pm:epic-show` - View epic structure
- `/pm:epic-status` - Check task completion
- `/pm:prd-parse` - Create epic from PRD
