# NestJS 评审规则

> 适用场景：审查 NestJS 项目的 PR、diff、设计文档。

## 评审顺序（按优先级）

1. Module 声明完整性 → 2. Controller 职责 → 3. Service 注入 → 4. DTO 校验 → 5. Entity 定义 → 6. 异常处理 → 7. Swagger 文档 → 8. 配置管理 → 9. 中间件 → 10. 测试 → 11. 类型安全

## 硬性驳回项（MUST-FIX）

### Module 系统
- Module 未正确声明 `imports`/`controllers`/`providers`/`exports`。
- 跨模块直接注入未 exported 的 Provider。
- 手动 `new` Service 绕过 IOC 容器。

### Controller
- Controller 包含业务逻辑。
- Controller 直接注入 `DataSource` 或 `EntityManager`。
- 使用 `interface` 作为 DTO 入参类型（必须用 class）。
- 参数未使用 `@Body()`/`@Param()`/`@Query()` 装饰器。

### DTO 校验
- DTO 未使用 `class-validator` 装饰器。
- 未全局注册 `ValidationPipe`。
- `ValidationPipe` 未配置 `whitelist: true`。

### Entity
- TypeORM Entity 缺少主键定义。
- 生产环境 `synchronize: true`。

### 异常处理
- Service 层抛非 NestJS 标准异常。
- 未使用全局异常过滤器统一响应格式。
- 使用 `try-catch` 吞异常无日志。

### 配置
- 硬编码配置值。
- 敏感信息（密钥、密码）硬编码在代码中。

### 安全
- 未启用 `helmet`。
- CORS 使用 `*` 通配符（生产环境）。
- 未启用 `@nestjs/throttler`。

### 测试
- 新功能无单元测试。
- 修改功能未同步修改测试。
- Mock 数据库连接。
- 僵尸断言。

## 建议性反馈（SHOULD-FIX）

- 使用 `any` 类型。
- Service 方法无返回类型注解。
- Controller 方法直接返回 Entity（应返回 DTO）。
- 未使用 `@ApiTags`/`@ApiOperation` 注解。
- 文件名未使用 `kebab-case`。

## NIT

- import 顺序混乱。
- 注释中的拼写错误。
- 未使用的 import。

## NestJS 特定陷阱

- `@InjectRepository` 的 Entity 类必须已在 `TypeOrmModule.forFeature()` 中注册。
- `class-transformer` 的 `@Type()` 在 Query 参数中必须使用。
- Guard 中抛出异常会被框架自动处理，无需手动 try-catch。
- 异步 Provider 使用 `useFactory` + `async/await` 或 `inject`。

## 反馈格式

每条反馈含：位置（`file:line`）、级别（MUST-FIX / SHOULD-FIX / NIT / QUESTION）、依据、建议。
