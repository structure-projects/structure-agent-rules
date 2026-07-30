# React 前端 CI/CD 规则

> 面向 React 前端项目的 CI/CD 规范。本规则自包含，不依赖其他技术栈目录。

## 1. 通用原则

- **MUST** 所有 CI 使用 GitHub Actions。
- **MUST** workflow 文件位于 `.github/workflows/`。
- **MUST** Secrets 通过 GitHub Secrets 管理，**禁止** 硬编码。

## 2. 标准 Workflow

### 2.1 `test.yml` —— 前端测试

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
    defaults:
      run:
        working-directory: ./

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: package-lock.json

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

### 2.2 `build-and-push.yml` —— Docker 构建

```yaml
name: Build and Push

on:
  push:
    branches: [main, master]

permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install and Build
        run: |
          npm ci
          npm run build

      - name: Build and Push Docker Image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: |
            registry.example.com/${{ github.repository }}:${{ github.sha }}
            registry.example.com/${{ github.repository }}:latest
```

### 2.3 Dockerfile

```dockerfile
# 多阶段构建
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:1.27-alpine AS production
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### 2.4 `e2e.yml` —— E2E 测试

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

      - name: Run E2E tests
        run: npm run test:e2e
```

## 3. Secrets 配置

| Secret | 工作流 | 说明 |
|---|---|---|
| `DOCKER_USERNAME` | build-and-push.yml | Docker Registry 用户名 |
| `DOCKER_PASSWORD` | build-and-push.yml | Docker Registry 密码 |
