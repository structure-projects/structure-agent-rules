# Svelte 前端测试规则

> 角色：svelte-tester（前端）。面向编写 Svelte 测试代码的 AI Agent。

## 测试分层

| 层级 | 工具 | 覆盖范围 | 速度 |
|---|---|---|---|
| **单元测试** | Vitest | utils、stores、纯函数 | 快 |
| **组件测试** | Vitest + @testing-library/svelte | 组件渲染、事件、Props | 中 |
| **E2E 测试** | Playwright | 完整用户流程 | 慢 |

## 测试配置

### Vitest 配置

```ts
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'jsdom',
    include: ['src/**/*.{test,spec}.{js,ts}'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov']
    }
  }
});
```

- **MUST** 使用 `jsdom` 环境
- **MUST** 开启 `coverage` 配置

## 单元测试

### Store 测试

```ts
// user.test.ts
import { describe, it, expect } from 'vitest';
import { get } from 'svelte/store';
import { users, addUser, removeUser } from './user';

describe('user store', () => {
  it('should add user', () => {
    addUser({ id: '1', name: 'Test' });
    expect(get(users)).toHaveLength(1);
  });

  it('should remove user', () => {
    addUser({ id: '1', name: 'Test' });
    removeUser('1');
    expect(get(users)).toHaveLength(0);
  });
});
```

- **MUST** 使用 `get()` 读取 store 当前值

### 工具函数测试

```ts
// utils.test.ts
import { describe, it, expect } from 'vitest';
import { formatDate } from './utils';

describe('formatDate', () => {
  it('should format date correctly', () => {
    const result = formatDate('2024-01-15');
    expect(result).toBe('2024年1月15日');
  });
});
```

## 组件测试（@testing-library/svelte）

```ts
// UserCard.test.ts
import { describe, it, expect } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/svelte';
import UserCard from './UserCard.svelte';

describe('UserCard', () => {
  it('renders user name', () => {
    render(UserCard, {
      props: { name: '张三', email: 'zhang@test.com' }
    });
    expect(screen.getByText('张三')).toBeInTheDocument();
  });

  it('emits delete event on button click', async () => {
    const { component } = render(UserCard, {
      props: { name: 'Test', onDelete: () => {} }
    });

    const mockDelete = vi.fn();
    component.$on('delete', mockDelete);

    const button = screen.getByRole('button', { name: /delete/i });
    await fireEvent.click(button);

    expect(mockDelete).toHaveBeenCalled();
  });
});
```

### 测试 Svelte 5 Runes 组件

```ts
// Counter.test.ts (Svelte 5)
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/svelte';
import Counter from './Counter.svelte';

describe('Counter', () => {
  it('renders initial count', () => {
    render(Counter, {
      props: { initial: 5 }
    });
    expect(screen.getByText('5')).toBeInTheDocument();
  });
});
```

## E2E 测试（Playwright）

```ts
// e2e/user-flow.spec.ts
import { test, expect } from '@playwright/test';

test.describe('用户管理', () => {
  test('完整用户流程', async ({ page }) => {
    await page.goto('/users');

    // 验证列表加载
    await expect(page.getByText('用户列表')).toBeVisible();

    // 新增
    await page.click('[data-test="add-user-btn"]');
    await page.fill('[data-test="user-name-input"]', '测试用户');
    await page.click('[data-test="save-btn"]');
    await expect(page.getByText('测试用户')).toBeVisible();

    // 删除
    await page.click('[data-test="delete-btn"]');
    await page.click('[data-test="confirm-btn"]');
    await expect(page.getByText('测试用户')).not.toBeVisible();
  });
});
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
| 单元测试 | `{name}.test.ts` | 与源文件同目录或 `__tests__/` |
| E2E 测试 | `{feature}.spec.ts` | `tests/` 或 `e2e/` 目录 |
