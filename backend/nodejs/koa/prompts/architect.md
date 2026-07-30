# Koa 架构与设计规则

> 适用场景：Koa 项目架构设计、模块划分、分层决策、技术选型。

## 硬约束

- Node.js 版本 MUST >= 18（推荐 20 LTS）。
- 项目 MUST 使用 ES Module 或 CommonJS（推荐 ESM）。
- 目录结构 MUST 清晰分层：routes、controllers、services、models、middlewares。

## 分层架构

```
Router → Controller → Service → Repository/Model
   ↓         ↓           ↓
Middleware   DTO      Entity
```

- **Router**：路由定义，使用 `koa-router` 模块化路由。
- **Controller**：请求处理，参数提取、调用 Service、响应返回。**禁止**写业务逻辑。
- **Service**：业务逻辑，纯函数或类方法。
- **Repository/Model**：数据访问（Sequelize Model / Knex.js）。

## 目录结构（推荐）

```
project/
├── src/
│   ├── index.js / app.js         # 入口与 Koa app 创建
│   ├── routes/                   # koa-router 路由定义
│   ├── controllers/              # 控制器
│   ├── services/                 # 业务逻辑
│   ├── models/                   # Sequelize Models / Knex 定义
│   ├── middlewares/              # 中间件
│   ├── validators/               # Joi/Zod schema
│   ├── config/                   # 配置
│   └── utils/
├── migrations/                   # 数据库迁移
├── test/
├── .env
└── package.json
```

## 技术选型

| 层次 | 推荐方案 | 替代方案 |
|---|---|---|
| Web 框架 | Koa | — |
| 路由 | koa-router | @koa/router |
| ORM | Sequelize | Knex.js / Prisma |
| 校验 | Joi | Zod |
| 认证 | koa-jwt + jsonwebtoken | — |
| 请求解析 | koa-body | koa-bodyparser |
| 静态文件 | koa-static | — |
| 日志 | pino / winston | koa-logger |
| 测试 | Jest + supertest | mocha + chai |
| 配置 | dotenv | — |

## Koa 中间件级联

- Koa 中间件是洋葱模型，MUST 理解 `await next()` 的执行顺序。
- 中间件顺序：Error Handler → Logger → CORS → Body Parser → Auth → Routes。

```javascript
const Koa = require('koa');
const app = new Koa();

// 1. 错误处理（最外层）
app.use(errorHandler);

// 2. 日志
app.use(logger);

// 3. CORS
app.use(cors({ origin: 'https://example.com' }));

// 4. Body 解析
app.use(koaBody({ multipart: true }));

// 5. 路由
app.use(router.routes());
```

## 配置管理

- **MUST** 使用 `dotenv` + `.env` 管理配置。
- **MUST** 按环境拆分：`.env.development`、`.env.production`。
- **禁止** 硬编码配置值。

## 错误处理

- **MUST** 在最外层注册全局错误处理中间件。
- **MUST** 使用 `ctx.throw(status, message)` 抛出 HTTP 错误。
- **SHOULD** 定义自定义错误类，携带业务错误码。

```javascript
// 全局错误处理中间件
async function errorHandler(ctx, next) {
  try {
    await next();
  } catch (err) {
    ctx.status = err.status || 500;
    ctx.body = {
      code: ctx.status,
      message: err.message || 'Internal Server Error',
    };
    ctx.app.emit('error', err, ctx);
  }
}
```

## 安全

- **MUST** 使用 `@koa/cors` 配置 CORS 白名单。
- **MUST** 使用 `koa-helmet` 安全头。
- **SHOULD** 启用 Rate Limiting（`koa-ratelimit`）。

## Context（ctx）对象

Koa 的 `ctx` 封装了 Node.js 的 `request` 和 `response`：
- `ctx.request.body` — 解析后的请求体（需 koa-body）
- `ctx.params` — 路由参数（需 koa-router）
- `ctx.query` — URL 查询参数
- `ctx.state` — 中间件间传递数据（如 `ctx.state.user`）
- `ctx.throw(400, 'Bad Request')` — 抛出 HTTP 错误

## 构建与部署

- **MUST** 使用多阶段 Docker 构建（node:20-alpine）。
- **MUST** 生产环境使用 `NODE_ENV=production`。
- **SHOULD** 使用 PM2 或 Docker 进行进程管理。
