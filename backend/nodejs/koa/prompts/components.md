# Koa 组件与依赖速查

> 适用场景：Koa 项目中使用生态组件时的配置参考、最佳实践。

## 核心框架

### Koa + koa-router

```javascript
const Koa = require('koa');
const Router = require('koa-router');
const app = new Koa();
const router = new Router({ prefix: '/api/v1' });

router.get('/users/:id', async (ctx) => {
  ctx.body = { id: ctx.params.id };
});

app.use(router.routes());
app.use(router.allowedMethods());
app.listen(3000);
```

### koa-body（请求解析）

```javascript
const koaBody = require('koa-body');

app.use(koaBody({
  multipart: true,
  formidable: { maxFileSize: 10 * 1024 * 1024 }, // 10MB
}));
```

### Sequelize（ORM）

```javascript
const { Sequelize, DataTypes } = require('sequelize');

const sequelize = new Sequelize('database', 'user', 'password', {
  host: 'localhost',
  dialect: 'postgres',
  pool: { max: 10, min: 0, acquire: 30000, idle: 10000 },
  logging: false, // 生产 MUST false
});

// Model 定义
const User = sequelize.define('User', {
  username: { type: DataTypes.STRING, allowNull: false, unique: true },
  email: { type: DataTypes.STRING, allowNull: false, unique: true },
});
```

### Knex.js（Query Builder）

```javascript
const knex = require('knex');

const db = knex({
  client: 'pg',
  connection: process.env.DATABASE_URL,
  pool: { min: 2, max: 10 },
});

// 查询
const users = await db('users').where('status', 'active').select('*');

// 事务
await db.transaction(async (trx) => {
  await trx('users').insert({ username: 'test' });
  await trx('profiles').insert({ userId: 1 });
});
```

### Joi（校验）

```javascript
const Joi = require('joi');

const createUserSchema = Joi.object({
  username: Joi.string().min(3).max(32).required(),
  email: Joi.string().email().required(),
  password: Joi.string().min(8).required(),
});

// 校验中间件
async function validate(schema) {
  return async (ctx, next) => {
    const { error, value } = schema.validate(ctx.request.body);
    if (error) {
      ctx.throw(400, error.details[0].message);
    }
    ctx.request.body = value;
    await next();
  };
}
```

### Zod（校验 - ESM）

```javascript
import { z } from 'zod';

const createUserSchema = z.object({
  username: z.string().min(3).max(32),
  email: z.string().email(),
  password: z.string().min(8),
});

const result = createUserSchema.safeParse(ctx.request.body);
if (!result.success) {
  ctx.throw(400, result.error.issues[0].message);
}
```

### koa-jwt（认证）

```javascript
const jwt = require('koa-jwt');

app.use(jwt({ secret: process.env.JWT_SECRET }).unless({
  path: [/^\/api\/v1\/auth\//, /^\/health/],
}));

// 获取用户信息
router.get('/profile', async (ctx) => {
  const user = ctx.state.user; // JWT payload 自动注入
  ctx.body = user;
});
```

### koa-static（静态文件）

```javascript
const serve = require('koa-static');
app.use(serve('./public'));
```

### 日志

```javascript
// pino
const pino = require('pino');
const logger = pino({ level: process.env.LOG_LEVEL || 'info' });

app.use(async (ctx, next) => {
  const start = Date.now();
  await next();
  logger.info({ method: ctx.method, url: ctx.url, status: ctx.status, ms: Date.now() - start });
});
```

## 禁止事项

- **禁止** 在 Controller 中直接使用 Sequelize Model/Knex 实例。
- **禁止** 使用 `try-catch` 吞异常不记录日志。
- **禁止** 硬编码配置值。
- **禁止** 生产环境 Sequelize `sync()`。
