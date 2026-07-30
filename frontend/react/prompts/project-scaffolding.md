# React 前端项目脚手架规则

> 面向创建 React 前端项目的 AI Agent。

## 创建步骤

1. **MUST** 使用 Vite 创建项目：`npm create vite@latest my-app -- --template react-ts`
2. **MUST** 技术栈：React 18+ + TypeScript 5 + Vite 5 + React Router v6 + TanStack Query
3. **MUST** 状态管理按需选型：Zustand（轻量）或 Redux Toolkit（复杂企业应用）

### package.json

```json
{
  "name": "my-react-app",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite --port 3000",
    "build": "tsc -b && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "format": "prettier --write \"src/**/*.{ts,tsx,css}\"",
    "test": "vitest",
    "test:coverage": "vitest --coverage",
    "test:e2e": "playwright test"
  },
  "dependencies": {
    "react": "^18.3.0",
    "react-dom": "^18.3.0",
    "react-router-dom": "^6.26.0",
    "@tanstack/react-query": "^5.51.0",
    "zustand": "^4.5.0",
    "axios": "^1.7.0"
  },
  "devDependencies": {
    "@types/react": "^18.3.0",
    "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.3.0",
    "typescript": "^5.5.0",
    "vite": "^5.4.0",
    "vitest": "^2.0.0",
    "@testing-library/react": "^16.0.0",
    "@testing-library/jest-dom": "^6.4.0",
    "@playwright/test": "^1.45.0",
    "eslint": "^9.0.0",
    "prettier": "^3.3.0",
    "tailwindcss": "^3.4.0",
    "jsdom": "^24.0.0"
  }
}
```

## 检查清单

- [ ] `tsconfig.json` `strict: true`
- [ ] `vite.config.ts` 配置 `@vitejs/plugin-react` + 路径别名
- [ ] Tailwind CSS 或 CSS Modules 配置完成
- [ ] ESLint + Prettier 配置完成
- [ ] React Router v6 路由配置（`createBrowserRouter`）
- [ ] TanStack Query `QueryClientProvider` 挂载
- [ ] 状态管理（Zustand/RTK）Store 初始化
- [ ] Error Boundary 包裹根路由
- [ ] `main.tsx` 入口正确挂载 `<App />`

### vite.config.ts 参考

```ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tsconfigPaths from 'vite-tsconfig-paths'

export default defineConfig({
  plugins: [react(), tsconfigPaths()],
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true
      }
    }
  },
  resolve: {
    alias: {
      '@': '/src'
    }
  }
})
```

### tsconfig.json 关键配置

```json
{
  "compilerOptions": {
    "strict": true,
    "jsx": "react-jsx",
    "moduleResolution": "bundler",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"]
}
```

## Tailwind CSS 集成

```bash
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

```js
// tailwind.config.js
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {}
  },
  plugins: []
}
```

## 禁止事项

- **禁止** 使用 Class Component
- **禁止** 直接操作 DOM（除非在 `useRef` + `useEffect` 场景下无法避免）
- **禁止** 在组件中硬编码 API 地址（用环境变量）
- **禁止** 在 `useEffect` 中不声明依赖数组
- **禁止** 在渲染中直接调用 `fetch`（用 TanStack Query 或 useEffect）
