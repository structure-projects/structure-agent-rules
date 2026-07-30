# Ionic 测试规则

> 角色：structure-tester（Ionic 测试）。面向编写 Ionic 测试代码的 AI Agent。

## 测试分层

| 层级 | 工具 | 覆盖范围 | 速度 |
|---|---|---|---|
| **单元测试** | Jasmine/Karma（Angular）、Jest（React/Vue） | Service、Provider、Utils | 快 |
| **组件测试** | Jasmine + `@ionic/angular-test`、Testing Library | Ionic 组件渲染 | 中 |
| **E2E 测试** | Cypress 或 Playwright | 完整页面流程 | 慢 |

## 单元测试

### Angular Service 测试

```typescript
import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { UserService } from './user.service';

describe('UserService', () => {
  let service: UserService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [UserService],
    });
    service = TestBed.inject(UserService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should fetch users', () => {
    const mockUsers = [{ id: 1, name: '张三' }];

    service.getUsers().subscribe(users => {
      expect(users).toEqual(mockUsers);
    });

    const req = httpMock.expectOne('/api/users');
    expect(req.request.method).toBe('GET');
    req.flush(mockUsers);
  });

  it('should handle error', () => {
    service.getUsers().subscribe({
      error: (err) => {
        expect(err.status).toBe(500);
      },
    });

    const req = httpMock.expectOne('/api/users');
    req.flush('Server error', { status: 500, statusText: 'Internal Server Error' });
  });
});
```

- **MUST** Angular Service 测试使用 `TestBed` + `HttpClientTestingModule`
- **MUST** 使用 `HttpTestingController` Mock HTTP 请求
- **MUST** `afterEach` 中调用 `httpMock.verify()` 确保无未处理请求

### React/Vue Service 测试

```typescript
import { renderHook, act } from '@testing-library/react';
import { useUserService } from './userService';

jest.mock('axios');
const mockedAxios = axios as jest.Mocked<typeof axios>;

describe('useUserService', () => {
  it('should fetch users', async () => {
    mockedAxios.get.mockResolvedValue({ data: [{ id: 1, name: '张三' }] });

    const { result } = renderHook(() => useUserService());
    
    await act(async () => {
      await result.current.fetchUsers();
    });

    expect(result.current.users).toHaveLength(1);
  });
});
```

- **MUST** 使用 Jest Mock 模拟外部依赖
- **MUST** 使用 `@testing-library/react-hooks` 测试 Custom Hook

## 组件测试

### Angular 组件测试

```typescript
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { IonicModule } from '@ionic/angular';
import { RouterTestingModule } from '@angular/router/testing';
import { UserListPage } from './user-list.page';

describe('UserListPage', () => {
  let component: UserListPage;
  let fixture: ComponentFixture<UserListPage>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [UserListPage],
      imports: [IonicModule.forRoot(), RouterTestingModule],
    }).compileComponents();

    fixture = TestBed.createComponent(UserListPage);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should render user list', () => {
    component.users = [
      { id: 1, name: '张三', email: 'zhang@test.com' },
    ];
    fixture.detectChanges();

    const compiled = fixture.nativeElement;
    expect(compiled.querySelector('ion-item')).toBeTruthy();
    expect(compiled.textContent).toContain('张三');
  });
});
```

- **MUST** 组件测试导入 `IonicModule.forRoot()`
- **MUST** 路由相关组件导入 `RouterTestingModule`
- **MUST** 使用 `fixture.detectChanges()` 触发变更检测
- **SHOULD** 使用 `data-testid` 属性定位关键元素

### React 组件测试

```tsx
import { render, screen } from '@testing-library/react';
import { IonApp, IonReactRouter } from '@ionic/react';
import { UserList } from './UserList';

describe('UserList', () => {
  it('should render users', () => {
    render(
      <IonApp>
        <IonReactRouter>
          <UserList users={[{ id: 1, name: '张三' }]} />
        </IonReactRouter>
      </IonApp>
    );

    expect(screen.getByText('张三')).toBeInTheDocument();
  });
});
```

- **MUST** 组件渲染包裹在 `IonApp` 中
- **MUST** 导航相关组件包裹在 `IonReactRouter` 中

### Vue 组件测试

```typescript
import { mount } from '@vue/test-utils';
import { IonicVue } from '@ionic/vue';
import UserList from './UserList.vue';

describe('UserList', () => {
  it('should render users', () => {
    const wrapper = mount(UserList, {
      global: {
        plugins: [IonicVue],
      },
      props: {
        users: [{ id: 1, name: '张三' }],
      },
    });

    expect(wrapper.text()).toContain('张三');
  });
});
```

- **MUST** 组件挂载引入 `IonicVue` 插件

## E2E 测试

### Cypress

```typescript
describe('Login Flow', () => {
  it('should login successfully', () => {
    cy.visit('/login');
    cy.get('[data-testid="email-input"]').type('test@example.com');
    cy.get('[data-testid="password-input"]').type('password123');
    cy.get('[data-testid="login-button"]').click();
    
    // 等待导航完成（Ionic 动画）
    cy.wait(1000);
    cy.url().should('include', '/home');
    cy.get('[data-testid="user-greeting"]').should('contain', '欢迎');
  });
});
```

- **MUST** 使用 `data-testid` 定位元素
- **MUST** 等待 Ionic 动画完成后再断言（`cy.wait()` 或 `cy.get()` 重试）
- **SHOULD** 多平台截图对比（Cypress 不同视口）

### Playwright

```typescript
import { test, expect } from '@playwright/test';

test('login flow', async ({ page }) => {
  await page.goto('/login');
  await page.fill('[data-testid="email-input"]', 'test@example.com');
  await page.fill('[data-testid="password-input"]', 'password123');
  await page.click('[data-testid="login-button"]');
  
  await page.waitForURL('**/home');
  await expect(page.locator('[data-testid="user-greeting"]')).toContainText('欢迎');
});
```

## 测试工作流

- **MUST** 每开发一个功能立即写单元测试，通过才能做下一个功能
- **MUST** 功能修改时同步修改测试并通过
- **MUST** 核心 Service 写单元测试
- **MUST** 核心页面写组件测试
- **MUST** 核心流程写 E2E 测试
- **MUST** 提交前 `npm run test` + `npm run lint` + `npx tsc --noEmit` 全部通过
- **禁止** 测试/Lint/类型检查失败仍提交

## 测试文件命名

| 类型 | 命名 | 位置 |
|---|---|---|
| 单元测试 | `{target}.spec.ts`（Angular）/ `{target}.test.ts`（React/Vue） | 与源文件同目录 |
| 组件测试 | `{component}.spec.ts`（Angular）/ `{component}.test.tsx`（React） | 与源文件同目录 |
| E2E | `{feature}.e2e.ts` | `e2e/` 或 `cypress/e2e/` 目录 |

## Capacitor 插件 Mock

```typescript
// Jest Mock 示例
jest.mock('@capacitor/camera', () => ({
  Camera: {
    getPhoto: jest.fn().mockResolvedValue({
      webPath: 'data:image/jpeg;base64,...',
    }),
  },
}));

jest.mock('@capacitor/preferences', () => ({
  Preferences: {
    get: jest.fn().mockResolvedValue({ value: 'mock-value' }),
    set: jest.fn().mockResolvedValue(undefined),
    remove: jest.fn().mockResolvedValue(undefined),
  },
}));
```

- **MUST** Capacitor 插件在测试中 Mock（Web 环境不可用）
- **MUST** Mock 返回合理的数据结构
