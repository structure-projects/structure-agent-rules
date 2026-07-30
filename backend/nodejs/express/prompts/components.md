# Express 组件与依赖速查

Express 项目核心组件用法。

## Express + express.Router

```javascript
const express = require('express');
const app = express();
const router = express.Router();

router.get('/users/:id', async (req, res, next) => {
  try { res.json(await service.findById(req.params.id)); }
  catch (err) { next(err); }
});

app.use('/api/v1', router);
```

## Sequelize ORM

```javascript
const { Sequelize, DataTypes } = require('sequelize');
const sequelize = new Sequelize(process.env.DATABASE_URL, { logging: false });

const User = sequelize.define('User', {
  username: { type: DataTypes.STRING, allowNull: false, unique: true },
  email: { type: DataTypes.STRING, allowNull: false, unique: true },
});
```

## Prisma

```javascript
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const user = await prisma.user.findUnique({ where: { id: 1 } });
```

## Mongoose (MongoDB)

```javascript
const mongoose = require('mongoose');
const userSchema = new mongoose.Schema({ username: String, email: String });
const User = mongoose.model('User', userSchema);
```

## express-validator

```javascript
const { body, validationResult } = require('express-validator');

router.post('/users', [
  body('username').isString().isLength({ min: 3, max: 32 }),
  body('email').isEmail(),
], (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
  next();
});
```

## JWT 认证

```javascript
const jwt = require('jsonwebtoken');
const { expressjwt } = require('express-jwt');

app.use(expressjwt({ secret: process.env.JWT_SECRET, algorithms: ['HS256'] })
  .unless({ path: ['/api/v1/auth/login', '/health'] }));
```

## 安全中间件

- `helmet` — 安全头
- `cors` — 跨域
- `express-rate-limit` — 限流

## 日志

- `winston` — 结构化日志
- `pino` — 高性能日志
- `morgan` — HTTP 请求日志

## 禁止

- Controller 中直接使用 Model
- 硬编码配置值
- 生产环境 Sequelize `sync()` 或 Mongoose `autoIndex`
