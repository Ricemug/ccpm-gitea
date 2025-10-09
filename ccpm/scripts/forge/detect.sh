#!/usr/bin/env bash
# forge/detect.sh - Gitea-only version
#
# Usage:
#   source forge/detect.sh
#   FORGE_TYPE=$(detect_forge)
#
# Returns: "gitea" (always)

detect_forge() {
  # Always return gitea for this version
  echo "gitea"
  return 0
}

# If run directly, output result
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  detect_forge
fi
