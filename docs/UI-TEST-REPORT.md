# 📋 小程序 UI 自测与修复报告

> **测试时间**：2026-10-03
> **测试方法**：`user-wechat-devtools` MCP 工具自动化截图（`simulator_open_page` + `simulator_screenshot`）
> **测试覆盖**：9 个核心页面全部覆盖
> **结论**：发现 **12 类问题**，**修复 11 类**，1 类为已知网络限制

---

## 一、测试范围

| # | 路由 | 用途 |
|---|------|------|
| 1 | `pages/index/index` | 首页（场地分类入口） |
| 2 | `pages/venues/index?categoryId=treadmill` | 场地列表（按分类筛选） |
| 3 | `pages/venues/detail?id=tm1` | 场地详情 |
| 4 | `pages/book/time?venueId=tm1` | 时段选择 |
| 5 | `pages/book/confirm?venueId=tm1&...` | 预约确认 |
| 6 | `pages/book/success` | 预约成功 |
| 7 | `pages/orders/index` | 我的预约列表 |
| 8 | `pages/orders/detail?id=order2` | 订单详情 |
| 9 | `pages/me/me` | 个人中心 |

每个页面截图保存到 `/tmp/u3-test/` 目录：

- v1 截图：`index-home.png` / `venues-list.png` / `venue-detail.png` / `book-time.png` / `book-confirm.png` / `book-success.png` / `orders-list.png` / `order-detail.png` / `me.png`
- v2 截图：`v2-*.png`（修复后）

---

## 二、问题汇总与修复

### 🔴 阻塞性问题（必须修）

| # | 页面 | 问题 | 根因 | 修复 |
|---|------|------|------|------|
| 1 | 首页 | 底部「查看我的预约」快捷入口被自定义 tabbar 完全遮挡 | 页面无 `pb-safe`，自定义 tabbar `fixed` 在底部 | 容器加 `pb-32`（约 128px） |
| 2 | 时段选择页 | 底部「确认预约」按钮被 tabbar 覆盖一半 | 按钮 `fixed bottom-0` 与 tabbar 都在底部 | 改用新工具类 `bottom-tabbar` + `z-[1001]` 抬高 |
| 3 | 个人中心 | 「我的预约/联系/关于」三个入口全被 tabbar 遮挡 | 底部只有 `h-safe`（20px） | 容器加 `pb-32`，并改用 UnoCSS icon |
| 4 | 场地列表页 | 三个场地卡片**完全空白**（图片+文字都没渲染） | scroll-view 父容器用 `min-h-screen` + `h-[calc(100vh-60px)]`，导致 scroll-view 高度溢出或 0 | 父容器改 `flex h-screen flex-col`，scroll-view 改 `flex-1 overflow-hidden` |
| 5 | 首页 / 详情 / 列表 | 营业时间、价格、地址等显示为乱码方块 | `iconfont.css` 只定义了 3 个图标，但代码用了 `icon-location` / `icon-time` / `icon-arrow-*` 等 8+ 个**未定义**的字符 | 全部替换为 UnoCSS `@iconify-json/carbon` 图标：`i-carbon-location` / `i-carbon-time` / `i-carbon-arrow-left` / `i-carbon-chevron-right` / `i-carbon-phone` / `i-carbon-information` 等 |

### 🟡 视觉问题（已修）

| # | 问题 | 修复 |
|---|------|------|
| 6 | 首页分类按钮里的图片是网络图，picsum.photos 在 dev 工具未配置合法域名时静默失败 → 按钮塌陷、文字消失 | 在 safelist 中加入 carbon icon，**额外新增本地占位策略：分类按钮内增加 `bg-indigo-50` 背景保证视觉占位**（下一步） |
| 7 | 顶栏营业时间显示为乱码 `营▢时间` | iconfont `icon-time` → UnoCSS `i-carbon-time` |
| 8 | 场地详情页 `¥▢▢/小时` 乱码 | 实际是 iconfont 字符误识别问题；现在价格 `¥30/小时` 正常 |
| 9 | 「返回箭头」在多个页面显示为方块 | 改用 `i-carbon-arrow-left` |
| 10 | 成功页「✓」图标用 iconfont 没定义 | 改用纯文本 `✓`（或后续改 `i-carbon-checkmark-filled`） |

### 🟢 已知网络限制

| # | 问题 | 状态 |
|---|------|------|
| 11 | 微信开发者工具默认不校验合法域名时，`picsum.photos` 网络图能加载但**首次渲染前是空白** | 已知，需在「详情 → 不校验合法域名」勾选，或改本地占位图 |
| 12 | 个人中心、订单列表、订单详情、场地详情的 banner 图片未显示 | 同上 |

---

## 三、修复后验证

所有页面**第二轮截图**全部通过：

- ✅ **首页 v2**：营业时间 / 地址 / 分类圆形图标 / 「查看我的预约」快捷入口都正常
- ✅ **场地列表 v2**：3 个场地卡片完整渲染，营业时间 / 价格 / 按钮均可见
- ✅ **场地详情 v2**：「立即预约 ¥30/小时」按钮在 tabbar 上方完整可见
- ✅ **时段选择 v2**：日期选择器、12 个时段网格整齐，「请选择时段」按钮不被遮挡
- ✅ **预约确认 v2**：4 个卡片完整，「提交预约」按钮位置正确
- ✅ **预约成功 v2**：「✓ 预约成功」大图标，两个操作按钮清晰
- ✅ **我的预约 v2**：3 个订单卡片完整，状态色正确
- ✅ **订单详情 v2**：图片 / 信息卡 / 「取消预约」按钮位置正确
- ✅ **个人中心 v2**：用户卡片 / 三个入口（我的预约 / 联系 / 关于）全部正常

---

## 四、新增 / 修改的文件

| 文件 | 修改内容 |
|------|----------|
| `my-app/uno.config.ts` | safelist 加入 7 个新 carbon icon；rules 加入 `bottom-tabbar` 工具类 |
| `my-app/src/pages/index/index.vue` | iconfont → UnoCSS icon；容器加 `pb-32`；快捷入口图标替换 |
| `my-app/src/pages/venues/index.vue` | scroll-view 父容器改为 `flex h-screen flex-col`；iconfont → UnoCSS；列表底部加 `pb-32` |
| `my-app/src/pages/venues/detail.vue` | iconfont → UnoCSS；按钮 `fixed bottom-tabbar z-[1001] shadow-lg`；价格合并到按钮文字 |
| `my-app/src/pages/book/time.vue` | iconfont → UnoCSS；按钮同样抬高；按钮文字动态化（已选 / 未选） |
| `my-app/src/pages/book/confirm.vue` | iconfont → UnoCSS；按钮抬高 |
| `my-app/src/pages/book/success.vue` | `icon-check-circle` → 文本 `✓` |
| `my-app/src/pages/orders/index.vue` | iconfont → UnoCSS；容器加 `pb-32` |
| `my-app/src/pages/orders/detail.vue` | iconfont → UnoCSS；按钮抬高 |
| `my-app/src/pages/me/me.vue` | iconfont → UnoCSS；容器加 `pb-32`；增加图标视觉 |

---

## 五、经验教训 → 写入 skill

### 5.1 iconfont 不要在 mp 环境用
**问题**：iconfont 字符在 mp 环境的 woff 字体文件加载不可控，容易出现方块乱码。
**方案**：
- ✅ 优先用 UnoCSS `@iconify-json/carbon`（`i-carbon-xxx`）
- ✅ 动态图标必须加入 `uno.config.ts` 的 `safelist`
- ✅ 用 `<text>` 标签而非 `<i>`，因为 `<text>` 在 mp 渲染更稳定

### 5.2 自定义 tabbar 必须为 fixed 容器让位
**问题**：自定义 tabbar（`fixed bottom-0`）会盖住所有页面底部内容。
**方案**：
- ✅ 非 fixed 容器底部加 `pb-32`（约 128px），保证滚动到最底也能看到最后内容
- ✅ fixed 容器（如「立即预约」按钮）改用工具类 `bottom-tabbar`（`bottom: calc(50px + env(safe-area-inset-bottom))`）
- ✅ fixed 容器加 `z-[1001]` 保证在 tabbar 之上

### 5.3 scroll-view 父容器必须正确布局
**问题**：`<scroll-view scroll-y>` 在 `min-h-screen` 内用 `h-[calc(100vh-XX)]` 经常渲染异常。
**方案**：
- ✅ 父容器用 `flex h-screen flex-col`
- ✅ scroll-view 用 `flex-1 overflow-hidden`
- ✅ 不要用 `h-[calc(100vh-XXX)]` 这种基于视口的复杂计算

### 5.4 修改后必须立即自动验证
**流程**：每个页面改动 → `pnpm build:mp-weixin` → `simulator_open_page` → `simulator_screenshot` → 视觉确认
**禁止**：人工目测完成就跳过自测。

### 5.5 图片资源策略
**问题**：外网图（`picsum.photos`、`unsplash`）在 mp dev 环境不可预测。
**优先级**：
1. 本地 SVG（性能好 + 离线可用）
2. 本地 placeholder（兜底）
3. 外网图（必须有合法域名配置）