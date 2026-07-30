# NestJS 项目脚手架规则

> 适用场景：新建 NestJS 项目时的初始化步骤、目录创建、依赖配置。

## 初始化步骤（MUST 按顺序执行）

### 1. 使用 NestJS CLI 创建项目

```bash
npm i -g @nestjs/cli
nest new my-service --package-manager npm
cd my-service
```

### 2. 安装核心依赖

```bash
# 数据库（二选一）
npm install @nestjs/typeorm typeorm pg        # TypeORM
npm install @prisma/client && npm install -D prisma  # Prisma

# 校验
npm install class-validator class-transformer

# Swagger
npm install @nestjs/swagger

# 配置
npm install @nestjs/config

# 认证
npm install @nestjs/jwt @nestjs/passport passport passport-jwt
npm install -D @types/passport-jwt

# 安全
npm install helmet

# 限流
npm install @nestjs/throttler
```

### 3. 创建目录结构

```bash
mkdir -p src/common/{filters,guards,interceptors,pipes,decorators}
mkdir -p src/config
mkdir -p src/modules
```

### 4. 使用 CLI 生成模块

```bash
nest g module modules/user
nest g controller modules/user
nest g service modules/user
```

### 5. 创建 DTO 目录

```bash
mkdir -p src/modules/user/dto
mkdir -p src/modules/user/entities
```

### 6. 配置 main.ts

```typescript
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.use(helmet());
  app.enableCors({ origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'] });

  app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));

  const config = new DocumentBuilder()
    .setTitle('My API')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api-docs', app, document);

  app.enableShutdownHooks();
  await app.listen(process.env.PORT || 3000);
}
bootstrap();
```

### 7. 创建 .env

```env
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/mydb
JWT_SECRET=change-me-in-production
JWT_EXPIRATION=24h
```

### 8. 创建 tsconfig.build.json

```json
{
  "extends": "./tsconfig.json",
  "exclude": ["node_modules", "test", "dist", "**/*spec.ts"]
}
```

### 9. 创建 Dockerfile

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
RUN npm ci --omit=dev

FROM node:20-alpine
RUN apk --no-cache add tzdata
COPY --from=builder /app/dist /app/dist
COPY --from=builder /app/node_modules /app/node_modules
COPY --from=builder /app/package.json /app/
USER node
EXPOSE 3000
CMD ["node", "dist/main"]
```

## 禁止事项

- **禁止** 手动创建 Module/Controller/Service（使用 `nest g` CLI）。
- **禁止** 在 `main.ts` 中写业务逻辑。
- **禁止** 把接口（interface）当 DTO 用（DTO 必须是 class）。
