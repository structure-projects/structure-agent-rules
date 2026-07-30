# Svelte 前端项目脚手架规则

> 面向创建 Svelte/SvelteKit 前端项目的 AI Agent。

## 创建步骤

### 1. 使用 SvelteKit CLI 初始化

```bash
npx sv create my-app
# 或
npm create svelte@latest my-app
```

交互选择：
- SvelteKit demo app? → Yes (或 No 创建空白项目)
- TypeScript? → **Yes**
- ESLint? → Yes
- Prettier? → Yes
- Playwright? → Yes (E2E)
- Vitest? → Yes (单元测试)

### 2. 安装 UI 库（可选）

**Tailwind CSS**:
```bash
npx sv add tailwindcss
```

**Skeleton UI**:
```bash
npx sv add skeleton
```

### 3. 目录结构

```
my-app/
├── src/
│   ├── lib/
│   │   ├── components/    # 可复用组件
│   │   ├── stores/        # Svelte stores
│   │   ├── utils/         # 工具函数
│   │   └── types/         # TypeScript 类型
│   ├── routes/
│   │   ├── +layout.svelte
│   │   ├── +layout.server.ts
│   │   ├── +page.svelte
│   │   ├── api/
│   │   │   └── +server.ts # API 端点
│   │   └── (feature)/
│   │       ├── +page.svelte
│   │       └── +page.server.ts
│   ├── app.css            # 全局样式
│   ├── app.html           # HTML 模板
│   └── hooks.server.ts    # 服务端钩子
├── static/                # 静态资源
├── tests/                 # E2E 测试
├── svelte.config.js
├── vite.config.ts
├── tsconfig.json
└── package.json
```

### 4. svelte.config.js 配置

```js
import adapter from '@sveltejs/adapter-node';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
  preprocess: vitePreprocess(),
  kit: {
    adapter: adapter(),
    alias: {
      $lib: 'src/lib',
      $components: 'src/lib/components'
    }
  }
};

export default config;
```

- **MUST** 配置 `vitePreprocess` 处理 TypeScript
- **MUST** 根据部署目标选择 adapter
- **SHOULD** 配置 `alias` 简化导入路径

### 5. 环境变量

```ts
// $env/static/private (服务端，构建时注入)
import { DATABASE_URL } from '$env/static/private';

// $env/dynamic/private (服务端，运行时读取)
import { env } from '$env/dynamic/private';

// $env/static/public (客户端，构建时注入)
import { PUBLIC_API_URL } from '$env/static/public';

// $env/dynamic/public (客户端，运行时读取)
import { env } from '$env/dynamic/public';
```

- **MUST** 私密变量使用 `$env/static/private`
- **MUST** 公开变量使用 `$env/static/public`
- **MUST** 环境变量以 `PUBLIC_` 前缀暴露到客户端

### 6. hooks.server.ts

```ts
import type { Handle } from '@sveltejs/kit';

export const handle: Handle = async ({ event, resolve }) => {
  // 鉴权逻辑
  const session = await getSession(event.cookies);
  event.locals.user = session?.user;

  return resolve(event);
};
```

## 检查清单

- [ ] SvelteKit 创建，TypeScript 启用
- [ ] `svelte.config.js` 配置 adapter 和 preprocess
- [ ] `src/lib/` 包含 components、stores、utils
- [ ] `src/routes/` 文件路由结构
- [ ] `+layout.svelte` 和 `+layout.server.ts` 配置
- [ ] `hooks.server.ts` 鉴权/日志钩子
- [ ] Tailwind CSS 或 Skeleton UI 样式方案
- [ ] ESLint + Prettier 配置
- [ ] 环境变量按规则使用 `$env/` 模块

## 禁止事项

- **禁止** 在客户端代码中导入 `$env/static/private`（安全风险）
- **禁止** 在 `+page.server.ts` 中执行客户端代码
- **禁止** 在 `load` 函数中使用浏览器 API（无 `window`/`document`）
- **禁止** 混用 Svelte 4 的 `$:` 和 Svelte 5 的 `$state()` rune
