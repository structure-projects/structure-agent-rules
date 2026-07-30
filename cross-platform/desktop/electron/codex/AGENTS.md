# Electron 开发规则

本目录包含 Electron 桌面开发的完整 AI 规则集合。

## 规则文件

| 文件 | 说明 |
|---|---|
| `prompts/developer.md` | Electron 开发约束 |
| `prompts/architect.md` | Electron 架构与选型 |
| `prompts/components.md` | IPC/对话框/菜单/数据库/更新使用规范 |
| `prompts/tester.md` | Electron 测试规范 |
| `prompts/reviewer.md` | Electron 评审规则 |
| `prompts/project-scaffolding.md` | Electron 项目脚手架 |
| `prompts/ci-cd.md` | Electron CI/CD 规范 |

## 技术栈

- **框架**：Electron 28+
- **运行时**：Node.js 18+
- **进程模型**：Main (Node.js) + Renderer (Chromium 沙箱) + Preload (contextBridge)
- **前端**：React / Vue / Svelte / Angular（独立选择）
- **打包**：electron-builder 或 electron-forge
- **数据库**：better-sqlite3 / sqlite3
- **更新**：electron-updater

## 关键约束

- **MUST** `contextIsolation: true` + `nodeIntegration: false` + `sandbox: true`
- **MUST** IPC 通过 `ipcMain.handle()` + `contextBridge`
- **MUST** Preload 最小权限暴露 API
- **MUST** 文件/数据库操作在主进程
- **禁止** `nodeIntegration: true`、`contextIsolation: false`、`sendSync()`
