# Electron 架构规则

> 角色：structure-architect（桌面架构）。面向需要做 Electron 架构选型与技术决策的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。IDE 包装文件使用 `electron-` 前缀。

## 进程模型

### 三层架构

- **MUST** Main Process（Node.js 全能力）：窗口管理、文件系统、系统 API、IPC 处理、数据库
- **MUST** Renderer Process（Chromium，沙箱隔离）：UI 渲染，只能通过 IPC 访问系统能力
- **MUST** Preload Script：`contextBridge` 桥接层，安全暴露有限 API

```
┌──────────────────────────────────┐
│    Renderer Process (沙箱)       │
│    React / Vue / Svelte          │
│    - UI 渲染                      │
│    - 用户交互                     │
│    - 只能通过 window.electronAPI  │
│      调用主进程                   │
└──────────┬───────────────────────┘
           │ contextBridge (preload)
┌──────────▼───────────────────────┐
│       Main Process (Node.js)     │
│    - 窗口管理 (BrowserWindow)     │
│    - 文件系统 (fs)               │
│    - 数据库 (better-sqlite3)     │
│    - IPC Handler                 │
│    - 原生菜单 (Menu)             │
│    - 系统托盘 (Tray)             │
│    - 自动更新 (electron-updater) │
└──────────────────────────────────┘
```

### 主进程分层

```
src/main/
├── index.ts               # 入口：app.whenReady、创建窗口
├── ipc/                   # IPC Handler 层
│   ├── index.ts           # 注册所有 Handler
│   ├── greet.handler.ts
│   └── file.handler.ts
├── services/              # 业务逻辑层
│   ├── db.service.ts      # 数据库服务
│   └── config.service.ts  # 配置服务
├── menu.ts                # 原生菜单
├── tray.ts                # 系统托盘
└── updater.ts             # 自动更新
```

- **MUST** IPC Handler 只做输入验证和调用 Service
- **MUST** Service 层包含核心业务逻辑
- **MUST** 每个业务域独立 Handler 文件

### 渲染进程分层

```
src/renderer/
├── src/
│   ├── App.tsx
│   ├── main.tsx
│   ├── components/        # UI 组件
│   ├── hooks/             # React Hooks / Vue Composables
│   ├── services/
│   │   └── electron.service.ts  # window.electronAPI 封装
│   └── stores/            # 状态管理
├── index.html
└── vite.config.ts
```

- **MUST** `electron.service.ts` 封装 `window.electronAPI` 调用
- **MUST** 组件通过 Service/Hooks 调用（不直接访问 `window.electronAPI`）

## IPC 通信

### 请求-响应模式（Renderer → Main）

```typescript
// Main: ipcMain.handle()
ipcMain.handle('get-user', async (_event, userId: number): Promise<User> => {
  return dbService.getUser(userId);
});

// Preload: contextBridge
const api = {
  getUser: (userId: number) => ipcRenderer.invoke('get-user', userId),
};
contextBridge.exposeInMainWorld('electronAPI', api);

// Renderer: window.electronAPI
const user = await window.electronAPI.getUser(1);
```

- **MUST** 使用 `ipcMain.handle()` + `ipcRenderer.invoke()`（异步，返回 Promise）
- **禁止** 使用 `ipcRenderer.sendSync()`（阻塞渲染进程）

### 推送模式（Main → Renderer）

```typescript
// Main: webContents.send()
mainWindow.webContents.send('data-updated', { count: 42 });

// Preload: contextBridge + ipcRenderer.on
const api = {
  onDataUpdated: (callback: (data: any) => void) => {
    ipcRenderer.on('data-updated', (_event, data) => callback(data));
  },
};

// Renderer
window.electronAPI.onDataUpdated((data) => {
  console.log(data.count); // 42
});
```

- **MUST** Main → Renderer 推送使用 `webContents.send()`
- **MUST** Renderer 监听通过 `ipcRenderer.on()`（在 preload 中封装）

## 窗口管理

### 单窗口

```typescript
const mainWindow = new BrowserWindow({
  width: 1024,
  height: 768,
  minWidth: 800,
  minHeight: 600,
  title: 'My App',
  webPreferences: {
    preload: path.join(__dirname, '../preload/index.js'),
    contextIsolation: true,
    nodeIntegration: false,
    sandbox: true,
  },
});
```

### 多窗口

```typescript
function openSettingsWindow(): BrowserWindow {
  const settingsWindow = new BrowserWindow({
    width: 600,
    height: 400,
    parent: mainWindow,
    modal: true,
    webPreferences: {
      preload: path.join(__dirname, '../preload/index.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
  });

  settingsWindow.loadFile(path.join(__dirname, '../renderer/settings.html'));
  return settingsWindow;
}
```

- **MUST** 子窗口设置 `parent` 属性关联主窗口
- **SHOULD** 模态窗口使用 `modal: true`
- **MUST** 每个窗口使用相同的 preload 安全配置

### 原生菜单

```typescript
const template: Electron.MenuItemConstructorOptions[] = [
  {
    label: '文件',
    submenu: [
      { label: '新建', accelerator: 'CmdOrCtrl+N' },
      { label: '打开', accelerator: 'CmdOrCtrl+O' },
      { type: 'separator' },
      { role: 'quit' },
    ],
  },
  { label: '编辑', submenu: [/* undo, redo, cut, copy, paste */] },
  { label: '视图', submenu: [/* reload, devtools */] },
  { label: '帮助', submenu: [/* about */] },
];

const menu = Menu.buildFromTemplate(template);
Menu.setApplicationMenu(menu);
```

### 系统托盘

```typescript
const tray = new Tray('/path/to/icon.png');
tray.setToolTip('My App');
tray.setContextMenu(Menu.buildFromTemplate([
  { label: '显示', click: () => mainWindow.show() },
  { type: 'separator' },
  { label: '退出', click: () => app.quit() },
]));
```

## 数据层

- **MUST** 文件系统：主进程 `fs/promises`，通过 IPC 暴露
- **MUST** SQL：`better-sqlite3`（同步，适合 Electron 单用户场景）
- **SHOULD** 键值存储：`electron-store`（支持加密）
- **MUST** 数据库操作在主进程（渲染进程不直接访问 DB）

```typescript
// 数据库服务
import Database from 'better-sqlite3';
import path from 'path';
import { app } from 'electron';

class DbService {
  private db: Database.Database;

  constructor() {
    const dbPath = path.join(app.getPath('userData'), 'app.db');
    this.db = new Database(dbPath);
    this.db.pragma('journal_mode = WAL');
    this.initTables();
  }

  private initTables(): void {
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);
  }

  getUsers(): User[] {
    return this.db.prepare('SELECT * FROM users ORDER BY id DESC').all() as User[];
  }
}
```

## 安全

- **MUST** `contextIsolation: true`（永远不要关闭）
- **MUST** `nodeIntegration: false`（永远不要开启）
- **MUST** `sandbox: true`（生产环境）
- **MUST** `webSecurity: true`
- **禁止** `enableRemoteModule: true`
- **MUST** CSP 配置：

```html
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'">
```

- **MUST** IPC 输入验证
- **禁止** 加载不可信外部 URL

## 自动更新

```typescript
import { autoUpdater } from 'electron-updater';

export function setupAutoUpdater(): void {
  autoUpdater.autoDownload = false;
  autoUpdater.autoInstallOnAppQuit = true;

  autoUpdater.on('update-available', (info) => {
    // 通知用户有新版本
    mainWindow?.webContents.send('update-available', info);
  });

  autoUpdater.on('download-progress', (progress) => {
    mainWindow?.webContents.send('download-progress', progress);
  });

  autoUpdater.on('update-downloaded', () => {
    // 提示用户重启安装
    mainWindow?.webContents.send('update-downloaded');
  });

  // 启动时检查更新
  autoUpdater.checkForUpdates();
}
```

- **SHOULD** 使用 `electron-updater`（配合 electron-builder）
- **SHOULD** 提供手动检查更新入口
- **MUST** 更新包签名验证

## 打包

### electron-builder.yml

```yaml
appId: com.example.my-electron-app
productName: MyElectronApp
directories:
  output: dist
  buildResources: resources
files:
  - "!**/*.ts"
  - "!**/*.map"
  - "!src/**"
mac:
  category: public.app-category.utilities
  target:
    - dmg
    - zip
win:
  target:
    - nsis
    - portable
linux:
  target:
    - AppImage
    - deb
nsis:
  oneClick: false
  allowToChangeInstallationDirectory: true
publish:
  provider: github
  owner: my-org
  repo: my-electron-app
```

- **MUST** 使用 `electron-builder` 或 `electron-forge`
- **MUST** 多平台构建支持
- **SHOULD** 代码签名（macOS/Windows）
