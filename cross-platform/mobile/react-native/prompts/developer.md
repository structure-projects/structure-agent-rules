# React Native 开发规则

> 角色：structure-developer（React Native）。面向开发 React Native 应用的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。IDE 包装文件使用 `react-native-` 前缀。

## 硬约束

- **MUST** React Native 0.73+，开启 New Architecture
- **MUST** TypeScript strict 模式（`strict: true`）
- **MUST** 导航：React Navigation 6.x（`createNativeStackNavigator`）
- **MUST** 服务端状态：TanStack Query
- **MUST** 全局状态：Zustand（轻量）/ Redux Toolkit（复杂）
- **MUST** 引擎：Hermes（生产构建）
- **MUST** 样式：`StyleSheet.create()` 或 NativeWind
- **SHOULD** Expo 托管工作流（推荐）

## 关键优先级

- **项目初始化**：Expo > React Native CLI
- **状态管理**：TanStack Query（服务端）> Zustand（全局）> useState（局部）
- **导航**：React Navigation Native Stack > JS Stack
- **图片**：FastImage > Image
- **存储**：MMKV > AsyncStorage
- **动画**：Reanimated > Animated API

## 命名规范

- **MUST** 组件文件 PascalCase（`UserCard.tsx`）
- **MUST** Hook 文件 camelCase + `use` 前缀（`useUsers.ts`）
- **MUST** 工具文件 camelCase（`formatDate.ts`）
- **MUST** 类型文件 PascalCase（`User.ts` 或 `types.ts`）
- **MUST** 平台特定文件 `{name}.ios.tsx` / `{name}.android.tsx`
- **MUST** 测试文件 `{name}.test.tsx`

## 文件组织

```
src/
├── app/
│   ├── App.tsx                    # 根组件
│   └── navigation/
│       ├── RootNavigator.tsx
│       └── types.ts               # 导航类型
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── LoginScreen.tsx
│   │   │   └── RegisterScreen.tsx
│   │   ├── components/
│   │   │   └── LoginForm.tsx
│   │   ├── hooks/
│   │   │   └── useAuth.ts
│   │   └── api.ts
│   └── home/
│       ├── screens/
│       │   └── HomeScreen.tsx
│       └── components/
│           └── PostCard.tsx
├── shared/
│   ├── components/
│   │   ├── Button.tsx
│   │   ├── TextInput.tsx
│   │   └── LoadingIndicator.tsx
│   ├── hooks/
│   │   └── useDebounce.ts
│   ├── services/
│   │   ├── apiClient.ts
│   │   └── storage.ts
│   ├── stores/
│   │   ├── authStore.ts
│   │   └── settingsStore.ts
│   ├── types/
│   │   └── api.ts
│   └── utils/
│       ├── formatDate.ts
│       └── validation.ts
└── theme/
    ├── colors.ts
    ├── spacing.ts
    └── typography.ts
```

## 编码规范

### 组件

```tsx
// ✅ 正确：类型安全的组件
import React, { useCallback } from 'react'
import { View, Text, StyleSheet, Pressable } from 'react-native'

interface UserCardProps {
  user: User
  onPress?: (user: User) => void
}

export function UserCard({ user, onPress }: UserCardProps) {
  const handlePress = useCallback(() => {
    onPress?.(user)
  }, [user, onPress])

  return (
    <Pressable style={styles.container} onPress={handlePress}>
      <View style={styles.content}>
        <Text style={styles.name}>{user.name}</Text>
        <Text style={styles.email}>{user.email}</Text>
      </View>
    </Pressable>
  )
}

const styles = StyleSheet.create({
  container: {
    padding: 16,
    backgroundColor: '#fff',
    borderRadius: 8,
    marginBottom: 8
  },
  content: {
    flexDirection: 'column'
  },
  name: {
    fontSize: 16,
    fontWeight: '600'
  },
  email: {
    fontSize: 14,
    color: '#666',
    marginTop: 4
  }
})
```

- **MUST** 使用函数组件 + TypeScript 类型
- **MUST** Props 使用 `interface` 声明类型
- **MUST** 回调使用 `useCallback` 包裹
- **MUST** 样式使用 `StyleSheet.create()` 在组件外部定义

### Custom Hook

```tsx
// hooks/useUsers.ts
import { useQuery } from '@tanstack/react-query'
import { userService } from '../services/api'

export function useUsers() {
  return useQuery({
    queryKey: ['users'],
    queryFn: () => userService.getUsers(),
    staleTime: 5 * 60 * 1000
  })
}
```

- **MUST** API 调用封装在 Custom Hook 中
- **MUST** 使用 TanStack Query 的 `useQuery` / `useMutation`
- **MUST** 设置合理的 `queryKey` 和 `staleTime`

### API 客户端

```tsx
// services/apiClient.ts
import axios from 'axios'
import { useAuthStore } from '../stores/authStore'
import { storage } from './storage'

const apiClient = axios.create({
  baseURL: 'https://api.example.com',
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' }
})

// 请求拦截器：注入 Token
apiClient.interceptors.request.use((config) => {
  const token = storage.getString('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// 响应拦截器：统一错误处理
apiClient.interceptors.response.use(
  (response) => response.data,
  (error) => {
    if (error.response?.status === 401) {
      useAuthStore.getState().logout()
    }
    return Promise.reject(error)
  }
)

export default apiClient
```

- **MUST** 使用 axios 封装 HTTP 客户端
- **MUST** 请求拦截器自动注入 Token
- **MUST** 响应拦截器统一处理 401

## 平台适配

```tsx
import { Platform } from 'react-native'

const shadow = Platform.select({
  ios: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4
  },
  android: {
    elevation: 4
  }
})
```

- **MUST** 使用 `Platform.select()` 处理样式差异
- **MUST** 使用文件后缀 `.ios.tsx` / `.android.tsx` 分离逻辑差异

## 测试工作流

- **MUST** 每开发一个功能立即写单元测试（Jest + RNTL）
- **MUST** 功能修改时同步修改测试并通过
- **MUST** 核心流程写 E2E 测试（Detox）
- **MUST** 提交前 `npm run test` + `npm run lint` + `npx tsc --noEmit` 全部通过
- **禁止** 测试/Lint/类型检查失败仍提交

## 禁止事项

- **禁止** 使用 `any` 类型（TypeScript strict 模式）
- **禁止** 使用 `createStackNavigator`（用 Native Stack）
- **禁止** 在组件中直接调用 API（使用 Custom Hook）
- **禁止** 使用 `Animated` API（使用 Reanimated）
- **禁止** 使用 `Image` 加载远程图片（使用 FastImage）
- **禁止** 使用 AsyncStorage 存储敏感数据
- **禁止** 内联样式对象在 JSX 中
