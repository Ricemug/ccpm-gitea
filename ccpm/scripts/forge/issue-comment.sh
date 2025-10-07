#!/usr/bin/env bash
# forge/issue-comment.sh - 統一的 issue 評論介面
#
# 使用方式:
#   forge_issue_comment ISSUE_NUMBER --body "comment text" [options]
#
# 選項:
#   --repo REPO     指定 repository (選填)
#   --body BODY     評論內容 (必填)
#
# 回傳: 成功或失敗

# 載入配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

forge_issue_comment() {
  # 初始化
  forge_init || return 1

  # 參數解析
  local issue_number=""
  local repo=""
  local body=""

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

  # 驗證必填參數
  if [[ -z "$issue_number" ]]; then
    forge_error "Issue number is required"
    return 1
  fi

  if [[ -z "$body" ]]; then
    forge_error "Comment body is required (--body)"
    return 1
  fi

  # 根據 forge 類型執行對應指令
  if [[ "$FORGE_TYPE" == "github" ]]; then
    _forge_issue_comment_github "$issue_number" "$repo" "$body"
  elif [[ "$FORGE_TYPE" == "gitea" ]]; then
    _forge_issue_comment_gitea "$issue_number" "$repo" "$body"
  else
    forge_error "Unsupported forge type: $FORGE_TYPE"
    return 1
  fi
}

_forge_issue_comment_github() {
  local issue_number="$1"
  local repo="$2"
  local body="$3"

  local cmd="gh issue comment $issue_number --body \"$body\""

  if [[ -n "$repo" ]]; then
    cmd="$cmd --repo $repo"
  fi

  eval "$cmd"
}

_forge_issue_comment_gitea() {
  local issue_number="$1"
  local repo="$2"
  local body="$3"

  # tea comment 的語法是: tea comment <issue> <body>
  local cmd="tea comment $issue_number \"$body\""

  if [[ -n "$repo" ]]; then
    cmd="$cmd --repo $repo"
  fi

  eval "$cmd"
}

# 如果直接執行此腳本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  forge_issue_comment "$@"
fi
