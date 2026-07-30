# Svelte 前端开发规则

> 角色：svelte-developer（前端）。面向开发 Svelte/SvelteKit 应用的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。

## 硬约束

- **MUST** Svelte 4 或 Svelte 5（runes），明确版本不混用。
- **MUST** SvelteKit 为全栈框架（路由、SSR、API）。
- **MUST** TypeScript（`<script lang="ts">`）。
- **MUST** Vite 为构建工具（SvelteKit 内置）。
- **SHOULD** Tailwind CSS 或 Skeleton UI 作为样式方案。

## 关键优先级

- **路由**：SvelteKit 文件路由（`+page.svelte`）
- **数据加载**：Server load functions（`+page.server.ts`）
- **状态管理**：Stores（Svelte 4）→ `$state()` rune（Svelte 5）
- **样式**：Scoped `<style>` + Tailwind

## 组件规范

### 组件结构（Svelte 4）

```svelte
<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { writable } from 'svelte/store';

  // Props
  export let userId: string;
  export let showDetails: boolean = false;

  // Local state
  let user: User | null = null;
  let loading = true;

  // Reactive declarations
  $: displayName = user ? user.name : 'Unknown';

  // Lifecycle
  onMount(async () => {
    user = await fetchUser(userId);
    loading = false;
  });

  onDestroy(() => {
    // Cleanup
  });
</script>

{#if loading}
  <p>Loading...</p>
{:else if user}
  <div class="user-card">
    <h2>{displayName}</h2>
    {#if showDetails}
      <p>{user.email}</p>
    {/if}
  </div>
{:else}
  <p>User not found</p>
{/if}

<style>
  .user-card {
    padding: 16px;
    border: 1px solid #ddd;
    border-radius: 8px;
  }
</style>
```

### 组件结构（Svelte 5 Runes）

```svelte
<script lang="ts">
  let { userId, showDetails = false }: {
    userId: string;
    showDetails?: boolean;
  } = $props();

  let user = $state<User | null>(null);
  let loading = $state(true);
  let displayName = $derived(user ? user.name : 'Unknown');

  $effect(() => {
    fetchUser(userId).then(u => {
      user = u;
      loading = false;
    });
  });
</script>

<!-- template same as Svelte 4 -->
```

### 命名

- **MUST** 组件文件 PascalCase（`UserCard.svelte`）
- **MUST** 页面文件按路由规则（`+page.svelte`）
- **MUST** Store 文件 camelCase（`user.ts`）

### 模板语法

```svelte
<!-- 条件渲染 -->
{#if condition}
  <p>True</p>
{:else if otherCondition}
  <p>Other</p>
{:else}
  <p>False</p>
{/if}

<!-- 列表渲染 -->
{#each items as item, index (item.id)}
  <div>{index + 1}. {item.name}</div>
{:else}
  <p>No items</p>
{/each}

<!-- await 块 -->
{#await promise}
  <p>Loading...</p>
{:then value}
  <p>Result: {value}</p>
{:catch error}
  <p>Error: {error.message}</p>
{/await}

<!-- 响应式绑定 -->
<input bind:value={name} />
<input type="checkbox" bind:checked={agreed} />
```

- **MUST** `{#each}` 使用 key 表达式（`(item.id)`）
- **SHOULD** `{#await}` 处理 Promise 三种状态

## 路由规范（SvelteKit）

### 页面加载

```ts
// +page.server.ts
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, fetch }) => {
  const res = await fetch(`/api/users/${params.id}`);
  const user = await res.json();
  return { user };
};
```

```svelte
<!-- +page.svelte -->
<script lang="ts">
  import type { PageData } from './$types';
  export let data: PageData;
</script>

<h1>{data.user.name}</h1>
```

### 表单操作

```ts
// +page.server.ts
import type { Actions } from './$types';

export const actions: Actions = {
  default: async ({ request }) => {
    const formData = await request.formData();
    const name = formData.get('name') as string;
    // 处理表单...
    return { success: true };
  }
};
```

```svelte
<!-- +page.svelte -->
<form method="POST">
  <input name="name" required />
  <button type="submit">Save</button>
</form>
```

- **MUST** 数据加载使用 `load` 函数（server 或 universal）
- **SHOULD** 表单提交使用 SvelteKit Form Actions
- **MUST** 使用 `$types` 自动生成的类型（`PageData`、`PageServerLoad`）

## 样式规范

- **MUST** 组件样式写在 `<style>` 标签内（自动 scoped）
- **SHOULD** 全局样式放 `app.css` 或 `app.postcss`
- **SHOULD** 使用 CSS 变量实现主题化
- **禁止** 滥用 `:global()` 选择器

## 测试工作流

- 每开发一个功能**立即**写单元测试，**单测通过才能做下一个功能**
- 功能有修改时**同步修改测试**并通过
- 业务完成后写**E2E 测试**（Playwright），通过才算交付
- **提交前**：`npm run test` 全部通过 + `npm run build` 编译通过
- **禁止** 测试/编译失败仍提交
