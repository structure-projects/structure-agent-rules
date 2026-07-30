# Tauri CI/CD

## GitHub Actions

```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node
        uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - name: Setup Rust
        uses: actions-rs/toolchain@v1
        with: { toolchain: stable }
      - run: npm ci
      - run: npm run test
      - run: cargo test --manifest-path src-tauri/Cargo.toml

  build:
    needs: test
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - uses: actions-rs/toolchain@v1
        with: { toolchain: stable }
      - run: npm ci
      - name: Install Linux deps
        if: runner.os == 'Linux'
        run: sudo apt-get install -y libwebkit2gtk-4.1-dev
      - run: npm run tauri build
      - uses: actions/upload-artifact@v4
        with:
          name: app-${{ runner.os }}
          path: src-tauri/target/release/bundle/
```

## 自动更新

```json
// tauri.conf.json
{
  "plugins": {
    "updater": {
      "endpoints": ["https://updates.example.com/{{target}}/{{current_version}}"],
      "pubkey": "YOUR_PUBLIC_KEY"
    }
  }
}
```

## 检查清单

- [ ] Linux 构建安装 `libwebkit2gtk-4.1-dev`
- [ ] 各平台 artifact 正确上传
- [ ] 签名证书配置（macOS codesign, Windows EV）
- [ ] 自动更新 endpoint 正确
- [ ] 版本号语义化版本
