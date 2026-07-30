# AGENTS.md — Svelte 前端规则（Codex 自包含模板）

> 本文件自包含，可直接拷贝到 Svelte 前端项目根目录，供 Codex / 通用 AI Agent 自动加载。
> 修改规则时，请同步更新 `prompts/` 目录下的对应角色文件。

## 1. 硬约束

- **MUST** Svelte 4 或 Svelte 5（runes），版本语法不混用。
- **MUST** SvelteKit 为全栈框架（路由、SSR、API）。
- **MUST** TypeScript（`<script lang="ts">`）。
- **SHOULD** Tailwind CSS 或 Skeleton UI 作为样式方案。

## 2. 组件规范

- `.svelte` 文件：`<script>` → 模板 → `<style>` 顺序
- 文件名 PascalCase（`UserCard.svelte`）
- Props 完整 TypeScript 类型
- Svelte 4：`export let` Props + `$:` 响应式
- Svelte 5：`$props()` + `$state()` + `$derived()` + `$effect()`

## 3. 模板语法

- `{#if}` 条件渲染，`{#each}` 列表渲染，`{#await}` 异步渲染
- `{#each}` MUST 使用 key 表达式 `(item.id)`
- `bind:` 双向绑定（`bind:value`、`bind:checked`）

## 4. 路由（SvelteKit）

- 文件路由：`+page.svelte`、`+layout.svelte`、`+server.ts`
- 数据加载：`+page.server.ts` 的 `load` 函数
- 表单：Form Actions（`actions` 导出）
- 类型：`$types` 自动生成（`PageData`、`PageServerLoad`）

## 5. 状态管理

- Svelte 4：stores (`writable`、`derived`、`readable`)
- Svelte 5：`$state()` rune（组件内）、stores（全局）
- Context API：`setContext` / `getContext`

## 6. 样式

- 组件样式在 `<style>` 标签内，自动 scoped
- 全局样式放 `app.css` 或 `app.postcss`
- 禁止滥用 `:global()` 选择器
- CSS 变量实现主题化

## 7. 插槽与动画

- 命名插槽：`<slot name="header">`
- 插槽 Props：`<slot {item}>` → `let:item`
- 过渡动画：`transition:fly`、`transition:fade`
- 列表动画：`animate:flip`

## 8. 测试

| 层级 | 工具 |
|---|---|
| 单元测试 | Vitest |
| 组件测试 | Vitest + @testing-library/svelte |
| E2E | Playwright |

- 每功能开发后立即写单测，通过才能做下一个
- 业务完成后写 E2E
- 提交前 `npm run test` + `npm run build` 全通过

## 9. CI/CD

- GitHub Actions
- `test.yml`：npm ci + lint + type check + vitest + build
- `build-and-push.yml`：Docker (adapter-node) 构建推送
- `publish.yml`：npm publish（库发布，按需）
- Secrets：`NPM_TOKEN`、`DOCKER_USERNAME`、`DOCKER_PASSWORD`

## 10. 项目结构

```
src/
├── lib/
│   ├── components/    # 可复用组件 (.svelte)
│   ├── stores/        # Svelte stores (.ts)
│   ├── utils/         # 工具函数
│   └── types/         # TypeScript 类型
├── routes/
│   ├── +layout.svelte     # 根布局
│   ├── +layout.server.ts  # 布局数据
│   ├── +page.svelte       # 首页
│   ├── (feature)/
│   │   ├── +page.svelte
│   │   └── +page.server.ts
│   └── api/+server.ts     # API 端点
├── app.css
├── app.html
└── hooks.server.ts
```
