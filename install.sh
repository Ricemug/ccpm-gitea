#!/bin/bash
#
# CCPM Gitea Edition - Installation Script
#
# This script installs CCPM to your project's .claude directory
# and runs the initialization.
#
# Usage:
#   ./install.sh

set -e  # Exit on error

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  CCPM Gitea Edition - Installation      ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR=".claude"

# Check if .claude already exists
if [ -d "$TARGET_DIR" ]; then
  echo "⚠️  Warning: $TARGET_DIR directory already exists."
  echo ""
  read -p "Do you want to backup and replace it? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
  fi

  # Backup existing .claude
  BACKUP_DIR=".claude.backup.$(date +%s)"
  echo "📦 Backing up existing $TARGET_DIR to $BACKUP_DIR..."
  mv "$TARGET_DIR" "$BACKUP_DIR"
  echo "✅ Backup created"
  echo ""
fi

# Create .claude directory
echo "📁 Creating $TARGET_DIR directory..."
mkdir -p "$TARGET_DIR"

# Copy ccpm contents to .claude
echo "📝 Installing CCPM files..."
if [ -d "$SCRIPT_DIR/ccpm" ]; then
  cp -r "$SCRIPT_DIR/ccpm"/* "$TARGET_DIR"/
  echo "✅ Files copied to $TARGET_DIR/"
else
  echo "❌ Error: ccpm directory not found in $SCRIPT_DIR"
  echo "   Make sure you're running this script from the CCPM repository root."
  exit 1
fi

# Make scripts executable
echo "🔧 Setting up permissions..."
find "$TARGET_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} \;
echo "✅ Scripts are now executable"
echo ""

# Run initialization
echo "🚀 Running initialization..."
echo ""

if [ -f "$TARGET_DIR/scripts/pm/init.sh" ]; then
  bash "$TARGET_DIR/scripts/pm/init.sh"
else
  echo "❌ Error: init.sh not found at $TARGET_DIR/scripts/pm/init.sh"
  exit 1
fi

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  ✅ Installation Complete!               ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Try: /pm:help"
echo "  2. Create a PRD: /pm:prd-new <feature-name>"
echo "  3. Check status: /pm:status"
echo ""
