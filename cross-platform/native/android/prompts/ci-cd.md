# Android CI/CD 规则

> 面向 Android 项目的 CI/CD 规范。本规则自包含，不依赖其他技术栈目录。

## 1. 通用原则

- **MUST** 所有 CI 使用 GitHub Actions
- **MUST** workflow 文件位于 `.github/workflows/`
- **MUST** Secrets 通过 GitHub Secrets 管理，**禁止** 硬编码
- **MUST** 区分 debug（开发/测试）和 release（发布）构建

## 2. 标准 Workflow

### 2.1 `test.yml` —— 单元测试 + Lint

```yaml
name: Android Test

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

      - name: Setup JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Setup Gradle
        uses: gradle/actions/setup-gradle@v3

      - name: Run Lint
        run: ./gradlew lint

      - name: Run Unit Tests
        run: ./gradlew test

      - name: Upload Test Report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-report
          path: app/build/reports/tests/
```

### 2.2 `build.yml` —— 构建 APK/AAB

```yaml
name: Android Build

on:
  push:
    branches: [main, master]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Decode Keystore
        env:
          KEYSTORE_BASE64: ${{ secrets.KEYSTORE_BASE64 }}
        run: echo "$KEYSTORE_BASE64" | base64 -d > app/keystore.jks

      - name: Build Release AAB
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
        run: ./gradlew bundleRelease

      - name: Upload AAB
        uses: actions/upload-artifact@v4
        with:
          name: app-release.aab
          path: app/build/outputs/bundle/release/app-release.aab
```

### 2.3 `deploy.yml` —— 发布到 Google Play（内部测试）

```yaml
name: Deploy to Google Play

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Build and Deploy
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
          packageName: com.example.app
          releaseFiles: app/build/outputs/bundle/release/app-release.aab
          track: internal
```

## 3. 构建类型配置

```kotlin
// app/build.gradle.kts
android {
    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            isDebuggable = true
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

- **MUST** release 构建开启 minify + shrinkResources
- **MUST** debug 构建使用独立 applicationId（`applicationIdSuffix = ".debug"`）
- **MUST** 签名密钥通过 GitHub Secrets 注入，**禁止** 提交到仓库

## 4. Firebase 集成

- **SHOULD** 集成 Firebase Crashlytics 进行崩溃收集
- **SHOULD** 集成 Firebase Analytics 进行用户行为分析
- **MAY** 集成 Firebase Cloud Messaging（FCM）实现推送通知
- **MUST** `google-services.json` 通过 Secrets 注入，**禁止** 提交到仓库

## 5. Secrets 配置

| Secret | 工作流 | 说明 |
|---|---|---|
| `KEYSTORE_BASE64` | build.yml | Base64 编码的签名密钥文件 |
| `KEYSTORE_PASSWORD` | build.yml | 密钥库密码 |
| `KEY_ALIAS` | build.yml | 密钥别名 |
| `KEY_PASSWORD` | build.yml | 密钥密码 |
| `GOOGLE_PLAY_SERVICE_ACCOUNT` | deploy.yml | Google Play Console API 服务账号 JSON |

## 6. 禁止事项

- **禁止** 将签名密钥（keystore）提交到 Git 仓库
- **禁止** 将 `google-services.json` 提交到 Git 仓库
- **禁止** 在 CI 中直接使用明文密码
- **禁止** debug 和 release 使用同一个 applicationId
