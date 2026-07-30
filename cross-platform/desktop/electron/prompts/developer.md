# Electron 开发规范

## 进程模型

Electron 有三个进程角色：
- **Main Process**: Node.js 环境，应用生命周期管理
- **Renderer Process**: Chromium 沙箱，UI 渲染
- **Preload Script**: 桥接层，通过 `contextBridge` 暴露安全 API

## 安全（不可协商）

```javascript
// main.js
const mainWindow = new BrowserWindow({
  webPreferences: {
    contextIsolation: true,     // MUST: 上下文隔离
    nodeIntegration: false,     // MUST: 禁止 Node 在渲染进程
    sandbox: true,              // MUST: 沙箱
    preload: path.join(__dirname, 'preload.js')
  }
});
```

## Preload Script

```javascript
// preload.js
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  // 暴露给前端的 API
  getUsers: () => ipcRenderer.invoke('get-users'),
  saveUser: (user) => ipcRenderer.invoke('save-user', user),
  onUserUpdated: (callback) => ipcRenderer.on('user-updated', (_e, d) => callback(d)),
  removeUserListener: () => ipcRenderer.removeAllListeners('user-updated'),
});
```

### ❌ 绝对禁止

```javascript
// 禁止在 preload 中直接导出 Node.js API
const { readFile } = require('fs');  // ❌
contextBridge.exposeInMainWorld('fs', require('fs')); // ❌

// 禁止使用已废弃的 API
require('electron').remote;  // ❌ Remote Module 已移除
```

## IPC 通信

```javascript
// Main Process — 注册 Handler
const { ipcMain } = require('electron');

ipcMain.handle('get-users', async (_event, params) => {
  // MUST: 参数校验
  if (!params || typeof params.page !== 'number') {
    throw new Error('Invalid params');
  }
  return await db.all('SELECT * FROM users LIMIT ? OFFSET ?',
    [params.size, (params.page - 1) * params.size]);
});
```

```typescript
// Renderer — 调用
const users = await window.electronAPI.getUsers({ page: 1, size: 10 });
```

## TypeScript 类型声明

```typescript
// preload.d.ts
interface User { id: number; name: string; email: string; }

interface ElectronAPI {
  getUsers: (params: { page: number; size: number }) => Promise<User[]>;
  saveUser: (user: Omit<User, 'id'>) => Promise<void>;
  onUserUpdated: (callback: (user: User) => void) => void;
}

declare global {
  interface Window {
    electronAPI: ElectronAPI;
  }
}
```

## 文件系统

```javascript
// Main Process
const { dialog } = require('electron');
const fs = require('fs');

ipcMain.handle('save-file', async (_event, content) => {
  const { filePath } = await dialog.showSaveDialog({});
  if (filePath) {
    await fs.promises.writeFile(filePath, content);
    return filePath;
  }
  return null;
});
```

## 窗口管理

```javascript
let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: { /* 安全配置 */ }
  });
  mainWindow.loadURL(MAIN_WINDOW_WEBPACK_ENTRY);
}

// 窗口关闭时保存状态
mainWindow.on('close', () => {
  mainWindowState.save(mainWindow);
});
```

## 检查清单

- [ ] `contextIsolation: true`, `nodeIntegration: false`, `sandbox: true`
- [ ] Preload 只通过 `contextBridge` 暴露有限 API
- [ ] IPC Handler 校验所有参数
- [ ] TypeScript 类型声明完整
- [ ] 无 `require('electron').remote`
- [ ] CSP 配置在 HTML meta 标签
