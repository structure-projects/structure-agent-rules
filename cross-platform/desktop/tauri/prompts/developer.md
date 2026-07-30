# Tauri 开发规则

> 角色：structure-developer（Tauri 桌面开发）。面向开发 Tauri 应用的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。IDE 包装文件使用 `tauri-` 前缀。

## 硬约束

- **MUST** Tauri 2.x + Rust 2021 edition
- **MUST** 前端框架：React 18+ / Vue 3+ / Svelte 4+ 任选
- **MUST** `src-tauri/` 为 Rust 后端，`src/`（或其他）为前端
- **MUST** IPC：`invoke()`（前端 → Rust），`emit()`（Rust → 前端）
- **MUST** 所有 Rust 命令函数标注 `#[tauri::command]`
- **MUST** 安全基线：`contextIsolation: true`，前端不能直接访问 Node.js API
- **MUST** `Cargo.toml` 使用 workspace 管理依赖版本

## 关键优先级

- **前端框架**：React > Vue > Svelte（Tauri 无偏好，按团队技术栈）
- **前端构建**：Vite（推荐）> webpack
- **IPC 封装**：Service 层 > 组件内直接 `invoke`
- **存储**：`@tauri-apps/plugin-store` > `localStorage`（安全存储）
- **SQL**：`tauri-plugin-sql`（简单场景）> `sqlx`（复杂场景）

## 项目结构

```
my-tauri-app/
├── src/                              # 前端源码
│   ├── components/
│   ├── services/
│   │   └── ipc.service.ts           # IPC 封装（invoke 集中管理）
│   ├── hooks/                        # React hooks / Vue composables
│   ├── stores/                       # 状态管理
│   ├── App.tsx
│   └── main.tsx
├── src-tauri/                        # Rust 后端
│   ├── src/
│   │   ├── main.rs                   # Tauri 入口
│   │   ├── lib.rs                    # 库入口（推荐）
│   │   ├── commands/                 # 命令模块
│   │   │   ├── mod.rs
│   │   │   ├── greet.rs
│   │   │   └── file.rs
│   │   ├── services/                 # 业务逻辑
│   │   ├── models/                   # 数据模型
│   │   └── db/                       # 数据库层
│   ├── Cargo.toml
│   ├── tauri.conf.json               # Tauri 配置
│   ├── capabilities/                 # 权限配置
│   │   └── default.json
│   ├── icons/                        # 应用图标
│   └── resources/                    # 静态资源
├── package.json
├── vite.config.ts
├── tsconfig.json
└── .gitignore
```

## 编码规范

### Rust 命令（src-tauri/src/commands/）

```rust
use serde::{Deserialize, Serialize};
use tauri::State;
use std::sync::Mutex;

#[derive(Default)]
pub struct AppState {
    pub counter: Mutex<i64>,
}

#[derive(Serialize, Deserialize)]
pub struct GreetResponse {
    pub message: String,
}

#[tauri::command]
pub fn greet(name: &str) -> Result<GreetResponse, String> {
    if name.trim().is_empty() {
        return Err("名称不能为空".to_string());
    }
    Ok(GreetResponse {
        message: format!("你好, {}!", name),
    })
}

#[tauri::command]
pub fn increment_counter(state: State<'_, AppState>) -> Result<i64, String> {
    let mut counter = state.counter.lock().map_err(|e| e.to_string())?;
    *counter += 1;
    Ok(*counter)
}

#[tauri::command]
pub async fn read_file(path: String) -> Result<String, String> {
    tokio::fs::read_to_string(&path)
        .await
        .map_err(|e| format!("读取文件失败: {}", e))
}
```

- **MUST** 命令函数返回 `Result<T, String>` 或 `Result<T, impl Serialize>`
- **MUST** 参数和返回值实现 `Serialize` / `Deserialize`
- **MUST** 全局状态使用 `tauri::State<T>` 访问
- **MUST** 异步命令使用 `async` + `tokio`
- **MUST** 输入验证在命令入口处完成
- **禁止** 在命令函数中 `panic!`（返回 `Err` 替代）

### main.rs / lib.rs

```rust
// src-tauri/src/lib.rs
mod commands;
mod services;
mod models;
mod db;

use commands::*;
use std::sync::Mutex;

pub struct AppState {
    pub counter: Mutex<i64>,
}

pub fn run() {
    tauri::Builder::default()
        .manage(AppState {
            counter: Mutex::new(0),
        })
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_dialog::init())
        .invoke_handler(tauri::generate_handler![
            commands::greet,
            commands::increment_counter,
            commands::read_file,
        ])
        .run(tauri::generate_context!())
        .expect("启动应用失败");
}
```

- **MUST** 使用 `lib.rs` 作为库入口（`main.rs` 只调用 `run()`）
- **MUST** 插件在 `Builder` 中注册
- **MUST** 命令通过 `invoke_handler!` 注册

### 前端 IPC 封装（services/ipc.service.ts）

```typescript
import { invoke } from '@tauri-apps/api/core';
import { listen, emit, type UnlistenFn } from '@tauri-apps/api/event';

// 命令封装
export const ipcService = {
  greet(name: string): Promise<string> {
    return invoke('greet', { name });
  },

  incrementCounter(): Promise<number> {
    return invoke('increment_counter');
  },

  readFile(path: string): Promise<string> {
    return invoke('read_file', { path });
  },
};

// 事件封装
export function onEvent<T>(event: string, handler: (payload: T) => void): Promise<UnlistenFn> {
  return listen<T>(event, (e) => handler(e.payload));
}

export function emitEvent(event: string, payload?: unknown): Promise<void> {
  return emit(event, payload);
}
```

- **MUST** 所有 `invoke()` 调用封装在 IPC Service 中
- **MUST** 组件中不直接调用 `invoke()`（通过 IPC Service）
- **MUST** 事件监听在组件卸载时取消（`unlisten`）

### React 组件示例

```tsx
import { useEffect, useState } from 'react';
import { ipcService, onEvent } from '@/services/ipc.service';

function App() {
  const [greeting, setGreeting] = useState('');
  const [counter, setCounter] = useState(0);

  const handleGreet = async () => {
    const result = await ipcService.greet('World');
    setGreeting(result);
  };

  useEffect(() => {
    const unlisten = onEvent<number>('counter-updated', (count) => {
      setCounter(count);
    });
    return () => { unlisten.then(fn => fn()); };
  }, []);

  return (
    <div>
      <h1>{greeting}</h1>
      <p>计数器: {counter}</p>
      <button onClick={handleGreet}>打招呼</button>
    </div>
  );
}
```

- **MUST** 组件中不直接 `invoke()`，通过 `ipcService` 调用
- **MUST** `useEffect` 中清理事件监听
- **MUST** 使用 `@tauri-apps/api/core` 的 `invoke`（非 `window.__TAURI__`）

## 安全

- **MUST** `tauri.conf.json` 中启用 CSP
- **MUST** `capabilities` 最小权限原则（按需开放 Shell、FS、Dialog 等权限）
- **MUST** 文件访问限定在 scope 内
- **禁止** 在命令中 `eval()` / `exec()` 用户输入
- **禁止** 在 `capabilities` 中使用通配符权限

## 测试工作流

- **MUST** 每开发一个功能立即写单元测试
- **MUST** 功能修改时同步修改测试并通过
- **MUST** Rust 命令写 `#[cfg(test)]` 单元测试
- **MUST** 前端 IPC Service 写单元测试
- **MUST** 核心流程写 E2E
- **MUST** 提交前 `cargo test` + `npm run test` + `npm run lint` + `cargo clippy` 全部通过
- **禁止** 测试/Lint/Clippy 失败仍提交

## 禁止事项

- **禁止** 在命令函数中 `panic!` / `unwrap()` 生产代码
- **禁止** 组件中直接调用 `invoke()`（通过 IPC Service）
- **禁止** 事件监听不清理（内存泄漏）
- **禁止** `capabilities` 权限过大
- **禁止** 直接使用 `window.__TAURI__`（使用 `@tauri-apps/api`）
- **禁止** 前端直接访问文件系统（通过 Tauri FS plugin + IPC）
- **禁止** 在前端暴露敏感 Rust 状态
