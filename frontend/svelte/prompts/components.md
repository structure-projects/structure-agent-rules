# Svelte 组件使用规范

> 本文件描述 Svelte 项目中组件的使用规范。本规则自包含，不依赖其他技术栈目录。

## .svelte 文件结构

```svelte
<script lang="ts">
  // 1. 导入
  import { onMount } from 'svelte';
  import ChildComponent from './ChildComponent.svelte';

  // 2. Props（Svelte 4）
  export let name: string = '';
  export let count: number = 0;

  // 3. 响应式声明（Svelte 4）
  $: doubled = count * 2;

  // 4. 生命周期
  onMount(() => {
    console.log('mounted');
  });
</script>

<!-- 5. 模板 -->
<div class="container">
  <h1>Hello {name}</h1>
  <p>Count: {count}, Doubled: {doubled}</p>
  <ChildComponent {name} bind:count />
</div>

<!-- 6. 样式（自动 scoped） -->
<style>
  .container {
    padding: 16px;
  }
  h1 {
    color: var(--primary-color);
  }
</style>
```

- **MUST** 文件使用 `.svelte` 扩展名
- **MUST** 按顺序组织：`<script>` → 模板 → `<style>`
- **SHOULD** `<script>` 使用 `lang="ts"`

## Props（Svelte 4）

```svelte
<script lang="ts">
  // 基础 Props
  export let name: string;
  export let age: number = 0;
  export let tags: string[] = [];
  
  // 回调 Props（替代事件）
  export let onDelete: (id: string) => void = () => {};
</script>
```

- **MUST** Svelte 4 使用 `export let` 声明 Props
- **MUST** 必传 Props 不设默认值
- **SHOULD** 使用回调 Props 替代 `createEventDispatcher`（Svelte 5 推荐）

## Props（Svelte 5 Runes）

```svelte
<script lang="ts">
  let { name, age = 0, onDelete }: {
    name: string;
    age?: number;
    onDelete?: (id: string) => void;
  } = $props();
</script>
```

- **SHOULD** Svelte 5 使用 `$props()` rune 声明 Props
- **MUST** `$props()` 提供完整 TypeScript 类型

## 事件（Svelte 4）

```svelte
<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  
  const dispatch = createEventDispatcher<{
    delete: { id: string };
    update: { id: string; name: string };
  }>();

  function handleDelete(id: string) {
    dispatch('delete', { id });
  }
</script>

<button on:click={() => handleDelete('1')}>Delete</button>
```

- **MUST** `createEventDispatcher` 提供类型参数
- **SHOULD** Svelte 5 改用回调 Props 替代事件分发

## 插槽（Slots）

```svelte
<!-- Card.svelte -->
<div class="card">
  <div class="card-header">
    <slot name="header">Default Header</slot>
  </div>
  <div class="card-body">
    <slot>Default Content</slot>
  </div>
  <div class="card-footer">
    <slot name="footer" />
  </div>
</div>
```

```svelte
<!-- 使用 -->
<Card>
  <svelte:fragment slot="header">Custom Header</svelte:fragment>
  <p>Body content</p>
  <button slot="footer">Action</button>
</Card>
```

### 插槽 Props

```svelte
<!-- List.svelte -->
<script lang="ts">
  export let items: T[] = [];
</script>

{#each items as item, index}
  <slot {item} {index} />
{/each}
```

```svelte
<!-- 使用 -->
<List items={users} let:item let:index>
  <p>{index + 1}. {item.name}</p>
</List>
```

- **SHOULD** 使用命名插槽组织复杂布局
- **SHOULD** 使用插槽 Props 实现列表渲染自定义

## 动画与过渡

```svelte
<script>
  import { fade, fly, slide, scale } from 'svelte/transition';
  import { flip } from 'svelte/animate';
</script>

{#if visible}
  <div transition:fly={{ y: 200, duration: 300 }}>
    Animated content
  </div>
{/if}

{#each items as item (item.id)}
  <div animate:flip>{item.name}</div>
{/each}
```

- **SHOULD** 使用内置 transition/animate 提升 UX
- **MAY** 自定义 transition 函数（`(node, params) => { ... }`）
