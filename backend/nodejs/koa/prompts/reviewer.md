# Koa 评审规则

> 适用场景：审查 Koa 项目的 PR、diff、设计文档。

## 评审顺序（按优先级）

1. 中间件顺序 → 2. Controller 职责 → 3. Service 逻辑 → 4. 路由组织 → 5. 错误处理 → 6. 校验 → 7. 配置管理 → 8. 数据访问 → 9. 安全 → 10. 测试

## 硬性驳回项（MUST-FIX）

### 中间件
- 错误处理中间件未放在最外层（第一个 `app.use`）。
- 中间件中忘记 `await next()`。
- 中间件顺序错误（如 Body Parser 在 Auth 之后）。

### Controller
- Controller 包含业务逻辑。
- Controller 直接使用 Sequelize Model 或 Knex 实例。
- 使用 `try-catch` 处理所有错误而非全局错误中间件。

### Service
- Service 直接操作 `ctx` 对象。
- Service 方法无错误处理。
- 使用 `console.log` 而非日志库。

### 路由
- 路由未使用 koa-router。
- 路由未模块化（所有路由在一个文件中）。
- 忘记 `router.allowedMethods()`。

### 错误处理
- 未注册全局错误处理中间件。
- 使用 `try-catch` 吞异常不记录日志。
- `ctx.throw()` 的 message 暴露内部信息。

### 校验
- 入参未校验。
- 校验逻辑写在 Controller 中。

### 配置
- 硬编码配置值。
- 敏感信息（密钥、密码）未使用环境变量。

### 安全
- 未启用 CORS 或使用 `*` 通配符。
- 未启用 helmet。
- 未启用 Rate Limiting。

### 数据访问
- 生产环境使用 Sequelize `sync()`。
- 未设置数据库连接池参数。
- N+1 查询问题。

### 测试
- 新功能无单测。
- 修改功能未同步修改测试。
- 僵尸断言。

## 建议性反馈（SHOULD-FIX）

- 使用 `var` 而非 `const`/`let`。
- 回调风格而非 `async/await`。
- Controller 方法过多（建议拆分）。
- 未使用 `ctx.assert()` 简化条件判断。

## NIT

- 文件名不符合 `kebab-case`。
- console.log 残留。
- import 顺序混乱。

## 反馈格式

每条反馈含：位置（`file:line`）、级别（MUST-FIX / SHOULD-FIX / NIT / QUESTION）、依据、建议。
