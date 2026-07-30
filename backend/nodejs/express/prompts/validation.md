# Express 数据校验规则

Express 项目的请求参数校验。

## 硬约束

- MUST 使用 express-validator 进行入参校验
- MUST 校验逻辑放在路由中间件链中，不在 Controller 中手写
- MUST 所有入参均需校验
- 禁止仅在前端做校验

## express-validator 使用

```javascript
const { body, query, param, validationResult } = require('express-validator');

const createUserValidation = [
  body('username').isString().isLength({ min: 3, max: 32 }).withMessage('用户名 3-32 字符'),
  body('email').isEmail().withMessage('邮箱格式不正确'),
  body('password').isLength({ min: 8 }).withMessage('密码至少 8 位'),
];

const userQueryValidation = [
  query('page').optional().isInt({ min: 1 }).toInt(),
  query('pageSize').optional().isInt({ min: 1, max: 100 }).toInt(),
  query('keyword').optional().isString(),
];
```

## 校验中间件

```javascript
function validate(validations) {
  return async (req, res, next) => {
    await Promise.all(validations.map(v => v.run(req)));
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ code: 400, errors: errors.array() });
    }
    next();
  };
}
```

## 路由中使用

```javascript
router.post('/', validate(createUserValidation), userController.create);
router.get('/', validate(userQueryValidation), userController.list);
```

## 自定义校验器

```javascript
body('email').custom(async (email) => {
  const user = await User.findOne({ where: { email } });
  if (user) throw new Error('邮箱已被注册');
  return true;
});
```

## 业务校验（Service 层）

```javascript
async create(dto) {
  const exists = await User.findOne({ where: { email: dto.email } });
  if (exists) {
    const err = new Error('邮箱已被注册');
    err.status = 409;
    throw err;
  }
  return User.create(dto);
}
```

## 禁止

- 仅在前端做校验
- Controller 中手写 if 逐字段校验
- 返回原始 express-validator 错误给前端（必须格式化）
