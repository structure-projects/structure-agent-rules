# Express 测试规则

编写 Express 项目的单元测试和集成测试。

## 测试工作流（MUST）

- 每开发一个功能立即写单测，通过才能做下一个
- 修改功能时同步修改测试
- 业务完成后写集成测试
- 提交前：`npm test` 全部通过
- 禁止测试失败仍提交

## 分层

- `*.test.js` / `*.spec.js` — 单元测试，jest.mock 隔离依赖
- `*.integration.test.js` — 集成测试，Testcontainers 真实中间件
- API 测试用 `supertest` + `app`

## Service 单测

```javascript
const userService = require('./user.service');
const User = require('../models/user.model');
jest.mock('../models/user.model');

it('should return user', async () => {
  User.findByPk.mockResolvedValue({ id: 1, username: 'test' });
  const result = await userService.findById(1);
  expect(result.username).toBe('test');
});
```

## API 集成测试（supertest）

```javascript
const request = require('supertest');
const app = require('../src/app');

it('GET /api/v1/users/:id', async () => {
  const res = await request(app).get('/api/v1/users/1').expect(200);
  expect(res.body.data.id).toBe(1);
});
```

## Mock 边界

- 只允许 Mock 外部 API、第三方 SDK
- 允许 Mock 自己的 Service/Model（单测中）
- 禁止集成测试 Mock 数据库

## 禁止

- 僵尸断言
- setTimeout 等待异步
- 集成测试 Mock 数据库
- test.skip 无注释
