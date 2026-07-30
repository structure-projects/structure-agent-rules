# Koa CI/CD 规则

> 适用场景：Koa 项目的持续集成、持续部署、流水线配置。

## CI 流水线阶段（MUST 顺序执行）

1. **Install** → 2. **Lint** → 3. **Test** → 4. **Build** → 5. **Image** → 6. **Deploy**

## Install 阶段

- **MUST** 使用 `npm ci` 或 `pnpm install --frozen-lockfile`。
- **MUST** lock 文件提交到版本管理。

## Lint 阶段

- **MUST** 使用 ESLint + Prettier。
- **SHOULD** 使用 `husky` + `lint-staged` 在 pre-commit 执行。

```json
{
  "scripts": {
    "lint": "eslint src/ test/",
    "format": "prettier --write \"src/**/*.js\""
  }
}
```

## Test 阶段

- **MUST** 运行 `npm test`，覆盖率 >= 70%。
- **MUST** 集成测试使用 Testcontainers 或 docker-compose 提供真实数据库。

```json
{
  "jest": {
    "coverageThreshold": {
      "global": {
        "branches": 70,
        "functions": 70,
        "lines": 70,
        "statements": 70
      }
    }
  }
}
```

## Docker 镜像阶段

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY src/ ./src/

FROM node:20-alpine
RUN apk --no-cache add tzdata
COPY --from=builder /app /app
USER node
EXPOSE 3000
CMD ["node", "src/index.js"]
```

## GitHub Actions

```yaml
name: CI
on: [push, pull_request]
jobs:
  ci:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: testdb
        ports: ["5432:5432"]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: "20" }
      - run: npm ci
      - run: npm run lint
      - run: npm test -- --coverage
```

## 部署阶段

- **MUST** 部署前执行健康检查。
- **SHOULD** 使用 PM2 或 Docker 进程管理。
- **SHOULD** 使用 Kubernetes Deployment + Service。

## 禁止事项

- **禁止** 跳过 lint 直接构建。
- **禁止** 测试覆盖率低于 70% 合并 PR。
- **禁止** CI 中使用 `latest` 标签 Docker 镜像。
- **禁止** 镜像中保留 devDependencies。
