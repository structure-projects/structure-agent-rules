# Tauri 项目搭建

## 创建项目

```bash
# npm
npm create tauri-app@latest

# 交互选择: 项目名、前端框架、包管理

cd my-tauri-app
npm install
```

## 项目结构

```
my-tauri-app/
├── src-tauri/              # Rust Core
│   ├── Cargo.toml
│   ├── tauri.conf.json     # 核心配置
│   ├── capabilities/       # 权限声明
│   ├── icons/              # 桌面图标
│   └── src/
│       ├── main.rs         # 入口 + Command 注册
│       └── lib.rs
├── src/                    # Frontend (React/Vue)
│   ├── App.tsx
│   └── main.tsx
├── package.json
├── tsconfig.json
└── vite.config.ts
```

## tauri.conf.json 核心配置

```json
{
  "$schema": "https://raw.githubusercontent.com/tauri-apps/tauri/dev/crates/tauri-config-schema/schema.json",
  "productName": "My App",
  "version": "1.0.0",
  "identifier": "com.example.myapp",
  "build": {
    "frontendDist": "../dist",
    "devUrl": "http://localhost:1420",
    "beforeDevCommand": "npm run dev",
    "beforeBuildCommand": "npm run build"
  },
  "app": {
    "windows": [
      {
        "title": "My App",
        "width": 1200,
        "height": 800
      }
    ],
    "security": {
      "csp": "default-src 'self'; script-src 'self'"
    }
  },
  "bundle": {
    "active": true,
    "targets": "all",
    "icon": [
      "icons/32x32.png",
      "icons/128x128.png",
      "icons/icon.icns",
      "icons/icon.ico"
    ]
  }
}
```

## 开发命令

```bash
npm run tauri dev     # 开发运行
npm run tauri build   # 生产构建
npm run tauri android # Android 构建
npm run tauri ios     # iOS 构建
```

## Rust 依赖

```toml
[dependencies]
tauri = { version = "2", features = ["unstable"] }
tauri-plugin-fs = "2"
tauri-plugin-shell = "2"
tauri-plugin-dialog = "2"
tauri-plugin-notification = "2"
tauri-plugin-updater = "2"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
sqlx = { version = "0.7", features = ["runtime-tokio", "sqlite"] }
```
