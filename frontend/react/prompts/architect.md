# React 前端架构规则

> 角色：architect（前端架构）。面向需要做 React 前端架构选型与技术决策的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。

## 技术栈基线

- **MUST** React 18+ 配合 TypeScript strict mode
- **MUST** Vite 作为构建工具
- **MUST** Functional Components + Hooks（禁止 Class Component）
- **MUST** Node.js 20 LTS

## 状态管理

### 选型原则

| 场景 | 方案 | 说明 |
|---|---|---|
| 轻量/中型应用 | Zustand | 简洁、TS 友好、无 boilerplate |
| 复杂企业应用 | Redux Toolkit (RTK) | 中间件、DevTools、可预测状态 |
| 服务端状态 | TanStack Query (React Query) | 缓存、去重、后台刷新 |

### Zustand Store 架构

```ts
// stores/userStore.ts
import { create } from 'zustand'

interface UserState {
  currentUser: User | null
  fetchUser: () => Promise<void>
}

export const useUserStore = create<UserState>((set) => ({
  currentUser: null,
  fetchUser: async () => {
    const user = await userApi.getCurrent()
    set({ currentUser: user })
  }
}))
```

- **MUST** Store 按领域拆分（`stores/userStore.ts`、`stores/authStore.ts`）
- **SHOULD** 服务端数据用 TanStack Query，客户端状态用 Zustand/RTK

### Redux Toolkit Store 架构

```
stores/
├── index.ts          # configureStore
├── hooks.ts          # useAppDispatch, useAppSelector
├── userSlice.ts
├── authSlice.ts
└── {domain}Slice.ts
```

## 路由

- **MUST** React Router v6（`createBrowserRouter`）
- **MUST** 懒加载：`React.lazy(() => import('./pages/Xxx'))`
- **MUST** 路由配置集中管理，嵌套路由用 `<Outlet />`

```tsx
// router/index.tsx
import { createBrowserRouter } from 'react-router-dom'
import { lazy, Suspense } from 'react'

const UserList = lazy(() => import('@/pages/users/UserList'))

export const router = createBrowserRouter([
  {
    path: '/',
    element: <AppLayout />,
    children: [
      {
        path: 'users',
        element: (
          <Suspense fallback={<PageLoading />}>
            <UserList />
          </Suspense>
        )
      }
    ]
  }
])
```

## CSS 方案

- **MUST** Tailwind CSS 或 CSS Modules 作为样式方案
- **禁止** 内联样式（`style={{}}`）
- **MAY** `styled-components` 用于复杂动态样式（需评审）

```tsx
// CSS Modules 示例
import styles from './UserCard.module.css'

// Tailwind 示例
<div className="flex items-center gap-4 p-4 rounded-lg bg-white shadow-sm">
```

## 组件分层

| 层 | 定位 | 示例 |
|---|---|---|
| **L1** | 通用 UI 组件（Button、Table、Form、Modal） | `components/ui/` |
| **L2** | 领域业务组件（UserSelector、RoleTree） | `components/business/` |
| **L3** | 页面组件（UserListPage、RoleManagePage） | `pages/` |

- **MUST** L1 组件纯展示 + 交互，不依赖业务逻辑
- **MUST** L2 组件可调用 API hooks
- **MUST** L3 组件串联 L1/L2，实现完整页面

## 构建工具链

- **MUST** Vite + `@vitejs/plugin-react`
- **MUST** TypeScript strict mode（`strict: true`）
- **SHOULD** `vite-plugin-svgr` 处理 SVG
- **SHOULD** `vite-tsconfig-paths` 简化路径别名

## 目录结构

```
src/
├── api/              # API 请求函数
├── components/       # 组件
│   ├── ui/           # L1 通用 UI
│   └── business/     # L2 领域组件
├── hooks/            # 自定义 Hooks (useXxx)
├── layouts/          # 布局组件
├── pages/            # L3 页面
├── router/           # React Router 配置
├── stores/           # Zustand / Redux stores
├── styles/           # 全局样式、CSS 变量
├── types/            # 共享 TypeScript 类型
├── utils/            # 工具函数
├── App.tsx
└── main.tsx
```
