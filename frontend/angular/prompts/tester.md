# Angular 前端测试规则

> 角色：angular-tester（前端）。面向编写 Angular 测试代码的 AI Agent。

## 测试分层

| 层级 | 工具 | 覆盖范围 | 速度 |
|---|---|---|---|
| **单元测试** | Jasmine/Karma 或 Jest | Services、Pipes、Guards | 快 |
| **组件测试** | TestBed + Jasmine/Karma | 组件渲染、Input/Output、DOM | 中 |
| **E2E 测试** | Playwright 或 Cypress | 完整用户流程 | 慢 |

## 测试配置

### Jasmine/Karma（默认）

```json
// karma.conf.js
module.exports = function (config) {
  config.set({
    frameworks: ['jasmine', '@angular-devkit/build-angular'],
    plugins: [
      require('karma-jasmine'),
      require('karma-chrome-launcher'),
      require('karma-coverage'),
      require('@angular-devkit/build-angular/plugins/karma')
    ],
    browsers: ['ChromeHeadless'],
    coverageReporter: {
      dir: require('path').join(__dirname, './coverage'),
      reporters: [{ type: 'lcov' }, { type: 'text-summary' }]
    },
    singleRun: true,
    restartOnFileChange: true
  });
};
```

- **MUST** CI 环境使用 `ChromeHeadless`
- **MUST** 开启 `codeCoverage: true`

## 服务测试

```ts
// user.service.spec.ts
import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { UserService } from './user.service';

describe('UserService', () => {
  let service: UserService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        UserService,
        provideHttpClient(),
        provideHttpClientTesting()
      ]
    });
    service = TestBed.inject(UserService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should fetch users', () => {
    const mockUsers = [{ id: '1', name: 'Test' }];
    
    service.getUsers().subscribe(users => {
      expect(users).toEqual(mockUsers);
    });

    const req = httpMock.expectOne('/api/users');
    expect(req.request.method).toBe('GET');
    req.flush(mockUsers);
  });
});
```

- **MUST** 使用 `HttpTestingController` 模拟 HTTP 请求
- **MUST** `afterEach` 中调用 `httpMock.verify()` 验证无未处理请求

## 组件测试（TestBed）

```ts
// user-card.component.spec.ts
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { UserCardComponent } from './user-card.component';

describe('UserCardComponent', () => {
  let component: UserCardComponent;
  let fixture: ComponentFixture<UserCardComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UserCardComponent]
    }).compileComponents();

    fixture = TestBed.createComponent(UserCardComponent);
    component = fixture.componentInstance;
  });

  it('should render user name', () => {
    fixture.componentRef.setInput('user', { name: '张三', email: 'zhang@test.com' });
    fixture.detectChanges();
    
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.textContent).toContain('张三');
  });

  it('should emit delete event', () => {
    const mockUser = { id: '1', name: 'Test' };
    fixture.componentRef.setInput('user', mockUser);
    
    let emittedId = '';
    component.delete.subscribe((id: string) => emittedId = id);
    
    const button = fixture.nativeElement.querySelector('[data-test="delete-btn"]');
    button.click();
    
    expect(emittedId).toBe('1');
  });
});
```

- **MUST** 使用 `fixture.componentRef.setInput()` 设置 Signals Input
- **MUST** 调用 `fixture.detectChanges()` 触发变更检测
- **SHOULD** 使用 `data-test` 属性定位元素

## E2E 测试（Playwright）

```ts
// e2e/user-management.spec.ts
import { test, expect } from '@playwright/test';

test.describe('用户管理', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/users');
  });

  test('新增用户', async ({ page }) => {
    await page.click('[data-test="add-user-btn"]');
    await page.fill('[data-test="user-name-input"]', '测试用户');
    await page.fill('[data-test="user-email-input"]', 'test@example.com');
    await page.click('[data-test="save-btn"]');
    await expect(page.locator('text=测试用户')).toBeVisible();
  });

  test('删除用户', async ({ page }) => {
    await page.click('[data-test="delete-btn-测试用户"]');
    await page.click('[data-test="confirm-delete-btn"]');
    await expect(page.locator('text=测试用户')).not.toBeVisible();
  });
});
```

## 测试工作流

- **MUST** 每开发一个功能立即写单元/组件测试
- **MUST** 功能修改时同步修改测试
- **MUST** 业务完成后写 E2E 测试覆盖核心流程
- **MUST** 提交前 `ng test --no-watch --code-coverage` 全部通过
- **MUST** 提交前 `ng build --configuration production` 编译通过
- **禁止** 测试/编译失败仍提交

## 测试文件命名

| 类型 | 命名 | 位置 |
|---|---|---|
| 单元测试 | `{name}.spec.ts` | 与源文件同目录 |
| E2E 测试 | `{feature}.spec.ts` | `e2e/` 目录 |
