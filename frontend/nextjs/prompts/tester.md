# Next.js 前端测试规则

> 角色：tester（前端）。面向编写 Next.js 测试代码的 AI Agent。

## 测试分层

| 层级 | 工具 | 覆盖范围 | 速度 |
|---|---|---|---|
| **单元测试** | Vitest | utils、lib、Server Actions | 快 |
| **组件测试** | Vitest + React Testing Library | Client Components | 中 |
| **E2E 测试** | Playwright | 完整用户流程（含 SSR） | 慢 |

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

// Mock next/navigation
vi.mock('next/navigation', () => ({
  useRouter: () => ({
    push: vi.fn(),
    refresh: vi.fn(),
    back: vi.fn()
  }),
  usePathname: () => '/',
  useSearchParams: () => new URLSearchParams()
}))
```

### Server Action 测试

```ts
// app/actions/user.test.ts
import { describe, it, expect } from 'vitest'
import { createUser } from './user'

describe('createUser', () => {
  it('should validate required fields', async () => {
    const formData = new FormData()
    // 不填 name 和 email
    const result = await createUser(formData)
    expect(result.error).toBeDefined()
    expect(result.error?.fieldErrors.name).toBeDefined()
  })

  it('should validate email format', async () => {
    const formData = new FormData()
    formData.set('name', 'Test')
    formData.set('email', 'invalid-email')
    const result = await createUser(formData)
    expect(result.error?.fieldErrors.email).toBeDefined()
  })
})
```

### 工具函数测试

```ts
// lib/utils.test.ts
import { describe, it, expect } from 'vitest'
import { formatDate, cn } from '../utils'

describe('formatDate', () => {
  it('should format date to Chinese locale', () => {
    const date = new Date('2024-01-15')
    expect(formatDate(date)).toBe('2024年1月15日')
  })
})

describe('cn', () => {
  it('should merge Tailwind classes', () => {
    expect(cn('px-4 py-2', 'py-4')).toBe('px-4 py-4')
  })
})
```

## 组件测试（React Testing Library）

```tsx
// components/UserTable.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import { UserTable } from '../UserTable'

describe('UserTable', () => {
  const mockUsers = [
    { id: '1', name: '张三', email: 'zhang@test.com' },
    { id: '2', name: '李四', email: 'li@test.com' }
  ]

  it('renders user list', () => {
    render(<UserTable users={mockUsers} />)
    expect(screen.getByText('张三')).toBeInTheDocument()
    expect(screen.getByText('李四')).toBeInTheDocument()
  })

  it('calls onDelete when delete button clicked', () => {
    const onDelete = vi.fn()
    render(<UserTable users={mockUsers} onDelete={onDelete} />)

    fireEvent.click(screen.getAllByRole('button', { name: /删除/i })[0])
    expect(onDelete).toHaveBeenCalledWith('1')
  })

  it('shows empty state when no users', () => {
    render(<UserTable users={[]} />)
    expect(screen.getByText(/暂无数据/i)).toBeInTheDocument()
  })
})
```

- **MUST** 查询优先使用 `getByRole`、`getByLabelText`、`getByText`
- **MUST** Mock `next/navigation` 的 hooks
- **SHOULD** 测试 loading 和 error 状态

## E2E 测试（Playwright）

```ts
// e2e/auth.spec.ts
import { test, expect } from '@playwright/test'

test.describe('认证流程', () => {
  test('登录到仪表盘', async ({ page }) => {
    await page.goto('/login')

    await page.fill('[data-testid="email-input"]', 'test@example.com')
    await page.fill('[data-testid="password-input"]', 'password123')
    await page.click('[data-testid="login-btn"]')

    await expect(page).toHaveURL('/dashboard')
    await expect(page.locator('[data-testid="user-name"]')).toContainText('Test User')
  })

  test('未登录重定向到登录页', async ({ page }) => {
    await page.goto('/dashboard')
    await expect(page).toHaveURL('/login')
  })
})
```

```ts
// e2e/user-crud.spec.ts
import { test, expect } from '@playwright/test'

test.describe('用户管理 CRUD', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login')
    await page.fill('[data-testid="email-input"]', 'admin@test.com')
    await page.fill('[data-testid="password-input"]', 'admin123')
    await page.click('[data-testid="login-btn"]')
    await page.goto('/dashboard/users')
  })

  test('创建用户', async ({ page }) => {
    await page.click('[data-testid="create-user-btn"]')
    await page.fill('[data-testid="user-name-input"]', '新用户')
    await page.fill('[data-testid="user-email-input"]', 'new@test.com')
    await page.click('[data-testid="submit-btn"]')

    await expect(page.locator('text=新用户')).toBeVisible()
  })
})
```

- **MUST** 使用 `data-testid` 作为选择器
- **MUST** E2E 测试覆盖认证流程 + 核心 CRUD
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
