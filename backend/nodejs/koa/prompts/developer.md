# Koa 开发规则

> 适用场景：编写 Node.js/Koa 代码时始终生效。

## 硬约束

- 使用 `async/await`（Koa 中间件基于 async 函数）。
- 错误 MUST 被处理（全局错误中间件 + `ctx.throw`）。
- 禁止在 Controller 中写业务逻辑。
- 路由 MUST 使用 `koa-router` 模块化组织。

## 代码风格

- **MUST** 使用 ESLint + Prettier。
- **SHOULD** 使用 ESM（`"type": "module"`），Koa 完全支持。
- **MUST** 文件名：`kebab-case`（`user.controller.js`）。

## 中间件模式（洋葱模型）

```javascript
// Koa 中间件 MUST 是 async 函数
async function myMiddleware(ctx, next) {
  // 请求进入（前置操作）
  console.log('-->', ctx.method, ctx.url);

  await next(); // 等待后续中间件执行

  // 响应返回（后置操作）
  console.log('<--', ctx.status);
}
```

## Controller 层

```javascript
// user.controller.js
const userService = require('../services/user.service');

class UserController {
  async findById(ctx) {
    const { id } = ctx.params;
    const user = await userService.findById(Number(id));
    if (!user) {
      ctx.throw(404, '用户不存在');
    }
    ctx.body = { code: 0, data: user };
  }

  async create(ctx) {
    const dto = ctx.request.body;
    const user = await userService.create(dto);
    ctx.status = 201;
    ctx.body = { code: 0, data: user };
  }

  async list(ctx) {
    const { page = 1, pageSize = 20, keyword } = ctx.query;
    const result = await userService.list({ page: Number(page), pageSize: Number(pageSize), keyword });
    ctx.body = { code: 0, data: result };
  }
}

module.exports = new UserController();
```

**Controller 约束**：
- **MUST** 只做参数提取 + 调用 Service + 返回响应。
- **MUST** 使用 `ctx.throw(status, message)` 处理错误。
- **禁止** 写业务逻辑、直接操作数据库。

## Service 层

```javascript
// user.service.js
const User = require('../models/user.model');

class UserService {
  async findById(id) {
    return User.findByPk(id, { attributes: { exclude: ['password'] } });
  }

  async create(dto) {
    const exists = await User.findOne({ where: { email: dto.email } });
    if (exists) {
      const err = new Error('邮箱已被注册');
      err.status = 409;
      throw err;
    }
    return User.create(dto);
  }
}

module.exports = new UserService();
```

## 路由模块化

```javascript
// routes/user.routes.js
const Router = require('koa-router');
const router = new Router({ prefix: '/api/v1/users' });
const userController = require('../controllers/user.controller');
const { validate } = require('../middlewares/validator');
const { createUserSchema } = require('../validators/user.validator');

router.get('/', userController.list);
router.get('/:id', userController.findById);
router.post('/', validate(createUserSchema), userController.create);

module.exports = router;

// routes/index.js —— 汇总
const Router = require('koa-router');
const router = new Router();
router.use(require('./user.routes').routes());
module.exports = router;
```

## 错误处理中间件

```javascript
// middlewares/error-handler.js
async function errorHandler(ctx, next) {
  try {
    await next();
  } catch (err) {
    const status = err.status || 500;
    ctx.status = status;
    ctx.body = {
      code: status,
      message: err.expose ? err.message : 'Internal Server Error',
    };
    if (status === 500) {
      console.error(err);
    }
  }
}

module.exports = errorHandler;
```

## 校验中间件

```javascript
// middlewares/validator.js
function validate(schema) {
  return async (ctx, next) => {
    const { error, value } = schema.validate(ctx.request.body, {
      abortEarly: false,
      stripUnknown: true,
    });
    if (error) {
      ctx.throw(400, error.details.map(d => d.message).join('; '));
    }
    ctx.request.body = value;
    await next();
  };
}
```

## app.js 组装

```javascript
const Koa = require('koa');
const koaBody = require('koa-body');
const cors = require('@koa/cors');
const helmet = require('koa-helmet');
const errorHandler = require('./middlewares/error-handler');
const router = require('./routes');

const app = new Koa();

app.use(errorHandler);
app.use(helmet());
app.use(cors({ origin: process.env.CORS_ORIGIN }));
app.use(koaBody());
app.use(router.routes());
app.use(router.allowedMethods());

module.exports = app;
```

## 测试工作流（MUST）

- 每开发一个功能 **立即** 写单元测试，**单测通过才能做下一个功能**。
- 功能有修改时 **同步修改测试** 并通过。
- 业务完成后写 **集成测试**，通过才算交付。
- **提交前**：`npm test` 全部通过。
- **禁止** 测试失败仍提交。

## 提交前自检

- [ ] Controller 只做参数提取 + 调用 Service + 返回响应？
- [ ] 使用 `ctx.throw()` 处理错误？
- [ ] 全局错误处理中间件已注册？
- [ ] 路由使用 koa-router 模块化？
- [ ] 入参使用 Joi/Zod 校验？
- [ ] `npm test` 全部通过？
