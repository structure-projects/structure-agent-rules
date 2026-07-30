# AGENTS.md — Vue 3 前端规则（Codex 自包含模板）

> 本文件自包含，可直接拷贝到 Vue 3 前端项目根目录，供 Codex / 通用 AI Agent 自动加载。
> 修改规则时，请同步更新 `prompts/` 目录下的对应角色文件。

## 1. 硬约束

- npm scope **MUST** `@structure-projects`（公开包）；私有包不要使用该 scope。
- **MUST** 技术栈：Vue 3 + Vite + TypeScript + Pinia + Vue Router + Element Plus + UnoCSS + wujie-vue3。
- **MUST** `*-ui` 是 wujie 微前端子应用，`private: true`。
- **MUST** `*-ui-components` 开发时 `file:` 本地引用，正式发布到 npm (`@structure-projects/{领域}-ui-components`)。
- **MUST** `@structure-projects/components` 按需命名导入（**不是 Vue 插件**）。
- **MUST** element-plus 由消费项目自行 `app.use(ElementPlus)` + 导入 CSS。
- **MUST** 子应用入口调用 `createWujieSubapp().init()`。
- **MUST** HTTP 请求用 `@structure-projects/gateway-client` 的 `request`。

## 2. 组件规范

- 文件名 PascalCase（`UserTable.vue`）
- `<script setup lang="ts">` 必须
- Props 用 `defineProps<T>()`，Emits 用 `defineEmits<T>()`
- L1: `@structure-projects/components`（npm），L2: `*-ui-components`（本地），L3: 页面组件（内部）

## 3. 状态管理（Pinia）

- Setup Store 语法（`defineStore('id', () => { ... })`）
- 按领域拆分（`stores/user.ts`、`stores/role.ts`）

## 4. 路由

- 懒加载：`() => import('@/views/xxx/Index.vue')`
- 权限路由从后端 `structure-resource/menus` API 获取
- meta 声明 `title`、`icon`、`keepAlive`

## 5. 样式

- UnoCSS 原子类为默认方式
- `<style scoped>` 用于组件特有样式
- 禁止内联 `style="..."`

## 6. 微前端（wujie）

- 子应用入口：`createWujieSubapp().init()`
- 基座：`structure-portal`
- 子应用 lifecycle 声明 `beforeMount`、`afterMount`、`beforeUnmount`

## 7. 构建

- Vite 构建工具
- TypeScript strict 模式
- `unplugin-auto-import`（Vue/Pinia API 自动导入）
- `unplugin-vue-components`（Element Plus 按需导入）

## 8. 测试

| 层级 | 工具 |
|---|---|
| 单元测试 | Vitest |
| 组件测试 | Vitest + Vue Test Utils |
| E2E | Playwright |

- 每功能开发后立即写单测，通过才能做下一个
- 业务完成后写 E2E
- 提交前 `npm run test` 全通过 + `npm run build` 编译通过

## 9. CI/CD

- GitHub Actions
- `test.yml`：npm ci + vitest + vue-tsc
- `build-and-push.yml`：Docker (nginx) 构建推送（`*-ui`）
- `publish.yml`：npm publish（仅 `*-ui-components`）
- Secrets：`NPM_TOKEN`、`DOCKER_USERNAME`、`DOCKER_PASSWORD`

## 10. 项目结构

```
structure-{X}-ui/
├── src/
│   ├── api/          # API 封装
│   ├── components/   # L3 页面级组件
│   ├── composables/  # 可复用组合函数
│   ├── layouts/      # 布局
│   ├── router/       # 路由
│   ├── stores/       # Pinia
│   ├── styles/       # 全局样式（极少用）
│   ├── views/        # 页面
│   ├── App.vue
│   └── main.ts       # createWujieSubapp().init()
├── vite.config.ts
├── tsconfig.json
├── uno.config.ts
└── package.json      # private: true
```
