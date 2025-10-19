# Claude Code PM - Gitea Only Edition

> 🔧 **Gitea-Only Version**: This is an independent fork that only supports Gitea.
>
> **Original Project**: [automazeio/ccpm](https://github.com/automazeio/ccpm) by [@aroussi](https://x.com/aroussi)
> **License**: MIT (same as original)
>
> This version removes GitHub support and simplifies the codebase to focus exclusively on Gitea workflows.

[![Automaze](https://img.shields.io/badge/By-automaze.io-4b3baf)](https://automaze.io)
&nbsp;
[![Claude Code](https://img.shields.io/badge/+-Claude%20Code-d97757)](https://github.com/automazeio/ccpm/blob/main/README.md)
[![Gitea Issues](https://img.shields.io/badge/+-Gitea%20Issues-609926)](https://gitea.com)
&nbsp;
[![MIT License](https://img.shields.io/badge/License-MIT-28a745)](https://github.com/automazeio/ccpm/blob/main/LICENSE)
&nbsp;
[![Follow on 𝕏](https://img.shields.io/badge/𝕏-@aroussi-1c9bf0)](http://x.com/intent/follow?screen_name=aroussi)

### Claude Code workflow to ship ~~faster~~ _better_ using spec-driven development, Gitea issues, Git worktrees, and multiple AI agents running in parallel.

**[繁體中文文檔 (Traditional Chinese)](docs/zh-tw/README.md)** | **[簡體中文文檔 (Simplified Chinese)](docs/zh-cn/README.md)**

Stop losing context. Stop blocking on tasks. Stop shipping bugs. This battle-tested system turns PRDs into epics, epics into Gitea issues, and issues into production code – with full traceability at every step.

![Claude Code PM](screenshot.webp)

## Table of Contents

- [Background](#background)
- [The Workflow](#the-workflow)
- [What Makes This Different?](#what-makes-this-different)
- [Why Gitea Issues?](#why-gitea-issues)
- [Core Principle: No Vibe Coding](#core-principle-no-vibe-coding)
- [System Architecture](#system-architecture)
- [Workflow Phases](#workflow-phases)
- [Command Reference](#command-reference)
- [The Parallel Execution System](#the-parallel-execution-system)
- [Key Features & Benefits](#key-features--benefits)
- [Proven Results](#proven-results)
- [Example Flow](#example-flow)
- [Get Started Now](#get-started-now)
- [Local vs Remote](#local-vs-remote)
- [Technical Notes](#technical-notes)
- [Support This Project](#support-this-project)

## Background

Every team struggles with the same problems:
- **Context evaporates** between sessions, forcing constant re-discovery
- **Parallel work creates conflicts** when multiple developers touch the same code
- **Requirements drift** as verbal decisions override written specs
- **Progress becomes invisible** until the very end

This system solves all of that.

## The Workflow

```mermaid
graph LR
    A[PRD Creation] --> B[Epic Planning]
    B --> C[Task Decomposition]
    C --> D[Gitea Sync]
    D --> E[Parallel Execution]
```

### See It In Action (60 seconds)

```bash
# Create a comprehensive PRD through guided brainstorming
/pm:prd-new memory-system

# Transform PRD into a technical epic with task breakdown
/pm:prd-parse memory-system

# Push to Gitea and start parallel execution
/pm:epic-oneshot memory-system
/pm:issue-start 1235
```

## What Makes This Different?

| Traditional Development | Claude Code PM System |
|------------------------|----------------------|
| Context lost between sessions | **Persistent context** across all work |
| Serial task execution | **Parallel agents** on independent tasks |
| "Vibe coding" from memory | **Spec-driven** with full traceability |
| Progress hidden in branches | **Transparent audit trail** in Gitea |
| Manual task coordination | **Intelligent prioritization** with `/pm:next` |

## Why Gitea Issues?

Most Claude Code workflows operate in isolation – a single developer working with AI in their local environment. This creates a fundamental problem: **AI-assisted development becomes a silo**.

By using Gitea Issues as our database, we unlock something powerful:

### 🤝 **True Team Collaboration**
- Multiple Claude instances can work on the same project simultaneously
- Human developers see AI progress in real-time through issue comments
- Team members can jump in anywhere – the context is always visible
- Managers get transparency without interrupting flow

### 🔄 **Seamless Human-AI Handoffs**
- AI can start a task, human can finish it (or vice versa)
- Progress updates are visible to everyone, not trapped in chat logs
- Code reviews happen naturally through PR comments
- No "what did the AI do?" meetings

### 📈 **Scalable Beyond Solo Work**
- Add team members without onboarding friction
- Multiple AI agents working in parallel on different issues
- Distributed teams stay synchronized automatically
- Works with existing Gitea workflows and tools

### 🎯 **Single Source of Truth**
- No separate databases or project management tools
- Issue state is the project state
- Comments are the audit trail
- Labels provide organization

This isn't just a project management system – it's a **collaboration protocol** that lets humans and AI agents work together at scale, using infrastructure your team already trusts.

## Core Principle: No Vibe Coding

> **Every line of code must trace back to a specification.**

We follow a strict 5-phase discipline:

1. **🧠 Brainstorm** - Think deeper than comfortable
2. **📝 Document** - Write specs that leave nothing to interpretation
3. **📐 Plan** - Architect with explicit technical decisions
4. **⚡ Execute** - Build exactly what was specified
5. **📊 Track** - Maintain transparent progress at every step

No shortcuts. No assumptions. No regrets.

## System Architecture

```
.claude/
├── CLAUDE.md          # Always-on instructions (copy content to your project's CLAUDE.md file)
├── agents/            # Task-oriented agents (for context preservation)
├── commands/          # Command definitions
│   ├── context/       # Create, update, and prime context
│   ├── pm/            # ← Project management commands (this system)
│   └── testing/       # Prime and execute tests (edit this)
├── context/           # Project-wide context files
├── epics/             # ← PM's local workspace (place in .gitignore)
│   └── [epic-name]/   # Epic and related tasks
│       ├── epic.md    # Implementation plan
│       ├── [#].md     # Individual task files
│       └── updates/   # Work-in-progress updates
├── prds/              # ← PM's PRD files
├── rules/             # Place any rule files you'd like to reference here
└── scripts/           # Place any script files you'd like to use here
```

## Workflow Phases

### 1. Product Planning Phase

```bash
/pm:prd-new feature-name
```
Launches comprehensive brainstorming to create a Product Requirements Document capturing vision, user stories, success criteria, and constraints.

**Output:** `.claude/prds/feature-name.md`

### 2. Implementation Planning Phase

```bash
/pm:prd-parse feature-name
```
Transforms PRD into a technical implementation plan with architectural decisions, technical approach, and dependency mapping.

**Output:** `.claude/epics/feature-name/epic.md`

### 3. Task Decomposition Phase

```bash
/pm:epic-decompose feature-name
```
Breaks epic into concrete, actionable tasks with acceptance criteria, effort estimates, and parallelization flags.

**Output:** `.claude/epics/feature-name/[task].md`

### 4. Gitea Synchronization

```bash
/pm:epic-sync feature-name
# Or for confident workflows:
/pm:epic-oneshot feature-name
```
Pushes epic and tasks to Gitea as issues with appropriate labels and relationships.

### 5. Execution Phase

```bash
/pm:issue-start 1234  # Launch specialized agent
/pm:issue-sync 1234   # Push progress updates
/pm:next             # Get next priority task
```
Specialized agents implement tasks while maintaining progress updates and an audit trail.

## Command Reference

> [!TIP]
> Type `/pm:help` for a concise command summary

### Initial Setup
- `/pm:init` - Install dependencies and configure Gitea

### PRD Commands
- `/pm:prd-new` - Launch brainstorming for new product requirement
- `/pm:prd-parse` - Convert PRD to implementation epic
- `/pm:prd-list` - List all PRDs
- `/pm:prd-edit` - Edit existing PRD
- `/pm:prd-status` - Show PRD implementation status

### Epic Commands
- `/pm:epic-decompose` - Break epic into task files
- `/pm:epic-sync` - Push epic and tasks to Gitea
- `/pm:epic-oneshot` - Decompose and sync in one command
- `/pm:epic-list` - List all epics
- `/pm:epic-show` - Display epic and its tasks
- `/pm:epic-close` - Mark epic as complete
- `/pm:epic-edit` - Edit epic details
- `/pm:epic-refresh` - Update epic progress from tasks

### Issue Commands
- `/pm:issue-show` - Display issue and sub-issues
- `/pm:issue-status` - Check issue status
- `/pm:issue-start` - Begin work with specialized agent
- `/pm:issue-sync` - Push updates to Gitea
- `/pm:issue-close` - Mark issue as complete
- `/pm:issue-reopen` - Reopen closed issue
- `/pm:issue-edit` - Edit issue details

### Workflow Commands
- `/pm:next` - Show next priority issue with epic context
- `/pm:status` - Overall project dashboard
- `/pm:standup` - Daily standup report
- `/pm:blocked` - Show blocked tasks
- `/pm:in-progress` - List work in progress

### Sync Commands
- `/pm:sync` - Full bidirectional sync with Gitea
- `/pm:import` - Import existing Gitea issues

### Maintenance Commands
- `/pm:validate` - Check system integrity
- `/pm:clean` - Archive completed work
- `/pm:search` - Search across all content

## The Parallel Execution System

### Issues Aren't Atomic

Traditional thinking: One issue = One developer = One task

**Reality: One issue = Multiple parallel work streams**

A single "Implement user authentication" issue isn't one task. It's...

- **Agent 1**: Database tables and migrations
- **Agent 2**: Service layer and business logic
- **Agent 3**: API endpoints and middleware
- **Agent 4**: UI components and forms
- **Agent 5**: Test suites and documentation

All running **simultaneously** in the same worktree.

### The Math of Velocity

**Traditional Approach:**
- Epic with 3 issues
- Sequential execution

**This System:**
- Same epic with 3 issues
- Each issue splits into ~4 parallel streams
- **12 agents working simultaneously**

We're not assigning agents to issues. We're **leveraging multiple agents** to ship faster.

### Context Optimization

**Traditional single-thread approach:**
- Main conversation carries ALL the implementation details
- Context window fills with database schemas, API code, UI components
- Eventually hits context limits and loses coherence

**Parallel agent approach:**
- Main thread stays clean and strategic
- Each agent handles its own context in isolation
- Implementation details never pollute the main conversation
- Main thread maintains oversight without drowning in code

Your main conversation becomes the conductor, not the orchestra.

### Gitea vs Local: Perfect Separation

**What Gitea Sees:**
- Clean, simple issues
- Progress updates
- Completion status

**What Actually Happens Locally:**
- Issue #1234 explodes into 5 parallel agents
- Agents coordinate through Git commits
- Complex orchestration hidden from view

Gitea doesn't need to know HOW the work got done – just that it IS done.

### The Command Flow

```bash
# Analyze what can be parallelized
/pm:issue-analyze 1234

# Launch the swarm
/pm:epic-start memory-system

# Watch the magic
# 12 agents working across 3 issues
# All in: ../epic-memory-system/

# One clean merge when done
/pm:epic-merge memory-system
```

## Key Features & Benefits

### 🧠 **Context Preservation**
Never lose project state again. Each epic maintains its own context, agents read from `.claude/context/`, and updates locally before syncing.

### ⚡ **Parallel Execution**
Ship faster with multiple agents working simultaneously. Tasks marked `parallel: true` enable conflict-free concurrent development.

### 🔗 **Gitea Native**
Works with tools your team already uses. Issues are the source of truth, comments provide history, and fully integrated with Gitea's workflow.

### 🤖 **Agent Specialization**
Right tool for every job. Different agents for UI, API, and database work. Each reads requirements and posts updates automatically.

### 📊 **Full Traceability**
Every decision is documented. PRD → Epic → Task → Issue → Code → Commit. Complete audit trail from idea to production.

### 🚀 **Developer Productivity**
Focus on building, not managing. Intelligent prioritization, automatic context loading, and incremental sync when ready.

## Proven Results

Teams using this system report:
- **89% less time** lost to context switching – you'll use `/compact` and `/clear` a LOT less
- **5-8 parallel tasks** vs 1 previously – editing/testing multiple files at the same time
- **75% reduction** in bug rates – due to the breaking down features into detailed tasks
- **Up to 3x faster** feature delivery – based on feature size and complexity

## Example Flow

```bash
# Start a new feature
/pm:prd-new memory-system

# Review and refine the PRD...

# Create implementation plan
/pm:prd-parse memory-system

# Review the epic...

# Break into tasks and push to Gitea
/pm:epic-oneshot memory-system
# Creates issues: #1234 (epic), #1235, #1236 (tasks)

# Start development on a task
/pm:issue-start 1235
# Agent begins work, maintains local progress

# Sync progress to Gitea
/pm:issue-sync 1235
# Updates posted as issue comments

# Check overall status
/pm:epic-show memory-system
```

## Get Started Now

### Quick Setup (2 minutes)

> 📌 **Note**: This is the **Gitea-only version** of CCPM. It only supports Gitea and does not include GitHub support. For the full version with both GitHub and Gitea support, visit [automazeio/ccpm](https://github.com/automazeio/ccpm).

#### Installation Steps

**Option 1: Automated Installation (Recommended)**

1. **Clone this repository into your project**:
   ```bash
   cd path/to/your/project/
   git clone https://github.com/Ricemug/ccpm.git ccpm-gitea
   ```

2. **Run the installation script**:
   ```bash
   cd ccpm-gitea
   ./install.sh
   ```

   This will:
   - Copy all CCPM files to `.claude/` directory
   - Run the initialization automatically
   - Set up Gitea CLI (tea) if needed
   - Create necessary directories and labels

**Option 2: Manual Installation**

1. **Clone and copy files**:
   ```bash
   cd path/to/your/project/
   git clone https://github.com/Ricemug/ccpm.git temp-ccpm
   mkdir -p .claude
   cp -r temp-ccpm/ccpm/* .claude/
   rm -rf temp-ccpm
   ```

   > ⚠️ **IMPORTANT**:
   > - The `ccpm/` directory contains the template files
   > - Copy the **contents** of `ccpm/` to `.claude/` (not the ccpm folder itself)
   > - If you already have a `.claude` directory, backup it first

2. **Initialize the PM system**:
   ```bash
   /pm:init
   ```
   This command will:
   - Check for Gitea CLI (tea) and install if needed
   - Verify authentication with your Gitea instance
   - Create required directories
   - Set up labels in your repository

   > 💡 **Authentication**: You need to configure tea CLI first:
   > ```bash
   > tea login add --name myserver --url https://your-gitea.com --token YOUR_TOKEN
   > ```
   > Get your token from: Gitea Settings → Applications → Generate New Token

3. **Create `CLAUDE.md`** with your repository information
   ```bash
   /init include rules from .claude/CLAUDE.md
   ```
   > If you already have a `CLAUDE.md` file, run: `/re-init` to update it with important rules from `.claude/CLAUDE.md`.

4. **Prime the system**:
   ```bash
   /context:create
   ```



### Start Your First Feature

```bash
/pm:prd-new your-feature-name
```

Watch as structured planning transforms into shipped code.

## Local vs Remote

| Operation | Local | Gitea |
|-----------|-------|-------|
| PRD Creation | ✅ | — |
| Implementation Planning | ✅ | — |
| Task Breakdown | ✅ | ✅ (sync) |
| Execution | ✅ | — |
| Status Updates | ✅ | ✅ (sync) |
| Final Deliverables | — | ✅ |

## Technical Notes

### Gitea Integration
- **Gitea-only version** - simplified and focused on Gitea workflows
- Uses markdown task lists in epic issue body for task tracking
  - Format: `- [ ] Task: Title #123`
  - Tasks are checked off as they complete
- Epic issues track sub-task completion automatically via task list
- Labels provide organization (`epic:feature`, `task:feature`)
- Full integration with Gitea's issue system and workflows

### File Naming Convention
- Tasks start as `001.md`, `002.md` during decomposition
- After Gitea sync, renamed to `{issue-id}.md` (e.g., `1234.md`)
- Makes it easy to navigate: issue #1234 = file `1234.md`

### Design Decisions
- Focused exclusively on Gitea for simplicity
- All commands operate on local files first for speed
- Synchronization with Gitea is explicit and controlled
- Worktrees provide clean git isolation for parallel work
- Uses Gitea's native issue system without external dependencies

---

## Support This Project

Claude Code PM was developed at [Automaze](https://automaze.io) **for developers who ship, by developers who ship**.

If Claude Code PM helps your team ship better software:

- ⭐ **[Star this repository](https://github.com/automazeio/ccpm)** to show your support
- 🐦 **[Follow @aroussi on X](https://x.com/aroussi)** for updates and tips


---

> [!TIP]
> **Ship faster with Automaze.** We partner with founders to bring their vision to life, scale their business, and optimize for success.
> **[Visit Automaze to book a call with me ›](https://automaze.io)**

---

## Star History

![Star History Chart](https://api.star-history.com/svg?repos=automazeio/ccpm)
