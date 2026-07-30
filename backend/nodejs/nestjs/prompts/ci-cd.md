# NestJS CI/CD 规则

> 适用场景：NestJS 项目的持续集成、持续部署、流水线配置。

## CI 流水线阶段（MUST 顺序执行）

1. **Install** → 2. **Lint** → 3. **Test** → 4. **Build** → 5. **Image** → 6. **Deploy**

## Install 阶段

- **MUST** 使用 `npm ci`（CI 环境）或 `pnpm install --frozen-lockfile`。
- **MUST** 锁定依赖版本（`package-lock.json` 或 `pnpm-lock.yaml` 必须提交）。

## Lint 阶段

- **MUST** 使用 ESLint + `@typescript-eslint` + Prettier。
- **MUST** 配置 `.eslintrc.js` 继承 NestJS 推荐配置。
- **SHOULD** 在 pre-commit hook 中执行 lint-staged。

```json
// package.json scripts
{
  "lint": "eslint \"{src,test}/**/*.ts\" --fix",
  "format": "prettier --write \"src/**/*.ts\""
}
```

## Test 阶段

- **MUST** 运行 `npm test`（单元测试）+ `npm run test:e2e`（E2E 测试）。
- **MUST** 覆盖率门槛 >= 70%。
- **MUST** E2E 测试使用 Testcontainers 或 docker-compose 提供真实数据库。

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

## Build 阶段

- **MUST** 使用 `nest build` 或 `tsc -p tsconfig.build.json` 编译。
- **MUST** 生产构建排除 devDependencies：`npm ci --omit=dev`。

```makefile
build:
	npm run build
	npm ci --omit=dev
```

## Docker 镜像阶段

- **MUST** 使用多阶段构建，构建阶段用 `node:20-alpine`，运行阶段用 `node:20-alpine`。
- **MUST** 运行阶段只复制 `dist/` + `node_modules`（production）+ `package.json`。
- **SHOULD** 使用非 root 用户：`USER node`。

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

## GitHub Actions 示例

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
      - run: npm run build
```

## 部署阶段

- **MUST** 部署前执行健康检查。
- **SHOULD** 使用 NestJS 的 `enableShutdownHooks()` 优雅关闭。
- **SHOULD** 使用 Kubernetes 或 Docker Compose 编排。

## 禁止事项

- **禁止** 跳过 lint 直接构建。
- **禁止** 测试覆盖率低于 70% 时合并 PR。
- **禁止** CI 中使用 `latest` 标签的 Docker 镜像。
- **禁止** 在镜像中保留源代码和 devDependencies。
