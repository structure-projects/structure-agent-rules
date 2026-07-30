# React 前端测试规则

> 角色：tester（前端）。面向编写 React 测试代码的 AI Agent。

## 测试分层

| 层级 | 工具 | 覆盖范围 | 速度 |
|---|---|---|---|
| **单元测试** | Vitest | Hooks、utils、stores | 快 |
| **组件测试** | Vitest + React Testing Library | 组件渲染、事件、Props | 中 |
| **E2E 测试** | Playwright | 完整用户流程 | 慢 |

## 单元测试（Vitest）

### 配置

```ts
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import tsconfigPaths from 'vite-tsconfig-paths'

export default defineConfig({
  plugins: [react(), tsconfigPaths()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test/setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov']
    }
  }
})
```

### setup 文件

```ts
// src/test/setup.ts
import '@testing-library/jest-dom'
```

### Hook 测试

```ts
// hooks/useCounter.test.ts
import { renderHook, act } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { useCounter } from '../useCounter'

describe('useCounter', () => {
  it('should increment', () => {
    const { result } = renderHook(() => useCounter())

    act(() => {
      result.current.increment()
    })

    expect(result.current.count).toBe(1)
  })

  it('should not go below 0', () => {
    const { result } = renderHook(() => useCounter({ min: 0 }))

    act(() => {
      result.current.decrement()
    })

    expect(result.current.count).toBe(0)
  })
})
```

### Store 测试（Zustand）

```ts
// stores/authStore.test.ts
import { describe, it, expect, beforeEach } from 'vitest'
import { useAuthStore } from '../authStore'

describe('authStore', () => {
  beforeEach(() => {
    useAuthStore.setState({ token: null, user: null })
  })

  it('should login successfully', async () => {
    const { login } = useAuthStore.getState()
    await login({ username: 'test', password: 'test' })

    const { token, user } = useAuthStore.getState()
    expect(token).toBeTruthy()
    expect(user).toBeTruthy()
  })

  it('should logout', () => {
    useAuthStore.setState({ token: 'xxx', user: { id: '1', name: 'Test' } })

    const { logout } = useAuthStore.getState()
    logout()

    const { token, user } = useAuthStore.getState()
    expect(token).toBeNull()
    expect(user).toBeNull()
  })
})
```

## 组件测试（React Testing Library）

```tsx
// components/UserCard.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import { UserCard } from '../UserCard'

describe('UserCard', () => {
  const mockUser = { id: '1', name: '张三', email: 'zhang@test.com' }

  it('renders user name', () => {
    render(<UserCard user={mockUser} />)
    expect(screen.getByText('张三')).toBeInTheDocument()
  })

  it('calls onEdit when edit button clicked', () => {
    const onEdit = vi.fn()
    render(<UserCard user={mockUser} onEdit={onEdit} />)

    fireEvent.click(screen.getByRole('button', { name: /编辑/i }))
    expect(onEdit).toHaveBeenCalledWith('1')
  })

  it('does not render delete button when onDelete not provided', () => {
    render(<UserCard user={mockUser} />)
    expect(screen.queryByRole('button', { name: /删除/i })).not.toBeInTheDocument()
  })
})
```

- **MUST** 查询优先使用 `getByRole`、`getByLabelText`、`getByText`（可访问性优先）
- **SHOULD** 仅在无合适语义查询时使用 `getByTestId`
- **MUST** 事件用 `fireEvent` 或 `@testing-library/user-event`

## E2E 测试（Playwright）

```ts
// e2e/user-management.spec.ts
import { test, expect } from '@playwright/test'

test.describe('用户管理', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/users')
  })

  test('增删改查全流程', async ({ page }) => {
    // 新增用户
    await page.click('[data-testid="add-user-btn"]')
    await page.fill('[data-testid="user-name-input"]', '测试用户')
    await page.fill('[data-testid="user-email-input"]', 'test@example.com')
    await page.click('[data-testid="confirm-btn"]')
    await expect(page.locator('text=测试用户')).toBeVisible()

    // 编辑用户
    await page.click('[data-testid="edit-btn-测试用户"]')
    await page.fill('[data-testid="user-name-input"]', '修改后用户')
    await page.click('[data-testid="confirm-btn"]')
    await expect(page.locator('text=修改后用户')).toBeVisible()

    // 删除用户
    await page.click('[data-testid="delete-btn-修改后用户"]')
    await page.click('[data-testid="confirm-delete-btn"]')
    await expect(page.locator('text=修改后用户')).not.toBeVisible()
  })
})
```

- **MUST** 使用 `data-testid` 作为选择器（非 CSS class 或文本脆弱匹配）
- **SHOULD** 使用 Playwright 的 `trace` 和 `video` 记录失败用例

## 测试工作流

- **MUST** 每开发一个功能立即写单元/组件测试
- **MUST** 功能修改时同步修改测试
- **MUST** 业务完成后写 E2E 测试覆盖核心流程
- **MUST** 提交前 `npm run test` 全部通过 + `npm run build` 编译通过
- **禁止** 测试/编译失败仍提交

## 测试文件命名

| 类型 | 命名 | 位置 |
|---|---|---|
| 单元测试 | `{target}.test.ts(x)` | 同目录 `__tests__/` 或相邻 |
| E2E 测试 | `{feature}.spec.ts` | `e2e/` 目录 |
