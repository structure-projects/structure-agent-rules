# Express 开发规则

编写 Express/Node.js 代码时的规则。

## 硬约束

- 使用 `async/await`，Controller 中 try-catch 或 wrap 异步错误。
- 错误 MUST 传递给 `next(err)`，由全局错误处理中间件统一处理。
- 路由 MUST 使用 `express.Router()` 模块化。

## Controller 层

```javascript
// user.controller.js
const userService = require('../services/user.service');

exports.findById = async (req, res, next) => {
  try {
    const user = await userService.findById(Number(req.params.id));
    if (!user) return res.status(404).json({ code: 404, message: '用户不存在' });
    res.json({ code: 0, data: user });
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const user = await userService.create(req.body);
    res.status(201).json({ code: 0, data: user });
  } catch (err) {
    next(err);
  }
};
```

**约束**：只做参数提取 + 调用 Service + 返回响应。错误传给 `next(err)`。禁止写业务逻辑。

## Service 层

```javascript
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
```

## 路由模块化

```javascript
const router = express.Router();
router.get('/', userController.list);
router.get('/:id', userController.findById);
router.post('/', validate(createUserSchema), userController.create);
module.exports = router;
```

## 错误处理中间件（4-arg）

```javascript
function errorHandler(err, req, res, next) {
  const status = err.status || 500;
  res.status(status).json({
    code: status,
    message: err.expose ? err.message : 'Internal Server Error',
  });
  if (status === 500) console.error(err);
}
```

## app.js 组装

```javascript
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const app = express();

app.use(helmet());
app.use(cors({ origin: process.env.CORS_ORIGIN }));
app.use(express.json());
app.use('/api/v1', require('./routes'));
app.use(errorHandler);

module.exports = app;
```

## 测试工作流（MUST）

- 每开发一个功能立即写单测，通过才能做下一个
- 修改功能时同步修改测试
- 业务完成后写集成测试
- 提交前：`npm test` 全部通过
- 禁止测试失败仍提交

## 提交前自检

- Controller 只做参数提取 + 调用 Service + 返回响应？
- 错误传给 `next(err)`？
- 全局 4-arg 错误处理中间件已注册？
- 路由使用 express.Router() 模块化？
- 入参使用 express-validator 校验？
- `npm test` 全部通过？
