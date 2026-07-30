# UniApp 前端 CI/CD 规则

> 面向 UniApp 前端项目的 CI/CD 规范。本规则自包含，不依赖其他技术栈目录。

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

      - name: Unit tests
        run: npm run test -- --coverage

      - name: Build (H5)
        run: npm run build:h5
```

### 2.2 `build-h5.yml` —— H5 构建部署

```yaml
name: Build and Deploy H5

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
          npm run build:h5

      - name: Build and Push Docker Image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: |
            registry.example.com/${{ github.event.repository.name }}-h5:${{ github.sha }}
            registry.example.com/${{ github.event.repository.name }}-h5:latest
```

### 2.3 `build-mp-weixin.yml` —— 微信小程序 CI

```yaml
name: Build WeChat Mini Program

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

      - name: Install dependencies
        run: npm ci

      - name: Build Mini Program
        run: npm run build:mp-weixin

      - name: Upload Mini Program
        uses: actions/upload-artifact@v4
        with:
          name: mp-weixin-dist
          path: dist/build/mp-weixin/

      - name: Upload via miniprogram-ci
        run: |
          npx miniprogram-ci upload \
            --pp ./dist/build/mp-weixin/ \
            --pkp ./private.key \
            --appid ${{ secrets.WX_APPID }} \
            --uv ${{ secrets.WX_UPLOAD_VERSION }}
```

### 2.4 Dockerfile（H5 部署）

```dockerfile
FROM nginx:1.27-alpine
COPY dist/build/h5 /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## 3. 平台构建命令

| 平台 | 命令 |
|---|---|
| H5 | `npm run build:h5` |
| 微信小程序 | `npm run build:mp-weixin` |
| 支付宝小程序 | `npm run build:mp-alipay` |
| App | HBuilderX 云打包或本地打包 |

## 4. 小程序提审

- **MUST** 使用 `miniprogram-ci` 自动上传代码
- **MUST** `private.key` 通过 CI Secrets 注入
- **MUST** 版本号通过 CI 变量管理

## 5. Secrets 配置

| Secret | 工作流 | 说明 |
|---|---|---|
| `WX_APPID` | build-mp-weixin.yml | 微信小程序 AppID |
| `WX_UPLOAD_VERSION` | build-mp-weixin.yml | 上传版本号 |
| `DOCKER_USERNAME` | build-h5.yml | Docker Registry 用户名 |
| `DOCKER_PASSWORD` | build-h5.yml | Docker Registry 密码 |
