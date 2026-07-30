# CLAUDE.md — Angular 前端技术栈

本文件为 Angular 前端技术栈规则，供 AI Agent 理解 Angular 技术栈约定。

## 生态坐标

| 维度 | 值 | 说明 |
|---|---|---|
| 框架 | Angular 17+ | 优先 Standalone Components |
| 语言 | TypeScript 5.x+ | strict 模式 |
| 样式 | SCSS | ViewEncapsulation 默认 |
| UI 库 | Angular Material / PrimeNG | 二选一 |
| 状态管理 | Signals + RxJS | 可选 NgRx |
| 测试 | Jasmine/Karma 或 Jest | 组件测试用 TestBed |
| E2E | Playwright 或 Cypress | |
| 构建 | Angular CLI + esbuild | AOT 编译 |
| Node.js | 20 LTS | |

## 项目结构

```
src/app/
├── core/          # 单例服务、守卫、拦截器
├── shared/        # 共享组件/指令/管道
├── features/      # 业务领域（懒加载）
├── layouts/       # 布局组件
├── app.component.ts
├── app.config.ts  # 应用 providers
└── app.routes.ts  # 根路由
```

## 关键技术事实

- Standalone Components (`standalone: true`) 是默认选择，避免 NgModules。
- Signals API (`input()`, `output()`, `model()`) 替代 `@Input()`/`@Output()` 装饰器。
- `@Injectable({ providedIn: 'root' })` 实现树摇友好的 DI。
- `inject()` 函数替代构造函数注入。
- `ChangeDetectionStrategy.OnPush` 为推荐默认值。
- `loadComponent` / `loadChildren` 实现路由懒加载。
- HTTP 拦截器在 `app.config.ts` 中通过 `withInterceptors()` 注册。
- RxJS 订阅必须在 `ngOnDestroy()` 中清理（或使用 `takeUntilDestroyed()`）。
