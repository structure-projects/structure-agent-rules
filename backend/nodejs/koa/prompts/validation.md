# Koa 数据校验规则

> 适用场景：Koa 项目的请求参数校验、DTO 校验、业务校验。

## 硬约束

- **MUST** 使用 Joi（推荐）或 Zod 进行入参校验。
- **MUST** 校验逻辑放在中间件中，不在 Controller 中手写。
- **MUST** 所有入参（Body、Query、Params）均需校验。
- **禁止** 仅在前端做校验。

## Joi 校验中间件

```javascript
// middlewares/validator.js
function validate(schema, source = 'body') {
  return async (ctx, next) => {
    const data = ctx.request[source] || ctx[source];
    const { error, value } = schema.validate(data, {
      abortEarly: false,
      stripUnknown: true,
      allowUnknown: false,
    });

    if (error) {
      const messages = error.details.map(d => d.message).join('; ');
      ctx.throw(400, messages);
    }

    // 替换为校验后的值（含默认值、类型转换）
    if (source === 'body') {
      ctx.request.body = value;
    } else {
      ctx[source] = value;
    }
    await next();
  };
}

module.exports = { validate };
```

## Joi Schema 定义

```javascript
// validators/user.validator.js
const Joi = require('joi');

const createUserSchema = Joi.object({
  username: Joi.string().min(3).max(32).required()
    .messages({
      'string.min': '用户名至少 3 个字符',
      'string.max': '用户名最多 32 个字符',
      'any.required': '用户名为必填项',
    }),
  email: Joi.string().email().required()
    .messages({ 'string.email': '邮箱格式不正确' }),
  password: Joi.string().min(8).required()
    .messages({ 'string.min': '密码至少 8 个字符' }),
  role: Joi.string().valid('admin', 'user', 'guest').default('user'),
});

const updateUserSchema = Joi.object({
  username: Joi.string().min(3).max(32),
  email: Joi.string().email(),
}).min(1); // 至少更新一个字段

const userQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  pageSize: Joi.number().integer().min(1).max(100).default(20),
  keyword: Joi.string().allow('').optional(),
});

module.exports = { createUserSchema, updateUserSchema, userQuerySchema };
```

## 在路由中使用

```javascript
// routes/user.routes.js
const { validate } = require('../middlewares/validator');
const { createUserSchema, userQuerySchema } = require('../validators/user.validator');

router.post('/', validate(createUserSchema), userController.create);
router.get('/', validate(userQuerySchema, 'query'), userController.list);
```

## Zod 校验（ESM 推荐）

```javascript
// validators/user.validator.js
import { z } from 'zod';

export const createUserSchema = z.object({
  username: z.string().min(3).max(32),
  email: z.string().email(),
  password: z.string().min(8),
  role: z.enum(['admin', 'user', 'guest']).default('user'),
});

// middlewares/validator.js (Zod 版本)
export function validateZod(schema) {
  return async (ctx, next) => {
    const result = schema.safeParse(ctx.request.body);
    if (!result.success) {
      ctx.throw(400, result.error.issues.map(i => i.message).join('; '));
    }
    ctx.request.body = result.data;
    await next();
  };
}
```

## 路径参数校验

```javascript
const idParamSchema = Joi.object({
  id: Joi.number().integer().positive().required(),
});

// 在 Controller 中校验路径参数
async findById(ctx) {
  const { error, value } = idParamSchema.validate(ctx.params);
  if (error) {
    ctx.throw(400, '无效的 ID');
  }
  // ...
}
```

## 业务校验（Service 层）

```javascript
class UserService {
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
```

## 禁止事项

- **禁止** 仅在前端做校验。
- **禁止** 在 Controller 中手写 `if (!req.body.username)` 逐字段校验。
- **禁止** 校验中间件未处理错误直接抛异常。
- **禁止** 返回原始 Joi/Zod 错误给前端（必须格式化）。
