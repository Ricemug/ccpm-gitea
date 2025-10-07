#!/bin/bash

REPO_URL="https://github.com/automazeio/ccpm.git"
TEMP_DIR="temp-ccpm-$$"  # Add PID for uniqueness
TARGET_DIR=".claude"

echo "Installing CCPM to $TARGET_DIR..."

# Check if .claude already exists
if [ -d "$TARGET_DIR" ]; then
    echo "Warning: $TARGET_DIR already exists."
    read -p "Backup and replace? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    # Backup existing .claude
    BACKUP_DIR=".claude.backup.$(date +%s)"
    echo "Backing up to $BACKUP_DIR..."
    mv "$TARGET_DIR" "$BACKUP_DIR"
fi

# Clone to temporary directory
echo "Cloning repository..."
git clone "$REPO_URL" "$TEMP_DIR"

if [ $? -eq 0 ]; then
    echo "Clone successful. Installing files..."

    # Copy ccpm directory to .claude
    cp -r "$TEMP_DIR/ccpm" "$TARGET_DIR"

    # Clean up
    rm -rf "$TEMP_DIR"

    echo ""
    echo "✅ CCPM installed successfully to $TARGET_DIR/"
    echo ""
    echo "Next steps:"
    echo "  1. Run: /pm:init"
    echo "  2. Follow the initialization prompts"
    echo ""
else
    echo "❌ Error: Failed to clone repository."
    exit 1
fi
