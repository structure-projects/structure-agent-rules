# Electron 项目脚手架规则

> 面向创建 Electron 项目的 AI Agent。

## 创建步骤

### 方式一：electron-vite（推荐，Vite + Electron）

```bash
npm create @quick-start/electron@latest my-electron-app -- --template react-ts
```

### 方式二：electron-forge + Vite

```bash
npm init electron-app@latest my-electron-app -- --template=vite-typescript
```

### 方式三：手动搭建

```bash
mkdir my-electron-app && cd my-electron-app
npm init -y
npm install electron@latest electron-builder --save-dev
npm install electron-updater electron-store better-sqlite3
```

- **MUST** Electron 28+
- **MUST** Node.js 18+
- **MUST** 前端构建工具：Vite（推荐）

## 前端框架模板

```bash
# React + TypeScript
npm create @quick-start/electron@latest my-app -- --template react-ts

# Vue 3 + TypeScript
npm create @quick-start/electron@latest my-app -- --template vue-ts

# Svelte + TypeScript
npm create @quick-start/electron@latest my-app -- --template svelte-ts
```

## 项目配置

### package.json

```json
{
  "name": "my-electron-app",
  "version": "0.1.0",
  "description": "My Electron App",
  "main": "dist/main/index.js",
  "scripts": {
    "dev": "electron-vite dev",
    "build": "electron-vite build",
    "preview": "electron-vite preview",
    "lint": "eslint . --ext .ts,.tsx",
    "typecheck": "tsc --noEmit",
    "test": "jest",
    "test:e2e": "playwright test",
    "pack": "electron-builder --dir",
    "dist": "electron-builder",
    "dist:mac": "electron-builder --mac",
    "dist:win": "electron-builder --win",
    "dist:linux": "electron-builder --linux"
  },
  "dependencies": {
    "electron-updater": "^6.0.0",
    "electron-store": "^8.0.0",
    "better-sqlite3": "^11.0.0"
  },
  "devDependencies": {
    "electron": "^28.0.0",
    "electron-builder": "^24.0.0",
    "electron-vite": "^2.0.0",
    "@types/better-sqlite3": "^7.0.0",
    "typescript": "^5.3.0",
    "eslint": "^8.0.0",
    "jest": "^29.0.0",
    "@playwright/test": "^1.40.0"
  }
}
```

### electron-builder.yml

```yaml
appId: com.example.my-electron-app
productName: MyElectronApp
copyright: Copyright © 2024

directories:
  output: dist
  buildResources: resources

files:
  - "dist/**/*"
  - "!**/*.ts"
  - "!**/*.map"
  - "!**/src/**"

mac:
  category: public.app-category.utilities
  icon: resources/icon.icns
  target:
    - target: dmg
      arch: [x64, arm64]
    - target: zip
      arch: [x64, arm64]
  hardenedRuntime: true
  entitlements: resources/entitlements.mac.plist

win:
  icon: resources/icon.ico
  target:
    - target: nsis
      arch: [x64, ia32]
    - target: portable

linux:
  icon: resources/icon.png
  target:
    - target: AppImage
      arch: [x64]
    - target: deb
      arch: [x64]
  category: Utility

nsis:
  oneClick: false
  perMachine: false
  allowToChangeInstallationDirectory: true
  deleteAppDataOnUninstall: false

publish:
  provider: github
  owner: my-org
  repo: my-electron-app
```

- **MUST** `appId` 使用反向域名格式
- **MUST** 多平台 target 配置
- **MUST** macOS `hardenedRuntime: true`

### tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx"
  }
}
```

- **MUST** `strict: true`
- **MUST** `target: "ES2022"`（Electron 28+ 支持）

## 目录结构

```
my-electron-app/
├── src/
│   ├── main/                      # 主进程
│   │   ├── index.ts               # 入口
│   │   ├── ipc/                   # IPC Handler
│   │   │   ├── index.ts
│   │   │   ├── greet.handler.ts
│   │   │   └── file.handler.ts
│   │   ├── services/
│   │   │   └── db.service.ts
│   │   ├── menu.ts
│   │   ├── tray.ts
│   │   └── updater.ts
│   ├── preload/
│   │   └── index.ts               # contextBridge
│   ├── renderer/                  # 渲染进程（前端）
│   │   ├── src/
│   │   │   ├── App.tsx
│   │   │   ├── main.tsx
│   │   │   ├── components/
│   │   │   ├── hooks/
│   │   │   └── services/
│   │   │       └── electron.service.ts
│   │   └── index.html
│   └── shared/
│       └── types.ts               # IPC 通道类型
├── resources/                     # 打包资源
│   ├── icon.png
│   ├── icon.icns
│   └── icon.ico
├── e2e/
│   └── app.e2e.ts
├── package.json
├── electron-builder.yml
├── tsconfig.json
├── electron.vite.config.ts
└── .gitignore
```

## 主进程入口模板

```typescript
// src/main/index.ts
import { app, BrowserWindow, shell } from 'electron';
import path from 'path';
import { registerIpcHandlers } from './ipc';
import { createAppMenu } from './menu';
import { createTray } from './tray';
import { setupAutoUpdater } from './updater';

let mainWindow: BrowserWindow | null = null;

function createWindow(): void {
  mainWindow = new BrowserWindow({
    width: 1024,
    height: 768,
    minWidth: 800,
    minHeight: 600,
    show: false,
    webPreferences: {
      preload: path.join(__dirname, '../preload/index.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
  });

  mainWindow.on('ready-to-show', () => {
    mainWindow?.show();
  });

  // 外部链接用默认浏览器打开
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    if (url.startsWith('https:')) shell.openExternal(url);
    return { action: 'deny' };
  });

  if (process.env.NODE_ENV === 'development') {
    mainWindow.loadURL('http://localhost:5173');
    mainWindow.webContents.openDevTools();
  } else {
    mainWindow.loadFile(path.join(__dirname, '../renderer/index.html'));
  }
}

app.whenReady().then(() => {
  registerIpcHandlers();
  createWindow();
  createAppMenu(mainWindow!);
  createTray(mainWindow!);
  setupAutoUpdater(mainWindow!);

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
```

## 构建命令

```bash
# 开发
npm run dev                        # electron-vite dev（热重载）

# 构建
npm run build                      # 编译 TypeScript + 打包前端
npm run pack                       # electron-builder --dir（测试打包）
npm run dist                       # 完整打包（当前平台）
npm run dist:mac                   # macOS
npm run dist:win                   # Windows
npm run dist:linux                 # Linux
```

## .gitignore 关键条目

```
# 构建产物
dist/
out/
release/

# 依赖
node_modules/

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db

# 签名密钥
*.p12
*.pem
*.key

# 环境变量
.env
.env.local
```

## 检查清单

- [ ] Electron 28+ + Node.js 18+
- [ ] `contextIsolation: true`
- [ ] `nodeIntegration: false`
- [ ] `sandbox: true`（生产环境）
- [ ] `appId` 反向域名
- [ ] 多平台构建配置
- [ ] CSP 配置
- [ ] 自动更新配置
- [ ] 代码签名证书配置
- [ ] `.gitignore` 排除 `dist/`、签名密钥
- [ ] Preload 最小权限暴露

## 禁止事项

- **禁止** 使用 Electron < 28（安全漏洞）
- **禁止** `nodeIntegration: true`（极度危险）
- **禁止** `contextIsolation: false`（极度危险）
- **禁止** `enableRemoteModule: true`
- **禁止** 签名密钥提交到 Git
- **禁止** 渲染进程直接 `require('electron')` 或 `require('fs')`
