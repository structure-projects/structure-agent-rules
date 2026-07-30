# CLAUDE.md — UniApp 前端技术栈

本文件为 UniApp 跨平台前端技术栈规则，供 AI Agent 理解 UniApp 技术栈约定。

## 生态坐标

| 维度 | 值 | 说明 |
|---|---|---|
| 框架 | Vue 3 + UniApp | `@dcloudio/uni-app` |
| 语言 | TypeScript | `<script setup lang="ts">` |
| 样式 | SCSS + rpx 单位 | 750rpx = 屏幕宽度 |
| UI 库 | uView Plus / Uni UI | `uview-plus` 为主 |
| 状态管理 | Pinia | Setup Store 语法 |
| 路由 | pages.json | 非 Vue Router |
| 后端 | uni.request / uniCloud | |
| 测试 | Vitest + @vue/test-utils | |
| 构建 | Vite + @dcloudio/vite-plugin-uni | |
| Node.js | 20 LTS | |

## 项目结构

```
src/
├── pages/              # 页面（每个页面一个目录）
├── components/         # 公共组件（easycom 自动导入）
├── api/                # API 封装
│   └── request.ts      # 统一请求
├── stores/             # Pinia
├── utils/              # 工具函数
├── static/             # 静态资源
├── App.vue             # 应用入口（onLaunch 等）
├── main.ts             # createSSRApp + Pinia + uView Plus
├── pages.json          # 页面配置（核心路由）
├── manifest.json       # 各平台 appid
└── uni.scss            # 全局 SCSS 变量
```

## 关键技术事实

- 路由由 `pages.json` 定义，不使用 Vue Router。页面跳转用 `uni.navigateTo`、`uni.switchTab` 等 API。
- 使用 UniApp 内置组件：`<view>`（容器）、`<text>`（文本）、`<image>`（图片）。禁止使用 HTML 标签。
- 样式单位使用 `rpx`（750rpx = 屏幕宽度），禁止使用 `px`。
- 平台差异代码使用条件编译：`#ifdef H5`、`#ifdef MP-WEIXIN`、`#endif`。
- `createSSRApp` 而非 `createApp`，导出 `createApp` 函数。
- uView Plus 通过 `app.use(uviewPlus)` 注册，easycom 自动导入 `u-` 前缀组件。
- API 请求必须封装 `uni.request`，不直接在业务代码中调用。
- 小程序分包不能超过 2MB，需要合理规划 `subPackages`。
