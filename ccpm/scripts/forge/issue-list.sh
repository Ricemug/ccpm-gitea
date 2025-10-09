#!/usr/bin/env bash
# forge/issue-list.sh - Gitea issue listing
#
# Usage:
#   forge_issue_list [options]
#
# Options:
#   --repo REPO       Repository (optional)
#   --state STATE     Filter by state: open|closed|all (default: open)
#   --labels LABELS   Filter by labels (comma-separated, optional)
#   --limit N         Limit results (optional)
#
# Returns: Issue list in YAML format

# Load config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

forge_issue_list() {
  # Initialize
  forge_init || return 1

  # Parse parameters
  local repo=""
  local state="open"
  local labels=""
  local limit=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo)
        repo="$2"
        shift 2
        ;;
      --state)
        state="$2"
        shift 2
        ;;
      --labels)
        labels="$2"
        shift 2
        ;;
      --limit)
        limit="$2"
        shift 2
        ;;
      *)
        forge_error "Unknown option: $1"
        return 1
        ;;
    esac
  done

  # Build tea command
  local cmd=(tea issues list --state "$state" --output yaml)

  if [[ -n "$repo" ]]; then
    cmd+=(--repo "$repo")
  fi

  if [[ -n "$labels" ]]; then
    cmd+=(--labels "$labels")
  fi

  if [[ -n "$limit" ]]; then
    cmd+=(--limit "$limit")
  fi

  # Execute command
  "${cmd[@]}"
}

# If run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  forge_issue_list "$@"
fi
