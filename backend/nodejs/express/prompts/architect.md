# Express 架构与设计规则

> 适用场景：Express 项目架构设计、模块划分、分层决策、技术选型。

## 硬约束

- Node.js 版本 MUST >= 18（推荐 20 LTS）。
- 项目 MUST 使用 ES Module 或 CommonJS。
- 目录结构 MUST 清晰分层：routes、controllers、services、models、middlewares。

## 分层架构

```
Router（路由层） → Controller（控制层） → Service（业务层） → Model（数据层）
       ↓                    ↓                        ↓
  Middleware（中间件）    DTO（入参校验）         Entity（领域模型）
```

- **Router**：使用 `express.Router()` 模块化路由。
- **Controller**：`(req, res, next)` 处理请求。**禁止**写业务逻辑。
- **Service**：业务逻辑，纯函数或类方法。
- **Model**：数据访问（Sequelize / Mongoose / Prisma / Knex）。

## 目录结构（推荐）

```
project/
├── src/
│   ├── index.js                  # 入口
│   ├── app.js                    # Express app 创建与中间件注册
│   ├── routes/                   # 路由定义
│   │   ├── index.js
│   │   └── user.routes.js
│   ├── controllers/              # 控制器
│   │   └── user.controller.js
│   ├── services/                 # 业务逻辑
│   │   └── user.service.js
│   ├── models/                   # Sequelize/Mongoose Models
│   │   └── user.model.js
│   ├── middlewares/              # 中间件
│   │   ├── auth.js
│   │   ├── error-handler.js
│   │   └── validator.js
│   ├── validators/               # express-validator schemas
│   │   └── user.validator.js
│   ├── config/                   # 配置
│   │   └── index.js
│   └── utils/
├── migrations/
├── test/
├── .env
└── package.json
```

## 技术选型

| 层次 | 推荐方案 | 替代方案 |
|---|---|---|
| Web 框架 | Express | — |
| 路由 | express.Router() | — |
| ORM | Sequelize | Prisma / Mongoose / Knex.js |
| 校验 | express-validator | Joi / Zod |
| 认证 | jsonwebtoken + express-jwt | passport |
| 安全 | helmet + cors + express-rate-limit | — |
| 日志 | winston / pino | morgan |
| 测试 | Jest + supertest | mocha + chai |
| 配置 | dotenv | — |

## Express 中间件

Express 中间件签名：`(req, res, next) => void`。

- **MUST** 按顺序注册：Security → Parser → Logger → Routes → Error Handler。
- **MUST** 错误处理中间件使用 4-arg 签名：`(err, req, res, next)`。

```javascript
const express = require('express');
const app = express();

// 1. 安全
app.use(helmet());
app.use(cors({ origin: process.env.CORS_ORIGIN }));

// 2. 请求解析
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 3. 日志
app.use(morgan('combined'));

// 4. 路由
app.use('/api/v1', require('./routes'));

// 5. 错误处理（4-arg 中间件，放最后）
app.use(errorHandler);
```

## 配置管理

- **MUST** 使用 `dotenv` + `.env` 管理配置。
- **MUST** 按环境拆分：`.env.development`、`.env.production`。
- **禁止** 硬编码配置值。

## 错误处理

- **MUST** 使用 4-arg 错误处理中间件：`(err, req, res, next)`。
- **MUST** Controller 中错误传递给 `next(err)` 而非直接 `res.status().json()`。
- **SHOULD** 定义自定义错误类。

```javascript
// 全局错误处理中间件（4 个参数）
function errorHandler(err, req, res, next) {
  const status = err.status || 500;
  res.status(status).json({
    code: status,
    message: err.expose ? err.message : 'Internal Server Error',
  });
}
```

## 安全

- **MUST** 使用 `helmet` 安全头。
- **MUST** 使用 `cors` 白名单配置。
- **MUST** 使用 `express-rate-limit` 限流。
- **SHOULD** 使用 `express-mongo-sanitize` / `xss-clean` 防注入。

## 构建与部署

- **MUST** 使用多阶段 Docker 构建。
- **MUST** 生产环境 `NODE_ENV=production`。
- **SHOULD** 使用 PM2 或 Docker 进程管理。
