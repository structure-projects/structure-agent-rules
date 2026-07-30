# Electron 组件/模块使用规范

> 本文件描述 Electron 开发中的进程通信、原生对话框、菜单、托盘和常用库使用规范。
> 本规则自包含，不依赖其他技术栈目录。

## IPC 通信规范

### 请求-响应模式（推荐）

```typescript
// === 共享类型 (src/shared/types.ts) ===
export const IPC_CHANNELS = {
  GREET: 'greet',
  SAVE_FILE: 'save-file',
  READ_FILE: 'read-file',
  GET_USER: 'get-user',
  CREATE_USER: 'create-user',
} as const;

// === 主进程 (src/main/ipc/greet.handler.ts) ===
import { ipcMain } from 'electron';
import { IPC_CHANNELS } from '../../shared/types';

export function registerGreetHandler(): void {
  ipcMain.handle(IPC_CHANNELS.GREET, async (_event, name: string): Promise<string> => {
    if (!name?.trim()) throw new Error('名称不能为空');
    return `你好, ${name.trim()}!`;
  });
}

// === Preload (src/preload/index.ts) ===
import { contextBridge, ipcRenderer } from 'electron';
import { IPC_CHANNELS } from '../shared/types';

const api = {
  greet: (name: string) => ipcRenderer.invoke(IPC_CHANNELS.GREET, name),
};

contextBridge.exposeInMainWorld('electronAPI', api);

// === 渲染进程 ===
const greeting = await window.electronAPI.greet('World');
```

- **MUST** IPC 通道名在 `shared/types.ts` 中统一定义
- **MUST** 使用 `ipcMain.handle()` + `ipcRenderer.invoke()`（异步）
- **禁止** 使用 `ipcRenderer.sendSync()`（阻塞）

### 事件推送模式（Main → Renderer）

```typescript
// === 主进程 ===
mainWindow.webContents.send('data-updated', { count: 42 });

// === Preload ===
const api = {
  onDataUpdated: (callback: (data: unknown) => void) => {
    const handler = (_event: Electron.IpcRendererEvent, data: unknown) => callback(data);
    ipcRenderer.on('data-updated', handler);
    // 返回清理函数
    return () => ipcRenderer.removeListener('data-updated', handler);
  },
};
```

- **MUST** Preload 中提供清理函数（`removeListener`）
- **MUST** 渲染进程中在组件卸载时调用清理函数

## 原生对话框

### 打开文件

```typescript
import { dialog, BrowserWindow } from 'electron';

ipcMain.handle('open-file', async (): Promise<{ content: string; filePath: string } | null> => {
  const window = BrowserWindow.getFocusedWindow();
  if (!window) throw new Error('无活动窗口');

  const { filePaths, canceled } = await dialog.showOpenDialog(window, {
    title: '选择文件',
    filters: [
      { name: '文本文件', extensions: ['txt', 'md', 'json'] },
      { name: '所有文件', extensions: ['*'] },
    ],
    properties: ['openFile'],
  });

  if (canceled || filePaths.length === 0) return null;

  const content = await fs.promises.readFile(filePaths[0], 'utf-8');
  return { content, filePath: filePaths[0] };
});
```

### 保存文件

```typescript
ipcMain.handle('save-file', async (_event, content: string, defaultName?: string): Promise<string | null> => {
  const window = BrowserWindow.getFocusedWindow();
  if (!window) throw new Error('无活动窗口');

  const { filePath, canceled } = await dialog.showSaveDialog(window, {
    title: '保存文件',
    defaultPath: defaultName || 'untitled.txt',
    filters: [
      { name: '文本文件', extensions: ['txt', 'md'] },
      { name: '所有文件', extensions: ['*'] },
    ],
  });

  if (canceled || !filePath) return null;

  await fs.promises.writeFile(filePath, content, 'utf-8');
  return filePath;
});
```

### 消息框

```typescript
ipcMain.handle('show-confirm', async (_event, message: string): Promise<boolean> => {
  const window = BrowserWindow.getFocusedWindow();
  if (!window) throw new Error('无活动窗口');

  const { response } = await dialog.showMessageBox(window, {
    type: 'question',
    title: '确认',
    message,
    buttons: ['取消', '确认'],
    defaultId: 0,
    cancelId: 0,
  });

  return response === 1;
});
```

- **MUST** 对话框操作在主进程（`dialog` 只在主进程可用）
- **MUST** 添加文件类型过滤器
- **MUST** 获取当前焦点窗口 `BrowserWindow.getFocusedWindow()`

## 原生菜单

```typescript
import { Menu, MenuItem, app, BrowserWindow } from 'electron';

export function createAppMenu(mainWindow: BrowserWindow): Menu {
  const isMac = process.platform === 'darwin';

  const template: Electron.MenuItemConstructorOptions[] = [
    ...(isMac ? [{
      label: app.getName(),
      submenu: [
        { role: 'about' as const },
        { type: 'separator' as const },
        { role: 'quit' as const },
      ],
    }] : []),
    {
      label: '文件',
      submenu: [
        {
          label: '新建',
          accelerator: 'CmdOrCtrl+N',
          click: () => mainWindow.webContents.send('menu-new'),
        },
        {
          label: '打开',
          accelerator: 'CmdOrCtrl+O',
          click: () => mainWindow.webContents.send('menu-open'),
        },
        {
          label: '保存',
          accelerator: 'CmdOrCtrl+S',
          click: () => mainWindow.webContents.send('menu-save'),
        },
        { type: 'separator' },
        isMac ? { role: 'close' } : { role: 'quit' },
      ],
    },
    {
      label: '编辑',
      submenu: [
        { role: 'undo' },
        { role: 'redo' },
        { type: 'separator' },
        { role: 'cut' },
        { role: 'copy' },
        { role: 'paste' },
      ],
    },
    {
      label: '视图',
      submenu: [
        { role: 'reload' },
        { role: 'forceReload' },
        { role: 'toggleDevTools' },
        { type: 'separator' },
        { role: 'resetZoom' },
        { role: 'zoomIn' },
        { role: 'zoomOut' },
        { type: 'separator' },
        { role: 'togglefullscreen' },
      ],
    },
    {
      label: '帮助',
      submenu: [
        {
          label: '关于',
          click: () => mainWindow.webContents.send('menu-about'),
        },
      ],
    },
  ];

  const menu = Menu.buildFromTemplate(template);
  Menu.setApplicationMenu(menu);
  return menu;
}
```

- **MUST** macOS 第一个菜单为应用名（`app.getName()`）
- **MUST** 使用 `role` 属性复用系统行为
- **SHOULD** 菜单点击通过 IPC 通知渲染进程

## 系统托盘

```typescript
import { Tray, Menu, nativeImage, app, BrowserWindow } from 'electron';
import path from 'path';

let tray: Tray | null = null;

export function createTray(mainWindow: BrowserWindow): Tray {
  const iconPath = path.join(__dirname, '../../resources/tray-icon.png');
  const icon = nativeImage.createFromPath(iconPath);

  tray = new Tray(icon.resize({ width: 16, height: 16 }));

  const contextMenu = Menu.buildFromTemplate([
    {
      label: '显示主窗口',
      click: () => {
        mainWindow.show();
        mainWindow.focus();
      },
    },
    { type: 'separator' },
    {
      label: '退出',
      click: () => {
        app.isQuitting = true;
        app.quit();
      },
    },
  ]);

  tray.setToolTip('My Electron App');
  tray.setContextMenu(contextMenu);

  tray.on('double-click', () => {
    mainWindow.show();
    mainWindow.focus();
  });

  return tray;
}
```

- **MUST** 托盘图标 16x16（macOS）/ 32x32（Windows）
- **MUST** 提供"显示"和"退出"选项
- **SHOULD** 双击托盘图标显示窗口

## 数据库（better-sqlite3）

```typescript
import Database from 'better-sqlite3';
import path from 'path';
import { app } from 'electron';

class DatabaseService {
  private static instance: DatabaseService;
  private db: Database.Database;

  private constructor() {
    const dbPath = path.join(app.getPath('userData'), 'app.db');
    this.db = new Database(dbPath);
    this.db.pragma('journal_mode = WAL');
    this.db.pragma('foreign_keys = ON');
    this.initialize();
  }

  static getInstance(): DatabaseService {
    if (!DatabaseService.instance) {
      DatabaseService.instance = new DatabaseService();
    }
    return DatabaseService.instance;
  }

  private initialize(): void {
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        role TEXT DEFAULT 'user',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);
  }

  // 参数化查询（防止 SQL 注入）
  getUserById(id: number): User | undefined {
    return this.db.prepare('SELECT * FROM users WHERE id = ?').get(id) as User | undefined;
  }

  createUser(name: string, email: string): User {
    const stmt = this.db.prepare('INSERT INTO users (name, email) VALUES (?, ?)');
    const result = stmt.run(name, email);
    return this.getUserById(result.lastInsertRowid as number)!;
  }

  updateUser(id: number, data: Partial<User>): void {
    const sets = Object.keys(data).map(k => `${k} = ?`).join(', ');
    const values = Object.values(data);
    this.db.prepare(`UPDATE users SET ${sets}, updated_at = CURRENT_TIMESTAMP WHERE id = ?`)
      .run(...values, id);
  }

  deleteUser(id: number): void {
    this.db.prepare('DELETE FROM users WHERE id = ?').run(id);
  }
}
```

- **MUST** 使用参数化查询（防 SQL 注入）
- **MUST** 数据库文件存储在 `app.getPath('userData')`
- **MUST** 启用 WAL 模式（提升并发性能）
- **SHOULD** 单例模式管理数据库连接

## 键值存储（electron-store）

```typescript
import Store from 'electron-store';

interface StoreSchema {
  theme: 'light' | 'dark';
  language: string;
  windowBounds: { width: number; height: number; x?: number; y?: number };
}

const store = new Store<StoreSchema>({
  defaults: {
    theme: 'light',
    language: 'zh-CN',
    windowBounds: { width: 1024, height: 768 },
  },
  encryptionKey: 'your-encryption-key', // 加密敏感数据
});

// 主进程 IPC
ipcMain.handle('get-setting', (_event, key: keyof StoreSchema) => {
  return store.get(key);
});

ipcMain.handle('set-setting', (_event, key: keyof StoreSchema, value: unknown) => {
  store.set(key, value);
});
```

- **MUST** 用户偏好使用 `electron-store`
- **SHOULD** 敏感数据使用 `encryptionKey`
- **MUST** 通过 IPC 暴露给渲染进程

## 自动更新（electron-updater）

```typescript
import { autoUpdater } from 'electron-updater';
import { BrowserWindow } from 'electron';

export function setupAutoUpdater(mainWindow: BrowserWindow): void {
  autoUpdater.autoDownload = false;
  autoUpdater.autoInstallOnAppQuit = true;

  autoUpdater.on('checking-for-update', () => {
    mainWindow.webContents.send('update-status', 'checking');
  });

  autoUpdater.on('update-available', (info) => {
    mainWindow.webContents.send('update-status', 'available', info);
  });

  autoUpdater.on('update-not-available', () => {
    mainWindow.webContents.send('update-status', 'not-available');
  });

  autoUpdater.on('download-progress', (progress) => {
    mainWindow.webContents.send('update-progress', progress.percent);
  });

  autoUpdater.on('update-downloaded', () => {
    mainWindow.webContents.send('update-status', 'downloaded');
  });

  autoUpdater.on('error', (error) => {
    mainWindow.webContents.send('update-error', error.message);
  });

  // 检查更新
  autoUpdater.checkForUpdates();
}

// 手动下载更新
export function downloadUpdate(): void {
  autoUpdater.downloadUpdate();
}

// 安装并重启
export function quitAndInstall(): void {
  autoUpdater.quitAndInstall();
}
```

- **SHOULD** 应用启动时自动检查更新
- **SHOULD** 提供手动检查更新入口
- **MUST** 更新状态通过 IPC 通知渲染进程
