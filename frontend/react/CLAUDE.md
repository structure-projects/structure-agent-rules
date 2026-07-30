# CLAUDE.md — React 前端技术栈生态

本文件为 structure-projects 开源生态的 **React 前端规则**，供 AI Agent 理解前端技术栈约定。

## 生态坐标

| 维度 | 值 | 说明 |
|---|---|---|
| 技术栈 | React 18+ + TypeScript strict + Vite | 函数组件 + Hooks |
| 状态管理 | Zustand / Redux Toolkit | 客户端全局状态 |
| 服务端状态 | TanStack Query (React Query) | 缓存、去重、后台刷新 |
| 路由 | React Router v6 | `createBrowserRouter` + 懒加载 |
| HTTP 客户端 | axios（封装） | 统一拦截器、错误处理 |
| 样式 | Tailwind CSS / CSS Modules | 禁止内联样式 |
| 测试 | Vitest + React Testing Library + Playwright | 单元/组件/E2E |

## 关键决策

- **Functional Components only**：禁止 Class Component
- **状态分层**：服务端数据 → TanStack Query，客户端全局 → Zustand/RTK，组件局部 → useState/useReducer
- **Props 类型**：所有组件 Props 通过 `interface` 声明完整 TypeScript 类型
- **文件命名**：组件 PascalCase `.tsx`，Hook `useXxx.ts`，工具函数 camelCase `.ts`
- **组件导出**：优先命名导出 `export const Xxx`，避免默认导出滥用

## 项目结构

```
src/
├── api/              # API 请求函数
├── components/
│   ├── ui/           # L1 通用 UI 组件
│   └── business/     # L2 领域业务组件
├── hooks/            # 自定义 Hooks (useXxx)
├── layouts/          # 布局组件
├── pages/            # L3 页面组件
├── router/           # React Router 配置
├── stores/           # Zustand / Redux stores
├── styles/           # 全局样式、CSS 变量
├── types/            # 共享 TypeScript 类型
├── utils/            # 工具函数
├── App.tsx
└── main.tsx
```

## 版本信息

| 依赖 | 版本 |
|---|---|
| React | 18.x+ |
| TypeScript | 5.x+ |
| Vite | 5.x+ |
| React Router | 6.x |
| TanStack Query | 5.x |
| Zustand | 4.x |
| Vitest | 2.x |
| Playwright | 1.x |
| Node.js | 20 LTS |

## 关键技术事实

- 禁止 Class Component，全部使用 Functional Components + Hooks。
- `useEffect` 必须有正确的依赖数组和清理函数。
- 服务端数据必须用 TanStack Query 管理，禁止手动管理 loading/error/data。
- 全局客户端状态用 Zustand（轻量）或 Redux Toolkit（复杂企业应用）。
- CSS 方案为 Tailwind CSS 或 CSS Modules，严格禁止内联 `style={{}}`。
- 关键路由必须包裹 Error Boundary。
- 所有 API 请求统一封装在 `api/` 目录。
- 环境变量客户端暴露的用 `VITE_` 前缀。
