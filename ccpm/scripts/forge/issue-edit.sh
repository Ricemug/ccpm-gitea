#!/usr/bin/env bash
# forge/issue-edit.sh - Gitea issue editing
#
# Usage:
#   forge_issue_edit ISSUE_NUMBER [options]
#
# Options:
#   --repo REPO           Repository (optional)
#   --title TITLE         Update title (optional)
#   --body BODY           Update body (optional)
#   --add-labels LABELS   Add labels (comma-separated, optional)
#   --remove-labels LABELS Remove labels (comma-separated, optional)
#   --milestone MILESTONE Set milestone (optional)
#   --state STATE         Set state (open|closed, optional)
#
# Returns: Success or failure

# Load config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

forge_issue_edit() {
  # Initialize
  forge_init || return 1

  # Parse parameters
  local issue_number=""
  local repo=""
  local title=""
  local body=""
  local add_labels=""
  local remove_labels=""
  local milestone=""
  local state=""

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
      --title)
        title="$2"
        shift 2
        ;;
      --body)
        body="$2"
        shift 2
        ;;
      --add-labels)
        add_labels="$2"
        shift 2
        ;;
      --remove-labels)
        remove_labels="$2"
        shift 2
        ;;
      --milestone)
        milestone="$2"
        shift 2
        ;;
      --state)
        state="$2"
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

  # Handle state changes (Gitea requires separate close/reopen commands)
  if [[ -n "$state" ]]; then
    # Validate state value
    if [[ "$state" != "open" && "$state" != "closed" ]]; then
      forge_error "Invalid state value: $state. Must be 'open' or 'closed'."
      return 1
    fi

    local state_cmd
    if [[ "$state" == "closed" ]]; then
      state_cmd=(tea issues close "$issue_number")
    elif [[ "$state" == "open" ]]; then
      state_cmd=(tea issues reopen "$issue_number")
    fi

    if [[ -n "$repo" ]]; then
      state_cmd+=(--repo "$repo")
    fi

    # Execute state change
    if ! "${state_cmd[@]}"; then
      local error_msg="Failed to change issue state for issue #$issue_number"
      [[ -n "$repo" ]] && error_msg+=" in repo $repo"
      forge_error "$error_msg"
      return 1
    fi
  fi

  # Handle title, body, and milestone edits
  local has_edits=false

  if [[ -n "$title" ]] || [[ -n "$body" ]] || [[ -n "$milestone" ]]; then
    local edit_cmd=(tea issues edit "$issue_number")

    [[ -n "$title" ]] && edit_cmd+=(--title "$title")
    [[ -n "$body" ]] && edit_cmd+=(--body "$body")
    [[ -n "$milestone" ]] && edit_cmd+=(--milestone "$milestone")
    [[ -n "$repo" ]] && edit_cmd+=(--repo "$repo")

    if ! "${edit_cmd[@]}"; then
      forge_error "Failed to edit issue #$issue_number"
      return 1
    fi
    has_edits=true
  fi

  # Handle label operations
  if [[ -n "$add_labels" ]]; then
    local add_cmd=(tea issues edit "$issue_number" --add-labels "$add_labels")
    if [[ -n "$repo" ]]; then
      add_cmd+=(--repo "$repo")
    fi
    if ! "${add_cmd[@]}"; then
      forge_error "Failed to add labels to issue #$issue_number"
      return 1
    fi
    has_edits=true
  fi

  if [[ -n "$remove_labels" ]]; then
    local remove_cmd=(tea issues edit "$issue_number" --remove-labels "$remove_labels")
    if [[ -n "$repo" ]]; then
      remove_cmd+=(--repo "$repo")
    fi
    if ! "${remove_cmd[@]}"; then
      forge_error "Failed to remove labels from issue #$issue_number"
      return 1
    fi
    has_edits=true
  fi

  # Return success if we processed any edits or state changes
  if [[ "$has_edits" == "true" ]] || [[ -n "$state" ]]; then
    return 0
  fi
}

# If run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  forge_issue_edit "$@"
fi
