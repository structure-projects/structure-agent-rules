# Electron 开发规则

## 角色与触发

本目录包含 Electron 桌面开发的 AI 规则。文件以 `electron-` 为前缀，与其他技术栈规则天然不冲突。

### 按角色触发

| 角色 | 规则文件 | 触发条件 |
|---|---|---|
| **developer** | `prompts/developer.md` | 编写主进程/渲染进程代码 |
| **architect** | `prompts/architect.md` | 架构选型、模块设计 |
| **reviewer** | `prompts/reviewer.md` | 审查 PR / diff |
| **tester** | `prompts/tester.md` | 编写测试代码 |
| **components** | `prompts/components.md` | 使用 IPC/对话框/菜单/数据库/更新 |
| **project-scaffolding** | `prompts/project-scaffolding.md` | 创建新项目 |
| **ci-cd** | `prompts/ci-cd.md` | 配置 CI/CD 流水线 |

### 技术栈约束

- **MUST** Electron 28+ + Node.js 18+
- **MUST** 进程模型：Main + Renderer + Preload
- **MUST** `contextIsolation: true` + `nodeIntegration: false` + `sandbox: true`
- **MUST** IPC：`ipcMain.handle()` + `ipcRenderer.invoke()` + `contextBridge`
- **MUST** 前端框架独立选择（React/Vue/Svelte/Angular）
- **禁止** `nodeIntegration: true`、`contextIsolation: false`、`sendSync()`、preload 暴露危险 API

详细规则请阅读各 `prompts/` 文件。
