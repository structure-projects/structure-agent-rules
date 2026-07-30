# Angular 前端架构规则

> 角色：angular-architect（前端架构）。面向需要做 Angular 前端架构选型与技术决策的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。

## Angular 版本与模块化

### 版本策略

- **MUST** 使用 Angular 17+，优先采用 Standalone Components API。
- **SHOULD** 新项目默认使用 Standalone API，避免创建 NgModules。
- **MAY** 遗留项目保留 NgModules，逐步迁移到 Standalone。

### 项目结构

```
src/
├── app/
│   ├── core/               # 单例服务、守卫、拦截器
│   │   ├── guards/
│   │   ├── interceptors/
│   │   └── services/
│   ├── shared/             # 共享模块（组件、指令、管道）
│   │   ├── components/
│   │   ├── directives/
│   │   └── pipes/
│   ├── features/           # 特性模块（懒加载）
│   │   ├── user/
│   │   ├── product/
│   │   └── ...
│   ├── layouts/            # 布局组件
│   ├── app.component.ts    # Standalone 根组件
│   ├── app.config.ts       # 应用配置（providers）
│   └── app.routes.ts       # 根路由配置
├── environments/
├── assets/
└── styles/
```

- **MUST** `core/` 仅包含单例服务（`@Injectable({ providedIn: 'root' })`）
- **MUST** `shared/` 包含可复用的 Component、Directive、Pipe
- **MUST** `features/` 按业务领域划分，支持懒加载

## 路由架构

### 懒加载

```ts
// app.routes.ts
export const routes: Routes = [
  {
    path: 'users',
    loadChildren: () => import('./features/user/user.routes').then(m => m.userRoutes)
  },
  {
    path: 'products',
    loadComponent: () => import('./features/product/product-list.component').then(m => m.ProductListComponent)
  }
];
```

- **MUST** 特性模块使用 `loadChildren` 或 `loadComponent` 懒加载
- **SHOULD** 使用 `PreloadAllModules` 或自定义预加载策略优化首屏
- **MUST** 路由守卫放 `core/guards/`，使用 `canActivate` 函数式守卫（Angular 15+）

## 状态管理

### 方案选型

| 方案 | 适用场景 | 复杂度 |
|---|---|---|
| **Angular Signals** | 组件内/跨组件轻量状态 | 低 |
| **RxJS + Services** | 复杂异步流、HTTP 缓存 | 中 |
| **NgRx Store** | 大型企业应用全局状态 | 高 |

- **SHOULD** 优先使用 Angular Signals（`signal()`、`computed()`、`effect()`）管理组件状态
- **SHOULD** RxJS 用于 HTTP 数据流和复杂异步场景
- **MAY** 大型应用引入 NgRx，但需评估收益

### Signals 模式

```ts
// user.store.ts (Signal-based store)
import { signal, computed } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class UserStore {
  private state = signal<UserState>({ users: [], loading: false });
  
  readonly users = computed(() => this.state().users);
  readonly loading = computed(() => this.state().loading);
  
  loadUsers() {
    this.state.update(s => ({ ...s, loading: true }));
    // HTTP call...
  }
}
```

## 依赖注入

- **MUST** 服务使用 `@Injectable({ providedIn: 'root' })` 实现树摇
- **SHOULD** 使用 `inject()` 函数替代构造函数注入（更简洁）
- **MUST** HTTP 拦截器在 `app.config.ts` 通过 `provideHttpClient(withInterceptors([...]))` 注册

## CSS 方案

- **MUST** 使用 SCSS（`styleUrls` 或内联 `styles`）
- **SHOULD** 利用 Angular ViewEncapsulation 隔离样式（默认 `Emulated`）
- **MAY** 引入 Tailwind CSS 或 Angular Material 主题系统
- **禁止** 在 `styles.scss` 中使用深层选择器覆盖第三方组件样式

## UI 组件库

- **SHOULD** 使用 Angular Material（官方）或 PrimeNG（社区）
- **MUST** UI 库通过 `app.config.ts` 的 providers 统一注册
- **禁止** 同时引入多个功能重叠的 UI 库

## 构建工具链

- **MUST** Angular CLI 为默认构建工具
- **MUST** TypeScript 严格模式（`strict: true`）
- **MUST** 生产构建开启 AOT 编译（默认）
- **SHOULD** 使用 esbuild 构建器（`@angular-devkit/build-angular:application`，Angular 17+）
