---
allowed-tools: Bash, Read, Write, AskUserQuestion
---

# Constitution Create

Create or update project constitution with AI-guided customization.

## Usage
```
/pm:constitution-create
```

## What is a Constitution?

A project constitution defines:
- **Core Principles**: Code quality, architecture, security standards
- **Technology Stack**: Approved frameworks and libraries
- **Decision-Making**: Who decides what and how
- **Development Workflow**: Git workflow, code review, testing
- **Quality Gates**: What must pass before merge/release

All PRDs and epics should align with the constitution.

## Instructions

### 1. Check if Constitution Already Exists

```bash
if [ -f ".claude/CONSTITUTION.md" ]; then
  echo "⚠️  Constitution already exists at .claude/CONSTITUTION.md"
  echo ""
  echo "Contents:"
  head -30 .claude/CONSTITUTION.md
  echo ""
  echo "..."
  echo ""
  read -p "Do you want to update it? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled. Constitution unchanged."
    exit 0
  fi

  # Backup existing
  cp .claude/CONSTITUTION.md .claude/CONSTITUTION.backup.$(date +%s).md
  echo "✓ Backed up existing constitution"
fi
```

### 2. Copy Template

```bash
# Copy template from ccpm to .claude/
cp ccpm/CONSTITUTION.md .claude/CONSTITUTION.md
echo "✓ Copied constitution template"
```

### 3. Gather Project Context

Ask the user about their project to customize the constitution:

Use the AskUserQuestion tool to ask:

**Question 1:**
- **question**: "What is your primary technology stack?"
- **header**: "Tech Stack"
- **multiSelect**: false
- **options**:
  - label: "JavaScript/TypeScript (Node.js, React)"
    description: "Full-stack JavaScript with Node.js backend and React/Vue/Angular frontend"
  - label: "Python (Django/FastAPI)"
    description: "Python backend with Django or FastAPI framework"
  - label: "Go (Gin/Echo)"
    description: "Go backend with Gin or Echo framework"
  - label: "Java/Kotlin (Spring)"
    description: "JVM-based backend with Spring framework"

**Question 2:**
- **question**: "What type of project is this?"
- **header**: "Project Type"
- **multiSelect**: false
- **options**:
  - label: "Web Application"
    description: "Full-stack web application with frontend and backend"
  - label: "API Service"
    description: "Backend API service without frontend"
  - label: "Mobile App"
    description: "Mobile application (iOS/Android)"
  - label: "Library/Package"
    description: "Reusable library or package for other developers"

**Question 3:**
- **question**: "What are your quality priorities?"
- **header**: "Priorities"
- **multiSelect**: true
- **options**:
  - label: "Performance"
    description: "Fast response times, optimized resource usage"
  - label: "Security"
    description: "Strong security practices, compliance requirements"
  - label: "Scalability"
    description: "Ability to handle growth in users/data"
  - label: "Maintainability"
    description: "Clean code, good documentation, easy to modify"

### 4. Customize Constitution

Read the template and customize based on user answers:

```bash
# Read user answers from AskUserQuestion results
tech_stack="[TECH_STACK_FROM_QUESTION_1]"
project_type="[PROJECT_TYPE_FROM_QUESTION_2]"
priorities="[PRIORITIES_FROM_QUESTION_3]"
```

Use the Read tool to read `.claude/CONSTITUTION.md`, then use the Write tool to update it with:

1. **Update technology stack section** based on tech_stack answer
2. **Adjust quality standards** based on priorities
3. **Set project type-specific requirements** based on project_type
4. **Update timestamp**: Replace `[DATE]` with current date

For example:
- If "Performance" priority selected, emphasize performance standards
- If "API Service" type, remove frontend-specific requirements
- If "JavaScript/TypeScript" stack, specify npm/yarn, ESLint, Jest

### 5. Review and Finalize

```bash
echo ""
echo "✨ Constitution created at: .claude/CONSTITUTION.md"
echo ""
echo "📖 Review and customize:"
echo "   - Edit core principles for your team's needs"
echo "   - Specify your exact technology stack"
echo "   - Adjust quality gates and thresholds"
echo "   - Update decision-making roles"
echo ""
echo "📝 Next steps:"
echo "   1. Review the constitution with your team"
echo "   2. Customize sections as needed"
echo "   3. Reference it in PRDs: /pm:prd-new"
echo "   4. Check alignment in epics: /pm:epic-decompose"
echo ""
echo "💡 Tip: Update the constitution as your project evolves"
```

## Constitution Benefits

**For PRDs:**
- Ensures new features align with project standards
- Provides reference for technology choices
- Defines quality expectations upfront

**For Epics:**
- Validates architectural decisions
- Ensures security standards are met
- Maintains consistency across features

**For Tasks:**
- Clear coding standards reference
- Known testing requirements
- Defined review criteria

## Integration with CCPM

The constitution integrates with:

1. **/pm:prd-new** - Will prompt to check constitution alignment
2. **/pm:epic-decompose** - Can validate against constitution
3. **/pm:issue-start** - Agents can reference constitution for standards

After creating the constitution, future PRDs and epics will automatically check alignment with it.
