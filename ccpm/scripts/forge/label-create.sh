#!/usr/bin/env bash
# forge/label-create.sh - Gitea label creation
#
# Usage:
#   forge_label_create --name "label-name" --color "#ffffff" [options]
#
# Options:
#   --repo REPO           Repository (optional)
#   --name NAME           Label name (required)
#   --color COLOR         Label color (hex color, required)
#   --description DESC    Label description (optional)
#
# Returns: Success or failure

# Load config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

forge_label_create() {
  # Initialize
  forge_init || return 1

  # Parse parameters
  local repo=""
  local name=""
  local color=""
  local description=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo)
        repo="$2"
        shift 2
        ;;
      --name)
        name="$2"
        shift 2
        ;;
      --color)
        color="$2"
        shift 2
        ;;
      --description)
        description="$2"
        shift 2
        ;;
      *)
        forge_error "Unknown option: $1"
        return 1
        ;;
    esac
  done

  # Validate required parameters
  if [[ -z "$name" ]]; then
    forge_error "Label name is required (--name)"
    return 1
  fi

  if [[ -z "$color" ]]; then
    forge_error "Label color is required (--color)"
    return 1
  fi

  # Build tea command
  local cmd=(tea labels create --name "$name" --color "$color")

  if [[ -n "$repo" ]]; then
    cmd+=(--repo "$repo")
  fi

  if [[ -n "$description" ]]; then
    cmd+=(--description "$description")
  fi

  # Execute command
  "${cmd[@]}"
}

# If run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  forge_label_create "$@"
fi
