# Vue 3 前端开发规则

> 角色：structure-developer（前端）。面向在 structure-projects 生态内开发 Vue 3 应用的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。与 `backend/java/structure-boot/` 组合使用时文件名带前缀，天然不冲突。

## 硬约束

- npm scope **MUST** `@structure-projects`（公开包）；私有包不要使用该 scope。
- **MUST** 技术栈：Vue 3 + Vite + TypeScript + Pinia + Vue Router + Element Plus + UnoCSS + wujie-vue3。
- **MUST** `*-ui` 是 wujie 微前端子应用，`package.json` 中 `name` 为 `@structure-projects/{领域}-ui`，`private: true`。
- **MUST** `*-ui-components` 在 **开发时** 通过 `file:../../structure-{X}/structure-{X}-ui-components` 本地引用；**正式发布时发布到 npm**（`@structure-projects/{领域}-ui-components`）。
- **MUST** 使用 `@structure-projects/components` 时 **按需命名导入**（**不是 Vue 插件**，无 `install`）；element-plus 是 external，**消费项目自己 `app.use(ElementPlus)` 并 `import 'element-plus/dist/index.css'`**。
- **MUST** 子应用入口调用 `createWujieSubapp().init()`（来自 `@structure-projects/wujie-subapp`）。
- **MUST** HTTP 请求用 `@structure-projects/gateway-client` 或 `@structure-projects/components` 的 default `request`（自动带 7 个网关 Header）。

## 关键优先级

- **工具库**：项目级 `@structure-projects/components` → element-plus → 自定义组件
- **状态管理**：Pinia store 模块化，每个领域一个 store 文件
- **路由**：Vue Router 懒加载，菜单与路由权限统一从后端 `structure-resource` 获取

## 组件规范

### 命名
- **MUST** 组件文件名 PascalCase（`UserTable.vue`）
- **MUST** 业务组件使用领域中文前缀（如 `UserCard.vue`、`RoleForm.vue`）
- **SHOULD** UI 基础组件复用 `@structure-projects/components` 或 element-plus

### Props 与 Emits
- **MUST** Props 用 `defineProps<T>()` 类型定义
- **MUST** Emits 用 `defineEmits<T>()` 类型定义
- **MUST** 复杂类型 Props 给默认值

### Script Setup
- **MUST** 使用 `<script setup lang="ts">`
- **SHOULD** 业务逻辑提取到 `composables/`（`useXxx`）
- **SHOULD** 状态管理放 Pinia store，非组件内部 ref

## 路由规范

- **MUST** 懒加载：`() => import('@/views/xxx/Index.vue')`
- **MUST** 路由 meta 声明 `title`、`icon`、`keepAlive`
- **MUST** 权限路由从后端 `structure-resource/menus` API 获取

## 样式规范

- **MUST** 使用 UnoCSS 原子类为默认样式方式
- **MAY** `<style scoped>` 用于组件特有样式
- **禁止** 内联样式（`style="..."`）

## 状态管理（Pinia）

```ts
// stores/user.ts
export const useUserStore = defineStore('user', () => {
  const currentUser = ref<User | null>(null)
  const fetchUser = async () => { /* ... */ }
  return { currentUser, fetchUser }
})
```

- **MUST** 使用 Setup Store 语法（`defineStore('id', () => { ... })`）
- **SHOULD** 按领域拆分 store（`stores/user.ts`、`stores/role.ts`）

## 请求规范

```ts
import { request } from '@structure-projects/gateway-client'
// 或 import { default as request } from '@structure-projects/components'

const data = await request.get<UserVO>('/api/users', { params })
const result = await request.post<UserVO>('/api/users', body)
```

- **MUST** 统一用 gateway-client 的 `request` 实例
- **MUST** 响应类型用 `ResResultVO<T>` 对应的接口声明
- **禁止** 直接用 `axios` / `fetch`

## 测试工作流

- 每开发一个功能 **立即** 写单元测试，**单测通过才能做下一个功能**
- 功能有修改时 **同步修改测试** 并通过
- 业务完成后写 **E2E 测试**（Playwright），通过才算交付
- **提交前**：`npm run test` 全部通过 + `npm run build` 编译通过
- **禁止** 测试/编译失败仍提交
