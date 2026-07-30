# Ionic CI/CD 规则

> 面向 Ionic 项目的 CI/CD 规范。本规则自包含，不依赖其他技术栈目录。

## 1. 通用原则

- **MUST** 所有 CI 使用 GitHub Actions
- **MUST** workflow 文件位于 `.github/workflows/`
- **MUST** Secrets 通过 GitHub Secrets 管理，**禁止** 硬编码
- **MUST** 使用 Node.js 18+ 环境

## 2. 标准 Workflow

### 2.1 `test.yml` —— 测试 + Lint

```yaml
name: Ionic Test

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install Dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: TypeScript Check
        run: npx tsc --noEmit

      - name: Unit Tests
        run: npm run test -- --no-watch --no-progress --browsers=ChromeHeadless --code-coverage

      - name: Upload Coverage
        uses: actions/upload-artifact@v4
        with:
          name: coverage
          path: coverage/
```

### 2.2 `build.yml` —— 构建 Web + 原生

```yaml
name: Ionic Build

on:
  push:
    branches: [main, master]

jobs:
  build-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install Dependencies
        run: npm ci

      - name: Build Web
        run: ionic build --prod

      - name: Upload Web Build
        uses: actions/upload-artifact@v4
        with:
          name: web-build
          path: www/

  build-android:
    runs-on: ubuntu-latest
    needs: build-web
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Download Web Build
        uses: actions/download-artifact@v4
        with:
          name: web-build
          path: www/

      - name: Install Dependencies
        run: npm ci

      - name: Sync Capacitor
        run: npx cap sync android

      - name: Build Android
        run: cd android && ./gradlew assembleRelease

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: android-apk
          path: android/app/build/outputs/apk/release/

  build-ios:
    runs-on: macos-latest
    needs: build-web
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'

      - name: Download Web Build
        uses: actions/download-artifact@v4
        with:
          name: web-build
          path: www/

      - name: Install Dependencies
        run: npm ci

      - name: Sync Capacitor
        run: npx cap sync ios

      - name: Build iOS
        run: |
          cd ios/App
          xcodebuild -workspace App.xcworkspace -scheme App \
            -sdk iphoneos -configuration Release \
            -archivePath $PWD/build/App.xcarchive archive \
            CODE_SIGNING_ALLOWED=NO
```

### 2.3 `deploy.yml` —— 发布商店（Fastlane）

```yaml
name: Deploy to Stores

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'

      - name: Deploy to Google Play
        uses: maierj/fastlane-action@v3
        with:
          lane: android deploy
        env:
          GOOGLE_PLAY_JSON_KEY: ${{ secrets.GOOGLE_PLAY_JSON_KEY }}

  deploy-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Deploy to App Store
        uses: maierj/fastlane-action@v3
        with:
          lane: ios deploy
        env:
          APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
```

## 3. Fastlane 集成

```ruby
# android/fastlane/Fastfile
platform :android do
  desc "Deploy to Google Play"
  lane :deploy do
    gradle(task: "bundleRelease")
    upload_to_play_store(track: 'internal')
  end
end

# ios/fastlane/Fastfile
platform :ios do
  desc "Deploy to App Store"
  lane :deploy do
    match(type: "appstore")
    build_app(scheme: "App")
    upload_to_app_store
  end
end
```

- **SHOULD** 使用 Fastlane 管理发布流程
- **MUST** 签名密钥和 API 密钥通过 Secrets 注入

## 4. E2E 测试集成

```yaml
name: Ionic E2E

on:
  pull_request:
    branches: [main, master]

jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install Dependencies
        run: npm ci

      - name: Cypress E2E
        uses: cypress-io/github-action@v6
        with:
          build: npm run build
          start: npm start
          wait-on: 'http://localhost:8100'
          browser: chrome
```

## 5. Capacitor 资源生成

```yaml
- name: Generate App Assets
  run: npx @capacitor/assets generate --iconBackgroundColor '#3880ff'
```

- **SHOULD** CI 中自动生成应用图标和启动屏

## 6. Secrets 配置

| Secret | 工作流 | 说明 |
|---|---|---|
| `API_BASE_URL` | build.yml | 生产 API 地址 |
| `GOOGLE_PLAY_JSON_KEY` | deploy.yml | Google Play 服务账号 JSON |
| `APP_STORE_CONNECT_API_KEY` | deploy.yml | App Store Connect API Key |
| `MATCH_PASSWORD` | deploy.yml | Fastlane Match 密码（iOS） |
| `KEYSTORE_PASSWORD` | build.yml | Android 签名密钥密码 |

## 7. 禁止事项

- **禁止** 将签名密钥提交到 Git
- **禁止** 在 CI 中硬编码环境变量
- **禁止** 使用 `ionic cordova` 命令（已废弃）
- **禁止** 跳过 `ionic cap sync` 直接构建原生项目
- **禁止** 将 `.env` 文件提交到 Git（包含敏感信息时）
