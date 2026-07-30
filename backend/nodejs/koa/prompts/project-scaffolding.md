# Koa 项目脚手架规则

> 适用场景：新建 Koa 项目时的初始化步骤、目录创建、依赖配置。

## 初始化步骤（MUST 按顺序执行）

### 1. 初始化项目

```bash
mkdir my-service && cd my-service
npm init -y
```

### 2. 安装核心依赖

```bash
npm install koa koa-router koa-body @koa/cors koa-helmet dotenv
npm install sequelize pg              # Sequelize + PostgreSQL
npm install joi                       # 校验
npm install jsonwebtoken koa-jwt      # JWT 认证
npm install pino                      # 日志

npm install -D nodemon jest supertest
```

### 3. 创建目录结构

```bash
mkdir -p src/{routes,controllers,services,models,middlewares,validators,config,utils}
mkdir -p migrations seeders test
```

### 4. 创建入口 `src/index.js`

```javascript
require('dotenv').config();
const app = require('./app');

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### 5. 创建 app `src/app.js`

```javascript
const Koa = require('koa');
const koaBody = require('koa-body');
const cors = require('@koa/cors');
const helmet = require('koa-helmet');
const errorHandler = require('./middlewares/error-handler');
const router = require('./routes');

const app = new Koa();
app.use(errorHandler);
app.use(helmet());
app.use(cors({ origin: process.env.CORS_ORIGIN }));
app.use(koaBody());
app.use(router.routes());
app.use(router.allowedMethods());

module.exports = app;
```

### 6. 创建 `.env`

```env
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/mydb
JWT_SECRET=change-me-in-production
CORS_ORIGIN=http://localhost:5173
```

### 7. 创建 Dockerfile

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY src/ ./src/
USER node
EXPOSE 3000
CMD ["node", "src/index.js"]
```

### 8. 添加 npm scripts

```json
{
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js",
    "test": "jest --coverage",
    "lint": "eslint src/ test/"
  }
}
```

## 禁止事项

- **禁止** 手动创建 vendor 目录。
- **禁止** 在入口文件中写业务逻辑。
- **禁止** 把路由和 Controller 放在同一个文件中。
