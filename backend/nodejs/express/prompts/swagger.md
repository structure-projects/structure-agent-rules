# Express Swagger/OpenAPI 规则

Express 项目的 API 文档生成。

## 硬约束

- MUST 使用 swagger-jsdoc + swagger-ui-express
- MUST 每个公开 API 有完整 JSDoc 注解
- SHOULD 生产环境可关闭 Swagger UI

## 安装

```bash
npm install swagger-jsdoc swagger-ui-express
```

## 配置

```javascript
const swaggerJSDoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

const options = {
  definition: {
    openapi: '3.0.0',
    info: { title: 'My API', version: '1.0.0' },
    servers: [{ url: 'http://localhost:3000' }],
    components: {
      securitySchemes: { bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' } },
    },
  },
  apis: ['./src/routes/*.js', './src/controllers/*.js'],
};

const swaggerSpec = swaggerJSDoc(options);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
```

## Controller JSDoc

```javascript
/**
 * @swagger
 * /api/v1/users:
 *   post:
 *     summary: 创建用户
 *     tags: [用户管理]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/CreateUserRequest'
 *     responses:
 *       201:
 *         description: 创建成功
 */
```

## 禁止

- 生产环境默认暴露 Swagger UI
- JSDoc 注解与实现不一致
- 公共 API 缺少 security 定义
