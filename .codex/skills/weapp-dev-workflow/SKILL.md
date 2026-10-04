---
name: weapp-dev-workflow
description: 开发微信小程序的标准工作流规范。当用户说"开发一个【xxx】微信小程序"时，Agent 自动套用此 Skill 中的开发前必做、数据方案、布局要点、自测要求和交付标准约束。不要在已有 weapp-env-setup 项目的上下文中再次触发 env-setup Skill（环境已经装好了）。
---

# 微信小程序开发标准工作流

当用户说 **"开发一个【xxx】微信小程序"** 时，按以下模板和约束执行。

**结构**：用户输入 `[xxx]` 为核心功能需求（变量），其余部分为固定约束，Agent 无权删改。

**与 weapp-frontend-design 的关系**：本 Skill 可独立调用。**如果 `docs/prd/*.md` 存在，优先按 PRD 里的"## 核心功能"清单实现**（即先经过 `weapp-frontend-design` 确认过的方案）；不存在则按学员本轮直接描述的功能开发。三个 Skill（`weapp-env-setup` / `weapp-frontend-design` / `weapp-dev-workflow`）正交独立，可单独使用，也可串联。

---

## 1. 开发前必做

Agent 在开始写代码前**必须先读取** `./my-app/.agents/` 目录（如果存在），了解：

- 脚手架目录规范
- 组件库用法约定
- 路由/页面文件组织方式
- Mock 数据存放规范

> **路径说明**：本仓库只放 Skills 和 PRD，**实际 unibest 工程代码放在 `./my-app/`**（由 `weapp-env-setup` Step 6 创建）。
> PRD 在 `docs/prd/*.md`，代码在 `my-app/src/`，两者同仓库但分层明确。

若 `./my-app/.agents/` 不存在，跳过此步。

---

## 2. 核心功能（用户输入）

用户填入 `[xxx]`，以下是**示例结构**，实际开发时按用户描述的功能模块替换：

```markdown
## 核心功能
1. 首页：门店介绍、保养项目入口
2. 服务列表：分类展示保养项目
3. 服务详情：项目说明、价格
4. 预约下单：选择到店时间、填写车辆信息（车牌/车型）、联系人信息、提交预约单
5. 订单列表：查看预约记录
6. 个人中心：用户信息、订单入口
```

**Agent 必须按用户实际描述的功能模块来写代码**，不要照搬上面的示例描述。

---

## 3. 数据方案（固定约束）

- 所有请求走 **Mock 数据**，不接真实后端 API
- 封装**统一 request 方法**（即使不真正发请求，接口也要统一）
- 数据模型：按实际业务定义，至少包含 `services`、`orders`、`user`
- **图片处理**：服务图片建议使用网络图片（如 `picsum.photos`），避免本地 SVG 在微信小程序中可能被压缩导致显示异常

---

## 4. 布局要点（固定约束）

### 4.1 状态栏高度

首页顶部 Banner 或自定义导航栏区域，**必须动态获取状态栏高度**：

```javascript
const { statusBarHeight } = uni.getSystemInfoSync();
// 设置对应的 padding-top，避免顶部出现空白
```

### 4.2 安全区适配

- 底部固定按钮、内容区域需预留安全区：
  ```css
  padding-bottom: env(safe-area-inset-bottom);
  /* 或 uni-app 的 safe-area 类 */
  ```
- 防止被刘海屏、底部横条遮挡

---

## 6. 交工前自测（固定约束）

**⚠️ 重中之重：开发完成后、交工给用户前，必须执行自测验证通过。**

### 6.1 测试方式：H5 + 微信小程序双测

#### 6.1.1 H5 Playwright 截图自测

```javascript
// 1. 启动 dev server（如未启动）
// pnpm dev:h5

// 2. 使用 Playwright 截图验证
await page.goto('http://localhost:端口号');
await page.screenshot({ path: '模块名-首页.png' });

// 3. 检查截图确认无问题后，再进行下一步
```

#### 6.1.2 微信小程序自动化测试（首选：wechat-devtools MCP server）

**这是当前推荐的测试方式**，由 MCP server 直接调用开发者工具，比 `miniprogram-automator` 更轻量、无需额外写脚本、Agent 能在同一会话里完成"截图→断言→改代码→重测"的闭环。

**前置条件（一次性配置，Agent 不自动执行）：**

1. 微信开发者工具已安装并启动
2. **「设置 → 安全设置 → 服务端口」已开启**
3. **「设置 → 安全设置」勾选「启动工具时自动打开项目」**（可选但推荐）
4. MCP server 已配置（详见 `weapp-env-setup` 的 Step 5c），配置如下：

   ```json
   // ~/.cursor/mcp.json
   {
     "mcpServers": {
       "wechat-devtools": {
         "command": "wechatide",
         "args": ["mcp"]
       }
     }
   }
   ```

5. 配置后必须**重启 Cursor** 才生效

**MCP 工具清单与典型用法：**

> ⚠️ 工具命名空间为 `user-wechat-devtools`。所有工具的第一个必填参数都是 `project`（项目绝对路径）。

| 工具 | 用途 | 关键参数 |
|---|---|---|
| `simulator_open_page` | 触发编译并打开指定页面 | `project`, `page-path` |
| `simulator_refresh` | 重新编译当前页面 | `project` |
| `simulator_screenshot` | 截图（默认长边 1280 JPEG） | `project`,可选 `path` |
| `automation_navigate` | 页面导航（navigateTo/switchTab/...） | `project`, `action`, `url` |
| `automation_element_action` | 点击/输入/读元素 | `project`, `action`(tap/input/text/...), `selector`, `value` |
| `automation_get_page_data` | 读取页面/组件 data | `project`, `selector`, `action`(getData) |
| `automation_evaluate` | 在运行时执行任意 JS | `project`, `fnSource` |
| `auto_preview` | 推预览到开发者微信（生成二维码） | `project`, `page-path` |
| `quit` | 退出开发者工具 | - |

**典型测试流程（Agent 直接用工具调用，无需写脚本）：**

```
1. simulator_open_page({ project, page-path: "pages/orders/index" })
   → 自动触发编译 + 打开页面

2. simulator_screenshot({ project })
   → 拿截图，肉眼/视觉验证布局

3. automation_element_action({
     project,
     action: "tap",
     selector: "view.btn-submit",
     waitForSelector: "view.btn-submit"   // 推荐：等到元素出现再点
   })

4. automation_element_action({
     project, action: "input",
     selector: "input.car-plate",
     value: "京A12345"
   })

5. simulator_screenshot({ project })
   → 看提交后的页面状态

6. automation_evaluate({
     project,
     fnSource: "function() { return wx.getStorageSync('orders') }"
   })
   → 验证 Mock 数据是否正确写入
```

**优势 vs miniprogram-automator：**

| 维度 | MCP server | miniprogram-automator |
|---|---|---|
| 写脚本 | ❌ 不需要 | ✅ 需要 |
| Agent 直接调用 | ✅ | ❌（要开额外进程） |
| 截图速度 | 快（直接走开发者工具 API） | 中（要走 WebSocket） |
| 失败重试 | 在对话里直接重发工具 | 要改脚本再跑 |
| **首选** | ✅ **推荐用这个** | 备选 |

#### 6.1.3 微信小程序自动化测试（备选：miniprogram-automator）

**仅当 MCP server 未配置时使用**。完整脚本见 git 历史，不再赘述要点。

**安装依赖：**
```bash
cd my-app
pnpm add miniprogram-automator -D
```

**关键脚本骨架：**

```javascript
const Automator = require('miniprogram-automator');

async function test() {
  const miniProgram = await Automator.launch({
    toolsPath: '/Applications/wechatwebdevtools.app/Contents/Resources/app',
    projectPath: '/项目路径/my-app/dist/dev/mp-weixin',
  });

  const page = await miniProgram.currentPage();
  console.log('当前页面:', page.path);

  const data = await page.data();
  console.log('页面数据:', JSON.stringify(data));

  await miniProgram.screenshot({ path: './screenshot.png' });

  const btn = await page.$('view.class-name');
  if (btn) await btn.tap();

  await miniProgram.close();
}

test().catch(err => {
  console.error('错误:', err.message);
  process.exit(1);
});
```

**运行：** `node test-miniprogram.cjs`

**前提条件：**
- 微信开发者工具已打开项目
- 设置 → 通用设置 → 开启服务端口

**判断优先级的简单规则：**
- Agent 启动时用 `GetDynamicTools({ pattern: "wechat|devtool" })` 探测
- 若 `user-wechat-devtools` 命名空间 `namespaceStatus === "ready"` → 用 6.1.2 MCP 方案
- 否则用 6.1.3 miniprogram-automator 方案

---

### 6.2 检查项

- 截图：页面渲染是否正常（元素无遮挡、文字无溢出）
- 控制台：**无红色报错**（warn 可以忽略）
- 安全区：顶部状态栏和底部内容不被刘海屏、底部横条遮挡
- 机型覆盖：至少切换两种机型测试（如 iPhone 15 Pro 和普通安卓机）
- 交互：走一遍该模块核心交互（点击跳转、表单填写提交等）
- **图片与文字重叠**：检查图片下方是否有文字/卡片被图片遮挡（常见于 `-mt-*` 负 margin 场景）

### 6.3 🎨 视觉一致性检查（Playwright 测试重点）

#### 6.3.1 微信小程序导航栏与页面头部颜色必须一致

**这是交工前的 P0 视觉规范**：

- 微信小程序的**系统导航栏（顶栏）**和**页面自定义头部**必须使用**完全相同的颜色**
- 禁止出现：导航栏是白色而页面头部是紫色（或反之）的断层效果
- **配置方法**：
  - `pages.json` 中 `navigationBarBackgroundColor` 与页面自定义头部的 `background` 必须设置为同一颜色值
  - 例如：导航栏设为 `#7C3AED`（紫），页面头部背景也必须设为 `bg-indigo-500`（紫）或同色系渐变起始色

```json
// pages.json
{
  "navigationBarBackgroundColor": "#7C3AED",  // 紫色
  "navigationBarTextStyle": "white"
}
```

```vue
<!-- 页面头部 -->
<view class="bg-indigo-500">
  <!-- 颜色必须与 navigationBarBackgroundColor 一致 -->
</view>
```

#### 6.3.2 组件间覆盖/间距检查

**这是 Playwright 测试的另一重点**：

- 检查相邻组件之间是否有**覆盖风险**（如卡片与渐变头部靠太近）
- 检查元素**边距、padding**是否合理，是否有元素被遮挡
- 使用 Playwright 截图后，肉眼检查页面布局，确认所有元素清晰可读、互不干扰
- 特别关注：
  - 顶部状态栏 + 自定义头部 + 第一个内容组件之间的间距
  - 底部 tabBar 与最后一个内容组件之间的安全区
  - 浮层、卡片、模态框的边界是否清晰

#### 6.3.3 图片与文字重叠检查（⚠️ 常见 P0 bug）

**问题原因**：使用 `-mt-*` 负 margin 让卡片覆盖图片，容易出现文字被图片遮挡。

**典型错误代码**：
```html
<!-- ❌ 错误：-mt-8 负 margin 导致卡片覆盖不完全 -->
<image :src="..." mode="aspectFill" class="h-48 w-full" />
<view class="mx-4 -mt-8 rounded-xl bg-white p-4 shadow-lg">
  <!-- 文字可能被图片遮挡 -->
</view>
```

**正确写法**：
```html
<!-- ✅ 方案 A：不用负 margin，用足够间距 -->
<image :src="..." mode="aspectFill" class="h-48 w-full rounded-xl" />
<view class="mx-4 mt-6 rounded-xl bg-white p-4 shadow-lg">
  <!-- 文字不会被遮挡 -->
</view>

<!-- ✅ 方案 B：用 relative + absolute 精确定位 -->
<view class="relative">
  <image :src="..." mode="aspectFill" class="h-48 w-full" />
  <view class="absolute left-4 right-4 -bottom-6 rounded-xl bg-white p-4 shadow-lg">
    <!-- 卡片覆盖在图片底部 -->
  </view>
</view>
```

**自测重点**：
- 检查所有详情页的图片下方文字是否被图片覆盖
- 检查"状态标签"（如"已使用"、"待使用"）是否被图片遮挡
- 检查标题文字是否完整可见

#### 6.3.4 首页顶部渐变头部与状态栏颜色一致（⚠️ 常见 P0 bug）

**问题原因**：首页使用 `navigationStyle: 'custom'` 自定义导航栏，但系统导航栏区域仍存在，导致顶部出现颜色不一致。

**典型错误代码**：
```html
<!-- ❌ 错误：两个 view 分离，状态栏高度为 0 时会出现白色间隙 -->
<view :style="{ height: `${statusBarHeight}px`, background: 'linear-gradient(...)' }" />
<view class="bg-gradient-to-r from-indigo-500 to-purple-600 ...">
```

**正确写法**：
```html
<!-- ✅ 合并为同一 view，用 paddingTop 适配状态栏高度 -->
<view
  class="px-4 pb-4 text-white"
  :style="{ paddingTop: `${statusBarHeight}px`, background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' }"
>
  <!-- 内容 -->
</view>
```

**关键点**：
- 不要用两个 view 分别处理状态栏和内容
- 合并为一个 view，用 `paddingTop` 或 `:style` 动态设置顶部内边距
- `paddingTop` 配合渐变背景，确保颜色延伸覆盖整个顶部

**自测重点**：
- 检查首页顶部是否有白色/灰色间隙
- 检查渐变背景是否延伸到状态栏区域
- 在不同机型（iPhone/Android）上测试一致性

### 6.4 修复策略

发现问题**立即修复**，修完**重新自测**，直到无异常。

> 连续修复 **3 次**仍失败 → 暂停，输出：
> - 错误详情
> - 已尝试的修复方案（每次都记录）
> - 向用户请求介入

#### 6.3.5 Tabbar 图标不显示（⚠️ 常见 bug）

**问题原因**：UnoCSS 图标未正确配置图标集。

**典型错误**：
- 图标名称拼写错误（如 `carbon-document` 不存在）
- 未安装/导入图标集

**正确配置**：

```typescript
// uno.config.ts
import { defineConfig, presetIcons, transformerDirectives, transformerVariantGroup } from 'unocss'
import { presetUni } from '@uni-helper/unocss-preset-uni'

export default defineConfig({
  presets: [
    presetUni({ attributify: false }),
    presetIcons({
      scale: 1.2,
      warn: true,
      collections: {
        // 注册 Carbon 图标集（必须用动态导入）
        carbon: () => import('@iconify-json/carbon/icons.json').then(i => i.default),
      },
    }),
    // ...
  ],
  safelist: [
    'i-carbon-home',
    'i-carbon-calendar',  // 预约用日历图标
    'i-carbon-user',
  ],
})
```

```typescript
// src/tabbar/config.ts
export const customTabbarList: CustomTabBarItem[] = [
  { text: '首页', iconType: 'unocss', icon: 'i-carbon-home' },
  { text: '预约', iconType: 'unocss', icon: 'i-carbon-calendar' },
  { text: '我的', iconType: 'unocss', icon: 'i-carbon-user' },
]
```

**自测重点**：
- 构建日志**无** `failed to load icon` 警告
- Tabbar 三个图标全部可见
- 切换 tab 时图标颜色变化正常

#### 6.3.6 Tabbar 组件不显示（⚠️ 常见 bug）

**问题原因**：App.vue 未导入 Tabbar 组件。

**排查步骤**：
1. 检查 `src/App.vue` 是否导入并使用 `<Tabbar />`
2. 检查 Tabbar 组件是否正确配置（`custom: true` 在 `pages.json` 的 `tabBar` 中）

**正确写法**：
```vue
<!-- src/App.vue -->
<script setup lang="ts">
import Tabbar from '@/tabbar/index.vue'
// ...
</script>

<style lang="scss">
</style>
<Tabbar />
```

**pages.json 配置**：
```json
{
  "tabBar": {
    "custom": true,
    "list": [
      { "text": "首页", "pagePath": "pages/index/index" },
      { "text": "预约", "pagePath": "pages/orders/index" },
      { "text": "我的", "pagePath": "pages/me/me" }
    ]
  }
}
```

**自测重点**：
- 底部 Tabbar 在所有 tab 页显示
- 点击 Tabbar 项能正确切换页面

### 6.4 修复后自动验证流程（必须执行）

每次代码修改后，**立即执行以下验证**，包括调用微信开发者工具自动验证：

```bash
# 1. 单次构建微信小程序（跑完即退出，产物落在 dist/dev/mp-weixin/）
pnpm mp:once

# 2. 检查构建日志
# ✅ 通过标准：构建日志无 "failed to load icon" 警告
# ✅ 构建成功：显示 "DONE  Build complete."
```

> ⚠️ **不要用 `pnpm build:mp` / `build:mp:test`**：它们输出到 `dist/build/mp-weixin/`，而开发者工具打开的是 `dist/dev/mp-weixin/`，路径对不上还得重新导入。用 `pnpm mp:once`（见 6.7.4）。

**微信开发者工具自动验证（必须执行）**：

构建成功后，**必须**通过以下方式验证页面是否正常：

```
# 用 wechat-devtools MCP server 验证（首选）
# Agent 直接调用 MCP 工具，无需写脚本：
#   1. open_project_window({ project: "my-app/dist/dev/mp-weixin" })
#   2. simulator_open_page({ project, "page-path": "pages/index/index" })
#   3. simulator_screenshot({ project })
#   4. automation_element_action({ project, action: "tap", selector, waitForSelector })
#   5. automation_evaluate({ project, fnSource })
# （详见 6.1.2 节）
```

**验证通过标准**：
- ✅ 构建日志**无** `failed to load icon` 警告
- ✅ 显示 `DONE  Build complete.`
- ✅ MCP 工具能成功打开页面 + 截图（无 login 错误、无 import 错误、**无红屏**）
- ✅ `dist/dev/mp-weixin/` 目录已生成且页面四件套齐全
- ✅ 截图肉眼检查无问题（布局、安全区、图片加载）

**⚠️ 重要**：**必须调用 MCP 工具验证**，不能只检查构建日志。

**验证方法**：
1. `pnpm mp:once` 构建后用 MCP 工具调用
2. 若 MCP 调用出现 `login 错误`，先 `login` 工具扫码
3. 可同时打开 H5 预览：`open http://localhost:9000/`

**MCP 能发现构建日志无法检测的问题**：
- 组件是否正确注册
- API 调用是否失败
- 页面渲染是否正常
- 图标/图片是否加载成功
- 安全区是否被遮挡
- 视觉一致性（导航栏 vs 页面头部颜色）
- 是否有红屏（`xxx.json 文件读取错误`）

---

**如果 H5 服务已启动**，同时用浏览器验证：
```bash
# 终端里看到 "ready in xxxms" 后
open http://localhost:9000/#/pages/index/index
```

---

## 6.5 交付标准（固定约束）

最终交付前，必须完整跑通主流程：

**"浏览 → 详情 → 预约 → 查看订单"**

- 无报错
- 安全区合理
- 页面间跳转正确
- 数据流转正确（Mock 数据链路）

### 6.1 H5 测试通过后，执行微信小程序构建

H5 自测无问题后，**必须执行微信小程序的构建和部署**：

```bash
# 1. 构建微信小程序
pnpm build:mp

# 2. 提示用户导入微信开发者工具
# 打开微信开发者工具，导入 dist/build/mp-weixin 目录
```

> 这是固定的交付流程：H5 验证没问题 → 构建小程序 → 学员用微信开发者工具打开验证

---

## 6.6 常见 UI 问题速查（交工前必查清单）

### 6.6.1 ⚠️ 自定义 tabbar 遮挡问题（最常见）

**症状**：底部按钮 / 列表项 / 快捷入口被自定义 tabbar 完全覆盖或压住一半。

**根因**：
- 自定义 tabbar 是 `position: fixed; bottom: 0`，高度约 50px + 安全区 ≈ 80px
- 但页面 `<view>` 容器**没有给底部留够 padding**，导致内容跑到 tabbar 下面

**解决方案**（**必须**全部做到）：

1. **页面容器底部** 加 `pb-32`（约 128px），给 tabbar 让位
   ```vue
   <view class="min-h-screen bg-gray-50 pb-32">
   ```

2. **底部 fixed 按钮容器** 不能用 `fixed bottom-0`，要用**专用工具类 `bottom-tabbar`**（在 `uno.config.ts` 的 `rules` 中定义）：
   ```ts
   rules: [
     [
       'bottom-tabbar',
       {
         bottom: 'calc(50px + env(safe-area-inset-bottom))',
       },
     ],
     // ... 其他安全区规则
   ],
   ```
   ```vue
   <view class="fixed bottom-tabbar left-0 right-0 z-[1001] border-t border-gray-100 bg-white p-4 pb-safe shadow-lg">
     <view class="rounded-xl bg-gradient-to-r from-indigo-500 to-purple-600 py-4 text-center text-lg font-medium text-white" @tap="onConfirm">
       立即预约 ¥{{ price }}/小时
     </view>
   </view>
   ```

3. **scroll-view 父容器** 用 `flex h-screen flex-col`，scroll-view 用 `flex-1 overflow-hidden`，**不要**用 `h-[calc(100vh-XX)]`
   ```vue
   <view class="flex h-screen flex-col bg-gray-50">
     <view class="bg-white"><!-- 自定义导航 --></view>
     <scroll-view scroll-y class="flex-1 overflow-hidden">
       <view class="p-4 pb-32"><!-- 内容 --></view>
     </scroll-view>
   </view>
   ```

### 6.6.2 ⚠️ iconfont 字符乱码（次常见）

**症状**：`<text class="iconfont icon-location" />` 在 mp 环境显示成方块 ▢▢▢。

**根因**：
- `iconfont.css` 定义的 woff/ttf 字体在 mp 环境加载不可控
- 字符 unicode 在 css 中未定义（只定义了几个，但代码里用了十几个）

**解决方案**：
- ❌ **不要**在 mp 环境用 iconfont 字符
- ✅ 全部改用 UnoCSS `@iconify-json/carbon`（`i-carbon-xxx`）
- ✅ 动态图标必须加入 `uno.config.ts` 的 `safelist`：
   ```ts
   safelist: [
     'i-carbon-home',
     'i-carbon-user',
     'i-carbon-calendar',
     'i-carbon-location',
     'i-carbon-time',
     'i-carbon-arrow-left',
     'i-carbon-chevron-right',
     'i-carbon-phone',
     'i-carbon-information',
     'i-carbon-checkmark-filled',
     // ... 你页面用到的全部图标
   ],
   ```
- ✅ 常用 icon 映射速查：
   - 定位 → `i-carbon-location`
   - 时间 → `i-carbon-time`
   - 返回 → `i-carbon-arrow-left`
   - 右箭头 → `i-carbon-chevron-right`
   - 日历 → `i-carbon-calendar`
   - 电话 → `i-carbon-phone`
   - 信息 → `i-carbon-information`
   - 成功打钩 → `i-carbon-checkmark-filled`

### 6.6.3 ⚠️ 其它容易忽略的 UI 问题

| 现象 | 原因 | 处理 |
|------|------|------|
| 顶部 Banner 与状态栏之间有白条 | 状态栏高度没加到渐变背景里 | 渐变 `<view>` 内联 `:style="{ paddingTop: \`${statusBarHeight}px\` }"` |
| 自定义导航栏与页面头部颜色不一致 | 两者用了不同颜色变量 | 统一使用 `bg-gradient-to-r from-indigo-500 to-purple-600` |
| 卡片图片与文字重叠（`mt-*-X`） | 用 `-mt-X` 把图片负偏移出来 | 改用 `mt-6` 正 margin，加 `px-4` |
| tabbar 图标不显示 | UnoCSS 未注册 + `<text>` 没 `w-24px h-24px` | uno.config.ts 加 safelist + TabbarItem.vue 加尺寸 |
| `picsum.photos` 图片不显示 | mp dev 环境未配置合法域名 | 在「详情 → 不校验合法域名」勾选，或改本地占位图 |
| scroll-view 高度 0 | 父容器布局错 | 改 `flex h-screen flex-col` |
| **页面顶部同时出现两层标题和返回按钮** | `definePage` 配了 `navigationBarTitleText`（渲染原生导航栏）+ 模板里又写了自定义导航栏（带返回箭头） | 见下方 **6.6.4 详解** |
| **开发者工具反复红屏 `xxx.json 文件读取错误`、目录树来回闪** | `pnpm dev:mp` watch 模式反复清空 `dist/dev/mp-weixin/` | 改用 `pnpm mp:once`（单次 build），见 **6.7.4 详解** |

### 6.6.4 ⚠️ 两层导航栏问题（很常见，必须避免）

**症状**：
- 页面顶部出现 **两套标题 + 返回箭头**：上半部分是微信原生的（白色背景），下半部分是自己实现的（带渐变背景或自定义文字）
- 或者上半部原生返回箭头 + 下半部又有一个返回箭头

**根因**：
- `definePage` 的 `style.navigationBarTitleText` 会让微信**自动渲染原生导航栏**（带返回按钮）
- 模板里又写了一套 `<view class="自定义导航栏">`（带状态栏占位 + 返回箭头 + 标题）
- 两层同时渲染，必然重叠

**修复方案（选一）**：

#### 方案 A：用自定义导航栏（推荐，可控性高）

`definePage` 改为：
```ts
definePage({
  style: {
    navigationStyle: 'custom', // 完全隐藏原生导航栏
  },
})
```

模板里正常写自定义导航栏：
```vue
<view class="bg-white">
  <view :style="{ height: `${statusBarHeight}px` }" />
  <view class="flex items-center px-4 py-3">
    <text class="i-carbon-arrow-left mr-3 text-lg" @tap="uni.navigateBack()" />
    <text class="text-base font-medium">{{ title }}</text>
  </view>
</view>
```

#### 方案 B：用原生导航栏（最简，省事）

`definePage` 保持原样：
```ts
definePage({
  style: {
    navigationBarTitleText: '场地列表',
    navigationBarBackgroundColor: '#ffffff',
    navigationBarTextStyle: 'black',
  },
})
```

**删掉**模板里的：
```vue
<!-- ❌ 不要这样 -->
<view class="bg-white">
  <view :style="{ height: `${statusBarHeight}px` }" />
  <view class="flex items-center px-4 py-3">
    <text class="i-carbon-arrow-left mr-3 text-lg" @tap="uni.navigateBack()" />
    <text class="text-base font-medium">{{ title }}</text>
  </view>
</view>
```

原生导航栏会自动处理状态栏 + 返回按钮 + 标题。

**判断规则**：
- ✅ **tabbar 页面**（首页/订单/我的）：用方案 B（原生），因为自定义 tabbar 与自定义 navbar 容易冲突
- ✅ **非 tabbar 页面**（详情/预约/成功）：用方案 A（自定义），因为可以做到与渐变背景完美融合

**⚠️ 严禁**：两个方案都写一份，必然两层标题。

---

## 6.7 修复后立即自动验证（写在 skill 中）

### 6.7.1 Agent 侧的"修改即验证"闭环

每次代码修改后，**Agent 必须立即执行**：

1. **必须用 `pnpm mp:once`**（单次 build，约 5~10 秒跑完即退出，产物直接落到 `dist/dev/mp-weixin/`）
2. **绝对不要**用 `pnpm dev:mp` / `dev:mp:test` / `dev:mp:prod` 长时间挂着 —— 详见 **6.7.4 血泪教训**，会导致开发者工具红屏循环
3. **也不要用** `pnpm build:mp:test` —— 它虽然也是单次，但输出到 `dist/build/mp-weixin/`，开发者工具打开的是 `dist/dev/`，路径对不上，还得重新导入项目
4. build 完用 `user-wechat-devtools` MCP 工具（参见 6.1.2）：
   - `open_project_window` 打开项目窗口（`my-app/dist/dev/mp-weixin`）
   - `simulator_open_page` 打开关键路由（首页/列表/详情/表单/订单）
   - `simulator_screenshot` 截图
   - 视觉确认无问题后继续下一个修改

**如果 `pnpm mp:once` 脚本不存在**（学员是老项目），Agent 必须先帮学员加上：

```json
// my-app/package.json → scripts
"mp:once": "node ./scripts/create-base-files.js && UNI_OUTPUT_DIR=dist/dev/mp-weixin uni build -p mp-weixin --mode test",
"mp:once:prod": "node ./scripts/create-base-files.js && UNI_OUTPUT_DIR=dist/dev/mp-weixin uni build -p mp-weixin --mode production"
```

> 关键就是 `UNI_OUTPUT_DIR=dist/dev/mp-weixin` 这个环境变量 —— 它让**单次 build** 也能落到开发者工具已打开的目录，从而既避开 watch 清空问题，又不用重新导入项目。

**禁止**：完成所有改动后才一次性自测。**每一次**改动都要重新 build + 打开 + 截图。

**自测截图后必须检查清单**（一眼扫过去）：
1. ✅ **没有两层导航栏**（6.6.4）
2. ✅ 底部内容**没被 tabbar 遮挡**（6.6.1）
3. ✅ iconfont 字符**没变成方块**（6.6.2）
4. ✅ 安全区适配到位
5. ✅ **没有红屏**（`xxx.json 文件读取错误`）—— 见 6.7.4

### 6.7.2 用户侧的"开发 + 构建"工作流

**如果学员自己开发**（不是 Agent 在改），推荐工作流：

1. **微信开发者工具**：导入 `my-app/dist/dev/mp-weixin/`
2. 改 `src/` 文件 → 保存
3. **终端1**：`pnpm mp:once`（等 `DONE Build complete.`）
4. 微信开发者工具点「编译」刷新

**⚠️ 关键点**：
- ❌ **不要**在终端1 挂 `pnpm dev:mp` —— 它是 watch 模式且会**反复清空 dist**，导致开发者工具红屏循环（6.7.4）
- 微信开发者工具里改的文件**无效**，必须改 `src/`
- 学员看到效果慢时，第一反应是**检查上一次 `pnpm mp:once` 是否 build 成功**（看有没有 `DONE Build complete.`）、**开发者工具是否在 `dist/dev/mp-weixin`**

### 6.7.2.1 测试 AppID 反复失效的永久解法（强烈推荐）

**症状**：构建时日志报 `❌ 打开微信小程序开发者工具失败: 登录用户不是该小程序的开发者, [code 10]`（`APPID_ERROR`）。

**根因**：unibest 默认 `appid: touristappid`（测试号），**手动开开发者工具能跑**，但 `vite plugin` 构建时自动调 `cli open` 走的是带权限校验的接口 → 失败。

**永久解法**（unibest 框架已内置开关 `SKIP_OPEN_DEVTOOLS`，只需启用）：

```bash
# 一次性写入 shell 配置（macOS/Linux 用户）
echo 'export SKIP_OPEN_DEVTOOLS=true' >> ~/.zshrc
source ~/.zshrc

# Windows PowerShell
[System.Environment]::SetEnvironmentVariable('SKIP_OPEN_DEVTOOLS','true','User')
```

之后构建**不再自动调 cli open**，只写 `dist/dev/mp-weixin/`。配合手动首次打开，链路完全打通：

1. 在微信开发者工具**手动**导入 `my-app/dist/dev/mp-weixin/`（一次性；测试 AppID 手动开是放行的）
2. 工具**保持开启**、模拟器点亮
3. 改 `src/` → `pnpm mp:once` 写 dist → 工具点「编译」→ 模拟器刷新
4. **零 APPID_ERROR**

**⚠️ 别踩的坑**：
- 不要把 `SKIP_OPEN_DEVTOOLS` 写到 `my-app/.env` —— `vite.config.ts` 是从 `process.env` 读的（**不是** `loadEnv`），`.env` 里写无效
- 不要每次终端开新窗口再 export 一次——会忘；写到 `~/.zshrc` 一劳永逸
- **首次手动开工具这一步省不掉**——vite 不再帮你开，得学员自己点一次

**Agent 侧自测遇到 APPID_ERROR 怎么办**：
1. 先帮学员把 `SKIP_OPEN_DEVTOOLS=true` 写入 `~/.zshrc` 并 `source`
2. 让学员**手动**打开一次微信开发者工具导入 `my-app/dist/dev/mp-weixin/`
3. 再用 MCP `simulator_open_page` + `simulator_screenshot` 验证
4. 验证完告诉学员构建链路已打通，可以自己改了

### 6.7.3 自动信号脚本（可选）

`my-app/scripts/watch-mp.mjs` 提供：
- 监听 `src/` + 配置文件改动 → 写信号文件 `/tmp/u3-test/.autotest-signal`
- Agent 端 polling 该信号 → 自动触发 MCP 截图验证

启动方式（需要在终端 2 单独跑）：

```bash
pnpm dev:mp:auto
```

⚠️ 此脚本**不触发构建**，仅做"改动 → 信号 → Agent 截图"的信号中转。真正的构建由 Agent 执行 `pnpm mp:once`。

### 6.7.4 ⚠️ 血泪教训：`dev:mp` watch 模式导致开发者工具红屏循环

**这是一条已经付出过代价的规则，Agent 绝不能再犯。**

**症状**：
- 微信开发者工具反复弹出**红屏**：`pages/xxx/xxx.json 文件读取错误`
- 模拟器目录树在「空」和「有内容」之间**来回闪烁**
- 学员反馈"程序一直报错""是不是坏了""重装也没用"

**根因（两层叠加）**：

1. **`uni -p mp-weixin`（即 `pnpm dev:mp` / `dev:mp:test` / `dev:mp:prod`）本身就是 watch 模式，永不退出**。它输出末尾的 `DONE Build complete. Watching for changes...` 就是证据 —— 很多人误以为它 build 完就结束了。

2. 每次 watch 触发 rebuild 时，uni 会**先清空** `dist/dev/mp-weixin/`，再重新写入全部文件。而微信开发者工具正在 watch 这个目录 —— 目录被清空的那一瞬间它就读不到 `pages/me/me.json` → 报错；build 写完文件回来，错误消失；下一次改动又重来一遍 → **无限循环**。

3. **如果再叠加一个自己写的 watcher（如 `scripts/hot-watch.mjs`）会更糟**：它每次触发都 kill + 重启 `dev:mp`，等于**双重放大**清空-重建动作，闪得比单 watch 更厉害。

**Agent 排查这条症状的标准流程**：

```bash
# 1. 确认是否有 watch 进程还挂着
ps aux | grep -E "uni -p|uni build|hot-watch|dev:mp" | grep -v grep

# 2. 看 dist 是否处于「半空」状态
find my-app/dist/dev/mp-weixin -type f | wc -l   # 突然远小于页面数×4 → 正在被清空

# 3. 确认所有页面四件套齐全（js/json/wxml/wxss）
node -e '
const fs=require("fs");
const a=JSON.parse(fs.readFileSync("my-app/dist/dev/mp-weixin/app.json","utf8"));
const list=[...a.pages, ...((a.subPackages||a.subpackages||[]).flatMap(p=>(p.pages||[]).map(x=>p.root+"/"+x)))];
const bad=list.filter(p=>["js","json","wxml","wxss"].some(e=>!fs.existsSync(`my-app/dist/dev/mp-weixin/${p}.${e}`)));
console.log(bad.length?`缺文件: ${bad.join(", ")}`:`✅ ${list.length} 个页面全部齐全`);
'
```

**正确解法**（已在 `my-app/package.json` 落地）：

```bash
pnpm mp:once         # 单次 build，5~10 秒跑完即退出，产物 → dist/dev/mp-weixin/
pnpm mp:once:prod    # 生产模式单次 build，同样落到 dist/dev/mp-weixin/
```

**为什么这样能解决**：
- 单次 build **跑完就退出**，dist 只会被**完整地重写一次**，不会出现「空目录」中间态
- `UNI_OUTPUT_DIR=dist/dev/mp-weixin` 让产物仍落在开发者工具已打开的目录，**不用重新导入项目**
- 开发者工具的「自动保存时编译」可以留着（它只监听 dist 变化，不会自己清空目录，是安全的）

**⛔ 明确禁止**：
- 🚫 不要在后台长期挂 `pnpm dev:mp` / `dev:mp:test` / `dev:mp:prod`
- 🚫 不要用 `scripts/hot-watch.mjs`（`pnpm dev:mp:hot`）—— 会放大清空-重建，红屏更严重
- 🚫 不要为了"热更新"反复重启 watcher
- 🚫 看到红屏第一反应不要让学员"重装项目 / 删 dist 重导"，**根因是 watch 模式，不是配置错了**

---

## 7. 不用做的事

- 🚫 **不要**在没有 `weapp-env-setup` 环境的情况下触发环境安装流程（假设项目已在环境装好后开始）
- 🚫 **不要**跳过 `./my-app/.agents/` 目录的读取（如果存在）
- 🚫 **不要**到仓库外（如 `~/Desktop/apps/`）找代码 —— unibest 实际工程在 `./my-app/`
- 🚫 **不要**用本地 SVG 作为主要图片资源（微信小程序可能压缩）
- 🚫 **不要**硬编码状态栏高度（如写死 `padding-top: 44px`），必须动态获取
- 🚫 **不要**省略安全区适配（底部内容被刘海屏遮挡是 P0 bug）
- 🚫 **不要**在自测失败后跳过修复直接交付
- 🚫 **不要**连续修复 3 次仍失败后不报告就放弃
- 🚫 **不要**在交工前跳过 Playwright 验证 —— **这是最重要的规则，交工前必须验证**
- 🚫 **不要**用 `pnpm dev:mp` / `dev:mp:test` / `dev:mp:prod` 做构建 —— watch 模式反复清空 dist，导致开发者工具红屏循环（**6.7.4**）
- 🚫 **不要**用 `pnpm build:mp` / `build:mp:test` 做自测构建 —— 输出到 `dist/build/`，与开发者工具打开的 `dist/dev/` 路径不符
- 🚫 **不要**用 `pnpm dev:mp:hot`（`scripts/hot-watch.mjs`）—— 放大清空-重建，红屏更严重
- 🚫 **不要**把 `SKIP_OPEN_DEVTOOLS` 写进 `.env` —— `vite.config.ts` 从 `process.env` 读，`.env` 无效；必须写 `~/.zshrc`
