# Flutter CI/CD 规则

> 面向 Flutter 项目的 CI/CD 规范。本规则自包含，不依赖其他技术栈目录。

## 1. 通用原则

- **MUST** 所有 CI 使用 GitHub Actions
- **MUST** workflow 文件位于 `.github/workflows/`
- **MUST** Secrets 通过 GitHub Secrets 管理，**禁止** 硬编码
- **MUST** 使用 `subosito/flutter-action` 安装 Flutter

## 2. 标准 Workflow

### 2.1 `test.yml` —— 测试 + 分析

```yaml
name: Flutter Test

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

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Code Generation
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Analyze
        run: flutter analyze

      - name: Format Check
        run: dart format --set-exit-if-changed lib/ test/

      - name: Run Tests
        run: flutter test --coverage

      - name: Upload Coverage
        uses: actions/upload-artifact@v4
        with:
          name: coverage
          path: coverage/lcov.info
```

### 2.2 `build.yml` —— 构建 APK/IPA

```yaml
name: Flutter Build

on:
  push:
    branches: [main, master]

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22'

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Build APK
        run: flutter build apk --release --dart-define=API_BASE_URL=${{ secrets.API_BASE_URL }}

      - name: Build AAB
        run: flutter build appbundle --release

      - name: Upload Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: android-build
          path: build/app/outputs/

  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22'

      - name: Build iOS
        run: flutter build ios --release --no-codesign
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

      - name: Setup Flutter
        uses: subosito/flutter-action@v2

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

      - name: Setup Flutter
        uses: subosito/flutter-action@v2

      - name: Deploy to App Store
        uses: maierj/fastlane-action@v3
        with:
          lane: ios deploy
        env:
          APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
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
    build_app(scheme: "Runner")
    upload_to_app_store
  end
end
```

- **SHOULD** 使用 Fastlane 管理发布流程
- **MUST** 签名密钥和 API 密钥通过 Secrets 注入

## 4. Code Generation

- **MUST** CI 中运行 `build_runner build` 生成代码（Freezed、json_serializable、Riverpod）
- **MUST** 生成的代码提交到仓库（`*.g.dart`、`*.freezed.dart`）
- **禁止** 仅 CI 生成代码而不提交（会导致本地编译失败）

## 5. Secrets 配置

| Secret | 工作流 | 说明 |
|---|---|---|
| `API_BASE_URL` | build.yml | 生产 API 地址 |
| `GOOGLE_PLAY_JSON_KEY` | deploy.yml | Google Play 服务账号 JSON |
| `APP_STORE_CONNECT_API_KEY` | deploy.yml | App Store Connect API Key |
| `KEYSTORE_BASE64` | build.yml | Android 签名密钥 |
| `MATCH_PASSWORD` | deploy.yml | Fastlane Match 密码（iOS） |

## 6. 禁止事项

- **禁止** 将签名密钥提交到 Git
- **禁止** 在 CI 中硬编码环境变量
- **禁止** 跳过代码生成步骤直接构建
- **禁止** 将 `.env` 文件提交到 Git（包含敏感信息时）
