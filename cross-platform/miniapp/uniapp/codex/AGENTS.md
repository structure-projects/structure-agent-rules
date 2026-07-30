# AGENTS.md — UniApp 前端规则（Codex 自包含模板）

> 本文件自包含，可直接拷贝到 UniApp 前端项目根目录，供 Codex / 通用 AI Agent 自动加载。
> 修改规则时，请同步更新 `prompts/` 目录下的对应角色文件。

## 1. 硬约束

- **MUST** Vue 3 + UniApp（`@dcloudio/uni-app`）。
- **MUST** `<script setup lang="ts">`。
- **MUST** `pages.json` 配置所有页面路由和 tabBar。
- **MUST** `manifest.json` 配置各平台 appid。
- **SHOULD** uView Plus（`uview-plus`）作为 UI 组件库。
- **SHOULD** Pinia 作为状态管理。

## 2. 组件规范

- 使用 UniApp 内置组件：`<view>`、`<text>`、`<image>`、`<scroll-view>`、`<swiper>`
- 禁止使用 HTML 标签：`<div>`、`<span>`、`<img>`
- 文件名 kebab-case，easycom 自动导入 `components/` 下组件
- Props/Emits 完整 TypeScript 类型
- 样式 scoped + rpx 单位

## 3. 路由

- 路由由 `pages.json` 定义（非 Vue Router）
- `uni.navigateTo({ url: '/pages/xxx/index?id=1' })` — 普通跳转
- `uni.switchTab({ url: '/pages/index/index' })` — Tab 页跳转
- `uni.redirectTo({ url: '/pages/login/index' })` — 重定向
- `uni.reLaunch({ url: '/pages/index/index' })` — 重启应用
- `uni.navigateBack({ delta: 1 })` — 返回

## 4. 应用/页面生命周期

- App：`onLaunch`、`onShow`、`onHide`
- Page：`onLoad`、`onShow`、`onReady`、`onHide`、`onUnload`
- `onLoad` 接收页面参数，`onUnload` 清理资源

## 5. 状态管理（Pinia）

- Setup Store 语法：`defineStore('id', () => { ... })`
- Token 持久化到 `uni.setStorageSync('token', token)`
- 按领域拆分 store（`user.ts`、`order.ts`）

## 6. API 请求

- 封装 `uni.request` 为统一 request 函数
- 拦截器处理 Token 刷新和 401 跳转登录页
- 错误统一 `uni.showToast` 提示
- 禁止在业务代码中直接调用 `uni.request`

## 7. 条件编译

- `#ifdef H5` — 仅在 H5 编译
- `#ifdef MP-WEIXIN` — 仅在微信小程序编译
- `#ifndef H5` — 除 H5 外编译
- `#endif` — 结束条件块
- 支持：`H5`、`MP-WEIXIN`、`MP-ALIPAY`、`MP-BAIDU`、`APP-PLUS`

## 8. 样式

- 尺寸单位：`rpx`（750rpx = 屏幕宽度），禁止 `px`
- 全局变量在 `uni.scss` 中定义，所有页面自动可用
- 组件样式 scoped
- 主题色通过 SCSS 变量管理

## 9. 测试

| 层级 | 工具 |
|---|---|
| 单元测试 | Vitest |
| 组件测试 | Vitest + @vue/test-utils |
| E2E | 各平台真机调试 |

- 每功能开发后立即写单测，通过才能做下一个
- 业务完成后在目标平台真机验证
- 提交前 `npm run test` + 所有目标平台 `npm run build` 全通过

## 10. CI/CD

- GitHub Actions
- `test.yml`：npm ci + lint + vitest + build:h5
- `build-h5.yml`：Docker (nginx) 构建部署 H5
- `build-mp-weixin.yml`：微信小程序 CI（miniprogram-ci 上传）
- Secrets：`WX_APPID`、`DOCKER_USERNAME`、`DOCKER_PASSWORD`

## 11. 项目结构

```
src/
├── pages/              # 页面（每个页面一个目录）
│   ├── index/
│   │   └── index.vue
│   └── user/
│       └── index.vue
├── components/         # 公共组件（easycom 自动导入）
├── api/
│   ├── request.ts      # 统一请求封装
│   └── user.ts         # 用户 API
├── stores/             # Pinia
│   └── user.ts
├── utils/              # 工具函数
├── static/             # 静态资源（图片、字体）
│   └── images/
├── App.vue             # 应用入口
├── main.ts             # createSSRApp + use(Pinia) + use(uviewPlus)
├── pages.json          # 页面配置（核心路由）
├── manifest.json       # 各平台 appid 和权限
└── uni.scss            # 全局 SCSS 变量
```
