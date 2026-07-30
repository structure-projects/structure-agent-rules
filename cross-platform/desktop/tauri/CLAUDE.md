# Tauri 开发规则

## 角色与触发

本目录包含 Tauri 桌面开发的 AI 规则。文件以 `tauri-` 为前缀，与其他技术栈规则天然不冲突。

### 按角色触发

| 角色 | 规则文件 | 触发条件 |
|---|---|---|
| **developer** | `prompts/developer.md` | 编写 Rust/前端代码 |
| **architect** | `prompts/architect.md` | 架构选型、模块设计 |
| **reviewer** | `prompts/reviewer.md` | 审查 PR / diff |
| **tester** | `prompts/tester.md` | 编写测试代码 |
| **components** | `prompts/components.md` | 使用 Rust 命令/Tauri 插件/前端组件 |
| **project-scaffolding** | `prompts/project-scaffolding.md` | 创建新项目 |
| **ci-cd** | `prompts/ci-cd.md` | 配置 CI/CD 流水线 |

### 技术栈约束

- **MUST** Tauri 2.x + Rust 2021 edition
- **MUST** 前端：React 18+ / Vue 3+ / Svelte 4+ 任选
- **MUST** IPC：`invoke()`（前端 → Rust），`emit()`（Rust → 前端）
- **MUST** `src-tauri/` 为 Rust 后端，`src/` 为前端
- **MUST** 安全基线：`contextIsolation: true`
- **MUST** 命令函数返回 `Result<T, E>`（非 `panic!`）
- **禁止** 组件中直接 `invoke()`、命令中 `panic!`、capabilities 权限过大

详细规则请阅读各 `prompts/` 文件。
