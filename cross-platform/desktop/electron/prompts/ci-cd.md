# Electron CI/CD 规则

> 面向 Electron 项目的 CI/CD 规范。本规则自包含，不依赖其他技术栈目录。

## 1. 通用原则

- **MUST** 所有 CI 使用 GitHub Actions
- **MUST** workflow 文件位于 `.github/workflows/`
- **MUST** Secrets 通过 GitHub Secrets 管理
- **MUST** 多平台构建（Windows、macOS、Linux）

## 2. 标准 Workflow

### 2.1 `test.yml` —— 测试 + Lint

```yaml
name: Electron Test

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

      - name: Install Dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: TypeScript Check
        run: npm run typecheck

      - name: Unit Tests
        run: npm run test -- --coverage

      - name: Upload Coverage
        uses: actions/upload-artifact@v4
        with:
          name: coverage
          path: coverage/
```

### 2.2 `build.yml` —— 多平台构建

```yaml
name: Electron Build

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: ubuntu-latest
            target: linux
          - os: macos-latest
            target: mac
          - os: windows-latest
            target: win

    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install Dependencies
        run: npm ci

      - name: Build Electron
        run: npm run dist:${{ matrix.target }}
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APPLE_APP_SPECIFIC_PASSWORD: ${{ secrets.APPLE_APP_SPECIFIC_PASSWORD }}
          APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
          CSC_LINK: ${{ secrets.CSC_LINK }}
          CSC_KEY_PASSWORD: ${{ secrets.CSC_KEY_PASSWORD }}
          WIN_CSC_LINK: ${{ secrets.WIN_CSC_LINK }}
          WIN_CSC_KEY_PASSWORD: ${{ secrets.WIN_CSC_KEY_PASSWORD }}

      - name: Upload Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: electron-${{ matrix.target }}
          path: |
            dist/*.dmg
            dist/*.zip
            dist/*.AppImage
            dist/*.deb
            dist/*.exe
```

### 2.3 `release.yml` —— 发布到 GitHub Releases

```yaml
name: Electron Release

on:
  workflow_dispatch:
    inputs:
      version:
        description: '发布版本号 (e.g. 0.1.0)'
        required: true

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install Dependencies
        run: npm ci

      - name: Build and Release
        run: npm run dist
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        # electron-builder 自动发布到 GitHub Releases（publish.provider: github）
```

## 3. E2E 测试（Playwright + Electron）

```yaml
name: Electron E2E

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
          node-version: '20'
          cache: 'npm'

      - name: Install Dependencies
        run: npm ci

      - name: Install Playwright
        run: npx playwright install --with-deps chromium

      - name: Build
        run: npm run build

      - name: Run E2E
        run: xvfb-run npx playwright test
```

## 4. 代码签名

### macOS 签名

```yaml
- name: Setup macOS Code Signing
  if: matrix.os == 'macos-latest'
  env:
    MACOS_CERTIFICATE: ${{ secrets.MACOS_CERTIFICATE }}
    MACOS_CERTIFICATE_PWD: ${{ secrets.MACOS_CERTIFICATE_PWD }}
    KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
  run: |
    echo "$MACOS_CERTIFICATE" | base64 --decode > certificate.p12
    security create-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
    security default-keychain -s build.keychain
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
    security import certificate.p12 -k build.keychain -P "$MACOS_CERTIFICATE_PWD" -T /usr/bin/codesign
    security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASSWORD" build.keychain
```

### Windows 签名

```yaml
- name: Setup Windows Code Signing
  if: matrix.os == 'windows-latest'
  env:
    WINDOWS_CERTIFICATE: ${{ secrets.WINDOWS_CERTIFICATE }}
    WINDOWS_CERTIFICATE_PASSWORD: ${{ secrets.WINDOWS_CERTIFICATE_PASSWORD }}
  run: |
    echo "$WINDOWS_CERTIFICATE" | base64 --decode > certificate.pfx
```

## 5. 自动更新服务器

```yaml
# electron-builder.yml 中的 publish 配置自动处理
# GitHub Releases: provider: github
# 自建服务器: provider: generic, url: https://updates.example.com
```

## 6. Secrets 配置

| Secret | 工作流 | 说明 |
|---|---|---|
| `GITHUB_TOKEN` | build, release | GitHub 自动提供 |
| `APPLE_ID` | build (macOS) | Apple ID（公证） |
| `APPLE_APP_SPECIFIC_PASSWORD` | build (macOS) | Apple 应用专用密码 |
| `APPLE_TEAM_ID` | build (macOS) | Apple 团队 ID |
| `CSC_LINK` | build (macOS) | macOS 签名证书（base64） |
| `CSC_KEY_PASSWORD` | build (macOS) | macOS 签名证书密码 |
| `WIN_CSC_LINK` | build (Windows) | Windows 签名证书（base64） |
| `WIN_CSC_KEY_PASSWORD` | build (Windows) | Windows 签名证书密码 |

## 7. 禁止事项

- **禁止** 签名证书/私钥提交到 Git
- **禁止** 在 CI 中硬编码版本号
- **禁止** 跳过 TypeScript 类型检查
- **禁止** 跳过 Lint 检查
- **禁止** 在 CI 中使用 `npm install`（应用 `npm ci`）
- **禁止** 使用 Electron < 28 版本
