# Spec-Kit Integration Analysis

Comparison of GitHub's Spec-Kit with CCPM Gitea Edition and integration opportunities.

## What is Spec-Kit?

GitHub's Spec-Kit is a toolkit for **Spec-Driven Development (SDD)** that:
- Starts with executable specifications instead of code
- Uses AI agents (Claude Code, Copilot, Gemini) to generate from specs
- Provides structured templates and workflows
- Includes `/speckit.constitution` and `/speckit.specify` commands

**Source:** https://github.com/github/spec-kit

## CCPM vs Spec-Kit Comparison

### Similarities

| Feature | CCPM | Spec-Kit |
|---------|------|----------|
| Spec-first approach | ✅ PRD → Epic → Tasks | ✅ Constitution → Specification |
| AI agent integration | ✅ Claude Code slash commands | ✅ Multi-agent support |
| Structured workflow | ✅ 5-phase process | ✅ SDD workflow |
| Documentation-driven | ✅ PRD, Epic files | ✅ Spec documents |
| Issue tracking | ✅ Gitea issues | ⚠️ Not emphasized |

### Key Differences

| Aspect | CCPM | Spec-Kit |
|--------|------|----------|
| **Focus** | Project management | Executable specifications |
| **Tracking** | Gitea issues, progress | Spec validation |
| **Decomposition** | PRD → Epic → Tasks | Constitution → Spec → Code |
| **Testing** | Manual tracking | Executable specs verify code |
| **Platform** | Gitea-specific | Platform-agnostic |
| **Scope** | Full PM lifecycle | Specification phase |

## Integration Opportunities

### 1. Add Constitution Support

**What:** Project governance and principles document

**Implementation:**
```
/pm:constitution-create
  - Creates .claude/CONSTITUTION.md
  - Defines coding standards
  - Sets architectural principles
  - Establishes decision-making rules
```

**Benefit:** Consistent decision-making across all epics

### 2. Executable Specifications

**What:** PRDs that can validate code

**Current CCPM:**
```markdown
# PRD
User Story: User can login
Acceptance Criteria:
- Login form exists
- Credentials validated
```

**With Spec-Kit Integration:**
```markdown
# PRD with Executable Spec
User Story: User can login
Acceptance Criteria:
- Login form exists
- Credentials validated

## Verification Spec
```typescript
// Auto-generated from acceptance criteria
test('user can login', async () => {
  const form = await page.find('login-form')
  expect(form).toExist()

  await form.fill({ email, password })
  const result = await form.submit()
  expect(result.authenticated).toBe(true)
})
```
```

**Benefit:** PRD acceptance criteria become test specifications

### 3. Spec Validation Command

**New command:** `/pm:spec-validate <epic_name>`

**What it does:**
1. Read epic specification
2. Generate test cases from acceptance criteria
3. Run tests against implementation
4. Report which criteria are met/unmet

**Benefit:** Automated verification that code matches spec

### 4. PRD Templates with SDD

**Enhancement to** `/pm:prd-new`

**Add sections:**
```markdown
## Constitution Alignment
- [ ] Follows architecture principles
- [ ] Meets code quality standards
- [ ] Aligns with project goals

## Executable Criteria
For each acceptance criterion, define:
- Test specification
- Expected behavior
- Validation method
```

**Benefit:** Enforced alignment with project standards

### 5. Specification Change Tracking

**New workflow:**
```
/pm:spec-change <epic_name>
  - Detects spec changes
  - Identifies affected tasks
  - Validates code still meets spec
  - Suggests updates
```

**Benefit:** Maintain spec-code consistency

## Recommended Integration Plan

### Phase 1: Foundation (Low Effort, High Value) ✅ COMPLETED

1. **Add CONSTITUTION.md template** ✅
   - File: `ccpm/CONSTITUTION.md`
   - Command: `/pm:constitution-create`
   - Status: Implemented
   - Features:
     - Interactive constitution creation
     - Customization based on tech stack
     - Project type and priority selection
     - Auto-backup of existing constitution

2. **Enhance PRD template** ✅
   - Added "Executable Criteria" section
   - Added "Constitution Alignment" checklist
   - Updated quality checks
   - Status: Implemented in `/pm:prd-new`

3. **Add spec validation** ✅
   - Command: `/pm:spec-validate`
   - Status: Implemented
   - Features:
     - Task completeness check
     - Constitution alignment verification
     - PRD acceptance criteria mapping
     - Dependency validation
     - Validation summary report

### Phase 2: Integration (Medium Effort, High Value) 🔄 IN PROGRESS

4. **Optimize epic-sync** ✅
   - Added parallel task creation
   - Faster syncing for large epics
   - Thread-safe file operations
   - Status: Implemented

5. **Integrate with issue-close** ⏳
   - Verify spec before closing
   - Auto-run validation
   - Effort: 3 hours
   - Status: Not yet implemented

6. **Update epic-decompose** ⏳
   - Check constitution alignment
   - Verify spec completeness
   - Effort: 2 hours
   - Status: Not yet implemented

### Phase 3: Advanced (High Effort, Medium Value)

6. **Spec change detection**
   - Track spec modifications
   - Alert affected tasks
   - Effort: 10 hours

7. **Full spec-kit integration**
   - Import spec-kit templates
   - Adapt for Gitea workflow
   - Effort: 20 hours

## What NOT to Integrate

**Spec-Kit's CLI scaffolding** - CCPM already has installation
**Multi-platform support** - We're Gitea-only by design
**GitHub-specific features** - Not applicable

## Current CCPM Advantages to Preserve

1. **Gitea Integration** - Keep native Gitea workflow
2. **Issue Tracking** - Superior to spec-kit
3. **Progress Visibility** - Epic/task status tracking
4. **Git Worktree** - Isolation per task
5. **Parallel Agents** - Task decomposition

## Proposed New Features (Beyond Spec-Kit)

### 1. Dependency Visualization

```
/pm:deps-graph <epic_name>
  - Generate task dependency graph
  - Show parallel vs sequential paths
  - Identify critical path
```

### 2. Progress Dashboard

```
/pm:dashboard
  - Overall project health
  - Epic completion rates
  - Task velocity tracking
  - Blocker identification
```

### 3. Epic Templates

```
/pm:epic-template <type>
  - feature: New feature epic
  - bugfix: Bug fix epic
  - refactor: Refactoring epic
  - research: Research spike epic
```

### 4. Time Estimation

```
/pm:estimate <epic_name>
  - Analyze task complexity
  - Suggest time estimates
  - Compare with similar tasks
```

### 5. Automated Progress Updates

```
/pm:auto-sync
  - Watch git commits
  - Update task status automatically
  - Post progress to Gitea
```

## Conclusion

**Best Integration Strategy:**

1. ✅ **Adopt:** Constitution concept (governance)
2. ✅ **Adopt:** Executable specifications (testing)
3. ✅ **Adapt:** Spec validation (Gitea-specific)
4. ❌ **Ignore:** CLI scaffolding (we have install.sh)
5. ❌ **Ignore:** Multi-platform (we're Gitea-only)

**Priority:**
1. Add Constitution support (easy win)
2. Enhance PRD with executable criteria
3. Add spec validation command
4. Implement progress dashboard
5. Add dependency visualization

This keeps CCPM's strengths while adding spec-kit's best ideas.
