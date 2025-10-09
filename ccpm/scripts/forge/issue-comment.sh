#!/usr/bin/env bash
# forge/issue-comment.sh - Gitea issue commenting
#
# Usage:
#   forge_issue_comment ISSUE_NUMBER --body "comment text" [options]
#
# Options:
#   --repo REPO     Repository (optional)
#   --body BODY     Comment body (required)
#
# Returns: Success or failure

# Load config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

forge_issue_comment() {
  # Initialize
  forge_init || return 1

  # Parse parameters
  local issue_number=""
  local repo=""
  local body=""

  # First parameter is issue number
  if [[ $# -gt 0 ]] && [[ ! "$1" =~ ^-- ]]; then
    issue_number="$1"
    shift
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo)
        repo="$2"
        shift 2
        ;;
      --body)
        body="$2"
        shift 2
        ;;
      *)
        forge_error "Unknown option: $1"
        return 1
        ;;
    esac
  done

  # Validate required parameters
  if [[ -z "$issue_number" ]]; then
    forge_error "Issue number is required"
    return 1
  fi

  if [[ -z "$body" ]]; then
    forge_error "Comment body is required (--body)"
    return 1
  fi

  # Build tea command
  local cmd=(tea issues comment "$issue_number" "$body")

  if [[ -n "$repo" ]]; then
    cmd+=(--repo "$repo")
  fi

  # Execute command
  "${cmd[@]}"
}

# If run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  forge_issue_comment "$@"
fi
