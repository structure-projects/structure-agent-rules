# Svelte 前端架构规则

> 角色：svelte-architect（前端架构）。面向需要做 Svelte 前端架构选型与技术决策的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。

## Svelte 版本策略

- **MUST** 使用 Svelte 4 或 Svelte 5（runes 模式）。
- **SHOULD** 新项目使用 SvelteKit 作为全栈框架（路由、SSR、API 路由）。
- **MAY** 纯 SPA 项目使用 Vite + Svelte（不含 SvelteKit）。

### Svelte 4 vs Svelte 5

| 特性 | Svelte 4 | Svelte 5 (runes) |
|---|---|---|
| 响应式 | `$:` 响应式声明 | `$state()` rune |
| 派生状态 | `$: derived = ...` | `$derived(...)` |
| 副作用 | `$: { ... }` | `$effect(() => { ... })` |
| Props | `export let` | `$props()` |
| 事件 | `createEventDispatcher` | 回调 props |

- **SHOULD** 新项目使用 Svelte 5 runes 模式
- **MUST** Svelte 4 项目保持 `$:` 语法，不混用 runes

## 路由架构（SvelteKit）

### 文件路由

```
src/routes/
├── +layout.svelte          # 根布局
├── +layout.server.ts       # 根布局服务端数据
├── +page.svelte            # 首页
├── users/
│   ├── +layout.svelte      # 用户布局
│   ├── +page.svelte        # 用户列表
│   ├── +page.server.ts     # 服务端加载
│   ├── [id]/
│   │   ├── +page.svelte    # 用户详情
│   │   └── +page.server.ts
│   └── +server.ts          # API 端点
└── +error.svelte           # 错误页面
```

- **MUST** 使用 SvelteKit 文件路由（`+page.svelte`、`+layout.svelte`）
- **MUST** 数据加载使用 `+page.server.ts` 的 `load` 函数
- **SHOULD** 使用 `+layout.server.ts` 共享布局数据
- **MUST** API 路由使用 `+server.ts` 导出 HTTP 方法

## 状态管理

| 方案 | 适用场景 | 复杂度 |
|---|---|---|
| **Svelte stores** | 全局/跨组件状态 | 低 |
| **SvelteKit `$state()`** | 组件内状态（Svelte 5） | 低 |
| **Context API** | 组件树内共享 | 中 |

### Stores 模式

```ts
// stores/user.ts
import { writable, derived } from 'svelte/store';

export const users = writable<User[]>([]);
export const currentUserId = writable<string | null>(null);

export const currentUser = derived(
  [users, currentUserId],
  ([$users, $id]) => $users.find(u => u.id === $id)
);
```

### Svelte 5 Runes 模式

```svelte
<script>
  let count = $state(0);
  let doubled = $derived(count * 2);
  
  $effect(() => {
    console.log(`Count changed to ${count}`);
  });
</script>
```

- **SHOULD** Svelte 4 项目使用 stores 管理全局状态
- **SHOULD** Svelte 5 项目使用 `$state()` rune 管理组件状态
- **MAY** 跨组件共享使用 Context API（`setContext` / `getContext`）

## 样式方案

- **MUST** 组件样式写在 `<style>` 标签内（自动 scoped）
- **SHOULD** 使用 Tailwind CSS 或 Skeleton UI 加速开发
- **MAY** 使用 CSS 变量实现主题化
- **禁止** 使用 `:global()` 覆盖第三方组件样式（除非必要）

## 构建工具链

- **MUST** Vite 为构建工具（SvelteKit 内置）
- **MUST** TypeScript（`<script lang="ts">`）
- **SHOULD** 使用 SvelteKit adapter（`@sveltejs/adapter-node`、`@sveltejs/adapter-static`）
- **SHOULD** 使用 `vitePreprocess` 处理 TypeScript 和 SCSS

## 部署策略

| Adapter | 适用场景 |
|---|---|
| `@sveltejs/adapter-node` | Node.js 服务端部署 |
| `@sveltejs/adapter-static` | 纯静态站点 |
| `@sveltejs/adapter-vercel` | Vercel 部署 |
| `@sveltejs/adapter-cloudflare` | Cloudflare Pages |

- **MUST** 根据部署目标选择合适的 adapter
- **MUST** SSR 项目使用 adapter-node 或平台 adapter
