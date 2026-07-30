# Vue 3 前端 CI/CD 规则

> 面向 Vue 3 前端项目的 CI/CD 规范。本规则自包含，不依赖其他技术栈目录。

## 1. 通用原则

- **MUST** 所有 CI 使用 GitHub Actions。
- **MUST** workflow 文件位于 `.github/workflows/`。
- **MUST** Secrets 通过 GitHub Secrets 管理，**禁止** 硬编码。
- **MUST** `*-ui`（微前端子应用）和 `*-ui-components`（组件库）使用不同 CI。

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
        working-directory: ./structure-{X}-ui  # 或 ./structure-{X}-ui-components

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: structure-{X}-ui/package-lock.json

      - name: Install dependencies
        run: npm ci

      - name: Run unit tests
        run: npm run test -- --coverage

      - name: Type check
        run: npm run build  # vue-tsc + vite build
```

### 2.2 `build-and-push.yml` —— Docker 构建（`*-ui`）

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
    defaults:
      run:
        working-directory: ./structure-{X}-ui

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install and Build
        run: |
          npm install
          npm run build

      - name: Build and Push Docker Image
        uses: docker/build-push-action@v6
        with:
          context: ./structure-{X}-ui
          push: true
          tags: |
            registry.cn-hangzhou.aliyuncs.com/structured/structure-{X}-ui:${{ github.sha }}
            registry.cn-hangzhou.aliyuncs.com/structured/structure-{X}-ui:latest
```

### 2.3 Dockerfile（`*-ui`）

```dockerfile
FROM nginx:1.27-alpine AS production
COPY dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### 2.4 `publish.yml` —— npm 发布（`*-ui-components`）

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
    defaults:
      run:
        working-directory: ./structure-{X}-ui-components

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          registry-url: 'https://registry.npmjs.org'

      - name: Install dependencies
        run: npm install

      - name: Set version from release tag
        run: |
          TAG_NAME=${{ github.event.release.tag_name }}
          VERSION=${TAG_NAME#v}
          jq --arg v "$VERSION" '.version = $v' package.json > package.tmp.json && mv package.tmp.json package.json

      - name: Build
        run: npm run build

      - name: Publish to npm
        run: npm publish --access public
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**约束**：
- **MUST** 版本号从 release tag 提取（`jq` 写入 `package.json`），**禁止**手工维护版本号。
- **MUST** 发布到 `@structure-projects` scope，`--access public`。
- **MUST** Secrets：`NPM_TOKEN`。
- ⚠️ 只有 `*-ui-components` 才配此 workflow；`*-ui`（微前端子应用，`private: true`）**不发布**。

## 3. Secrets 配置

| Secret | 工作流 | 说明 |
|---|---|---|
| `NPM_TOKEN` | publish.yml | npm 自动化发布 Token |
| `DOCKER_USERNAME` | build-and-push.yml | Docker Registry 用户名 |
| `DOCKER_PASSWORD` | build-and-push.yml | Docker Registry 密码 |
