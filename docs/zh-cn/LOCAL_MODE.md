# CCPM 本地模式

CCPM 可以在本地模式下完美运作，无需任何 Gitea 整合。所有管理都透过本地 markdown 档案完成。

## 仅本地工作流程

### 1. 建立需求 (PRD)
```bash
/pm:prd-new user-authentication
```
- 建立：`.claude/prds/user-authentication.md`
- 输出：包含需求和使用者故事的完整 PRD

### 2. 转换为技术计划 (Epic)
```bash
/pm:prd-parse user-authentication
```
- 建立：`.claude/epics/user-authentication/epic.md`
- 输出：技术实施计划

### 3. 分解为任务
```bash
/pm:epic-decompose user-authentication
```
- 建立：`.claude/epics/user-authentication/001.md`、`002.md` 等
- 输出：包含验收标准的个别任务档案

### 4. 查看您的工作
```bash
/pm:epic-show user-authentication    # 查看 epic 和所有任务
/pm:status                           # 项目仪表板
/pm:prd-list                         # 列出所有 PRD
```

### 5. 处理任务
```bash
# 查看特定任务详细信息
cat .claude/epics/user-authentication/001.md

# 手动更新任务状态
vim .claude/epics/user-authentication/001.md
```

## 本地建立的内容

```text
.claude/
├── prds/
│   └── user-authentication.md      # 需求文件
├── epics/
│   └── user-authentication/
│       ├── epic.md                 # 技术计划
│       ├── 001.md                  # 任务：数据库架构
│       ├── 002.md                  # 任务：API 端点
│       └── 003.md                  # 任务：UI 元件
└── context/
    └── README.md                   # 项目上下文
```

## 可在本地运作的命令

### ✅ 完全本地命令
- `/pm:prd-new <name>` - 建立需求
- `/pm:prd-parse <name>` - 产生技术计划
- `/pm:epic-decompose <name>` - 分解为任务
- `/pm:epic-show <name>` - 查看 epic 和任务
- `/pm:status` - 项目仪表板
- `/pm:prd-list` - 列出 PRD
- `/pm:search <term>` - 搜寻内容
- `/pm:validate` - 检查档案完整性

### 🚫 仅 Gitea 命令（跳过这些）
- `/pm:epic-sync <name>` - 推送到 Gitea Issues
- `/pm:issue-sync <id>` - 更新 Gitea Issue
- `/pm:issue-start <id>` - 需要 Gitea Issue ID
- `/pm:epic-oneshot <name>` - 包含 Gitea 同步

## 本地模式的优势

- **✅ 无外部依赖** - 无需 Gitea 帐号/网络即可运作
- **✅ 完全隐私** - 所有数据保持在本地
- **✅ 版本控制友好** - 所有档案都是 markdown
- **✅ 团队协作** - 透过 git 共享 `.claude/` 目录
- **✅ 可自定义** - 自由编辑范本和工作流程
- **✅ 快速** - 无 API 呼叫或网络延迟

## 手动任务管理

任务储存为带有前置内容的 markdown 档案：

```markdown
---
name: 实作使用者登入 API
status: open          # open, in-progress, completed
created: 2024-01-15T10:30:00Z
updated: 2024-01-15T10:30:00Z
parallel: true
depends_on: [001]
---

# 任务：实作使用者登入 API

## 描述
建立 POST /api/auth/login 端点...

## 验收标准
- [ ] 端点接受电子邮件/密码
- [ ] 成功时返回 JWT 令牌
- [ ] 根据数据库验证凭证
```

在您工作时手动更新 `status` 栏位：
- `open` → `in-progress` → `completed`

就是这样！您拥有一个完全离线运作的完整项目管理系统。
