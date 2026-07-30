# Vue 3 前端测试规则

> 角色：structure-tester（前端）。面向编写 Vue 3 测试代码的 AI Agent。

## 测试分层

| 层级 | 工具 | 覆盖范围 | 速度 |
|---|---|---|---|
| **单元测试** | Vitest | composables、utils、stores | 快 |
| **组件测试** | Vitest + Vue Test Utils | 组件渲染、事件、Props/Emits | 中 |
| **E2E 测试** | Playwright | 完整用户流程 | 慢 |

## 单元测试（Vitest）

### 配置

```ts
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  test: {
    environment: 'jsdom',
    globals: true,
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov']
    }
  }
})
```

### composable 测试

```ts
// useCounter.test.ts
import { describe, it, expect } from 'vitest'
import { useCounter } from '../useCounter'

describe('useCounter', () => {
  it('should increment', () => {
    const { count, increment } = useCounter()
    expect(count.value).toBe(0)
    increment()
    expect(count.value).toBe(1)
  })
})
```

### store 测试

```ts
// userStore.test.ts
import { setActivePinia, createPinia } from 'pinia'
import { useUserStore } from '../user'

describe('userStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('should fetch users', async () => {
    const store = useUserStore()
    await store.fetchUsers()
    expect(store.users).toHaveLength(10)
  })
})
```

## 组件测试（Vue Test Utils）

```ts
// UserCard.test.ts
import { mount } from '@vue/test-utils'
import { describe, it, expect } from 'vitest'
import UserCard from '../UserCard.vue'

describe('UserCard', () => {
  it('renders user name', () => {
    const wrapper = mount(UserCard, {
      props: { user: { name: '张三', email: 'zhang@test.com' } }
    })
    expect(wrapper.text()).toContain('张三')
  })

  it('emits delete event', async () => {
    const wrapper = mount(UserCard, { props: { user: mockUser } })
    await wrapper.find('[data-test="delete-btn"]').trigger('click')
    expect(wrapper.emitted('delete')).toBeTruthy()
  })
})
```

## E2E 测试（Playwright）

```ts
// e2e/user-management.spec.ts
import { test, expect } from '@playwright/test'

test.describe('用户管理', () => {
  test('增删改查全流程', async ({ page }) => {
    await page.goto('/users')

    // 新增
    await page.click('[data-test="add-user-btn"]')
    await page.fill('[data-test="user-name-input"]', '测试用户')
    await page.click('[data-test="confirm-btn"]')
    await expect(page.locator('.el-message--success')).toBeVisible()

    // 编辑
    await page.click('[data-test="edit-btn-测试用户"]')
    await page.fill('[data-test="user-name-input"]', '修改后用户')
    await page.click('[data-test="confirm-btn"]')

    // 删除
    await page.click('[data-test="delete-btn-修改后用户"]')
    await page.click('[data-test="confirm-delete-btn"]')
  })
})
```

## 测试工作流

- **MUST** 每开发一个功能立即写单元/组件测试
- **MUST** 功能修改时同步修改测试
- **MUST** 业务完成后写 E2E 测试覆盖核心流程
- **MUST** 提交前 `npm run test` 全部通过
- **MUST** 提交前 `npm run build` 编译通过
- **禁止** 测试/编译失败仍提交

## 测试文件命名

| 类型 | 命名 | 位置 |
|---|---|---|
| 单元测试 | `{target}.test.ts` | 同目录 `__tests__/` 或相邻 |
| E2E 测试 | `{feature}.spec.ts` | `e2e/` 目录 |
