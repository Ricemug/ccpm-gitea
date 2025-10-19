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

echo "🚀 Initializing Claude Code PM System (Gitea Edition)"
echo "======================================================"
echo ""

# Get script directory for finding forge scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_DIR="$SCRIPT_DIR/forge"

# Always use Gitea
FORGE_TYPE="gitea"
export FORGE_TYPE

echo "🔍 Git Forge platform: Gitea"
echo ""

# Save forge type to config file for future use
# Note: .claude directory should already exist (created during installation)
echo "$FORGE_TYPE" > .claude/.forge_type
echo "  💾 Saved forge type to .claude/.forge_type"
echo ""

# Check for required tools
echo "🔍 Checking dependencies..."

# Check tea CLI
if command -v tea &> /dev/null; then
  echo "  ✅ Gitea CLI (tea) installed"
else
  # Check Homebrew paths (may not be in PATH for non-interactive shells)
  if [[ -x "/opt/homebrew/bin/tea" ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
    echo "  ✅ Gitea CLI (tea) found at /opt/homebrew/bin/tea"
  elif [[ -x "/usr/local/bin/tea" ]]; then
    export PATH="/usr/local/bin:$PATH"
    echo "  ✅ Gitea CLI (tea) found at /usr/local/bin/tea"
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
      echo "     Or use Homebrew: brew install tea"
      exit 1
    fi
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

# Info about task lists
echo ""
echo "ℹ️  Note: Gitea uses task lists for epic issues"
echo "  Epic issues will use markdown task lists: - [ ] Task #123"
echo ""

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
      echo "  1. Create your own repository on your Gitea instance"
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
tea --version | head -1
echo "  Logins: $(tea logins list 2>/dev/null | wc -l) configured"
echo "  Forge Type: $FORGE_TYPE"
echo ""
echo "🎯 Next Steps:"
echo "  1. Create your first PRD: /pm:prd-new <feature-name>"
echo "  2. View help: /pm:help"
echo "  3. Check status: /pm:status"
echo ""
echo "📚 Documentation: README.md"

exit 0
