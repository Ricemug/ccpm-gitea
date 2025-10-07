#!/usr/bin/env bash
# forge/label-create.sh - 統一的 label 建立介面
#
# 使用方式:
#   forge_label_create --name "label-name" --color "#ffffff" [options]
#
# 選項:
#   --repo REPO           指定 repository (選填)
#   --name NAME           Label 名稱 (必填)
#   --color COLOR         Label 顏色 (hex color，必填)
#   --description DESC    Label 說明 (選填)
#
# 回傳: 成功或失敗

# 載入配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

forge_label_create() {
  # 初始化
  forge_init || return 1

  # 參數解析
  local repo=""
  local name=""
  local color=""
  local description=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo)
        repo="$2"
        shift 2
        ;;
      --name)
        name="$2"
        shift 2
        ;;
      --color)
        color="$2"
        shift 2
        ;;
      --description)
        description="$2"
        shift 2
        ;;
      *)
        forge_error "Unknown option: $1"
        return 1
        ;;
    esac
  done

  # 驗證必填參數
  if [[ -z "$name" ]]; then
    forge_error "Label name is required (--name)"
    return 1
  fi

  if [[ -z "$color" ]]; then
    forge_error "Label color is required (--color)"
    return 1
  fi

  # 根據 forge 類型執行對應指令
  if [[ "$FORGE_TYPE" == "github" ]]; then
    _forge_label_create_github "$repo" "$name" "$color" "$description"
  elif [[ "$FORGE_TYPE" == "gitea" ]]; then
    _forge_label_create_gitea "$repo" "$name" "$color" "$description"
  else
    forge_error "Unsupported forge type: $FORGE_TYPE"
    return 1
  fi
}

_forge_label_create_github() {
  local repo="$1"
  local name="$2"
  local color="$3"
  local description="$4"

  # Build command as array to avoid eval
  local cmd=(gh label create "$name" --color "$color")

  if [[ -n "$repo" ]]; then
    cmd+=(--repo "$repo")
  fi

  if [[ -n "$description" ]]; then
    cmd+=(--description "$description")
  fi

  # Execute command safely without eval
  "${cmd[@]}"
}

_forge_label_create_gitea() {
  local repo="$1"
  local name="$2"
  local color="$3"
  local description="$4"

  # Build command as array to avoid eval
  local cmd=(tea labels create --name "$name" --color "$color")

  if [[ -n "$repo" ]]; then
    cmd+=(--repo "$repo")
  fi

  if [[ -n "$description" ]]; then
    cmd+=(--description "$description")
  fi

  # Execute command safely without eval
  "${cmd[@]}"
}

# 如果直接執行此腳本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  forge_label_create "$@"
fi
