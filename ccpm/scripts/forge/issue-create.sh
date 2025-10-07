#!/usr/bin/env bash
# forge/issue-create.sh - 統一的 issue 建立介面
#
# 使用方式:
#   forge_issue_create --title "..." --body "..." [options]
#
# 選項:
#   --repo REPO           指定 repository (選填)
#   --title TITLE         Issue 標題 (必填)
#   --body BODY           Issue 內容 (必填)
#   --labels LABELS       Labels (逗號分隔，選填)
#   --milestone MILESTONE Milestone (選填)
#   --assignee ASSIGNEE   Assignee (選填)
#
# 回傳: 建立的 issue 編號

# 載入配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

forge_issue_create() {
  # 初始化
  forge_init || return 1

  # 參數解析
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

  # 驗證必填參數
  if [[ -z "$title" ]]; then
    forge_error "Title is required (--title)"
    return 1
  fi

  if [[ -z "$body" ]]; then
    forge_error "Body is required (--body)"
    return 1
  fi

  # 根據 forge 類型執行對應指令
  if [[ "$FORGE_TYPE" == "github" ]]; then
    _forge_issue_create_github "$repo" "$title" "$body" "$labels" "$milestone" "$assignee"
  elif [[ "$FORGE_TYPE" == "gitea" ]]; then
    _forge_issue_create_gitea "$repo" "$title" "$body" "$labels" "$milestone" "$assignee"
  else
    forge_error "Unsupported forge type: $FORGE_TYPE"
    return 1
  fi
}

_forge_issue_create_github() {
  local repo="$1"
  local title="$2"
  local body="$3"
  local labels="$4"
  local milestone="$5"
  local assignee="$6"

  # Write body to temp file to avoid command injection and preserve formatting
  local temp_file
  temp_file=$(mktemp) || return 1
  printf '%s' "$body" > "$temp_file"

  # Build command as array to avoid eval
  local cmd=(gh issue create --title "$title" --body-file "$temp_file")

  if [[ -n "$repo" ]]; then
    cmd+=(--repo "$repo")
  fi

  if [[ -n "$labels" ]]; then
    cmd+=(--label "$labels")
  fi

  if [[ -n "$milestone" ]]; then
    cmd+=(--milestone "$milestone")
  fi

  if [[ -n "$assignee" ]]; then
    cmd+=(--assignee "$assignee")
  fi

  # Execute command safely
  "${cmd[@]}"
  local exit_code=$?

  # Clean up temp file
  rm -f "$temp_file"

  return $exit_code
}

_forge_issue_create_gitea() {
  local repo="$1"
  local title="$2"
  local body="$3"
  local labels="$4"
  local milestone="$5"
  local assignee="$6"

  # Build command as array to avoid eval
  # Gitea uses --description instead of --body
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

  # Execute command safely without eval
  "${cmd[@]}"
}

# 如果直接執行此腳本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  forge_issue_create "$@"
fi
