#!/bin/bash

echo "Initializing..."
echo ""
echo ""

echo " ██████╗ ██████╗██████╗ ███╗   ███╗"
echo "██╔════╝██╔════╝██╔══██╗████╗ ████║"
echo "██║     ██║     ██████╔╝██╔████╔██║"
echo "╚██████╗╚██████╗██║     ██║ ╚═╝ ██║"
echo " ╚═════╝ ╚═════╝╚═╝     ╚═╝     ╚═╝"

echo "┌─────────────────────────────────┐"
echo "│ Claude Code Project Management  │"
echo "│ by https://x.com/aroussi        │"
echo "└─────────────────────────────────┘"
echo "https://github.com/automazeio/ccpm"
echo ""
echo ""

echo "🚀 Initializing Claude Code PM System"
echo "======================================"
echo ""

# Get script directory for finding forge scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_DIR="$SCRIPT_DIR/forge"

# Detect Git Forge platform
echo "🔍 Detecting Git Forge platform..."

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "  ⚠️ Not a git repository. Defaulting to GitHub."
  AUTO_DETECTED="github"
else
  # Use forge detection
  if [ -f "$FORGE_DIR/detect.sh" ]; then
    source "$FORGE_DIR/detect.sh"
    AUTO_DETECTED=$(detect_forge)
  else
    echo "  ⚠️ Forge detection script not found. Defaulting to GitHub."
    AUTO_DETECTED="github"
  fi
fi

echo "  Auto-detected: $AUTO_DETECTED"
echo ""

# Check if FORGE_TYPE is already set (non-interactive mode)
if [[ -n "$FORGE_TYPE" ]]; then
  echo "  ℹ️ Using pre-configured forge type: $FORGE_TYPE"
else
  # Interactive mode
  echo "Which Git forge are you using?"
  echo "  1) GitHub (default)"
  echo "  2) Gitea (self-hosted)"
  echo "  3) Use auto-detection ($AUTO_DETECTED)"
  echo ""

  # Check if running in non-interactive environment
  if [[ ! -t 0 ]]; then
    echo "  ℹ️ Non-interactive mode detected, using auto-detected: $AUTO_DETECTED"
    FORGE_TYPE="$AUTO_DETECTED"
  else
    read -p "Enter your choice [1]: " forge_choice

    case "${forge_choice:-1}" in
      1)
        FORGE_TYPE="github"
        echo "  ✅ Selected: GitHub"
        ;;
      2)
        FORGE_TYPE="gitea"
        echo "  ✅ Selected: Gitea"
        ;;
      3)
        FORGE_TYPE="$AUTO_DETECTED"
        echo "  ✅ Using auto-detected: $FORGE_TYPE"
        ;;
      *)
        echo "  ⚠️  Invalid choice, defaulting to GitHub"
        FORGE_TYPE="github"
        ;;
    esac
  fi
fi

export FORGE_TYPE

# Save forge type to config file for future use
# Note: .claude directory should already exist (created during installation)
echo "$FORGE_TYPE" > .claude/.forge_type
echo "  💾 Saved forge type to .claude/.forge_type"
echo ""

# Check for required tools based on forge type
echo "🔍 Checking dependencies..."

if [[ "$FORGE_TYPE" == "github" ]]; then
  # Check gh CLI
  if command -v gh &> /dev/null; then
    echo "  ✅ GitHub CLI (gh) installed"
  else
    echo "  ❌ GitHub CLI (gh) not found"
    echo ""
    echo "  Installing gh..."
    if command -v brew &> /dev/null; then
      brew install gh
    elif command -v apt-get &> /dev/null; then
      sudo apt-get update && sudo apt-get install gh
    else
      echo "  Please install GitHub CLI manually: https://cli.github.com/"
      exit 1
    fi
  fi

  # Check gh auth status
  echo ""
  echo "🔐 Checking GitHub authentication..."
  if gh auth status &> /dev/null; then
    echo "  ✅ GitHub authenticated"
  else
    echo "  ⚠️ GitHub not authenticated"
    echo "  Running: gh auth login"
    gh auth login
  fi

  # Check for gh-sub-issue extension
  echo ""
  echo "📦 Checking gh extensions..."
  if gh extension list | grep -q "yahsan2/gh-sub-issue"; then
    echo "  ✅ gh-sub-issue extension installed"
  else
    echo "  📥 Installing gh-sub-issue extension..."
    gh extension install yahsan2/gh-sub-issue
  fi

elif [[ "$FORGE_TYPE" == "gitea" ]]; then
  # Check tea CLI
  if command -v tea &> /dev/null; then
    echo "  ✅ Gitea CLI (tea) installed"
  else
    echo "  ❌ Gitea CLI (tea) not found"
    echo ""
    echo "  Installing tea..."

    # Detect platform
    OS="$(uname -s)"
    ARCH="$(uname -m)"

    if [[ "$OS" == "Linux" ]]; then
      if [[ "$ARCH" == "x86_64" ]]; then
        TEA_URL="https://dl.gitea.com/tea/0.9.2/tea-0.9.2-linux-amd64"
      elif [[ "$ARCH" == "aarch64" ]]; then
        TEA_URL="https://dl.gitea.com/tea/0.9.2/tea-0.9.2-linux-arm64"
      fi
    elif [[ "$OS" == "Darwin" ]]; then
      if [[ "$ARCH" == "arm64" ]]; then
        TEA_URL="https://dl.gitea.com/tea/0.9.2/tea-0.9.2-darwin-arm64"
      else
        TEA_URL="https://dl.gitea.com/tea/0.9.2/tea-0.9.2-darwin-amd64"
      fi
    fi

    if [[ -n "$TEA_URL" ]]; then
      wget "$TEA_URL" -O /tmp/tea && chmod +x /tmp/tea && sudo mv /tmp/tea /usr/local/bin/tea
      echo "  ✅ tea CLI installed to /usr/local/bin/tea"
    else
      echo "  ⚠️ Unsupported platform. Please install tea CLI manually:"
      echo "     https://gitea.com/gitea/tea"
      exit 1
    fi
  fi

  # Check tea logins
  echo ""
  echo "🔐 Checking Gitea authentication..."
  if tea logins list &> /dev/null && [ "$(tea logins list | wc -l)" -gt 0 ]; then
    echo "  ✅ Gitea authenticated"
  else
    echo "  ⚠️ Gitea not authenticated"
    echo ""
    echo "  To authenticate with Gitea:"
    echo "  1. Create an API token in your Gitea instance:"
    echo "     Settings → Applications → Generate New Token"
    echo "  2. Required scopes: read:user, write:repository, write:issue"
    echo "  3. Run: tea login add --name <name> --url <gitea-url> --token <token>"
    echo ""
    echo "  Example:"
    echo "  tea login add --name myserver --url https://gitea.example.com --token abc123"
    echo ""
  fi

  # Info about gh-sub-issue alternative
  echo ""
  echo "ℹ️  Note: Gitea uses task lists instead of sub-issues"
  echo "  Epic issues will use markdown task lists: - [ ] Task #123"
  echo ""
fi

# Create directory structure
echo ""
echo "📁 Creating directory structure..."
mkdir -p .claude/prds
mkdir -p .claude/epics
mkdir -p .claude/rules
mkdir -p .claude/agents
mkdir -p .claude/scripts/pm
mkdir -p .claude/scripts/forge
echo "  ✅ Directories created"

# Copy scripts if in main repo
if [ -d "scripts/pm" ] && [ ! "$(pwd)" = *"/.claude"* ]; then
  echo ""
  echo "📝 Copying PM scripts..."
  cp -r scripts/pm/* .claude/scripts/pm/
  chmod +x .claude/scripts/pm/*.sh
  echo "  ✅ Scripts copied and made executable"
fi

# Copy forge scripts
if [ -d "$FORGE_DIR" ]; then
  echo ""
  echo "📝 Copying Forge abstraction scripts..."
  cp -r "$FORGE_DIR"/* .claude/scripts/forge/
  chmod +x .claude/scripts/forge/*.sh
  echo "  ✅ Forge scripts copied and made executable"
fi

# Check for git
echo ""
echo "🔗 Checking Git configuration..."
if git rev-parse --git-dir > /dev/null 2>&1; then
  echo "  ✅ Git repository detected"

  # Check remote
  if git remote -v | grep -q origin; then
    remote_url=$(git remote get-url origin)
    echo "  ✅ Remote configured: $remote_url"

    # Check if remote is the CCPM template repository
    if [[ "$remote_url" == *"automazeio/ccpm"* ]] || [[ "$remote_url" == *"automazeio/ccpm.git"* ]]; then
      echo ""
      echo "  ⚠️ WARNING: Your remote origin points to the CCPM template repository!"
      echo "  This means any issues you create will go to the template repo, not your project."
      echo ""
      echo "  To fix this:"
      echo "  1. Fork the repository or create your own on your Git Forge"
      echo "  2. Update your remote:"
      echo "     git remote set-url origin <your-repo-url>"
      echo ""
    else
      # Create labels using forge abstraction
      echo ""
      echo "🏷️ Creating labels..."

      # Source forge config
      if [ -f ".claude/scripts/forge/label-create.sh" ]; then
        epic_created=false
        task_created=false

        # Try to create epic label
        if .claude/scripts/forge/label-create.sh --name "epic" --color "0E8A16" --description "Epic issue containing multiple related tasks" 2>/dev/null; then
          epic_created=true
        fi

        # Try to create task label
        if .claude/scripts/forge/label-create.sh --name "task" --color "1D76DB" --description "Individual task within an epic" 2>/dev/null; then
          task_created=true
        fi

        # Report results
        if $epic_created && $task_created; then
          echo "  ✅ Labels created (epic, task)"
        elif $epic_created || $task_created; then
          echo "  ⚠️ Some labels created (epic: $epic_created, task: $task_created)"
        else
          echo "  ❌ Could not create labels (check repository permissions)"
        fi
      else
        echo "  ⚠️ Forge abstraction not available - skipping label creation"
      fi
    fi
  else
    echo "  ⚠️ No remote configured"
    echo "  Add with: git remote add origin <url>"
  fi
else
  echo "  ⚠️ Not a git repository"
  echo "  Initialize with: git init"
fi

# Create CLAUDE.md if it doesn't exist
if [ ! -f "CLAUDE.md" ]; then
  echo ""
  echo "📄 Creating CLAUDE.md..."
  cat > CLAUDE.md << 'EOF'
# CLAUDE.md

> Think carefully and implement the most concise solution that changes as little code as possible.

## Project-Specific Instructions

Add your project-specific instructions here.

## Testing

Always run tests before committing:
- `npm test` or equivalent for your stack

## Code Style

Follow existing patterns in the codebase.
EOF
  echo "  ✅ CLAUDE.md created"
fi

# Summary
echo ""
echo "✅ Initialization Complete!"
echo "=========================="
echo ""
echo "📊 System Status:"
if [[ "$FORGE_TYPE" == "github" ]]; then
  gh --version | head -1
  echo "  Extensions: $(gh extension list | wc -l) installed"
  echo "  Auth: $(gh auth status 2>&1 | grep -o 'Logged in to [^ ]*' || echo 'Not authenticated')"
elif [[ "$FORGE_TYPE" == "gitea" ]]; then
  tea --version | head -1
  echo "  Logins: $(tea logins list 2>/dev/null | wc -l) configured"
fi
echo "  Forge Type: $FORGE_TYPE"
echo ""
echo "🎯 Next Steps:"
echo "  1. Create your first PRD: /pm:prd-new <feature-name>"
echo "  2. View help: /pm:help"
echo "  3. Check status: /pm:status"
echo ""
echo "📚 Documentation: README.md"

exit 0
