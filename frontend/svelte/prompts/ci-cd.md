# Svelte 前端 CI/CD 规则

> 面向 Svelte/SvelteKit 前端项目的 CI/CD 规范。本规则自包含，不依赖其他技术栈目录。

## 1. 通用原则

- **MUST** 所有 CI 使用 GitHub Actions。
- **MUST** workflow 文件位于 `.github/workflows/`。
- **MUST** Secrets 通过 GitHub Secrets 管理，**禁止** 硬编码。

## 2. 标准 Workflow

### 2.1 `test.yml` —— 前端测试与构建

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
        run: npm run check

      - name: Unit tests
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
            registry.example.com/${{ github.event.repository.name }}:${{ github.sha }}
            registry.example.com/${{ github.event.repository.name }}:latest
```

### 2.3 Dockerfile（SvelteKit + adapter-node）

```dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS production
WORKDIR /app
COPY --from=build /app/build ./build
COPY --from=build /app/package*.json ./
RUN npm ci --omit=dev
EXPOSE 3000
CMD ["node", "build/index.js"]
```

### 2.4 SvelteKit 库发布（可选）

```yaml
name: Publish to npm

on:
  release:
    types: [published]

permissions:
  contents: read

jobs:
  publish:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          registry-url: 'https://registry.npmjs.org'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run package

      - name: Publish
        run: npm publish --access public
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## 3. Secrets 配置

| Secret | 工作流 | 说明 |
|---|---|---|
| `NPM_TOKEN` | publish.yml | npm 自动化发布 Token |
| `DOCKER_USERNAME` | build-and-push.yml | Docker Registry 用户名 |
| `DOCKER_PASSWORD` | build-and-push.yml | Docker Registry 密码 |
