# CCPM Gitea Fork Development Plan

**Date**: 2025-10-07
**Goal**: Build a universal version supporting both GitHub and Gitea

## Decision Summary

### Selected Approach: Option B - Build Universal Version ✅

**Rationale**:
- Gitea is an open-source GitHub alternative, users may use both
- Can contribute back to the original project, benefiting the open-source community
- tea CLI and gh CLI have similar command structures, low conversion cost
- Technically only requires building an abstraction layer, manageable complexity

**Estimated Effort**: 15-20 days

---

## Technical Analysis

### ✅ Advantages

1. **Complete tea CLI Functionality**
   - issues: create, edit, close, reopen, list
   - pull requests: create, merge, close, checkout
   - Full support for labels, milestones, releases
   - Comment functionality available

2. **High Architectural Compatibility**
   - CCPM core is markdown + shell scripts
   - Logic is platform-agnostic
   - Workflow design is universal

3. **Clear Command Mapping**
   ```bash
   GitHub CLI          →  Gitea tea CLI
   ──────────────────────────────────────
   gh issue create     →  tea issue create
   gh issue edit       →  tea issue edit
   gh issue comment    →  tea issue comment
   gh pr create        →  tea pull create
   gh auth login       →  tea login add
   ```

### ⚠️ Main Challenges

1. **Missing gh-sub-issue Extension**
   - CCPM relies on this for parent-child issue relationships
   - Gitea/tea **has no equivalent feature**
   - **Solution**: Use task lists (`- [ ] #123`) instead

2. **JSON Output Format Differences**
   - Need to verify tea CLI's `--output json` format
   - May need to adjust parsing logic

3. **Different Authentication Mechanisms**
   - GitHub: OAuth/Token automation
   - Gitea: Manual server URL + token setup required

4. **Repository Detection Logic**
   - GitHub: `gh repo view --json nameWithOwner`
   - Gitea: tea uses current directory's git config
   - Need to rewrite repository detection

---

## Development Phases

### Phase 1: Feasibility Validation (1-2 days)
- [ ] Install and test all necessary tea CLI commands
- [ ] Create Gitea test repository
- [ ] Verify JSON output format
- [ ] Test authentication flow

### Phase 2: Build Abstraction Layer (3-5 days)

Build a unified git forge interface:

```bash
.claude/scripts/forge/
├── detect.sh         # Detect GitHub vs Gitea
├── init.sh           # Initialize corresponding CLI
├── issue-create.sh   # Unified issue creation
├── issue-edit.sh     # Unified issue editing
├── issue-comment.sh  # Unified issue commenting
├── pr-create.sh      # Unified PR creation
└── repo-info.sh      # Unified repo information
```

**Design Principles**:
- Provide consistent external interface
- Internally call corresponding CLI based on forge type
- Unified error handling

### Phase 3: Implement Gitea Support (5-7 days)

#### Core File Modifications

| File | Modification Scope | Description |
|------|-------------------|-------------|
| `scripts/pm/init.sh` | Major | Support tea CLI installation and configuration |
| `commands/pm/epic-sync.md` | Major | Use forge abstraction layer |
| `rules/github-operations.md` | Rewrite | Rename to `forge-operations.md` |
| `commands/pm/issue-*.md` | Medium | Replace CLI calls |
| `commands/pm/epic-*.md` | Medium | Replace CLI calls |

#### Sub-issue Alternative Implementation
- Epic issues use task lists to track sub-tasks
- Auto-update task list status
- Maintain visual progress tracking

### Phase 4: Testing and Documentation (2-3 days)
- [ ] Complete workflow testing (GitHub + Gitea)
- [ ] Write Gitea setup documentation
- [ ] Update README to explain dual-platform support
- [ ] Create examples and tutorials

---

## Core Files Requiring Modification

### High Priority (Must Modify)
1. `ccpm/scripts/pm/init.sh` - Initialization flow
2. `ccpm/commands/pm/epic-sync.md` - Epic synchronization
3. `ccpm/rules/github-operations.md` - Platform operation rules
4. `ccpm/commands/pm/issue-start.md` - Issue startup
5. `ccpm/commands/pm/issue-sync.md` - Issue synchronization

### Medium Priority (Needs Adjustment)
6. `ccpm/commands/pm/issue-edit.md`
7. `ccpm/commands/pm/issue-close.md`
8. `ccpm/commands/pm/epic-close.md`
9. Other pm commands (~15 files)

### Low Priority (Optional)
10. Documentation and example updates

---

## Technical Notes

### Important tea CLI Commands

```bash
# Authentication
tea login add --name myserver --url https://gitea.example.com --token abc123

# Issue Operations
tea issue create --title "Title" --body "Body" --labels "epic,task"
tea issue edit 123 --add-labels "in-progress"
tea issue close 123

# PR Operations
tea pull create --title "PR Title" --body "Description"
tea pull merge 123

# Queries
tea issue list --output json
tea repo show
```

### Abstraction Layer Design Example

```bash
# .claude/scripts/forge/detect.sh
detect_forge() {
  remote_url=$(git remote get-url origin 2>/dev/null || echo "")

  if [[ "$remote_url" == *"github.com"* ]]; then
    echo "github"
  elif [[ "$remote_url" == *"gitea"* ]] || command -v tea &>/dev/null; then
    echo "gitea"
  else
    echo "unknown"
  fi
}
```

---

## Next Actions

1. ✅ Record conversation (this document)
2. 🔄 Rename project directory
3. ⏳ Create Gitea test repository
4. ⏳ Start Phase 1: Verify tea CLI functionality

---

## Reference Resources

- CCPM Original Project: https://github.com/automazeio/ccpm
- Gitea tea CLI: https://gitea.com/gitea/tea
- Gitea CLI Documentation: https://docs.gitea.com/administration/command-line
- tea CLI Command Reference: https://gitea.com/gitea/tea/src/branch/main/docs/CLI.md
