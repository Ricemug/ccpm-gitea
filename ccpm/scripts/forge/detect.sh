#!/usr/bin/env bash
# forge/detect.sh - 偵測當前 repository 使用的 Git Forge 平台
#
# 使用方式:
#   source forge/detect.sh
#   FORGE_TYPE=$(detect_forge)
#
# 回傳值:
#   "github"  - GitHub
#   "gitea"   - Gitea
#   "unknown" - 無法識別

detect_forge() {
  # 取得 git remote URL
  local remote_url
  remote_url=$(git remote get-url origin 2>/dev/null || echo "")

  if [[ -z "$remote_url" ]]; then
    echo "github"  # 預設 GitHub
    return 0
  fi

  # 方法 1: 檢查是否為 GitHub
  if [[ "$remote_url" =~ github\.com ]]; then
    echo "github"
    return 0
  fi

  # 方法 2: URL 包含 gitea 關鍵字
  if [[ "$remote_url" =~ gitea ]]; then
    echo "gitea"
    return 0
  fi

  # 方法 3: 檢查常見的 Gitea 端口 (啟發式)
  # Gitea 預設: 3000, 也常見: 53000, 8080
  if [[ "$remote_url" =~ :3000/|:53000/|:8080/ ]]; then
    echo "gitea"
    return 0
  fi

  # 方法 4: 檢查可用的 CLI 工具
  # 如果有 gh 能連線，可能是 GitHub
  if command -v gh &>/dev/null; then
    if gh repo view &>/dev/null 2>&1; then
      echo "github"
      return 0
    fi
  fi

  # 如果有 tea 能連線，可能是 Gitea
  if command -v tea &>/dev/null; then
    if tea issues list --limit 1 &>/dev/null 2>&1; then
      echo "gitea"
      return 0
    fi
  fi

  # 預設返回 GitHub (最保險的選擇)
  # 使用者可以在 init 時手動選擇
  echo "github"
  return 0
}

# 如果直接執行此腳本，輸出結果
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  detect_forge
fi
