# Electron 评审规则

> 角色：structure-reviewer（Electron 评审）。面向审查 Electron PR / diff 的 AI Agent。

## 审查清单

### 进程模型
- [ ] Main / Renderer / Preload 三层分离清晰
- [ ] `contextIsolation: true`（是否明确设置）
- [ ] `nodeIntegration: false`（是否明确设置）
- [ ] `sandbox: true`（生产环境）
- [ ] `webSecurity: true`

### IPC 通信
- [ ] 是否使用 `ipcMain.handle()` + `ipcRenderer.invoke()`（异步）
- [ ] 是否避免了 `ipcRenderer.sendSync()`（阻塞）
- [ ] Preload 是否通过 `contextBridge.exposeInMainWorld()` 暴露 API
- [ ] Preload 暴露的 API 是否最小化
- [ ] IPC 通道名是否在 `shared/types.ts` 中统一定义

### 主进程（Main Process）
- [ ] 文件/数据库操作是否在主进程（非渲染进程）
- [ ] 窗口管理是否正确（生命周期、多窗口）
- [ ] 错误处理是否完善（try-catch + 结构化错误）
- [ ] 是否有未处理的 `uncaughtException`
- [ ] `app.on('window-all-closed')` 是否正确处理

### Preload 脚本
- [ ] 是否使用 `contextBridge`（非直接暴露 `ipcRenderer`）
- [ ] 暴露的 API 是否最小化（按需暴露）
- [ ] 是否避免了在 preload 中使用 `fs`、`child_process`、`path` 等
- [ ] `window.electronAPI` 类型声明是否完整

### 渲染进程（Renderer Process）
- [ ] 是否通过 `window.electronAPI` 调用主进程
- [ ] 是否避免了 `require('electron')` / `require('fs')`
- [ ] `window.electronAPI` 类型声明是否存在
- [ ] 是否处理了 loading / error 状态
- [ ] 前端代码是否与 Electron 代码解耦

### 安全（重点）
- [ ] `contextIsolation: true` ✓
- [ ] `nodeIntegration: false` ✓
- [ ] `sandbox: true` ✓
- [ ] CSP 是否配置
- [ ] 是否禁用了 `enableRemoteModule`
- [ ] IPC 输入是否验证
- [ ] 是否限制了 `webviewTag`（不需要时禁用）
- [ ] 是否加载不可信外部 URL
- [ ] `shell.openExternal` 是否验证 URL

### 窗口管理
- [ ] 窗口配置是否合理（尺寸、最小尺寸、preload）
- [ ] 多窗口场景是否正确管理生命周期
- [ ] 原生菜单是否完整（文件/编辑/帮助）
- [ ] 系统托盘是否提供"显示"/"退出"
- [ ] macOS `activate` 事件是否正确处理

### 性能
- [ ] 主进程是否有阻塞操作（应使用异步 API）
- [ ] 渲染进程是否有内存泄漏（事件监听清理）
- [ ] 大文件操作是否异步 + 流式
- [ ] `webContents.openDevTools()` 是否只在开发环境

### 测试
- [ ] 主进程 IPC Handler 是否有单元测试
- [ ] 渲染进程组件是否有组件测试
- [ ] IPC 通信是否有集成测试
- [ ] E2E 是否覆盖关键用户路径

### 打包配置
- [ ] `electron-builder.yml` 各字段是否正确
- [ ] `appId` 是否反向域名
- [ ] 自动更新配置是否正确
- [ ] 代码签名是否正确配置
- [ ] 多平台 target 是否配置

## 常见驳回原因

1. **`nodeIntegration: true`**：严重安全风险，立即驳回
2. **`contextIsolation: false`**：严重安全风险，立即驳回
3. **Preload 直接暴露 `ipcRenderer`**：应通过 `contextBridge` 封装
4. **渲染进程 `require('electron')`**：安全违规
5. **使用 `ipcRenderer.sendSync()`**：阻塞 UI 线程
6. **`sandbox: false` 生产环境**：安全风险
7. **CSP 未配置**：XSS 风险
8. **IPC 缺少输入验证**：安全风险
9. **主进程同步阻塞操作**：性能问题
10. **事件监听未清理**：内存泄漏
11. **`webContents.openDevTools()` 在生产环境**：信息泄漏
12. **加载不可信外部 URL**：安全风险
