# CCPM Gitea Fork 开发计划

**日期**: 2025-10-07
**目标**: 建立通用版本，同时支持 GitHub 和 Gitea

## 决策摘要

### 选择方案：选项 B - 建立通用版本 ✅

**理由**:
- Gitea 是 GitHub 的开源替代，使用者可能同时使用两者
- 可贡献回原项目，造福开源社群
- tea CLI 与 gh CLI 命令结构相似，转换成本低
- 技术上只需建立抽象层，复杂度可控

**预估工时**: 15-20 天

---

## 技术分析

### ✅ 有利因素

1. **tea CLI 功能完整**
   - issues: create, edit, close, reopen, list
   - pull requests: create, merge, close, checkout
   - labels, milestones, releases 完整支持
   - comment 功能可用

2. **架构兼容性高**
   - CCPM 核心是 markdown + shell scripts
   - 逻辑与 Git forge 平台无关
   - 工作流程设计通用

3. **命令映射清楚**
   ```bash
   GitHub CLI          →  Gitea tea CLI
   ──────────────────────────────────────
   gh issue create     →  tea issue create
   gh issue edit       →  tea issue edit
   gh issue comment    →  tea issue comment
   gh pr create        →  tea pull create
   gh auth login       →  tea login add
   ```

### ⚠️ 主要挑战

1. **gh-sub-issue 扩充功能缺失**
   - CCPM 依赖此功能建立 parent-child issue 关系
   - Gitea/tea **无对应功能**
   - **解决方案**: 使用 task list (`- [ ] #123`) 替代

2. **JSON 输出格式差异**
   - 需验证 tea CLI 的 `--output json` 格式
   - 可能需调整解析逻辑

3. **认证机制不同**
   - GitHub: OAuth/Token 自动化
   - Gitea: 需手动设定 server URL + token

4. **Repository 探测逻辑**
   - GitHub: `gh repo view --json nameWithOwner`
   - Gitea: tea 使用当前目录的 git config
   - 需重写 repository 侦测

---

## 开发阶段规划

### 阶段一：验证可行性 (1-2 天)
- [ ] 安装并测试 tea CLI 所有必要指令
- [ ] 建立 Gitea 测试 repository
- [ ] 验证 JSON 输出格式
- [ ] 测试认证流程

### 阶段二：建立抽象层 (3-5 天)

建立统一的 git forge 接口：

```bash
.claude/scripts/forge/
├── detect.sh         # 侦测 GitHub vs Gitea
├── init.sh           # 初始化对应的 CLI
├── issue-create.sh   # 统一的 issue 建立
├── issue-edit.sh     # 统一的 issue 编辑
├── issue-comment.sh  # 统一的 issue 评论
├── pr-create.sh      # 统一的 PR 建立
└── repo-info.sh      # 统一的 repo 信息
```

**设计原则**:
- 对外提供一致的接口
- 内部根据 forge 类型调用对应 CLI
- 错误处理统一化

### 阶段三：实作 Gitea 支持 (5-7 天)

#### 核心文件修改

| 文件 | 改动程度 | 说明 |
|------|---------|------|
| `scripts/pm/init.sh` | 大幅 | 支持 tea CLI 安装与设定 |
| `commands/pm/epic-sync.md` | 大幅 | 使用 forge 抽象层 |
| `rules/github-operations.md` | 重写 | 改为 `forge-operations.md` |
| `commands/pm/issue-*.md` | 中度 | 替换 CLI 调用 |
| `commands/pm/epic-*.md` | 中度 | 替换 CLI 调用 |

#### Sub-issue 替代方案实作
- epic issue 使用 task list 追踪 sub-tasks
- 自动更新 task list 状态
- 保持可视化进度追踪

### 阶段四：测试与文档 (2-3 天)
- [ ] 完整工作流程测试（GitHub + Gitea）
- [ ] 撰写 Gitea 设定文档
- [ ] 更新 README 说明双平台支持
- [ ] 建立范例与教学

---

## 需要修改的核心文件清单

### 高优先级（必须修改）
1. `ccpm/scripts/pm/init.sh` - 初始化流程
2. `ccpm/commands/pm/epic-sync.md` - Epic 同步
3. `ccpm/rules/github-operations.md` - 平台操作规则
4. `ccpm/commands/pm/issue-start.md` - Issue 启动
5. `ccpm/commands/pm/issue-sync.md` - Issue 同步

### 中优先级（需调整）
6. `ccpm/commands/pm/issue-edit.md`
7. `ccpm/commands/pm/issue-close.md`
8. `ccpm/commands/pm/epic-close.md`
9. 其他 pm commands (~15 个)

### 低优先级（可选）
10. 文档与范例更新

---

## 技术笔记

### tea CLI 重要指令

```bash
# 认证
tea login add --name myserver --url https://gitea.example.com --token abc123

# Issue 操作
tea issue create --title "Title" --body "Body" --labels "epic,task"
tea issue edit 123 --add-labels "in-progress"
tea issue close 123

# PR 操作
tea pull create --title "PR Title" --body "Description"
tea pull merge 123

# 查询
tea issue list --output json
tea repo show
```

### 抽象层设计范例

```bash
# .claude/scripts/forge/detect.sh
detect_forge() {
  remote_url=$(git remote get-url origin 2>/dev/null || echo "")

  if [[ "$remote_url" == *"github.com"* ]]; then
    echo "github"
  elif [[ "$remote_url" == *"gitea"* ]] || command -v tea &>/dev/null; then
    echo "gitea"
  else
    echo "unknown"
  fi
}
```

---

## 下一步行动

1. ✅ 记录对话内容（本文档）
2. 🔄 重命名项目目录
3. ⏳ 建立 Gitea 测试 repository
4. ⏳ 开始阶段一：验证 tea CLI 功能

---

## 参考资源

- CCPM 原项目: https://github.com/automazeio/ccpm
- Gitea tea CLI: https://gitea.com/gitea/tea
- Gitea CLI 文档: https://docs.gitea.com/administration/command-line
- tea CLI 命令参考: https://gitea.com/gitea/tea/src/branch/main/docs/CLI.md
