# Koa 测试规则

> 适用场景：编写 Koa 项目的单元测试和集成测试。

## 测试工作流（MUST）

- 每开发一个功能 **立即** 写单元测试，**单测通过才能做下一个功能**。
- 功能有修改时 **同步修改测试** 并通过。
- 业务完成后写 **集成测试**，通过才算交付。
- 覆盖正常 + 异常 + 边界；断言验证行为与数据（**禁止** 僵尸断言）。
- **提交前**：`npm test` 全部通过。

## 测试分层与命名

| 类型 | 文件 | 说明 |
|---|---|---|
| 单元测试 | `*.test.js` 或 `*.spec.js` | 不启动外部依赖 |
| 集成测试 | `*.integration.test.js` | Testcontainers 真实中间件 |

## Service 单元测试

```javascript
// services/user.service.test.js
const userService = require('./user.service');
const User = require('../models/user.model');

jest.mock('../models/user.model');

describe('UserService', () => {
  afterEach(() => jest.clearAllMocks());

  describe('findById', () => {
    it('should return user when found', async () => {
      const mockUser = { id: 1, username: 'test', email: 'test@example.com' };
      User.findByPk.mockResolvedValue(mockUser);

      const result = await userService.findById(1);
      expect(result).toEqual(mockUser);
      expect(User.findByPk).toHaveBeenCalledWith(1, expect.any(Object));
    });

    it('should return null when not found', async () => {
      User.findByPk.mockResolvedValue(null);
      const result = await userService.findById(999);
      expect(result).toBeNull();
    });
  });
});
```

## Controller 测试

```javascript
// controllers/user.controller.test.js
const userController = require('./user.controller');
const userService = require('../services/user.service');

jest.mock('../services/user.service');

describe('UserController', () => {
  it('should return user', async () => {
    const ctx = {
      params: { id: '1' },
      body: null,
    };
    userService.findById.mockResolvedValue({ id: 1, username: 'test' });

    await userController.findById(ctx);
    expect(ctx.body.code).toBe(0);
    expect(ctx.body.data.username).toBe('test');
  });

  it('should throw 404 when not found', async () => {
    const ctx = { params: { id: '999' }, throw: jest.fn() };
    userService.findById.mockResolvedValue(null);

    await userController.findById(ctx);
    expect(ctx.throw).toHaveBeenCalledWith(404, '用户不存在');
  });
});
```

## API 集成测试（supertest）

```javascript
// test/users.api.test.js
const request = require('supertest');
const app = require('../src/app');

describe('Users API', () => {
  it('GET /api/v1/users/:id - success', async () => {
    const res = await request(app.callback())
      .get('/api/v1/users/1')
      .expect(200);

    expect(res.body.code).toBe(0);
    expect(res.body.data.id).toBe(1);
  });

  it('POST /api/v1/users - validation error', async () => {
    const res = await request(app.callback())
      .post('/api/v1/users')
      .send({ username: 'ab' }) // too short
      .expect(400);
  });
});
```

## Mock 边界

- **只允许** Mock 外部 HTTP API、第三方 SDK。
- **允许** Mock 自己的 Service/Model（单测中）。
- **禁止** 集成测试 Mock 数据库。

## 禁止事项

- **禁止** 僵尸断言。
- **禁止** `setTimeout` 等待异步。
- **禁止** 集成测试 Mock 数据库。
- **禁止** `test.skip` 无注释说明。
