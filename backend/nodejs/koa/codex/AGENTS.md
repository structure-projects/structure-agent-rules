# AGENTS.md — Koa 项目规则

> 本文件是 **Codex / 通用 AI Agent** 在 Koa 项目中的工作规则。
> **详细规则**：`prompts/developer.md` / `prompts/architect.md` / `prompts/components.md` / `prompts/tester.md` / `prompts/reviewer.md` / `prompts/validation.md` / `prompts/swagger.md` / `prompts/ci-cd.md`。

---

## 1. 硬约束

- Node.js >= 18，使用 `async/await`。
- 路由 MUST 使用 koa-router 模块化。
- 全局错误处理中间件 MUST 放在最外层。
- 入参 MUST 使用 Joi/Zod 校验。

## 2. 模块布局

```
src/
├── index.js / app.js
├── routes/              # koa-router 路由定义
├── controllers/         # 控制器
├── services/            # 业务逻辑
├── models/              # Sequelize Models
├── middlewares/         # 中间件（error-handler, auth, validator）
├── validators/          # Joi/Zod schema
├── config/              # 配置
└── utils/
```

## 3. 洋葱模型中间件顺序（MUST）

```
Error Handler → Logger → CORS → Body Parser → Auth → Routes
```

## 4. Controller 规范

```javascript
async findById(ctx) {
  const { id } = ctx.params;
  const user = await userService.findById(Number(id));
  if (!user) ctx.throw(404, '用户不存在');
  ctx.body = { code: 0, data: user };
}
```

- **MUST** 只做参数提取 + 调用 Service + 返回响应
- **MUST** 使用 `ctx.throw()` 处理错误
- **禁止** 写业务逻辑、直接操作数据库

## 5. Service 规范

```javascript
class UserService {
  async findById(id) {
    return User.findByPk(id, { attributes: { exclude: ['password'] } });
  }
}
```

- **MUST** 纯逻辑，禁止引用 `ctx`
- **MUST** 使用 Sequelize Model 或 Knex 实例访问数据

## 6. 路由模块化

```javascript
const Router = require('koa-router');
const router = new Router({ prefix: '/api/v1/users' });

router.get('/', controller.list);
router.get('/:id', controller.findById);
router.post('/', validate(schema), controller.create);

module.exports = router;
```

## 7. 错误处理

```javascript
async function errorHandler(ctx, next) {
  try {
    await next();
  } catch (err) {
    ctx.status = err.status || 500;
    ctx.body = { code: ctx.status, message: err.expose ? err.message : 'Internal Server Error' };
  }
}
```

## 8. 校验

```javascript
// Joi
const schema = Joi.object({
  username: Joi.string().min(3).max(32).required(),
  email: Joi.string().email().required(),
});

// 中间件
function validate(schema) {
  return async (ctx, next) => {
    const { error, value } = schema.validate(ctx.request.body, { stripUnknown: true });
    if (error) ctx.throw(400, error.details[0].message);
    ctx.request.body = value;
    await next();
  };
}
```

## 9. 持久化

- **MUST** 生产环境禁止 Sequelize `sync()`
- **MUST** 使用版本化迁移
- **禁止** Controller 直接使用 Model

## 10. 安全

- **MUST** helmet + CORS 白名单
- **MUST** koa-jwt 认证
- **SHOULD** Rate Limiting

## 11. 测试

- 单测：`*.test.js`，jest.mock 隔离依赖
- 集成测试：`supertest` + `app.callback()`
- **MUST** 覆盖率 >= 70%
- **禁止** 僵尸断言、集成测试 Mock 数据库

## 12. 提交前自检

- [ ] 错误处理中间件在最外层？
- [ ] Controller 只做参数提取 + 调用 Service？
- [ ] 入参使用 Joi/Zod 校验？
- [ ] `npm test` 全部通过？

---

**详细规则**：`prompts/developer.md` / `prompts/components.md` / `prompts/tester.md` / `prompts/reviewer.md` / `prompts/architect.md` / `prompts/project-scaffolding.md` / `prompts/validation.md` / `prompts/swagger.md` / `prompts/ci-cd.md` / `CLAUDE.md`。
