---
name: weapp-env-setup
description: Auto-install the full environment for building WeChat Mini Programs (微信小程序) with AI assistance. Detects the OS, installs Node.js via nvm, pnpm, Git, helps install Cursor + WeChat DevTools, **and configures wechat-devtools MCP server so the Agent can directly control the WeChat DevTools UI for screenshot/click testing**, then scaffolds a unibest project. Use when the user asks to install the WeChat Mini Program development environment, set up the unibest scaffold, or start the "用 AI 做你的第一个小程序" tutorial.
---

# 微信小程序 AI 开发环境一键配置（自动版）

按顺序装 6 样东西。Agent 会自动检测 OS 并执行能跑的命令；GUI 应用（Cursor、微信开发者工具）会给出带链接的精确指引。

**调用方式**：在 Cursor 中对 Agent 说
> "用 weapp-env-setup 帮我装环境"

**自动化范围**：Agent 会自动执行所有命令行操作（Node、pnpm、Git、脚手架）。**Cursor 编辑器和微信开发者工具是 GUI 应用，必须由学员手动安装并登录**，Agent 只输出链接和步骤，不尝试自动安装（`brew install --cask` 也不行）。

---

## 0. 启动前确认（必须先做）

Agent 在开始前必须用 `AskQuestion` 向学员确认：

1. **当前操作系统**：让学员明确说出 "Mac / Windows / Linux（Ubuntu/Debian）"，而不是自己猜
2. **是否允许全局安装**：说明将安装 nvm、pnpm，可能修改 shell 配置文件（`~/.zshrc` / `~/.bashrc`）
3. **当前目录**：在哪里建项目。**默认是在当前仓库根目录下创建 `./my-app/`**（即 unibest 默认项目名 `my-app`，与本仓库同层）

得到全部答复后才进入第 1 步。

---

## 1. 进度跟踪（Agent 必做）

开始前先把下面这份 checklist 打印出来并在每一步完成后打勾；不要试图在脑中记忆进度。

```markdown
环境安装进度：
- [ ] 1. Node.js v22.x（通过 nvm）         ← 🤖 Agent 自动
- [ ] 2. pnpm v10.x                         ← 🤖 Agent 自动
- [ ] 3. Git                                ← 🤖 Agent 自动（Windows 除外）
- [ ] 4. Cursor 编辑器 + 邮箱登录           ← 👤 学员手动
- [ ] 5. 微信开发者工具 + 微信扫码登录      ← 👤 学员手动
- [ ] 5c. Cursor 配置 wechat-devtools MCP    ← 👤 学员手动 ⭐
- [ ] 6. unibest 项目脚手架                 ← 🤖 Agent 自动
- [ ] 7. 验收
```

---

## 2. OS 检测（Agent 必做）

执行对应命令，把结果记为 `$OST`：

```bash
# Mac / Linux
uname -s
# 输出 "Darwin" → macOS，"Linux" → Linux
```

```powershell
# Windows (PowerShell)
$env:OS
# 输出 "Windows_NT" → Windows
```

后续步骤根据 `$OST` 自动选分支，不要让用户每次选择。

---

## 3. 安装步骤（按顺序执行）

### Step 1 / Node.js —— 通过 nvm 安装

Agent 必须自己判断 nvm 是否已存在，已存在则跳过安装。

**macOS / Linux：**
```bash
# 检查 nvm
if ! command -v nvm &> /dev/null; then
  echo "nvm 未安装，开始安装..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# 安装并切换到 Node 22
nvm install 22
nvm alias default 22
nvm use 22

# 验证
node -v   # 期望 v22.x.x
```

> 若新装的 nvm 在当前 shell 里不生效（`nvm: command not found`），Agent 必须用 `source ~/.nvm/nvm.sh` 再跑一遍，或提示学员"重开终端再让 Cursor 重试"。

**Windows（指引学员手动，Agent 无法装 .exe）：**
- 卸载已装在系统里的 Node.js（控制面板 → 程序卸载）
- 下载 `nvm-setup.exe`：https://github.com/coreybutler/nvm-windows/releases
- 安装后**重开 PowerShell**，让 Cursor 重新跑验证命令

**无论哪个系统，Agent 都必须验证 `node -v` ≥ v20 才进入 Step 2**。

---

### Step 2 / pnpm v10.x

```bash
# Mac / Linux / Windows (任何有 npm 的环境)
npm install -g pnpm@10
pnpm -v   # 期望 10.x.x
```

如果 `npm install -g` 报权限错误（Mac EACCES）：

```bash
# 让 nvm 接管 npm 目录（这是装完 nvm 后应自动解决的）
# 如仍报错，回退到：
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
export PATH=~/.npm-global/bin:$PATH
# 然后再 npm install -g pnpm@10
```

**验证通过后才进入 Step 3**。

---

### Step 3 / Git

按 `$OST` 自动选：

**macOS：**
```bash
if ! command -v git &> /dev/null; then
  echo "Git 未安装，弹出系统提示请学员点「安装」..."
  git --version   # 这一句会触发安装弹窗
fi
git --version
```

> macOS 第一次跑 `git` 会弹"安装命令行开发者工具"窗口，**这是要学员点的**。Agent 应明确告诉学员"现在请你点弹窗里的『安装』按钮，等它跑完告诉我"。

**Linux (Debian/Ubuntu)：**
```bash
sudo apt update && sudo apt install -y git
git --version
```

**Windows：**
指引学员下载安装：https://git-scm.com/download/win （一路默认即可）

**所有系统都验证 `git --version` 有输出再进入 Step 4**。

---

### Step 4 / Cursor 编辑器（必须学员手动）

> 🚫 **硬性约束**：Agent **禁止**通过任何方式（`brew install --cask cursor`、`curl | sh` 下载 AppImage、`npm install -g cursor` 等）尝试自动安装 Cursor。GUI 应用必须学员本人手动下载、安装、注册并登录。

**指引文案（Agent 原样输出给学员，不要补充"我可以帮你装"的暗示）：**

```
请手动安装 Cursor（约 1 分钟）：
1. 打开浏览器访问 https://cursor.com
2. 点 "Download for Mac" / "Download for Windows"（按你系统）
3. 双击下载好的安装包：
   - Mac：把 Cursor 拖到 Applications 文件夹
   - Windows：双击 .exe 一路下一步
4. 打开 Cursor，用邮箱注册并登录（免费版即可）
5. 完成后请确认已安装
```

---

### Step 5 / 微信开发者工具（必须学员手动）

> 🚫 **硬性约束**：Agent **禁止**通过任何方式（`brew install --cask wechat-webdevtools`、下载 .exe 静默安装、`npm` 包等）尝试自动安装微信开发者工具。必须学员本人手动下载、双击安装、且**微信扫码登录**这一环必须本人在场。

**指引文案（Agent 原样输出给学员）：**

```
请手动安装微信开发者工具（约 1 分钟）：
1. 打开 https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html
2. 下载「稳定版 Stable Build」（别下预发布版）
3. 安装：
   - Mac：双击 .dmg，把应用拖到 Applications
   - Windows：双击 .exe 一路下一步
4. 首次打开会要求扫码，用你的微信扫一下登录
5. 完成后请确认已安装
```

---

### Step 5c / 配置 wechat-devtools MCP server（必须学员手动）⭐

> 🚫 **硬性约束**：Agent **禁止**自动修改 Cursor 的 `mcp.json`，必须由学员本人手动写入。这一步让 Agent 能**直接控制**微信开发者工具（截图、点击、读取页面数据），是自动化 UI 测试的关键。

**为什么需要它**：让 Cursor 的 Agent 像人一样操作开发者工具 —— 自动打开小程序、自动截图、自动点击按钮、自动读取页面 DOM。**没有它，Agent 无法做 UI 自动化**（即便安装了 `miniprogram-automator` SDK 也无法远程调用）。

**指引文案（Agent 原样输出给学员）：**

```
请在 Cursor 里配置 wechat-devtools MCP（约 1 分钟）：

1. 打开 Cursor 顶部菜单
3. 点击「Settings」 → 「MCP」
4. 右上角「Add new global MCP server」，会打开 `~/.cursor/mcp.json`
5. 在 mcpServers 里加入下面这段（注意 JSON 逗号）：

{
  "mcpServers": {
    "wechat-devtools": {
      "command": "wechatide",
      "args": [
        "mcp"
      ]
    }
  }
}

6. 保存后回到 MCP 设置页，应该能看到「wechat-devtools」显示 1 个 tool 加载成功
7. 如果没看到，点右侧刷新按钮；还不行就重启 Cursor

⚠️ 如果你的 Mac 装微信开发者工具时改了路径（比如装到 /Applications/微信开发者工具.app），
command 可能要改成绝对路径的 cli，比如：
"command": "/Applications/微信web开发者工具.app/Contents/MacOS/cli",
"args": ["-p", "mcp"]

验证：保存 → 重启 Cursor → 在对话里问 Agent "列出所有 MCP 工具"，
看到 wechat-devtools 相关的工具（preview、close、自动化测试工具等）就说明成功了
```

> Agent 验证方法：在对话里问 Agent "用 wechat-devtools MCP 列出当前可用的工具列表"，Agent 应该能看到该 MCP 的工具。

---

### Step 6 / 创建 unibest 项目

**项目位置约定**：脚手架放在**当前仓库根目录下**的 `./my-app/`（即与 `AGENTS.md` / `.gitignore` / `.cursor/` 同层）。
- ✅ 好处：PRD（`docs/prd/*.md`）与代码（`my-app/`）同仓库，路径关系清晰
- ✅ 好处：`my-app/` 已在 `.gitignore` 中，不进 git（学员克隆后重跑本 Skill 自动重建）
- ❌ **不要**放到 `~/Desktop/apps/` 等仓库外位置，会造成 PRD 和代码分离

**Agent 必做**：先 `AskQuestion` 确认两个参数：
- **项目目录**：默认 `./my-app`（即当前目录的子目录，相对路径）
- **项目名**：默认 `my-app`（与目录名一致）

得到答复后执行：

```bash
# Mac / Linux —— 假设当前是仓库根目录
mkdir -p my-app
npm create unibest my-app --ui wot-ui --platform h5,mp-weixin --login false --i18n false --lime-echart --ucharts
cd my-app
pnpm install
```

```powershell
# Windows (PowerShell) —— 假设当前是仓库根目录
mkdir my-app
cd my-app
npm create unibest my-app --ui wot-ui --platform h5,mp-weixin --login false --i18n false --lime-echart --ucharts
pnpm install
```

> ⚠️ 如果 `npm create unibest` 卡住或报网络错误，Agent 必须先尝试换源：
> ```bash
> npm config set registry https://registry.npmmirror.com
> ```
> 换源后重试。仍失败则收集完整错误日志给学员。

**Agent 必须实际启动一次预览验证**：

```bash
# Mac / Linux
pnpm dev:h5 &
DEV_PID=$!
sleep 15
# 检查端口是否在监听
curl -sI http://localhost:9000 | head -1   # 或 unibest 默认的端口
kill $DEV_PID 2>/dev/null
```

> 不同 unibest 版本默认端口可能不同（9000 / 5173 / 8080 等），Agent 必须先看 `pnpm dev:h5` 启动后的实际输出，拿到端口再 curl。

启动成功标志：
- 终端冒出 `http://localhost:xxxx`
- `curl` 返回 `HTTP/1.1 200 OK` 或类似
- 没有红字 error

**启动验证通过后才进入 Step 7**。

---

### Step 7 / 验收

Agent 跑一遍验收清单并把结果汇报给学员：

```bash
echo "=== 环境验收 ==="
echo "[Node]    $(node -v)"
echo "[npm]     $(npm -v)"
echo "[pnpm]    $(pnpm -v)"
echo "[git]     $(git --version)"
echo "[OS]      $(uname -s 2>/dev/null || echo Windows)"
```

**指引学员逐项确认**：
- [ ] Node 是 v22.x.x
- [ ] pnpm 是 10.x.x
- [ ] Git 有版本号
- [ ] Cursor 已登录（学员确认）
- [ ] 微信开发者工具已扫码（学员确认）
- [ ] wechat-devtools MCP 已配置并加载 tool（学员确认）
- [ ] `pnpm dev:h5` 启动后浏览器能看到带底部导航的空白应用骨架

全部 ✅ 后输出祝贺语：

```
🎉 你的微信小程序开发环境已全部就绪！

接下来你可以：
- 重新运行 pnpm dev:h5 启动网页预览
- 在 Cursor 里打开 my-app 项目，让 AI 帮你写小程序
- 让 Agent 直接调用 wechat-devtools MCP 操作微信开发者工具（截图、点击、自动化测试）
- 微信开发者工具导入 my-app/dist/dev/mp-weixin 即可看小程序效果
```

---

## 4. 错误处理原则

Agent 在执行任何命令时如果失败，按以下顺序处理：

1. **看错误日志的前 3 行** — 90% 的问题在这一行
2. **重试一次** — 临时网络问题经常重试就好
3. **换 npm 源** — `npm config set registry https://registry.npmmirror.com`
4. **网络相关 → 指引学员检查代理 / VPN**
5. **权限相关 → 提示 sudo / 管理员**
6. **GUI 相关 → 明确告诉学员这一步必须手动**
7. **真的搞不定 → 输出完整错误日志 + 已尝试的方案 + 让学员决定下一步**

**禁止**：Agent 不能用 `rm -rf ~/*` 之类危险命令清理"解决问题"，也不能强行重装系统级工具而不告知。

---

## 5. 不用做的事

- 🚫 **不要用任何方式（`brew install --cask`、下载 .dmg/.exe 静默安装、`npm install -g`、AppImage 等）尝试自动安装 Cursor 或微信开发者工具**——这两步必须学员手动完成
- ❌ 不要在主流程里 sudo 装系统包（除非 Step 3 Linux 安装 Git 那一处明确允许）
- ❌ 不要修改学员的 ~/.zshrc / ~/.bashrc / ~/.profile 之外的其他 dotfile
- ❌ 不要跳过验证（每一步验证通过才进下一步）
- ❌ 不要在 Step 4/5 试图自动装 GUI 应用（包括 `brew install --cask`、下载 .dmg/.exe 静默安装等任何形式）
- ❌ 不要在 Step 6 后忘记 kill dev server（避免端口占用）