# Angular 前端评审规则

> 角色：angular-reviewer（前端评审）。面向审查 Angular 前端 PR / diff 的 AI Agent。

## 审查清单

### 组件规范
- [ ] 是否使用 Standalone Components（非 NgModules）
- [ ] imports 数组是否明确声明（无隐式依赖）
- [ ] 是否使用 Signals API（`input()`、`output()`）而非装饰器
- [ ] 是否设置 `ChangeDetectionStrategy.OnPush`
- [ ] selector 是否使用 `app-` 前缀

### TypeScript
- [ ] 是否开启 strict 模式
- [ ] 接口/类型是否完整声明（避免 `any`）
- [ ] 是否使用 `inject()` 替代构造函数注入
- [ ] 是否无 `null` 安全问题（使用可选链 `?.`）

### 依赖注入
- [ ] 服务是否使用 `@Injectable({ providedIn: 'root' })`
- [ ] 是否避免在 Component 的 `providers` 中声明全局服务
- [ ] HTTP 拦截器是否在 `app.config.ts` 统一注册

### 性能
- [ ] 路由是否懒加载（`loadComponent` / `loadChildren`）
- [ ] 大列表是否使用虚拟滚动（CDK `@angular/cdk/scrolling`）
- [ ] 是否使用 `trackBy` 优化 `*ngFor` 或 `@for`
- [ ] 图片是否懒加载
- [ ] 是否避免不必要的 Observable 订阅

### 安全
- [ ] 表单是否使用 Angular 校验（非仅前端校验）
- [ ] 用户输入的 HTML 是否经过 DomSanitizer 处理
- [ ] 敏感 API 调用是否通过拦截器附加认证 Token

### 样式
- [ ] 是否使用 SCSS + ViewEncapsulation
- [ ] 是否无 `::ng-deep` 滥用
- [ ] 是否使用主题变量而非硬编码颜色

### RxJS
- [ ] 订阅是否在 `ngOnDestroy` 中取消（或使用 `takeUntilDestroyed`）
- [ ] 是否使用 `async` 管道减少手动订阅
- [ ] 是否避免嵌套 subscribe（使用 `switchMap`、`mergeMap` 等）

### 测试
- [ ] 新增组件是否有 TestBed 单元测试
- [ ] 服务是否有单元测试
- [ ] E2E 测试是否覆盖核心流程
- [ ] 测试用例是否有有意义的断言

## 常见驳回原因

1. **使用 NgModules 而非 Standalone**：新代码必须使用 Standalone API
2. **使用装饰器 `@Input()` 而非 Signals `input()`**：新组件优先 Signals
3. **订阅未取消**：RxJS 订阅在 `ngOnDestroy` 中未清理
4. **any 类型滥用**：TypeScript 类型不完整
5. **性能问题**：未使用 OnPush、未懒加载路由、未 trackBy
6. **安全漏洞**：表单无校验、HTML 未消毒
7. **引入新的 UI 库**（如同时使用 Material + PrimeNG）而未评审
