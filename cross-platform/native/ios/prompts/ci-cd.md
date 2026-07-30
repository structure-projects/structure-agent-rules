# iOS CI/CD 规则

> 面向 iOS 项目的 CI/CD 规范。本规则自包含，不依赖其他技术栈目录。

## 1. 通用原则

- **MUST** 所有 CI 使用 GitHub Actions
- **MUST** workflow 文件位于 `.github/workflows/`
- **MUST** Secrets 通过 GitHub Secrets 管理，**禁止** 硬编码
- **MUST** 使用 `macos-latest` runner（macOS 是 iOS 构建的必要条件）

## 2. 标准 Workflow

### 2.1 `test.yml` —— 单元测试 + Lint

```yaml
name: iOS Test

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.app

      - name: Run SwiftLint
        run: swiftlint --strict

      - name: Build and Test
        run: |
          xcodebuild test \
            -workspace MyApp.xcworkspace \
            -scheme MyApp \
            -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
            -resultBundlePath TestResults.xcresult

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: TestResults.xcresult
```

### 2.2 `build.yml` —— 构建 IPA

```yaml
name: iOS Build

on:
  push:
    branches: [main, master]

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Certificates
        env:
          BUILD_CERTIFICATE_BASE64: ${{ secrets.BUILD_CERTIFICATE_BASE64 }}
          P12_PASSWORD: ${{ secrets.P12_PASSWORD }}
          PROVISION_PROFILE_BASE64: ${{ secrets.PROVISION_PROFILE_BASE64 }}
        run: |
          echo "$BUILD_CERTIFICATE_BASE64" | base64 -d > certificate.p12
          security create-keychain -p "" build.keychain
          security import certificate.p12 -k build.keychain -P "$P12_PASSWORD" -A
          security set-key-partition-list -S apple-tool:,apple: -s -k "" build.keychain

      - name: Archive
        run: |
          xcodebuild archive \
            -workspace MyApp.xcworkspace \
            -scheme MyApp \
            -archivePath MyApp.xcarchive \
            -destination 'generic/platform=iOS'

      - name: Export IPA
        run: |
          xcodebuild -exportArchive \
            -archivePath MyApp.xcarchive \
            -exportPath . \
            -exportOptionsPlist ExportOptions.plist

      - name: Upload IPA
        uses: actions/upload-artifact@v4
        with:
          name: MyApp.ipa
          path: MyApp.ipa
```

### 2.3 `deploy.yml` —— 发布到 App Store / TestFlight

```yaml
name: Deploy to App Store

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Upload to App Store
        uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: MyApp.ipa
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_API_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_API_PRIVATE_KEY }}
```

## 3. 代码签名

- **MUST** 使用 GitHub Secrets 管理签名证书和 Provisioning Profile
- **MUST** 使用 `ExportOptions.plist` 配置导出选项
- **SHOULD** 使用 Fastlane Match 管理证书（团队协作时）

## 4. SwiftLint 配置

```yaml
# .swiftlint.yml
opt_in_rules:
  - empty_count
  - force_unwrapping
  - closure_spacing
  - explicit_init
  - overridden_super_call

disabled_rules:
  - line_length
  - trailing_whitespace

force_cast: error
force_try: error
```

- **MUST** CI 中运行 `swiftlint --strict`（警告视为错误）
- **MUST** `.swiftlint.yml` 提交到仓库

## 5. Secrets 配置

| Secret | 工作流 | 说明 |
|---|---|---|
| `BUILD_CERTIFICATE_BASE64` | build.yml | Base64 签名证书 .p12 |
| `P12_PASSWORD` | build.yml | .p12 证书密码 |
| `PROVISION_PROFILE_BASE64` | build.yml | Base64 Provisioning Profile |
| `APPSTORE_ISSUER_ID` | deploy.yml | App Store Connect API Issuer ID |
| `APPSTORE_API_KEY_ID` | deploy.yml | App Store Connect API Key ID |
| `APPSTORE_API_PRIVATE_KEY` | deploy.yml | App Store Connect API 私钥 |

## 6. 禁止事项

- **禁止** 将签名证书提交到 Git 仓库
- **禁止** 将 Provisioning Profile 提交到 Git 仓库
- **禁止** 在 CI 中硬编码 API 密钥
- **禁止** 使用 `--allowProvisioningUpdates` 在 CI 中自动管理签名（可能导致冲突）
