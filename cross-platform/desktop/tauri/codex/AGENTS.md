# Tauri 开发规则

本目录包含 Tauri 桌面开发的完整 AI 规则集合。

## 规则文件

| 文件 | 说明 |
|---|---|
| `prompts/developer.md` | Tauri 开发约束 |
| `prompts/architect.md` | Tauri 架构与选型 |
| `prompts/components.md` | Rust 命令/Tauri 插件/前端组件使用规范 |
| `prompts/tester.md` | Tauri 测试规范 |
| `prompts/reviewer.md` | Tauri 评审规则 |
| `prompts/project-scaffolding.md` | Tauri 项目脚手架 |
| `prompts/ci-cd.md` | Tauri CI/CD 规范 |

## 技术栈

- **框架**：Tauri 2.x
- **后端**：Rust 2021 edition
- **前端**：React 18+ / Vue 3+ / Svelte 4+
- **构建**：Vite + Cargo
- **IPC**：`invoke()` / `emit()`
- **插件**：tauri-plugin-shell, fs, dialog, notification, store, updater

## 关键约束

- **MUST** Rust 后端 + Web 前端双层架构
- **MUST** 命令函数标注 `#[tauri::command]`，返回 `Result`
- **MUST** 前端 IPC 调用封装在 Service 层
- **MUST** 事件监听在组件卸载时取消
- **MUST** `capabilities` 最小权限原则
- **MUST** CSP 在 `tauri.conf.json` 中配置
- **禁止** 命令中 `panic!`、组件直接 `invoke()`、权限过大
