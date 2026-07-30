# Vue 3 前端架构规则

> 角色：structure-architect（前端架构）。面向需要做前端架构选型与技术决策的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。与 `backend/java/structure-boot/` 组合使用时文件名带前缀。

## 微前端架构

### 方案选型

- **MUST** 使用 wujie（无界）作为微前端方案。
- **MUST** `structure-portal` 作为基座（Shell），负责路由分发与统一鉴权。
- **MUST** 各 `*-ui` 业务子应用独立开发、独立部署，通过 wujie 嵌入 Portal。

### 子应用注册

```ts
import { createWujieSubapp } from '@structure-projects/wujie-subapp'
createWujieSubapp().init()
```

- **MUST** 子应用入口统一调用 `createWujieSubapp().init()`
- **MUST** 子应用 lifecycle 声明 `beforeMount`、`afterMount`、`beforeUnmount`

### 通信

- **SHOULD** 子应用间通信通过 Event Bus（wujie 提供）或 Pinia shared store
- **SHOULD** 跨应用数据同步走后端 API，避免前端状态耦合

## 组件库分层

| 层 | 定位 | 示例 |
|---|---|---|
| **L1** | 基础组件库，npm 发布 `@structure-projects/components` | Button、Table、Form、Dialog 等 |
| **L2** | 领域组件库 `*-ui-components`，本地引用 | UserSelector、DeptTree、ResourceTable |
| **L3** | 页面级组件，子应用内部 | UserList、RoleManage、MenuConfig |

- **MUST** L1 组件不依赖业务逻辑，纯展示 + 交互
- **MUST** L2 组件可依赖 L1，可访问后端 API
- **MUST** L3 组件串联 L1/L2，实现业务页面

## 状态管理

- **MUST** 全局状态用 Pinia（Setup Store 语法）
- **SHOULD** 组件内部状态用 `ref` / `reactive`
- **MAY** URL 参数用 Vue Router query/params 作为临时状态

### Store 架构

```
stores/
├── user.ts          # 用户信息、登录态
├── permission.ts    # 权限菜单
├── app.ts           # 应用级设置（layout、theme）
└── {domain}.ts      # 业务领域状态
```

## CSS 方案

- **MUST** UnoCSS 为默认原子化方案（presetUno + presetAttributify）
- **MAY** `<style scoped>` 用于组件特有覆盖
- **禁止** 使用全局 CSS 覆盖第三方库样式

## 构建工具链

- **MUST** Vite 为构建工具
- **MUST** TypeScript 严格模式（`strict: true`）
- **SHOULD** 开启 `unplugin-auto-import`（Vue/Pinia API 自动导入）
- **SHOULD** 开启 `unplugin-vue-components`（Element Plus 按需导入）
- **MUST** wujie 子应用 Vite 配置 `build.lib` 模式输出

## 目录结构（子应用）

```
structure-{X}-ui/
├── src/
│   ├── api/              # API 请求封装
│   ├── components/       # L3 页面级组件
│   ├── composables/      # 可复用组合函数
│   ├── layouts/          # 布局组件
│   ├── router/           # Vue Router 配置
│   ├── stores/           # Pinia Stores
│   ├── styles/           # 全局样式（极少使用）
│   ├── views/            # 页面视图
│   ├── App.vue
│   └── main.ts           # 入口：createWujieSubapp().init()
├── public/
├── vite.config.ts
├── tsconfig.json
├── uno.config.ts
└── package.json
```
