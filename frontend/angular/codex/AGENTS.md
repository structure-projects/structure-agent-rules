# AGENTS.md — Angular 前端规则（Codex 自包含模板）

> 本文件自包含，可直接拷贝到 Angular 前端项目根目录，供 Codex / 通用 AI Agent 自动加载。
> 修改规则时，请同步更新 `prompts/` 目录下的对应角色文件。

## 1. 硬约束

- **MUST** Angular 17+ Standalone Components API。
- **MUST** TypeScript 严格模式（`strict: true`）。
- **MUST** SCSS 样式预处理器。
- **MUST** Angular CLI 构建工具。
- **SHOULD** Angular Material 或 PrimeNG 作为 UI 组件库。

## 2. 组件规范

- 文件名 kebab-case（`user-card.component.ts`），类名 PascalCase（`UserCardComponent`）
- `standalone: true` 必须
- `imports` 数组明确声明依赖
- Signals API（`input()`、`output()`）替代装饰器
- `ChangeDetectionStrategy.OnPush` 推荐默认
- selector 使用 `app-` 前缀

## 3. 依赖注入

- `@Injectable({ providedIn: 'root' })` 单例服务
- `inject()` 替代构造函数注入
- HTTP 拦截器在 `app.config.ts` 注册：`provideHttpClient(withInterceptors([...]))`

## 4. 路由

- 懒加载：`loadComponent` / `loadChildren`
- 函数式守卫：`() => inject(AuthGuard).canActivate()`
- 独立路由文件：`{feature}.routes.ts`
- 配置 `path: '**'` 404 页面

## 5. 状态管理

- Signals（组件内/跨组件轻量状态）：`signal()`、`computed()`、`effect()`
- RxJS + Services（复杂异步流、HTTP 缓存）
- NgRx Store（大型企业应用全局状态，按需）

## 6. 样式

- SCSS + ViewEncapsulation（默认 `Emulated`）
- 使用 CSS 变量或主题变量实现主题化
- 禁止在全局 `styles.scss` 中使用深层选择器覆盖第三方样式

## 7. 表单

- Reactive Forms 优先（复杂表单）
- Template-driven Forms 用于简单表单
- 表单校验使用 Angular Validators（内置 + 自定义）

## 8. 测试

| 层级 | 工具 |
|---|---|
| 单元测试 | Jasmine/Karma 或 Jest |
| 组件测试 | TestBed + Jasmine/Karma |
| E2E | Playwright 或 Cypress |

- 每功能开发后立即写单测，通过才能做下一个
- 业务完成后写 E2E
- 提交前 `ng test --no-watch` + `ng build --configuration production` 全通过

## 9. CI/CD

- GitHub Actions
- `test.yml`：npm ci + lint + ng test + ng build
- `build-and-push.yml`：Docker (nginx) 构建推送
- `publish.yml`：npm publish（Angular 库，按需）
- Secrets：`NPM_TOKEN`、`DOCKER_USERNAME`、`DOCKER_PASSWORD`

## 10. 项目结构

```
src/app/
├── core/
│   ├── guards/        # 路由守卫
│   ├── interceptors/  # HTTP 拦截器
│   ├── models/        # 数据模型/接口
│   └── services/      # 单例服务
├── shared/
│   ├── components/    # 可复用组件
│   ├── directives/    # 自定义指令
│   └── pipes/         # 自定义管道
├── features/          # 业务领域模块（懒加载）
├── layouts/           # 布局组件
├── app.component.ts   # Standalone 根组件
├── app.config.ts      # 应用 providers
└── app.routes.ts      # 根路由配置
```
