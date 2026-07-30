# AGENTS.md — Express 项目规则

> 本文件是 **Codex / 通用 AI Agent** 在 Express 项目中的工作规则。
> **详细规则**：`prompts/developer.md` / `prompts/architect.md` / `prompts/components.md` / `prompts/tester.md` / `prompts/reviewer.md` / `prompts/validation.md` / `prompts/swagger.md` / `prompts/ci-cd.md`。

---

## 1. 硬约束

- Node.js >= 18，使用 async/await。
- 路由 MUST 使用 express.Router() 模块化。
- 全局 4-arg 错误处理中间件 MUST 放在最后。
- 入参 MUST 使用 express-validator 校验。

## 2. 模块布局

```
src/
├── index.js / app.js
├── routes/              # express.Router() 路由定义
├── controllers/         # 控制器 (req, res, next)
├── services/            # 业务逻辑
├── models/              # Sequelize/Mongoose Models
├── middlewares/         # 中间件（error-handler, auth, validator）
├── validators/          # express-validator schemas
├── config/              # 配置
└── utils/
```

## 3. 中间件顺序（MUST）

```
helmet → cors → json parser → routes → error handler (4-arg)
```

## 4. Controller 规范

```javascript
exports.findById = async (req, res, next) => {
  try {
    const user = await userService.findById(Number(req.params.id));
    if (!user) return res.status(404).json({ code: 404, message: 'Not found' });
    res.json({ code: 0, data: user });
  } catch (err) {
    next(err);
  }
};
```

- **MUST** 只做参数提取 + 调用 Service + 返回响应
- **MUST** 错误传给 `next(err)`
- **禁止** 写业务逻辑、直接操作数据库

## 5. Service 规范

```javascript
class UserService {
  async findById(id) {
    return User.findByPk(id, { attributes: { exclude: ['password'] } });
  }
}
```

- **MUST** 纯逻辑，禁止引用 req/res

## 6. 错误处理（4-arg）

```javascript
function errorHandler(err, req, res, next) {
  const status = err.status || 500;
  res.status(status).json({
    code: status,
    message: err.expose ? err.message : 'Internal Server Error',
  });
}
```

## 7. 校验

```javascript
const { body, validationResult } = require('express-validator');

const createUserValidation = [
  body('username').isString().isLength({ min: 3, max: 32 }),
  body('email').isEmail(),
];

function validate(validations) {
  return async (req, res, next) => {
    await Promise.all(validations.map(v => v.run(req)));
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
    next();
  };
}
```

## 8. 持久化

- MUST 生产环境禁止 sync() / autoIndex
- MUST 使用版本化迁移
- 禁止 Controller 直接使用 Model

## 9. 安全

- MUST helmet + cors 白名单 + express-rate-limit

## 10. 测试

- 单测：jest.mock 隔离依赖
- 集成测试：supertest + app
- MUST 覆盖率 >= 70%
- 禁止僵尸断言、集成测试 Mock 数据库

## 11. 提交前自检

- [ ] 4-arg 错误处理中间件在最后？
- [ ] Controller 错误传给 next(err)？
- [ ] 入参使用 express-validator？
- [ ] npm test 全部通过？

---

**详细规则**：`prompts/developer.md` / `prompts/components.md` / `prompts/tester.md` / `prompts/reviewer.md` / `prompts/architect.md` / `prompts/project-scaffolding.md` / `prompts/validation.md` / `prompts/swagger.md` / `prompts/ci-cd.md` / `CLAUDE.md`。
