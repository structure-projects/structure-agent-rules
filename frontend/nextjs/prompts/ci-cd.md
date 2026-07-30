# Next.js 前端 CI/CD 规则

> 面向 Next.js 前端项目的 CI/CD 规范。本规则自包含，不依赖其他技术栈目录。

## 1. 通用原则

- **MUST** 所有 CI 使用 GitHub Actions。
- **MUST** workflow 文件位于 `.github/workflows/`。
- **MUST** Secrets 通过 GitHub Secrets 管理，**禁止** 硬编码。

## 2. 标准 Workflow

### 2.1 `test.yml` —— 全栈测试

```yaml
name: Test

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    env:
      DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test

    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Type check
        run: npx tsc --noEmit

      - name: Run unit tests
        run: npm run test -- --coverage

      - name: Build
        run: npm run build
```

### 2.2 `e2e.yml` —— E2E 测试

```yaml
name: E2E Tests

on:
  push:
    branches: [main, master]

jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright
        run: npx playwright install --with-deps chromium

      - name: Build and Start
        run: |
          npm run build
          npm run start &
          npx wait-on http://localhost:3000

      - name: Run E2E tests
        run: npm run test:e2e
```

### 2.3 `deploy.yml` —— Vercel 部署

```yaml
name: Deploy to Vercel

on:
  push:
    branches: [main, master]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'
```

### 2.4 Docker 部署（非 Vercel）

```dockerfile
# 多阶段构建 — Next.js standalone 模式
FROM node:20-alpine AS base
WORKDIR /app

FROM base AS deps
COPY package*.json ./
RUN npm ci

FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM base AS runner
ENV NODE_ENV production
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 3000
CMD ["node", "server.js"]
```

```yaml
# build-and-push.yml
name: Build and Push Docker

on:
  push:
    branches: [main, master]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build and Push Docker Image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: |
            registry.example.com/${{ github.repository }}:${{ github.sha }}
            registry.example.com/${{ github.repository }}:latest
```

## 3. 数据库迁移 CI

```yaml
# migrate.yml — Prisma 数据库迁移
name: Database Migrate

on:
  push:
    branches: [main, master]
    paths:
      - 'prisma/**'

jobs:
  migrate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Run migrations
        run: npx prisma migrate deploy
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

## 4. Secrets 配置

| Secret | 工作流 | 说明 |
|---|---|---|
| `DATABASE_URL` | test.yml, migrate.yml | 数据库连接字符串 |
| `VERCEL_TOKEN` | deploy.yml | Vercel 部署 Token |
| `VERCEL_ORG_ID` | deploy.yml | Vercel 组织 ID |
| `VERCEL_PROJECT_ID` | deploy.yml | Vercel 项目 ID |
| `AUTH_SECRET` | test.yml | next-auth 密钥 |
