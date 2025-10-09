#!/usr/bin/env bash
# forge/config.sh - Gitea-only configuration
#
# Usage:
#   source forge/config.sh
#   forge_init

# Get current script directory (supports bash and zsh)
if [[ -n "${BASH_SOURCE[0]}" ]]; then
  # Bash
  FORGE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [[ -n "${(%):-%x}" ]]; then
  # Zsh
  FORGE_SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
  # Fallback
  FORGE_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# Initialize forge environment
forge_init() {
  # Always use Gitea
  FORGE_TYPE="gitea"
  export FORGE_TYPE

  # Check if tea CLI is installed
  if ! command -v tea &>/dev/null; then
    echo "Error: Gitea CLI (tea) is not installed" >&2
    echo "Install: brew install tea (macOS) or download from https://gitea.com/gitea/tea" >&2
    return 1
  fi

  return 0
}

# Parse labels string to array (Gitea returns space-separated string)
forge_parse_labels() {
  local labels_input="$1"

  if [[ -z "$labels_input" ]]; then
    return 0
  fi

  # Convert space-separated to line-separated
  echo "$labels_input" | tr ' ' '\n' | grep -v '^$'
}

# Convert labels array to CLI parameter format (comma-separated)
forge_format_labels() {
  local labels=("$@")

  if [[ ${#labels[@]} -eq 0 ]]; then
    return 0
  fi

  local IFS=','
  echo "${labels[*]}"
}

# Parse YAML output, extract specific field
forge_yaml_get_field() {
  local yaml_content="$1"
  local field_name="$2"

  echo "$yaml_content" | grep "^    ${field_name}:" | sed -E "s/^    ${field_name}: '?([^']*)'?$/\1/"
}

# Error handling
forge_error() {
  echo "Error: $*" >&2
  return 1
}

# If run directly, test initialization
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  forge_init
  echo "Forge type: $FORGE_TYPE"
fi
