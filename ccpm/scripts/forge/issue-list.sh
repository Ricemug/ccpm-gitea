#!/usr/bin/env bash
# forge/issue-list.sh - 統一的 issue 列表查詢介面
#
# 使用方式:
#   forge_issue_list [options]
#
# 選項:
#   --repo REPO       指定 repository (選填)
#   --state STATE     過濾狀態 (open|closed|all，預設: open)
#   --labels LABELS   過濾 labels (逗號分隔)
#   --format FORMAT   輸出格式 (json|yaml，預設: yaml)
#
# 回傳: YAML 或 JSON 格式的 issue 列表

# 載入配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

forge_issue_list() {
  # 初始化
  forge_init || return 1

  # 參數解析
  local repo=""
  local state="open"
  local labels=""
  local format="yaml"

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
      --format)
        format="$2"
        shift 2
        ;;
      *)
        forge_error "Unknown option: $1"
        return 1
        ;;
    esac
  done

  # 根據 forge 類型執行對應指令
  if [[ "$FORGE_TYPE" == "github" ]]; then
    _forge_issue_list_github "$repo" "$state" "$labels" "$format"
  elif [[ "$FORGE_TYPE" == "gitea" ]]; then
    _forge_issue_list_gitea "$repo" "$state" "$labels" "$format"
  else
    forge_error "Unsupported forge type: $FORGE_TYPE"
    return 1
  fi
}

_forge_issue_list_github() {
  local repo="$1"
  local state="$2"
  local labels="$3"
  local format="$4"

  local cmd="gh issue list --state $state"

  if [[ -n "$repo" ]]; then
    cmd="$cmd --repo $repo"
  fi

  if [[ -n "$labels" ]]; then
    cmd="$cmd --label $labels"
  fi

  # GitHub CLI 輸出 JSON
  cmd="$cmd --json number,title,state,labels,milestone,body,url,createdAt,updatedAt,author,comments"

  if [[ "$format" == "yaml" ]]; then
    # 轉換 JSON 到 YAML (使用 python 或其他工具)
    eval "$cmd" | python3 -c 'import sys, yaml, json; print(yaml.dump(json.load(sys.stdin), default_flow_style=False))' 2>/dev/null || eval "$cmd"
  else
    eval "$cmd"
  fi
}

_forge_issue_list_gitea() {
  local repo="$1"
  local state="$2"
  local labels="$3"
  local format="$4"

  local cmd="tea issues list --state $state --output yaml"

  if [[ -n "$repo" ]]; then
    cmd="$cmd --repo $repo"
  fi

  if [[ -n "$labels" ]]; then
    # Gitea 使用 --labels (複數)
    cmd="$cmd --labels $labels"
  fi

  # 指定輸出欄位
  cmd="$cmd --fields index,title,state,labels,milestone,body,url,created,updated,author,comments"

  if [[ "$format" == "json" ]]; then
    # 轉換 YAML 到 JSON (使用 python 或其他工具)
    eval "$cmd" | python3 -c 'import sys, yaml, json; print(json.dumps(yaml.safe_load(sys.stdin)))' 2>/dev/null || eval "$cmd"
  else
    eval "$cmd"
  fi
}

# 如果直接執行此腳本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  forge_issue_list "$@"
fi
