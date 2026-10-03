# AGENTS.md

> 任何 AI Agent 工具（Cursor / Claude Code / Codex / Continue / Cline 等）首次进入此仓库时，请**先读本文件**。
>
> 本仓库提供 **3 个独立的 Agent Skill**：
> - `weapp-env-setup`——环境一键安装（Node / pnpm / Git / Cursor / 微信开发者工具 / unibest）
> - `weapp-frontend-design`——产品设计（需求澄清 → "## 核心功能"清单 → 学员确认 → 交接给 `weapp-dev-workflow`）
> - `weapp-dev-workflow`——按内部约束开发（Mock / 自测 / 安全区 / 机型覆盖 / 主流程跑通）
>
> 三个 Skill **正交独立**，可单独使用，也可按 `设计 → 开发` 串联。

## 这个仓库是什么

微信小程序 + AI 教学项目的工程模板。**核心交付物是 3 个 Agent Skills**——让学员在 5 分钟内把环境装好、把想法拆成方案、在标准约束下完成开发与交付。

## 如何识别 Skill

本仓库的 Skills 位于以下三个位置，**任选其一**读即可，内容完全相同：

| Agent 工具 | 读取路径 |
|-----------|---------|
| Cursor（任意版本） | `.cursor/skills/<skill-name>/SKILL.md` |
| Claude Code | `.claude/skills/<skill-name>/SKILL.md` |
| Codex / 其他 Agent Skills Spec 工具 | `.codex/skills/<skill-name>/SKILL.md` |

`<skill-name>` 可为 `weapp-env-setup` / `weapp-frontend-design` / `weapp-dev-workflow`。

如果三个目录都没有，按 `docs/manual-install-guide.md` 的纯文本指引操作（手动模式）。

## 如何调用

任何 Agent 工具的用户都可以这样召唤 Skill：

### 装环境

> 用 weapp-env-setup 帮我装环境

### 设计产品（可选，可跳过）

> 用 weapp-frontend-design 帮我设计一个【xxx】小程序
>
> 或
>
> 我想做一个【xxx】小程序，先帮我设计一下

### 开发

> 开发一个【xxx】微信小程序
>
> 或（如果已有 PRD）
>
> 按 docs/prd/<feature>.md 实现

Agent 收到后：

1. **先读对应路径的 SKILL.md**（Cursor 读 `.cursor/skills/...`，Claude Code 读 `.claude/skills/...`）
2. **严格按 SKILL.md 的流程与约束执行**
3. **遇到 GUI 应用（Cursor / 微信开发者工具）按"必须学员手动"规则处理**
4. **遇到错误按 SKILL.md 的"错误处理原则"分类处理**

### Skill 之间的接力

- `weapp-frontend-design` 收到学员的「确认」后，会**主动交接**给 `weapp-dev-workflow` 进入开发。
- `weapp-dev-workflow` 启动时若发现 `docs/prd/*.md` 存在，**优先**按 PRD 实现；不存在则按学员本轮直接描述的功能开发。
- 三个 Skill 均可独立调用，不存在"必须先经过谁"的硬依赖。

## Skill 同步约束

`.cursor/`、`.claude/`、`.codex/` 三处的 SKILL.md **必须保持一致**。如果只改了其中一处，本文件视为已损坏，请提醒仓库维护者运行 `scripts/sync-skills.sh` 同步。

## 修改 Skill 的工作流

```bash
# 1. 只改 .cursor/skills/<任意 skill>/SKILL.md（它是 source of truth）
# 2. 运行同步脚本
bash scripts/sync-skills.sh
# 3. 提交
git add . && git commit -m "chore: sync agent skills"
```

Windows 用户请用：

```powershell
# Windows 下软链不会生效，需要先复制再同步
Copy-Item .cursor/skills/weapp-env-setup/SKILL.md .claude/skills/weapp-env-setup/SKILL.md
Copy-Item .cursor/skills/weapp-env-setup/SKILL.md .codex/skills/weapp-env-setup/SKILL.md
```

## 不要做的事

- 🚫 不要在三个目录里各写一份不一样的 SKILL.md
- 🚫 不要把 SKILL.md 删掉任何一段（其他 Agent 工具可能依赖其中某段）
- 🚫 不要在 SKILL.md 里写"只适用于 Cursor"这种排他性语句
- 🚫 不要把 `weapp-frontend-design` 写成强制前置门（它是可选的"先想清楚再动手"工具）