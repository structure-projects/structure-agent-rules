# React 组件使用规范

> 本文件描述 React 项目中的组件开发规范。
> 本规则自包含，不依赖其他技术栈目录。

## 组件类型

| 类型 | 命名 | 位置 | 说明 |
|---|---|---|---|
| UI 组件 | PascalCase `.tsx` | `components/ui/` | 通用，无业务逻辑 |
| 业务组件 | PascalCase `.tsx` | `components/business/` | 领域特定 |
| 页面组件 | PascalCase `.tsx` | `pages/` | 路由页面 |

## Functional Components

```tsx
// ✅ 推荐：函数组件 + TypeScript Props
interface UserCardProps {
  user: User
  onEdit?: (id: string) => void
  onDelete?: (id: string) => void
}

export const UserCard: React.FC<UserCardProps> = ({ user, onEdit, onDelete }) => {
  return (
    <div className="user-card">
      <h3>{user.name}</h3>
      <p>{user.email}</p>
      <button onClick={() => onEdit?.(user.id)}>编辑</button>
    </div>
  )
}
```

- **MUST** 所有组件为函数组件，**禁止** Class Component
- **MUST** Props 通过 `interface` 声明完整 TypeScript 类型
- **MUST** 文件命名 PascalCase（`UserCard.tsx`）
- **MUST** 使用命名导出 `export const Xxx`，避免默认导出滥用

## Hooks 规范

### 内置 Hooks

| Hook | 用途 | 注意事项 |
|---|---|---|
| `useState` | 组件本地状态 | 避免过多 useState，考虑 useReducer |
| `useEffect` | 副作用 | 必须声明依赖数组，清理函数 |
| `useCallback` | 缓存函数引用 | 配合 React.memo 使用 |
| `useMemo` | 缓存计算值 | 避免过度使用，仅在重计算时 |
| `useRef` | DOM 引用 / 可变值 | 不触发重渲染 |
| `useContext` | 跨层级数据传递 | 配合 createContext |

### 自定义 Hooks（useXxx 模式）

```tsx
// hooks/useUsers.ts
export const useUsers = () => {
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(false)

  const fetchUsers = useCallback(async (params: UserQuery) => {
    setLoading(true)
    try {
      const data = await userApi.getList(params)
      setUsers(data)
    } finally {
      setLoading(false)
    }
  }, [])

  return { users, loading, fetchUsers }
}
```

- **MUST** 可复用业务逻辑提取到 `hooks/useXxx.ts`
- **MUST** 自定义 Hook 以 `use` 开头
- **SHOULD** 返回对象而非数组（便于解构时重命名）

## TanStack Query（React Query）

```tsx
// hooks/useUsers.ts — 使用 TanStack Query
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

export const useUsers = (params: UserQuery) => {
  return useQuery({
    queryKey: ['users', params],
    queryFn: () => userApi.getList(params),
    staleTime: 5 * 60 * 1000 // 5 分钟
  })
}

export const useCreateUser = () => {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: userApi.create,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['users'] })
  })
}
```

- **MUST** 服务端状态使用 TanStack Query，**禁止** 手动管理 loading/error/data
- **MUST** mutation 成功后 invalidate 相关 queries
- **SHOULD** 配置 `staleTime` 避免不必要的重新请求

## Error Boundaries

```tsx
// components/ui/ErrorBoundary.tsx
import { Component, type ReactNode } from 'react'

interface Props {
  fallback?: ReactNode
  children: ReactNode
}

export class ErrorBoundary extends Component<Props, { hasError: boolean }> {
  state = { hasError: false }

  static getDerivedStateFromError() {
    return { hasError: true }
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback ?? <div>Something went wrong</div>
    }
    return this.props.children
  }
}
```

- **MUST** 关键路由/组件包裹 Error Boundary
- **SHOULD** 每个页面模块有独立的 Error Boundary

## 性能优化

- **SHOULD** 纯展示组件用 `React.memo` 包裹
- **SHOULD** 传递给子组件的回调用 `useCallback`
- **SHOULD** 复杂计算用 `useMemo`
- **SHOULD** 大列表用虚拟滚动（`@tanstack/react-virtual`）
- **SHOULD** 路由懒加载用 `React.lazy` + `Suspense`
