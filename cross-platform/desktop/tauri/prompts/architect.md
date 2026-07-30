# Tauri 架构规则

> 角色：structure-architect（桌面架构）。面向需要做 Tauri 架构选型与技术决策的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。IDE 包装文件使用 `tauri-` 前缀。

## 架构模式

### 双层架构

- **MUST** Rust 后端（`src-tauri/`）负责：系统调用、文件 I/O、数据库、原生窗口管理
- **MUST** Web 前端负责：UI 渲染、用户交互、路由
- **MUST** IPC 桥接前后端：前端通过 `invoke()` 调用 Rust 命令，Rust 通过 `emit()` 推送事件

```
┌─────────────────────────────────────┐
│          Web 前端 (src/)            │
│  React / Vue / Svelte              │
│  - UI 渲染                          │
│  - 状态管理                         │
│  - 路由                             │
└──────────┬──────────────────────────┘
           │ invoke() / emit() (IPC)
┌──────────▼──────────────────────────┐
│       Rust 后端 (src-tauri/)        │
│  - #[tauri::command] 命令层         │
│  - Service 业务逻辑层               │
│  - Repository 数据访问层            │
│  - 窗口管理、系统托盘               │
│  - 文件系统、数据库、Shell          │
└─────────────────────────────────────┘
```

### Rust 端分层

```
src-tauri/src/
├── main.rs              # 入口（调用 lib::run()）
├── lib.rs               # Builder 配置、状态注册
├── commands/            # 命令层（#[tauri::command]）
│   ├── mod.rs
│   ├── greet.rs
│   ├── file.rs
│   └── db.rs
├── services/            # 业务逻辑层
│   ├── mod.rs
│   └── user_service.rs
├── models/              # 数据模型
│   ├── mod.rs
│   └── user.rs
└── db/                  # 数据库层
    ├── mod.rs
    └── sqlite.rs
```

- **MUST** Command 层只做参数验证和调用 Service
- **MUST** Service 层包含核心业务逻辑
- **MUST** Repository/DB 层封装数据访问

### 前端分层

```
src/
├── services/
│   └── ipc.service.ts      # IPC 封装（所有 invoke 集中管理）
├── hooks/                   # React hooks / Vue composables
│   └── useGreet.ts
├── stores/                  # 状态管理
│   └── appStore.ts
├── components/              # UI 组件
└── pages/                   # 页面
```

- **MUST** IPC Service 封装所有 `invoke()` 调用
- **MUST** Hooks/Composables 封装业务逻辑 + IPC 调用
- **MUST** 组件只负责渲染和事件处理

## IPC 通信

### 请求-响应（前端 → Rust）

```rust
// Rust 端
#[tauri::command]
async fn get_user(id: i32) -> Result<User, String> {
    db::get_user(id).await.map_err(|e| e.to_string())
}
```

```typescript
// 前端
const user = await ipcService.getUser(1);
```

### 推送事件（Rust → 前端）

```rust
// Rust 端
app_handle.emit("user-logged-in", UserEvent { username: "alice" })?;
```

```typescript
// 前端
import { listen } from '@tauri-apps/api/event';
const unlisten = await listen<UserEvent>('user-logged-in', (event) => {
  console.log(event.payload.username);
});
```

### 双向通信（Channel）

```rust
// Rust 端 - 使用 Channel 进行流式响应
#[tauri::command]
async fn stream_data(on_event: Channel<String>) -> Result<(), String> {
    for i in 0..10 {
        on_event.send(format!("chunk-{}", i)).map_err(|e| e.to_string())?;
        tokio::time::sleep(Duration::from_millis(100)).await;
    }
    Ok(())
}
```

## 状态管理

### Rust 全局状态

```rust
use std::sync::Mutex;
use tauri::State;

pub struct AppState {
    pub db: Mutex<Database>,
    pub config: Mutex<AppConfig>,
    pub window_count: Mutex<usize>,
}

// 注册
tauri::Builder::default()
    .manage(AppState { /* ... */ })
    .run(tauri::generate_context!())?;

// 使用
#[tauri::command]
fn get_config(state: State<'_, AppState>) -> Result<AppConfig, String> {
    state.config.lock().map(|c| c.clone()).map_err(|e| e.to_string())
}
```

- **MUST** 全局状态使用 `tauri::State<T>` 管理
- **MUST** 可变状态用 `Mutex<T>` 或 `Arc<RwLock<T>>` 包裹
- **SHOULD** 状态按领域拆分（非一个大 struct）

### 前端状态

| 框架 | 推荐方案 |
|---|---|
| React | Zustand / Redux Toolkit |
| Vue | Pinia |
| Svelte | Svelte stores |

## 窗口管理

### 单窗口

```json
// tauri.conf.json
{
  "app": {
    "windows": [
      {
        "label": "main",
        "title": "My App",
        "width": 1024,
        "height": 768,
        "resizable": true,
        "fullscreen": false
      }
    ]
  }
}
```

### 多窗口

```rust
use tauri::WebviewWindowBuilder;

#[tauri::command]
async fn open_settings(app: tauri::AppHandle) -> Result<(), String> {
    WebviewWindowBuilder::new(
        &app,
        "settings",
        tauri::WebviewUrl::App("settings".into()),
    )
    .title("设置")
    .inner_size(600.0, 400.0)
    .build()
    .map_err(|e| e.to_string())?;
    Ok(())
}
```

- **MUST** 多窗口使用 `WebviewWindowBuilder` 创建
- **MUST** 每个窗口有唯一 `label`
- **SHOULD** 主窗口在 `tauri.conf.json` 中配置

### 系统托盘

```rust
use tauri::tray::{TrayIconBuilder, MenuEvent};
use tauri::menu::{MenuBuilder, MenuItemBuilder};

let menu = MenuBuilder::new(app)
    .item(&MenuItemBuilder::with_id("show", "显示").build(app)?)
    .item(&MenuItemBuilder::with_id("quit", "退出").build(app)?)
    .build()?;

let tray = TrayIconBuilder::new()
    .menu(&menu)
    .on_menu_event(|app, event| match event.id.as_ref() {
        "show" => { /* 显示窗口 */ }
        "quit" => { app.exit(0); }
        _ => {}
    })
    .build(app)?;
```

- **SHOULD** 桌面应用提供系统托盘
- **MUST** 托盘菜单提供"显示"和"退出"选项

## Tauri 插件体系

| 插件 | 用途 | 必需 |
|---|---|---|
| `tauri-plugin-shell` | 执行 Shell 命令 | 常用 |
| `tauri-plugin-fs` | 文件系统访问 | 常用 |
| `tauri-plugin-dialog` | 原生对话框（打开/保存文件） | 常用 |
| `tauri-plugin-notification` | 系统通知 | 推荐 |
| `tauri-plugin-sql` | SQL 数据库（sqlite/mysql/postgres） | 按需 |
| `tauri-plugin-store` | 键值存储 | 推荐 |
| `tauri-plugin-updater` | 应用自动更新 | 推荐 |
| `tauri-plugin-clipboard` | 剪贴板 | 按需 |
| `tauri-plugin-global-shortcut` | 全局快捷键 | 按需 |
| `tauri-plugin-http` | HTTP 客户端（绕过 CORS） | 按需 |

### 权限配置（capabilities）

```json
// src-tauri/capabilities/default.json
{
  "identifier": "default",
  "description": "默认权限",
  "windows": ["main"],
  "permissions": [
    "core:default",
    "shell:allow-open",
    "fs:allow-read-text-file",
    "fs:allow-write-text-file",
    "dialog:allow-open",
    "dialog:allow-save",
    "notification:default"
  ]
}
```

- **MUST** 最小权限原则（只开放需要的权限）
- **MUST** 文件系统权限限定目录 scope
- **禁止** 使用通配符权限

## 数据层

- **MUST** 键值存储：`@tauri-apps/plugin-store`（加密存储）
- **SHOULD** SQL：`tauri-plugin-sql`（简单场景）或 `sqlx`（复杂查询）
- **MUST** 文件系统：`tauri-plugin-fs`（禁止前端直接 `fs`）
- **SHOULD** 缓存：前端 `localStorage` + Rust 端内存缓存

## 安全

- **MUST** CSP 在 `tauri.conf.json` 中配置
- **MUST** `capabilities` 最小权限
- **MUST** 文件访问 scope 白名单
- **禁止** `dangerousRemoteDomainIpcAccess`
- **MUST** 输入验证在命令入口处
- **禁止** 在命令中 `eval()` 用户输入
- **SHOULD** 敏感数据使用 `@tauri-apps/plugin-store` 加密存储

## 自动更新

```json
// tauri.conf.json
{
  "plugins": {
    "updater": {
      "endpoints": [
        "https://cdn.example.com/updates/{{target}}/{{arch}}/{{current_version}}"
      ],
      "pubkey": "YOUR_PUBLIC_KEY"
    }
  }
}
```

- **SHOULD** 使用 `tauri-plugin-updater` 实现自动更新
- **MUST** 更新包签名验证
- **MUST** 更新服务器 HTTPS
