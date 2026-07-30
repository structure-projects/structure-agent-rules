# Koa Swagger/OpenAPI 规则

> 适用场景：Koa 项目的 API 文档生成。

## 硬约束

- **MUST** 使用 `koa2-swagger-ui` + `swagger-jsdoc` 生成 OpenAPI 文档。
- **MUST** 每个公开 API 有完整的 JSDoc 注解。
- **SHOULD** 生产环境可关闭 Swagger UI。

## 安装

```bash
npm install swagger-jsdoc koa2-swagger-ui
```

## swagger-jsdoc 配置

```javascript
// config/swagger.js
const swaggerJSDoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'My Service API',
      version: '1.0.0',
      description: 'Koa 微服务 API',
    },
    servers: [{ url: 'http://localhost:3000' }],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
    },
  },
  apis: ['./src/routes/*.js', './src/controllers/*.js'],
};

module.exports = swaggerJSDoc(options);
```

## Controller JSDoc 注解

```javascript
/**
 * @swagger
 * /api/v1/users:
 *   post:
 *     summary: 创建用户
 *     tags: [用户管理]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/CreateUserRequest'
 *     responses:
 *       201:
 *         description: 创建成功
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/UserResponse'
 *       400:
 *         description: 参数校验失败
 */
async create(ctx) {
  // ...
}

/**
 * @swagger
 * /api/v1/users/{id}:
 *   get:
 *     summary: 获取用户详情
 *     tags: [用户管理]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: 成功
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/UserResponse'
 */
async findById(ctx) {
  // ...
}
```

## Schema 定义

```javascript
/**
 * @swagger
 * components:
 *   schemas:
 *     CreateUserRequest:
 *       type: object
 *       required:
 *         - username
 *         - email
 *         - password
 *       properties:
 *         username:
 *           type: string
 *           minLength: 3
 *           maxLength: 32
 *           example: zhangsan
 *         email:
 *           type: string
 *           format: email
 *           example: zhangsan@example.com
 *         password:
 *           type: string
 *           minLength: 8
 *
 *     UserResponse:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *         username:
 *           type: string
 *         email:
 *           type: string
 *         createdAt:
 *           type: string
 *           format: date-time
 */
```

## Swagger UI 路由

```javascript
const { koaSwagger } = require('koa2-swagger-ui');
const swaggerSpec = require('./config/swagger');

router.get('/api-docs', koaSwagger({
  routePrefix: false,
  swaggerOptions: { spec: swaggerSpec },
}));
```

## 禁止事项

- **禁止** 在生产环境默认暴露 Swagger UI。
- **禁止** JSDoc 注解与实现不一致。
- **禁止** 公共 API 缺少 security 定义。
