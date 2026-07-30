# React Native CI/CD 规则

> 面向 React Native 项目的 CI/CD 规范。本规则自包含，不依赖其他技术栈目录。

## 1. 通用原则

- **MUST** 所有 CI 使用 GitHub Actions
- **MUST** workflow 文件位于 `.github/workflows/`
- **MUST** Secrets 通过 GitHub Secrets 管理，**禁止** 硬编码
- **MUST** 区分 Expo 托管和 React Native CLI 项目

## 2. 标准 Workflow

### 2.1 `test.yml` —— 测试 + Lint + Type Check

```yaml
name: Test

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
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: TypeScript Check
        run: npx tsc --noEmit

      - name: Lint
        run: npm run lint

      - name: Unit Tests
        run: npm run test -- --coverage

      - name: Upload Coverage
        uses: actions/upload-artifact@v4
        with:
          name: coverage
          path: coverage/
```

### 2.2 `eas-build.yml` —— EAS Build（Expo 项目）

```yaml
name: EAS Build

on:
  push:
    branches: [main, master]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Setup Expo
        uses: expo/expo-github-action@v8
        with:
          expo-version: latest
          token: ${{ secrets.EXPO_TOKEN }}

      - name: Install dependencies
        run: npm ci

      - name: EAS Build (Android)
        run: eas build --platform android --profile preview --non-interactive

      - name: EAS Build (iOS)
        run: eas build --platform ios --profile preview --non-interactive
```

### 2.3 `eas-submit.yml` —— EAS Submit（发布商店）

```yaml
name: EAS Submit

on:
  push:
    tags:
      - 'v*'

jobs:
  submit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Expo
        uses: expo/expo-github-action@v8
        with:
          token: ${{ secrets.EXPO_TOKEN }}

      - name: EAS Submit (Android)
        run: eas submit --platform android --latest

      - name: EAS Submit (iOS)
        run: eas submit --platform ios --latest
```

## 3. EAS Build 配置 (`eas.json`)

```json
{
  "cli": { "version": ">= 7.0.0" },
  "build": {
    "preview": {
      "distribution": "internal",
      "android": { "buildType": "apk" },
      "ios": { "simulator": false }
    },
    "production": {
      "android": { "buildType": "app-bundle" },
      "ios": { "autoIncrement": true },
      "channel": "production"
    }
  },
  "submit": {
    "production": {}
  }
}
```

- **MUST** `preview` profile 用于内部测试
- **MUST** `production` profile 用于商店发布
- **MUST** Android production 使用 `app-bundle`

## 4. OTA 更新（Expo Updates）

- **SHOULD** 配置 `expo-updates` 实现 OTA 热更新
- **MUST** 使用 `channel` 区分环境（production、staging）
- **MUST** `expo publish` 或 `eas update` 发布更新

## 5. Secrets 配置

| Secret | 工作流 | 说明 |
|---|---|---|
| `EXPO_TOKEN` | eas-build.yml, eas-submit.yml | Expo 访问令牌 |
| `SENTRY_AUTH_TOKEN` | eas-build.yml | Sentry 错误追踪（可选） |

## 6. 禁止事项

- **禁止** 将签名密钥/证书提交到 Git
- **禁止** 将 `google-services.json` / `GoogleService-Info.plist` 提交到 Git
- **禁止** 在 CI 中硬编码 API 密钥
- **禁止** 在 `eas.json` 中硬编码敏感信息
