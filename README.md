# weapp-env-setup

[![Sync Skills](https://github.com/<owner>/<repo>/actions/workflows/sync-skills.yml/badge.svg)](https://github.com/<owner>/<repo>/actions/workflows/sync-skills.yml)

> 一键装好"用 AI 做微信小程序"所需的全部开发环境。

## 这是什么

本仓库是**微信小程序 AI 教学项目**的工程模板。核心交付物是一个 Agent Skill —— **`weapp-env-setup`**，让学员在 5 分钟内把 Node.js、pnpm、Git、Cursor、微信开发者工具、unibest 脚手架全部装好。

适合：
- 教学场景：学员跟着 AI 装环境，老师只负责答疑
- 个人项目：拿到任何新电脑，5 分钟恢复开发能力
- 团队 onboarding：新成员 5 分钟跑通第一个小程序

## 怎么用

### 方案 A：让 AI 帮你装（推荐）

克隆本仓库后，在 Cursor / Claude Code / Codex 中说：

> 用 weapp-env-setup 帮我装环境

AI 会自动：
- ✅ 自动装 Node、pnpm、Git
- 📋 输出 Cursor 和微信开发者工具的安装指引（必须你手动，因为是 GUI 应用）
- ✅ 自动创建 unibest 项目、跑 `pnpm dev:h5` 验证

### 方案 B：手动装

如果身边没有 AI 工具，按 [`docs/manual-install-guide.md`](docs/manual-install-guide.md) 一步步手动装完。

## 目录结构

```
.
├── AGENTS.md                              # 所有 AI 工具的统一入口
├── README.md                              # 本文件
├── .cursor/skills/weapp-env-setup/        # Cursor 读取
│   └── SKILL.md
├── .claude/skills/weapp-env-setup/        # Claude Code 读取
│   └── SKILL.md
├── .codex/skills/weapp-env-setup/         # Codex / 其他 Agent Skills Spec 工具读取
│   └── SKILL.md
├── .github/
│   └── copilot-instructions.md            # GitHub Copilot 引导
├── docs/
│   └── manual-install-guide.md            # 纯文档 fallback
└── scripts/
    └── sync-skills.sh                     # 同步脚本（修改 SKILL.md 后跑这个）
```

## 兼容性矩阵

| AI 工具 | 是否直接支持 | 说明 |
|---------|------------|------|
| Cursor (任意版本) | ✅ | 读 `.cursor/skills/.../SKILL.md` |
| Claude Code | ✅ | 读 `.claude/skills/.../SKILL.md` |
| Codex CLI / IDE 插件 | ✅ | 读 `.codex/skills/.../SKILL.md` |
| Continue (VSCode) | ✅ | 读 `.codex/skills/.../SKILL.md`（兼容） |
| Cline / Roo Code | ✅ | 读 `.codex/skills/.../SKILL.md`（兼容） |
| GitHub Copilot Coding Agent | ⚠️ 部分 | 读 `.github/copilot-instructions.md` 引导 |
| 其他 Agent Skills Spec 工具 | ✅ | 读 `.codex/skills/.../SKILL.md`（按官方 spec） |

> **CI 不自动 commit**：本仓库不启用任何自动修复/自动提交。`.github/workflows/sync-skills.yml` 只做**检测**，发现不一致会在 PR 报错，但**修复完全由维护者本地操作**（见下）。

## 维护流程

修改 Skill 的步骤：

```bash
# 1. 只改 .cursor/skills/weapp-env-setup/SKILL.md（唯一源）
# 2. 同步到其他工具目录
bash scripts/sync-skills.sh

# 3. 提交
git add . && git commit -m "feat: 升级 weapp-env-setup skill"
```
