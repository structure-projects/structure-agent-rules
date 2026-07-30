# UniApp 前端测试规则

> 角色：uniapp-tester（前端）。面向编写 UniApp 测试代码的 AI Agent。

## 测试分层

| 层级 | 工具 | 覆盖范围 | 速度 |
|---|---|---|---|
| **单元测试** | Vitest | utils、stores、纯函数 | 快 |
| **组件测试** | Vitest + @vue/test-utils | 组件渲染、Props/Emits | 中 |
| **端到端测试** | 各平台真机调试 | 完整用户流程 | 慢 |

> 注意：UniApp 跨平台特性决定了 E2E 测试主要依赖真机调试，自动化 E2E 在各平台差异较大。

## 测试配置

### Vitest 配置

```ts
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import uni from '@dcloudio/vite-plugin-uni';

export default defineConfig({
  plugins: [uni()],
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

- **MUST** 包含 `@dcloudio/vite-plugin-uni` 插件
- **MUST** 使用 `jsdom` 环境

## 单元测试

### Store 测试

```ts
// user.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { useUserStore } from '../user';

describe('userStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it('should login and set token', () => {
    const store = useUserStore();
    store.setToken('test-token');
    expect(store.token).toBe('test-token');
    expect(store.isLogin).toBe(true);
  });

  it('should logout and clear token', () => {
    const store = useUserStore();
    store.setToken('test-token');
    store.logout();
    expect(store.token).toBe('');
    expect(store.isLogin).toBe(false);
  });
});
```

### 工具函数测试

```ts
// utils.test.ts
import { describe, it, expect } from 'vitest';
import { formatDate, formatPrice } from '../utils';

describe('utils', () => {
  it('should format date', () => {
    expect(formatDate('2024-01-15')).toBe('2024年1月15日');
  });

  it('should format price', () => {
    expect(formatPrice(1234.5)).toBe('1,234.50');
  });
});
```

## 组件测试

```ts
// user-card.test.ts
import { describe, it, expect } from 'vitest';
import { mount } from '@vue/test-utils';
import UserCard from '../UserCard.vue';

describe('UserCard', () => {
  it('renders user name', () => {
    const wrapper = mount(UserCard, {
      props: {
        userName: '张三',
        email: 'zhang@test.com'
      }
    });
    expect(wrapper.text()).toContain('张三');
  });

  it('emits tap event', async () => {
    const wrapper = mount(UserCard, {
      props: {
        userName: '张三',
        email: 'zhang@test.com'
      }
    });
    await wrapper.find('.user-card').trigger('tap');
    expect(wrapper.emitted('tap')).toBeTruthy();
  });
});
```

## API 请求测试

```ts
// user-api.test.ts
import { describe, it, expect, vi } from 'vitest';
import { getUserInfo } from '../user';

// Mock uni.request
vi.mock('@/api/request', () => ({
  request: vi.fn((options) => {
    if (options.url === '/user/info') {
      return Promise.resolve({ id: '1', name: 'Test' });
    }
    return Promise.reject(new Error('Not found'));
  })
}));

describe('user API', () => {
  it('should fetch user info', async () => {
    const user = await getUserInfo();
    expect(user.name).toBe('Test');
  });
});
```

## 真机测试清单

由于 UniApp 跨平台特性，以下场景需要真机验证：

| 平台 | 验证项 |
|---|---|
| **微信小程序** | 登录流程、分享、支付、地图、相机 |
| **H5** | 路由、响应式布局、浏览器兼容性 |
| **App** | 原生模块、推送、离线包 |

- **MUST** 小程序功能在微信开发者工具 + 真机预览中验证
- **SHOULD** H5 功能在主流移动浏览器中验证
- **MAY** App 功能在 HBuilderX 基座中调试

## 测试工作流

- **MUST** 每开发一个功能立即写单元测试
- **MUST** 功能修改时同步修改测试
- **MUST** 业务完成后在目标平台真机验证核心流程
- **MUST** 提交前 `npm run test` 全部通过
- **MUST** 提交前所有目标平台 `npm run build` 编译通过
- **禁止** 测试/编译失败仍提交

## 测试文件命名

| 类型 | 命名 | 位置 |
|---|---|---|
| 单元测试 | `{name}.test.ts` | 与源文件同目录或 `__tests__/` |
