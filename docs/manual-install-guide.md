# 微信小程序开发环境手动安装指南

> 任何 AI 工具都不在身边？按这份指南一步步手动装完。
>
> 预计耗时：5-8 分钟（除下载大文件外）

## 1. 安装 Node.js（v22 LTS）

推荐用 **nvm** —— 可以装多版本、不污染系统、方便切版本。

### macOS / Linux

打开"终端"应用（聚焦搜索「终端」），粘贴：

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

nvm install 22
nvm alias default 22
nvm use 22

node -v   # 应输出 v22.x.x
```

### Windows

1. 卸载已装在系统里的 Node.js（如有）
2. 下载 `nvm-setup.exe`：https://github.com/coreybutler/nvm-windows/releases
3. 双击安装，一路下一步
4. **重开 PowerShell**，执行：

```powershell
nvm install 22
nvm use 22
node -v    # 应输出 v22.x.x
```

## 2. 安装 pnpm

```bash
npm install -g pnpm@10
pnpm -v    # 应输出 10.x.x
```

## 3. 安装 Git

- **macOS**：终端执行 `git --version`，按提示装"命令行开发者工具"
- **Windows**：https://git-scm.com/download/win 下载安装
- **Linux**：`sudo apt install -y git`

## 4. 安装 Cursor

- 下载：https://cursor.com
- 按提示装好、用邮箱注册登录（免费版即可）

## 5. 安装微信开发者工具

- 下载：https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html
- 选"稳定版 Stable Build"
- 装好后用微信扫码登录

## 6. 创建 unibest 项目

打开终端：

```bash
mkdir -p ~/Desktop/apps
cd ~/Desktop/apps
npm create unibest my-app --ui wot-ui --platform h5,mp-weixin --login false --i18n false --lime-echart --ucharts
cd my-app
pnpm install
pnpm dev:h5
```

浏览器自动打开 `http://localhost:xxxx`，看到带底部导航的空白应用骨架就成功了。

---

## 常见问题

| 现象 | 解决 |
|------|------|
| `node: command not found` | 重开终端，或 `source ~/.nvm/nvm.sh` |
| `pnpm` 装不上 | 确认 `node -v >= 20` 后重试 |
| `npm create unibest` 卡住 | `npm config set registry https://registry.npmmirror.com` 重试 |
| 微信开发者工具打不开 | 重新下载稳定版（非预发布版） |