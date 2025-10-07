#!/usr/bin/env bash
# forge/issue-edit.sh - 統一的 issue 編輯介面
#
# 使用方式:
#   forge_issue_edit ISSUE_NUMBER [options]
#
# 選項:
#   --repo REPO           指定 repository (選填)
#   --title TITLE         更新標題 (選填)
#   --body BODY           更新內容 (選填)
#   --add-labels LABELS   新增 labels (逗號分隔，選填)
#   --remove-labels LABELS 移除 labels (逗號分隔，選填)
#   --milestone MILESTONE 設定 milestone (選填)
#   --state STATE         設定狀態 (open|closed，選填)
#
# 回傳: 成功或失敗

# 載入配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

forge_issue_edit() {
  # 初始化
  forge_init || return 1

  # 參數解析
  local issue_number=""
  local repo=""
  local title=""
  local body=""
  local add_labels=""
  local remove_labels=""
  local milestone=""
  local state=""

  # 第一個參數是 issue number
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

  # 驗證必填參數
  if [[ -z "$issue_number" ]]; then
    forge_error "Issue number is required"
    return 1
  fi

  # 根據 forge 類型執行對應指令
  if [[ "$FORGE_TYPE" == "github" ]]; then
    _forge_issue_edit_github "$issue_number" "$repo" "$title" "$body" "$add_labels" "$remove_labels" "$milestone" "$state"
  elif [[ "$FORGE_TYPE" == "gitea" ]]; then
    _forge_issue_edit_gitea "$issue_number" "$repo" "$title" "$body" "$add_labels" "$remove_labels" "$milestone" "$state"
  else
    forge_error "Unsupported forge type: $FORGE_TYPE"
    return 1
  fi
}

_forge_issue_edit_github() {
  local issue_number="$1"
  local repo="$2"
  local title="$3"
  local body="$4"
  local add_labels="$5"
  local remove_labels="$6"
  local milestone="$7"
  local state="$8"

  # Build edit command as array to avoid eval
  local cmd=(gh issue edit "$issue_number")
  local has_edit_flags=false

  if [[ -n "$repo" ]]; then
    cmd+=(--repo "$repo")
  fi

  if [[ -n "$title" ]]; then
    cmd+=(--title "$title")
    has_edit_flags=true
  fi

  if [[ -n "$body" ]]; then
    cmd+=(--body "$body")
    has_edit_flags=true
  fi

  if [[ -n "$add_labels" ]]; then
    cmd+=(--add-label "$add_labels")
    has_edit_flags=true
  fi

  if [[ -n "$remove_labels" ]]; then
    cmd+=(--remove-label "$remove_labels")
    has_edit_flags=true
  fi

  if [[ -n "$milestone" ]]; then
    cmd+=(--milestone "$milestone")
    has_edit_flags=true
  fi

  # Only execute edit if there are actual changes
  if [[ "$has_edit_flags" == "true" ]]; then
    "${cmd[@]}"
  fi

  # Handle state changes separately (allows both edit and state change)
  if [[ -n "$state" ]]; then
    local state_cmd
    if [[ "$state" == "closed" ]]; then
      state_cmd=(gh issue close "$issue_number")
    elif [[ "$state" == "open" ]]; then
      state_cmd=(gh issue reopen "$issue_number")
    fi

    if [[ -n "${state_cmd[*]}" ]]; then
      [[ -n "$repo" ]] && state_cmd+=(--repo "$repo")
      "${state_cmd[@]}"
    fi
  fi
}

_forge_issue_edit_gitea() {
  local issue_number="$1"
  local repo="$2"
  local title="$3"
  local body="$4"
  local add_labels="$5"
  local remove_labels="$6"
  local milestone="$7"
  local state="$8"

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

    # Execute state change safely without eval
    if ! "${state_cmd[@]}"; then
      local error_msg="Failed to change issue state with tea issues for issue #$issue_number"
      [[ -n "$repo" ]] && error_msg+=" in repo $repo"
      forge_error "$error_msg"
      return 1
    fi
  fi

  # Handle title and body edits
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

  # Handle label operations (tea CLI supports this according to docs)
  if [[ -n "$add_labels" ]]; then
    local add_cmd=(tea issues edit "$issue_number" --add-labels "$add_labels")
    if [[ -n "$repo" ]]; then
      add_cmd+=(--repo "$repo")
    fi
    "${add_cmd[@]}" || {
      forge_error "Failed to add labels to issue #$issue_number"
      return 1
    }
    has_edits=true
  fi

  if [[ -n "$remove_labels" ]]; then
    local remove_cmd=(tea issues edit "$issue_number" --remove-labels "$remove_labels")
    if [[ -n "$repo" ]]; then
      remove_cmd+=(--repo "$repo")
    fi
    "${remove_cmd[@]}" || {
      forge_error "Failed to remove labels from issue #$issue_number"
      return 1
    }
    has_edits=true
  fi

  # Return success if we processed any edits or state changes
  if [[ "$has_edits" == "true" ]] || [[ -n "$state" ]]; then
    return 0
  fi
}

# 如果直接執行此腳本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  forge_issue_edit "$@"
fi
