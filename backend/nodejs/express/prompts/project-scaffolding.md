# Express 项目脚手架规则

新建 Express 项目的初始化步骤。

## 初始化步骤

### 1. 初始化项目

```bash
mkdir my-service && cd my-service
npm init -y
```

### 2. 安装依赖

```bash
npm install express helmet cors express-rate-limit dotenv
npm install sequelize pg              # ORM
npm install express-validator         # 校验
npm install jsonwebtoken express-jwt  # JWT
npm install winston morgan            # 日志

npm install -D nodemon jest supertest
```

### 3. 创建目录

```bash
mkdir -p src/{routes,controllers,services,models,middlewares,validators,config,utils}
mkdir -p migrations test
```

### 4. 入口 src/index.js

```javascript
require('dotenv').config();
const app = require('./app');
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server on port ${PORT}`));
```

### 5. Express app src/app.js

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

### 6. .env

```env
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/mydb
JWT_SECRET=change-me
CORS_ORIGIN=http://localhost:5173
```

### 7. Dockerfile

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

### 8. npm scripts

```json
{
  "start": "node src/index.js",
  "dev": "nodemon src/index.js",
  "test": "jest --coverage",
  "lint": "eslint src/ test/"
}
```
