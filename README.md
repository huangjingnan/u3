# weapp-env-setup

[![Sync Skills](https://github.com/<owner>/<repo>/actions/workflows/sync-skills.yml/badge.svg)](https://github.com/<owner>/<repo>/actions/workflows/sync-skills.yml)

> 一键装好"用 AI 做微信小程序"所需的全部开发环境。
>
> 本仓库提供 **3 个独立的 Agent Skill**，可单独使用，也可串联：
>
> | Skill | 职责 | 一句话 |
> |---|---|---|
> | `weapp-env-setup` | 环境检测与安装 | 装好 Node / pnpm / Git / Cursor / 微信开发者工具，并在仓库根创建 `./my-app/`（unibest 工程） |
> | `weapp-frontend-design` | 产品设计（需求澄清 → 方案确认） | 把想法拆成"## 核心功能"清单，不写代码 |
> | `weapp-dev-workflow` | 按内部约束开发 | 在 `./my-app/` 下写代码、Mock、自测、安全区、机型覆盖 |

## 这是什么

本仓库是**微信小程序 AI 教学项目**的工程模板。核心交付物是 **3 个 Agent Skills**：

- **`weapp-env-setup`**：让学员在 5 分钟内把 Node.js、pnpm、Git、Cursor、微信开发者工具、unibest 脚手架全部装好。
- **`weapp-frontend-design`**：把学员的产品想法拆成清晰的"## 核心功能"清单，学员确认后交接给 `weapp-dev-workflow`。
- **`weapp-dev-workflow`**：按学员需求（或已确认的 PRD）在 Mock 数据、安全区适配、自测、机型覆盖等约束下完成开发与交付。

三个 Skill **正交独立**，可单独使用，也可按 `设计 → 开发` 串联使用。

适合：
- 教学场景：学员跟着 AI 装环境、做需求、开发，老师只负责答疑
- 个人项目：拿到任何新电脑，5 分钟恢复开发能力
- 团队 onboarding：新成员 5 分钟跑通第一个小程序

## 怎么用

### Step 1 · 装环境

克隆本仓库后，在 Cursor / Claude Code / Codex 中说：

> 用 weapp-env-setup 帮我装环境

AI 会自动：
- ✅ 自动装 Node、pnpm、Git
- 📋 输出 Cursor 和微信开发者工具的安装指引（必须你手动，因为是 GUI 应用）
- ✅ 自动在本仓库根目录创建 `./my-app/`（unibest 工程）、跑 `pnpm dev:h5` 验证

### Step 2 · 设计产品（可选）

> 这一步是**可选**的——学员可以直接说"开发一个【xxx】小程序"跳过设计。

在 Cursor / Claude Code / Codex 中说：

> 用 weapp-frontend-design 帮我设计一个【xxx】小程序
>
> 或
>
> 我想做一个【xxx】小程序，先帮我设计一下

AI 会：
- 1~3 轮澄清需求
- 输出"## 核心功能"清单 + Mock 数据约定 + 不做的事
- 写入 `docs/prd/<feature>.md`
- 等学员**确认**后才交接给 `weapp-dev-workflow`

### Step 3 · 开发

在 Cursor / Claude Code / Codex 中说：

> 开发一个【xxx】微信小程序
>
> 或（如果已有 PRD）
>
> 按 docs/prd/<feature>.md 实现

AI 会按 `weapp-dev-workflow` 的内部约束（Mock 数据 / 状态栏动态高度 / 安全区 / 机型覆盖自测 / 主流程跑通）完成开发。代码全部写在 `./my-app/` 下面。

### 方案 B：手动装

如果身边没有 AI 工具，按 [`docs/manual-install-guide.md`](docs/manual-install-guide.md) 一步步手动装完。

## 目录结构

```
.
├── AGENTS.md                              # 所有 AI 工具的统一入口
├── README.md                              # 本文件
├── .gitignore                             # my-app/ 不进 git（学员克隆后由 weapp-env-setup 重建）
├── my-app/                                # ⭐ unibest 实际工程（不进 git）
│   └── .gitkeep                           # 占位文件，让目录在 git 里可见
├── docs/
│   ├── manual-install-guide.md            # 纯文档 fallback
│   └── prd/                               # weapp-frontend-design 产出的产品方案（进 git）
├── .cursor/skills/
│   ├── weapp-env-setup/                   # Cursor 读取：环境一键安装（默认创建 ./my-app/）
│   ├── weapp-frontend-design/             # Cursor 读取：产品设计（可选）
│   └── weapp-dev-workflow/                # Cursor 读取：按内部约束开发（读 ./my-app/.agents/）
├── .claude/skills/                        # Claude Code 读取（三处内容完全相同）
│   ├── weapp-env-setup/
│   ├── weapp-frontend-design/
│   └── weapp-dev-workflow/
├── .codex/skills/                         # Codex / 其他 Agent Skills Spec 工具读取
│   ├── weapp-env-setup/
│   ├── weapp-frontend-design/
│   └── weapp-dev-workflow/
├── .github/
│   └── copilot-instructions.md            # GitHub Copilot 引导
└── scripts/
    └── sync-skills.sh                     # 同步脚本（修改 SKILL.md 后跑这个）
```

### 关于 `my-app/` 的分层约定

- **`./my-app/`**：unibest 脚手架实际工程代码，由 `weapp-env-setup` Step 6 自动生成。
- **`./docs/prd/`**：`weapp-frontend-design` 产出的产品方案文档（PRD），是「真文档」，进 git。
- **模板层**：`AGENTS.md` / `README.md` / `.cursor/` / `.claude/` / `.codex/` / `.github/` / `scripts/` —— 教学项目的「模板」，进 git。

> **分层原则**：PRD（`docs/prd/`）和代码（`my-app/`）同仓库但分层明确。改代码 → 不进 git。改 PRD → 进 git。改 Skill → 三处同步。

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
# 1. 只改 .cursor/skills/<任意 skill>/SKILL.md（唯一源）
# 2. 同步到其他工具目录
bash scripts/sync-skills.sh

# 3. 提交
git add . && git commit -m "feat: 升级 skill"
```
