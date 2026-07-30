# CLAUDE.md — Svelte 前端技术栈

本文件为 Svelte 前端技术栈规则，供 AI Agent 理解 Svelte 技术栈约定。

## 生态坐标

| 维度 | 值 | 说明 |
|---|---|---|
| 框架 | Svelte 4 / Svelte 5 (runes) | 明确版本，不混用语法 |
| 全栈框架 | SvelteKit | 路由、SSR、API 路由 |
| 语言 | TypeScript | `<script lang="ts">` |
| 样式 | Scoped `<style>` + Tailwind CSS | Skeleton UI 可选 |
| 状态管理 | Stores / `$state()` rune | 按版本选择 |
| 测试 | Vitest + @testing-library/svelte | |
| E2E | Playwright | |
| 构建 | Vite (SvelteKit 内置) | |
| Node.js | 20 LTS | |

## 项目结构

```
src/
├── lib/
│   ├── components/    # 可复用组件
│   ├── stores/        # Svelte stores
│   ├── utils/         # 工具函数
│   └── types/         # TypeScript 类型
├── routes/
│   ├── +layout.svelte
│   ├── +page.svelte
│   ├── +page.server.ts
│   └── api/+server.ts
├── app.css
├── app.html
└── hooks.server.ts
```

## 关键技术事实

- `.svelte` 文件按 `<script>` → 模板 → `<style>` 顺序组织。
- Svelte 4 用 `export let` 声明 Props，`$:` 做响应式声明。
- Svelte 5 用 `$props()`、`$state()`、`$derived()`、`$effect()` runes。
- SvelteKit 使用文件路由：`+page.svelte`（页面）、`+layout.svelte`（布局）、`+server.ts`（API）。
- 数据加载通过 `+page.server.ts` 的 `load` 函数，自动生成 `$types`。
- 组件样式在 `<style>` 标签内自动 scoped，无需 CSS Modules。
- `{#each}` 必须使用 key 表达式 `(item.id)`。
- `{#await}` 处理 Promise 的三种状态（pending/resolved/rejected）。
- 环境变量通过 `$env/static/private`、`$env/static/public` 等模块访问。
- 部署通过 adapter 适配不同平台（node、static、vercel、cloudflare）。
