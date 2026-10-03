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

#### 6.1.2 微信小程序自动化测试（miniprogram-automator）

**安装依赖：**
```bash
cd my-app
pnpm add miniprogram-automator -D
```

**创建测试脚本 `test-miniprogram.cjs`：**
```javascript
const Automator = require('miniprogram-automator');

async function test() {
  // 1. 连接微信开发者工具
  const miniProgram = await Automator.launch({
    toolsPath: '/Applications/wechatwebdevtools.app/Contents/Resources/app',
    projectPath: '/项目路径/my-app/dist/dev/mp-weixin',
  });

  // 2. 获取当前页面信息
  const page = await miniProgram.currentPage();
  console.log('当前页面:', page.path);

  // 3. 获取页面数据
  const data = await page.data();
  console.log('页面数据:', JSON.stringify(data));

  // 4. 获取页面元素
  const elements = await page.$$('view');
  console.log('元素数量:', elements.length);

  // 5. 截图保存
  await miniProgram.screenshot({ path: './screenshot.png' });

  // 6. 模拟操作（点击）
  const btn = await page.$('view.class-name');
  if (btn) await btn.tap();

  await miniProgram.close();
  console.log('测试完成！');
}

test().catch(err => {
  console.error('错误:', err.message);
  process.exit(1);
});
```

**运行测试：**
```bash
node test-miniprogram.cjs
```

**前提条件：**
- 微信开发者工具已打开项目
- 设置 → 通用设置 → 开启服务端口

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
# 1. 构建微信小程序（构建成功后会自动打开微信开发者工具）
pnpm build:mp-weixin

# 2. 检查构建日志
# ✅ 通过标准：构建日志无 "failed to load icon" 警告
# ✅ 构建成功：显示 "Build complete."
```

**微信开发者工具自动验证（必须执行）**：

构建成功后，**必须**通过以下方式验证页面是否正常：

```bash
# 方法1：使用 miniprogram-ci 调用微信开发者工具 API 验证
# 安装：pnpm add -D miniprogram-ci

# 验证脚本（保存为 verify.js）
node -e "
const ci = require('miniprogram-ci');
const project = new ci.Project({
  appid: 'wx1234567890abcdef',
  type: 'miniProgram',
  projectPath: 'dist/build/mp-weixin',
  privateKeyPath: 'private.wx1234567890abcdef.key',
});
(async () => {
  const info = await ci.getDevCompileInfo({ project });
  console.log('✅ 微信开发者工具验证成功', JSON.stringify(info, null, 2));
})();
"

# 方法2：检查微信开发者工具是否正确加载项目
# 构建日志会显示 "🚀 正在打开微信小程序开发者工具..."
# 检查日志确认无报错即可
```

**验证通过标准**：
- ✅ 构建日志**无** `failed to load icon` 警告
- ✅ 显示 `Build complete.`
- ✅ 微信开发者工具成功打开项目（无 login 错误、无 import 错误）
- ✅ `dist/build/mp-weixin/` 目录已生成

**⚠️ 重要**：**必须调用微信开发者工具验证**，不能只检查构建日志。

**验证方法**：
1. `pnpm build:mp-weixin` 构建后会自动调用微信开发者工具 API
2. 检查终端输出是否有错误
3. 如果出现 `code: 10`（登录用户不是开发者），说明构建本身没问题，只是权限不足
4. 可同时打开 H5 预览：`open http://localhost:9000/`

**微信开发者工具能发现构建日志无法检测的问题**：
- 组件是否正确注册
- API 调用是否失败
- 页面渲染是否正常
- 图标/图片是否加载成功微信开发者工具能发现构建日志无法检测的问题（如组件未注册、API 调用失败等）。

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
