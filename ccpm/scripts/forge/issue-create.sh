#!/usr/bin/env bash
# forge/issue-create.sh - Gitea issue creation
#
# Usage:
#   forge_issue_create --title "..." --body "..." [options]
#
# Options:
#   --repo REPO           Repository (optional)
#   --title TITLE         Issue title (required)
#   --body BODY           Issue body (required)
#   --labels LABELS       Labels (comma-separated, optional)
#   --milestone MILESTONE Milestone (optional)
#   --assignee ASSIGNEE   Assignee (optional)
#
# Returns: Created issue number

# Load config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

forge_issue_create() {
  # Initialize
  forge_init || return 1

  # Parse parameters
  local repo=""
  local title=""
  local body=""
  local labels=""
  local milestone=""
  local assignee=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo)
        repo="$2"
        shift 2
        ;;
      --title)
        title="$2"
        shift 2
        ;;
      --body)
        body="$2"
        shift 2
        ;;
      --labels)
        labels="$2"
        shift 2
        ;;
      --milestone)
        milestone="$2"
        shift 2
        ;;
      --assignee)
        assignee="$2"
        shift 2
        ;;
      *)
        forge_error "Unknown option: $1"
        return 1
        ;;
    esac
  done

  # Validate required parameters
  if [[ -z "$title" ]]; then
    forge_error "Title is required (--title)"
    return 1
  fi

  if [[ -z "$body" ]]; then
    forge_error "Body is required (--body)"
    return 1
  fi

  # Build tea command
  local cmd=(tea issues create --title "$title" --description "$body")

  if [[ -n "$repo" ]]; then
    cmd+=(--repo "$repo")
  fi

  if [[ -n "$labels" ]]; then
    cmd+=(--labels "$labels")
  fi

  if [[ -n "$milestone" ]]; then
    cmd+=(--milestone "$milestone")
  fi

  if [[ -n "$assignee" ]]; then
    cmd+=(--assignees "$assignee")
  fi

  # Execute command
  "${cmd[@]}"
}

# If run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  forge_issue_create "$@"
fi
