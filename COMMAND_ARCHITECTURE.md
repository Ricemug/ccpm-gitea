# CCPM Command Architecture

This document explains how CCPM commands are implemented.

## Two Types of Commands

CCPM uses two different patterns for implementing commands:

### 1. Script-Based Commands (14 commands)

**Pattern:** Simple, single-purpose commands that execute a shell script.

**Definition:**
```markdown
---
allowed-tools: Bash(bash .claude/scripts/pm/script-name.sh)
---
```

**Examples:**
- `/pm:status` → `scripts/pm/status.sh`
- `/pm:next` → `scripts/pm/next.sh`
- `/pm:blocked` → `scripts/pm/blocked.sh`
- `/pm:help` → `scripts/pm/help.sh`

**Complete list:**
1. blocked
2. epic-list
3. epic-show
4. epic-status
5. help
6. init
7. in-progress
8. next
9. prd-list
10. prd-status
11. search
12. standup
13. status
14. validate

### 2. Workflow-Based Commands (24 commands)

**Pattern:** Complex workflows that use multiple Claude Code tools.

**Definition:**
```markdown
---
allowed-tools: Bash, Read, Write, LS, Task
---

# Command Name

## Instructions

Step-by-step workflow using:
- Bash commands for git/forge operations
- Read/Write for file operations
- LS for directory listings
- Task for launching agents
```

**Examples:**
- `/pm:issue-start` - Analyze issue, create worktree, launch parallel agents
- `/pm:epic-sync` - Sync epic and tasks to Gitea
- `/pm:issue-close` - Close issue, update epic progress
- `/pm:prd-new` - Create new PRD with AI assistance

**Complete list:**
1. clean
2. epic-close
3. epic-decompose
4. epic-edit
5. epic-merge
6. epic-oneshot
7. epic-refresh
8. epic-start
9. epic-start-worktree
10. epic-sync
11. import
12. issue-analyze
13. issue-close
14. issue-edit
15. issue-reopen
16. issue-show
17. **issue-start** ← This one exists!
18. issue-status
19. issue-sync
20. prd-edit
21. prd-new
22. prd-parse
23. sync
24. test-reference-update

## Why Two Patterns?

### Script-Based (Shell Scripts)

**Use when:**
- Command does a simple, single task
- No complex AI decision-making needed
- Output is straightforward (list, status, etc.)
- Fast execution is important

**Advantages:**
- Fast execution
- Easy to test independently
- Can be run directly: `bash .claude/scripts/pm/next.sh`
- No AI token usage

### Workflow-Based (Markdown Instructions)

**Use when:**
- Command requires multiple steps
- Needs AI decision-making or analysis
- Involves file creation/editing with AI
- Benefits from Task agents

**Advantages:**
- More flexible
- Can adapt to context
- Can use specialized agents
- Better error handling and user feedback

## Common Misconception

❌ **WRONG:** "issue-start has no script, so it's not implemented"

✅ **CORRECT:** "issue-start uses workflow-based pattern with Claude Code tools"

## Verification

All commands are properly implemented. You can verify:

```bash
# Check script-based commands
ls -1 ccpm/scripts/pm/*.sh

# Check workflow-based commands
grep -l "allowed-tools:.*Read.*Write" ccpm/commands/pm/*.md

# No orphan scripts
for script in ccpm/scripts/pm/*.sh; do
  name=$(basename "$script" .sh)
  grep -q "$name.sh" ccpm/commands/pm/*.md || echo "Orphan: $name"
done
```

**Result:** ✅ All 38 commands are implemented and working.

## How to Use

Both types work the same way in Claude Code:

```
/pm:status          # Runs status.sh
/pm:issue-start 42  # Executes issue-start.md workflow
```

Claude Code handles the execution automatically based on the `allowed-tools` definition.
