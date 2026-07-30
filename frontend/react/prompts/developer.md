# React 前端开发规则

> 角色：developer（前端）。面向 React 前端开发的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。

## 硬约束

- **MUST** 技术栈：React 18+ + TypeScript strict + Vite
- **MUST** Functional Components + Hooks（**禁止** Class Component）
- **MUST** Node.js 20 LTS
- **MUST** ESLint + Prettier 统一代码风格
- **MUST** 环境变量通过 `.env` 文件管理（`VITE_` 前缀暴露给客户端）

## 关键优先级

- **状态管理**：服务端数据 → TanStack Query，客户端全局状态 → Zustand/Redux Toolkit，组件局部状态 → useState/useReducer
- **路由**：React Router v6 懒加载
- **样式**：Tailwind CSS 或 CSS Modules，禁止 inline styles

## 组件规范

### 命名
- **MUST** 组件文件名 PascalCase（`UserTable.tsx`）
- **MUST** Hook 文件名 camelCase，以 `use` 开头（`useUsers.ts`）
- **MUST** 工具函数文件名 camelCase（`formatDate.ts`）

### 文件组织
```
src/
├── api/userApi.ts        # API 请求函数
├── components/
│   ├── ui/Button.tsx     # L1 通用组件
│   └── business/         # L2 业务组件
├── hooks/useUsers.ts     # 自定义 Hook
├── pages/users/          # 页面
│   ├── UserListPage.tsx
│   └── UserDetailPage.tsx
├── stores/userStore.ts   # Zustand store
├── types/user.ts         # 类型定义
└── utils/format.ts       # 工具函数
```

### Props 与 Events

```tsx
interface UserCardProps {
  user: User                    // 必传
  onEdit?: (id: string) => void // 可选回调
  className?: string            // 样式扩展
}

export const UserCard = ({ user, onEdit, className }: UserCardProps) => {
  // ...
}
```

- **MUST** Props 用 `interface` 声明（非 `type`）
- **MUST** 事件回调以 `on` 前缀命名（`onEdit`、`onDelete`）
- **MUST** 允许 `className` prop 用于外部样式扩展

## 状态管理（Zustand）

```ts
// stores/authStore.ts
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface AuthState {
  token: string | null
  user: User | null
  login: (credentials: LoginDTO) => Promise<void>
  logout: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      user: null,
      login: async (credentials) => {
        const res = await authApi.login(credentials)
        set({ token: res.token, user: res.user })
      },
      logout: () => set({ token: null, user: null })
    }),
    { name: 'auth-storage' }
  )
)
```

- **MUST** 需要持久化的状态用 `persist` middleware
- **MUST** 按领域拆分 store 文件
- **禁止** 在 store 中直接操作 DOM

## 请求规范

```ts
// api/userApi.ts
import { apiClient } from './client'

export const userApi = {
  getList: (params: UserQuery) =>
    apiClient.get<UserPage>('/api/users', { params }),

  getById: (id: string) =>
    apiClient.get<User>('/api/users/' + id),

  create: (data: CreateUserDTO) =>
    apiClient.post<User>('/api/users', data),

  update: (id: string, data: UpdateUserDTO) =>
    apiClient.put<User>('/api/users/' + id, data),

  delete: (id: string) =>
    apiClient.delete('/api/users/' + id)
}
```

- **MUST** API 请求封装到 `api/` 目录
- **MUST** 统一使用 axios 或 fetch 封装的 HTTP client
- **MUST** 请求/响应类型声明完整

## 环境配置

```env
# .env.development
VITE_API_BASE_URL=http://localhost:8080
VITE_APP_TITLE=My App (Dev)

# .env.production
VITE_API_BASE_URL=https://api.example.com
VITE_APP_TITLE=My App
```

- **MUST** 客户端暴露的变量用 `VITE_` 前缀
- **禁止** 在 `.env` 中存储密钥/Token

## 测试工作流

- 每开发一个功能 **立即** 写单元测试，**单测通过才能做下一个功能**
- 功能有修改时 **同步修改测试** 并通过
- 业务完成后写 **E2E 测试**（Playwright），通过才算交付
- **提交前**：`npm run test` 全部通过 + `npm run lint` 无报错 + `npm run build` 编译通过
- **禁止** 测试/编译失败仍提交
