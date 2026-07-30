# CLAUDE.md — Vue 3 前端技术栈生态

本文件为 [structure-projects](https://github.com/structure-projects) 开源生态的 **Vue 3 前端规则**，供 AI Agent 理解前端技术栈约定。

## 生态坐标

| 维度 | 值 | 说明 |
|---|---|---|
| npm scope | `@structure-projects` | 所有前端组件统一使用 |
| 技术栈 | Vue 3 + Vite + TypeScript + Pinia + Vue Router + Element Plus + UnoCSS | 微前端子应用标准 |
| 微前端方案 | wujie (无界) | `structure-portal` 为基座，各 `*-ui` 为子应用 |
| 组件库 | `@structure-projects/components` | L1 基础组件库（npm 包） |
| HTTP 客户端 | `@structure-projects/gateway-client` | 自动附带网关 Header |
| 子应用 SDK | `@structure-projects/wujie-subapp` | 子应用初始化工具 |

## 项目形态

前端项目存在两种形态，均作为对应领域项目的一部分（在 `structure-{X}/` 目录内）：

| 形态 | 说明 | npm 发布 |
|---|---|---|
| **`*-ui`** | wujie 微前端子应用，`private: true`，**不发布 npm** | 否 |
| **`*-ui-components`** | 本地组件库，开发时 `file:` 引用，正式发布到 npm | 是 |

## 独立前端项目（根目录）

| 项目 | 说明 |
|---|---|
| `structure-admin-ui` | 独立管理后台入口 |
| `structure-iam-ui` | wujie 子应用 |
| `structure-components` | L1 组件库 npm 包 |
| `structure-sso` | SSO 前端 |
| `structure-portal` | Portal-Shell wujie 基座 |

## 版本信息

| 依赖 | 说明 |
|---|---|
| Vue | 3.x |
| Vite | 5.x+ |
| TypeScript | 5.x+ |
| Pinia | 2.x |
| Vue Router | 4.x |
| Element Plus | 2.x |
| UnoCSS | 0.x |
| Node.js | 20 LTS |
| pnpm / npm | 包管理器 |

## 关键技术事实

- `@structure-projects/components` **不是 Vue 插件**，按需命名导入；element-plus 是 external，消费项目自己 `app.use(ElementPlus)` 并引 CSS。
- `createWujieSubapp().init()`（来自 `@structure-projects/wujie-subapp`）是子应用入口标准调用。
- HTTP 请求用 `@structure-projects/gateway-client` 的 `request`（自动带 7 个网关 Header）。
- 开发时 `*-ui-components` 通过 `file:../../structure-{X}/structure-{X}-ui-components` 本地引用 + Vite alias。
