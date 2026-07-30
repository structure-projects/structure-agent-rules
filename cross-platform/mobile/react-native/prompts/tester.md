# React Native 测试规则

> 角色：structure-tester（React Native 测试）。面向编写 React Native 测试代码的 AI Agent。

## 测试分层

| 层级 | 工具 | 覆盖范围 | 速度 |
|---|---|---|---|
| **单元测试** | Jest | Hooks、Utils、Services | 快 |
| **组件测试** | Jest + React Native Testing Library | 组件渲染、事件 | 中 |
| **E2E 测试** | Detox | 完整用户流程 | 慢 |

## 单元测试

### Jest 配置

```js
// jest.config.js
module.exports = {
  preset: 'react-native',
  setupFilesAfterSetup: ['./jest.setup.ts'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1'
  },
  transformIgnorePatterns: [
    'node_modules/(?!(react-native|@react-native|@react-navigation|react-native-reanimated|react-native-gesture-handler)/)'
  ]
}
```

- **MUST** 使用 `react-native` preset
- **MUST** 配置 `transformIgnorePatterns` 处理 RN 库
- **MUST** 配置 `moduleNameMapper` 映射路径别名

### Hook 测试

```tsx
import { renderHook, waitFor } from '@testing-library/react-native'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { useUsers } from '../useUsers'

// 包装器：提供 QueryClient
function createWrapper() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } }
  })
  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

describe('useUsers', () => {
  it('returns users on success', async () => {
    const { result } = renderHook(() => useUsers(), {
      wrapper: createWrapper()
    })
    
    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })
    
    expect(result.current.data).toHaveLength(10)
  })
})
```

- **MUST** Hook 测试使用 `renderHook` from RNTL
- **MUST** TanStack Query Hooks 需要 `QueryClientProvider` wrapper
- **MUST** 使用 `waitFor` 等待异步状态

## 组件测试（React Native Testing Library）

```tsx
import { render, screen, fireEvent } from '@testing-library/react-native'
import { UserCard } from '../UserCard'

describe('UserCard', () => {
  const mockUser = { id: 1, name: '张三', email: 'zhang@test.com' }
  
  it('renders user name and email', () => {
    render(<UserCard user={mockUser} />)
    
    expect(screen.getByText('张三')).toBeTruthy()
    expect(screen.getByText('zhang@test.com')).toBeTruthy()
  })
  
  it('calls onPress when pressed', () => {
    const onPress = jest.fn()
    render(<UserCard user={mockUser} onPress={onPress} />)
    
    fireEvent.press(screen.getByText('张三'))
    expect(onPress).toHaveBeenCalledWith(mockUser)
  })
  
  it('shows loading indicator', () => {
    render(<UserCard user={mockUser} loading />)
    expect(screen.getByAccessibilityHint('加载中')).toBeTruthy()
  })
})
```

- **MUST** 使用 `render` from `@testing-library/react-native`
- **MUST** 使用 `screen.getByText()` / `screen.getByTestId()` 查询元素
- **MUST** 使用 `fireEvent` 模拟用户交互
- **MUST** 使用 `jest.fn()` 创建 mock 回调

### Mock 配置

```tsx
// __mocks__/react-native-fast-image.tsx
import React from 'react'
import { Image } from 'react-native'

const FastImage = (props: React.ComponentProps<typeof Image>) => {
  return <Image {...props} />
}

export default FastImage
```

- **MUST** 为原生模块创建 mock（`__mocks__/` 目录）
- **MUST** mock 返回基本功能即可

## E2E 测试（Detox）

```tsx
// e2e/login.test.ts
describe('登录流程', () => {
  beforeAll(async () => {
    await device.launchApp()
  })
  
  it('should login successfully', async () => {
    await element(by.id('username-input')).typeText('admin')
    await element(by.id('password-input')).typeText('password')
    await element(by.id('login-button')).tap()
    
    await expect(element(by.id('home-screen'))).toBeVisible()
  })
})
```

- **MUST** E2E 使用 Detox 框架
- **MUST** 使用 `testID` 定位元素
- **MUST** 覆盖核心业务流程

## 测试工作流

- **MUST** 每开发一个功能立即写单元测试，通过才能做下一个功能
- **MUST** 功能修改时同步修改测试并通过
- **MUST** 核心页面写组件测试（RNTL）
- **MUST** 核心流程写 E2E 测试（Detox）
- **MUST** 提交前 `npm run test` + `npm run lint` + `npx tsc --noEmit` 全部通过
- **禁止** 测试/Lint/类型检查失败仍提交

## 测试文件命名

| 类型 | 命名 | 位置 |
|---|---|---|
| 单元测试 | `{target}.test.ts(x)` | 同目录 `__tests__/` 或相邻 |
| E2E 测试 | `{feature}.test.ts` | `e2e/` 目录 |
