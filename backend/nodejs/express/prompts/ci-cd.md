# Express CI/CD 规则

Express 项目 CI/CD 流水线配置。

## CI 流水线阶段

1. Install → 2. Lint → 3. Test → 4. Build → 5. Image → 6. Deploy

## Install

- MUST 使用 `npm ci`
- MUST lock 文件提交到版本管理

## Lint

- MUST 使用 ESLint + Prettier
- SHOULD 使用 husky + lint-staged

## Test

- MUST 运行 `npm test`，覆盖率 >= 70%
- MUST 集成测试使用 Testcontainers 或 docker-compose 提供真实数据库

## Docker

多阶段构建，node:20-alpine，运行阶段只保留生产依赖。

## GitHub Actions

使用 setup-node@v4 + npm ci + npm test + npm run build

## 禁止

- 跳过 lint 直接构建
- 测试覆盖率低于 70% 合并 PR
- CI 中使用 latest 标签 Docker 镜像
- 镜像中保留 devDependencies
