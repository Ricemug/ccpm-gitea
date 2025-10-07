#!/usr/bin/env bash
# forge/config.sh - Git Forge 抽象層配置與工具函數
#
# 使用方式:
#   source forge/config.sh
#   forge_init
#   forge_issue_list

# 取得當前腳本目錄
FORGE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 初始化 forge 環境
forge_init() {
  # 載入 detect.sh
  source "${FORGE_SCRIPT_DIR}/detect.sh"

  # 偵測 forge 類型
  FORGE_TYPE=$(detect_forge)
  export FORGE_TYPE

  if [[ "$FORGE_TYPE" == "unknown" ]]; then
    echo "Error: Cannot detect Git Forge type (GitHub or Gitea)" >&2
    return 1
  fi

  # 驗證對應的 CLI 工具是否安裝
  if [[ "$FORGE_TYPE" == "github" ]]; then
    if ! command -v gh &>/dev/null; then
      echo "Error: GitHub CLI (gh) is not installed" >&2
      return 1
    fi
  elif [[ "$FORGE_TYPE" == "gitea" ]]; then
    if ! command -v tea &>/dev/null; then
      echo "Error: Gitea CLI (tea) is not installed" >&2
      return 1
    fi
  fi

  return 0
}

# 解析 labels 字串為陣列
# GitHub: JSON array ["label1", "label2"]
# Gitea: Space-separated string "label1 label2"
forge_parse_labels() {
  local labels_input="$1"

  if [[ -z "$labels_input" ]]; then
    return 0
  fi

  if [[ "$FORGE_TYPE" == "github" ]]; then
    # GitHub 回傳 JSON array
    echo "$labels_input"
  else
    # Gitea 回傳空格分隔的字串
    # 轉換為陣列格式 (每行一個)
    echo "$labels_input" | tr ' ' '\n' | grep -v '^$'
  fi
}

# 將 labels 陣列轉換為 CLI 參數格式
# 輸入: labels 陣列 (每行一個)
# 輸出: GitHub: "label1,label2" / Gitea: "label1,label2"
forge_format_labels() {
  local labels=("$@")

  if [[ ${#labels[@]} -eq 0 ]]; then
    return 0
  fi

  # 兩個平台都使用逗號分隔
  local IFS=','
  echo "${labels[*]}"
}

# 處理 YAML 輸出，提取特定欄位
# 參數: $1 = yaml_content, $2 = field_name
forge_yaml_get_field() {
  local yaml_content="$1"
  local field_name="$2"

  # 簡單的 YAML 解析 (假設格式為 "field: 'value'" 或 "field: value")
  echo "$yaml_content" | grep "^    ${field_name}:" | sed -E "s/^    ${field_name}: '?([^']*)'?$/\1/"
}

# 錯誤處理
forge_error() {
  echo "Error: $*" >&2
  return 1
}

# 如果直接執行此腳本，執行初始化測試
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  forge_init
  echo "Forge type detected: $FORGE_TYPE"
fi
