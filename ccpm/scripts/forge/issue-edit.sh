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

  local cmd="gh issue edit $issue_number"

  if [[ -n "$repo" ]]; then
    cmd="$cmd --repo $repo"
  fi

  if [[ -n "$title" ]]; then
    cmd="$cmd --title \"$title\""
  fi

  if [[ -n "$body" ]]; then
    cmd="$cmd --body \"$body\""
  fi

  if [[ -n "$add_labels" ]]; then
    cmd="$cmd --add-label $add_labels"
  fi

  if [[ -n "$remove_labels" ]]; then
    cmd="$cmd --remove-label $remove_labels"
  fi

  if [[ -n "$milestone" ]]; then
    cmd="$cmd --milestone \"$milestone\""
  fi

  if [[ -n "$state" ]]; then
    if [[ "$state" == "closed" ]]; then
      cmd="gh issue close $issue_number"
      [[ -n "$repo" ]] && cmd="$cmd --repo $repo"
    elif [[ "$state" == "open" ]]; then
      cmd="gh issue reopen $issue_number"
      [[ -n "$repo" ]] && cmd="$cmd --repo $repo"
    fi
  fi

  eval "$cmd"
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

  # 處理狀態變更 (Gitea 需要分開的 close/reopen 指令)
  if [[ -n "$state" ]]; then
    local state_cmd=""
    if [[ "$state" == "closed" ]]; then
      state_cmd="tea issues close $issue_number"
    elif [[ "$state" == "open" ]]; then
      state_cmd="tea issues reopen $issue_number"
    fi

    if [[ -n "$state_cmd" ]]; then
      [[ -n "$repo" ]] && state_cmd="$state_cmd --repo $repo"
      eval "$state_cmd"
    fi
  fi

  # Gitea tea CLI 沒有統一的 edit 指令，需要使用 API 或分開處理
  # 這裡簡化處理：只支援 add-labels
  if [[ -n "$add_labels" ]]; then
    # 注意：tea 可能需要使用不同的方式來編輯 labels
    # 這裡假設使用 API 或其他方式
    forge_error "Gitea issue edit (labels) not fully implemented yet"
  fi

  # TODO: 實作完整的 Gitea issue edit 功能
  # 可能需要使用 Gitea API
}

# 如果直接執行此腳本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  forge_issue_edit "$@"
fi
