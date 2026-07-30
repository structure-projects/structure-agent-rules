# Angular 前端开发规则

> 角色：angular-developer（前端）。面向开发 Angular 应用的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。

## 硬约束

- **MUST** Angular 17+，优先 Standalone Components API。
- **MUST** TypeScript 严格模式（`strict: true`）。
- **MUST** 使用 Angular CLI 生成组件/服务/指令/管道（`ng generate`）。
- **MUST** RxJS 用于异步操作（HTTP 请求、事件流），配合 Signals 管理同步状态。
- **SHOULD** 使用 Angular Material 或 PrimeNG 作为 UI 组件库。
- **SHOULD** SCSS 作为样式预处理器。

## 关键优先级

- **组件模式**：Standalone Components > NgModules
- **状态管理**：Signals（组件级）→ RxJS Services（跨组件）→ NgRx（大型应用）
- **路由**：懒加载（`loadComponent` / `loadChildren`）
- **DI**：`@Injectable({ providedIn: 'root' })` 或 `inject()` 函数

## 组件规范

### 组件结构

```ts
import { Component, input, output, signal, computed, effect, inject } from '@angular/core';
import { UserService } from '../../core/services/user.service';

@Component({
  selector: 'app-user-list',
  standalone: true,
  imports: [CommonModule, MatTableModule],
  templateUrl: './user-list.component.html',
  styleUrls: ['./user-list.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class UserListComponent implements OnInit {
  private userService = inject(UserService);
  
  // Signals
  users = signal<User[]>([]);
  loading = signal(false);
  
  // Inputs/Outputs
  filter = input<string>('');
  selected = output<User>();
  
  // Computed
  filteredUsers = computed(() => 
    this.users().filter(u => u.name.includes(this.filter()))
  );

  ngOnInit() {
    this.loadUsers();
  }

  private async loadUsers() {
    this.loading.set(true);
    this.users.set(await this.userService.getUsers());
    this.loading.set(false);
  }
}
```

### 命名

- **MUST** 组件文件：`{name}.component.ts`（kebab-case）
- **MUST** 组件类：`{Name}Component`（PascalCase）
- **MUST** selector：`app-{name}`（kebab-case 前缀）
- **MUST** 模板文件：`{name}.component.html`
- **MUST** 样式文件：`{name}.component.scss`

### 变更检测

- **MUST** 使用 `ChangeDetectionStrategy.OnPush`（推荐默认）
- **SHOULD** Signals 自动触发变更检测（无需手动 `markForCheck()`）
- **MAY** RxJS Observable 配合 `async` 管道使用

## 服务规范

```ts
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class UserService {
  private http = inject(HttpClient);
  private baseUrl = '/api/users';

  getUsers(): Observable<User[]> {
    return this.http.get<User[]>(this.baseUrl);
  }

  getUser(id: string): Observable<User> {
    return this.http.get<User>(`${this.baseUrl}/${id}`);
  }

  createUser(user: Partial<User>): Observable<User> {
    return this.http.post<User>(this.baseUrl, user);
  }

  updateUser(id: string, user: Partial<User>): Observable<User> {
    return this.http.put<User>(`${this.baseUrl}/${id}`, user);
  }

  deleteUser(id: string): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
```

- **MUST** 服务使用 `@Injectable({ providedIn: 'root' })` 实现单例
- **SHOULD** 使用 `inject()` 替代构造函数注入
- **MUST** HTTP 调用通过 `HttpClient`（在 `app.config.ts` 中 `provideHttpClient()`）
- **MUST** HTTP 拦截器（认证、错误处理）在 `app.config.ts` 注册

## 路由规范

```ts
// app.routes.ts
import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: 'users',
    loadChildren: () => import('./features/user/user.routes').then(m => m.userRoutes)
  },
  {
    path: '',
    redirectTo: '/dashboard',
    pathMatch: 'full'
  },
  {
    path: '**',
    loadComponent: () => import('./shared/components/not-found.component').then(m => m.NotFoundComponent)
  }
];
```

- **MUST** 特性模块路由独立文件（`{feature}.routes.ts`）
- **MUST** 使用 `loadChildren` 或 `loadComponent` 实现懒加载
- **SHOULD** 使用函数式守卫（`() => inject(AuthGuard).canActivate()`）
- **MUST** 配置 `path: '**'` 通配 404 页面

## 样式规范

- **MUST** 使用 SCSS
- **SHOULD** 利用 Angular ViewEncapsulation（默认 `Emulated`）
- **禁止** 在全局 `styles.scss` 中使用深层选择器（`::ng-deep` 仅作为最后手段）
- **SHOULD** 使用 CSS 变量或主题变量实现主题化

## 表单规范

```ts
// Reactive Forms（推荐）
import { FormBuilder, Validators, ReactiveFormsModule } from '@angular/forms';

@Component({...})
export class UserFormComponent {
  private fb = inject(FormBuilder);
  
  form = this.fb.group({
    name: ['', [Validators.required, Validators.minLength(2)]],
    email: ['', [Validators.required, Validators.email]]
  });

  submit() {
    if (this.form.valid) {
      this.userService.createUser(this.form.value).subscribe();
    }
  }
}
```

- **SHOULD** 优先使用 Reactive Forms（复杂表单）
- **MAY** Template-driven Forms 用于简单表单
- **MUST** 表单校验使用 Angular Validators（内置 + 自定义）

## 测试工作流

- 每开发一个功能**立即**写单元测试，**单测通过才能做下一个功能**
- 功能有修改时**同步修改测试**并通过
- 业务完成后写**E2E 测试**（Playwright 或 Cypress），通过才算交付
- **提交前**：`ng test --no-watch --code-coverage` 全部通过 + `ng build` 编译通过
- **禁止** 测试/编译失败仍提交
