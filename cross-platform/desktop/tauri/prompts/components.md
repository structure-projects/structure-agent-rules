# Tauri 核心组件与 API

## 前端 API (`@tauri-apps/api`)

### invoke 调用 Rust

```typescript
import { invoke } from '@tauri-apps/api/core';

const users = await invoke<User[]>('list_users', { page: 1, size: 20 });
const user = await invoke<User>('get_user', { id: 1 });
```

### Event 通信

```typescript
// 前端 → Rust
import { emit } from '@tauri-apps/api/event';
emit('app-action', { type: 'refresh' });

// Rust → 前端
import { listen } from '@tauri-apps/api/event';
const unlisten = await listen<User>('user-updated', (event) => {
  console.log(event.payload);
});
// 组件卸载时取消
unlisten();
```

## Rust Command

```rust
#[tauri::command]
async fn list_users(state: State<'_, AppState>, page: i32, size: i32)
    -> Result<Vec<User>, String>
{
    state.user_service.list(page, size)
        .map_err(|e| e.to_string())
}

// main.rs 注册
.invoke_handler(tauri::generate_handler![list_users, get_user, create_user])
```

## 常用插件

| 插件 | 用途 |
|---|---|
| `tauri-plugin-fs` | 文件系统读写 |
| `tauri-plugin-shell` | 执行系统命令 |
| `tauri-plugin-dialog` | 原生对话框 |
| `tauri-plugin-notification` | 系统通知 |
| `tauri-plugin-clipboard` | 剪贴板 |
| `tauri-plugin-updater` | 自动更新 |
| `tauri-plugin-sql` | SQL 数据库 |
| `tauri-plugin-window-state` | 窗口状态持久化 |

## 文件操作

```typescript
import { readTextFile, writeTextFile } from '@tauri-apps/plugin-fs';

const content = await readTextFile('notes.txt');
await writeTextFile('notes.txt', 'new content');
```

## 对话框

```typescript
import { open, save } from '@tauri-apps/plugin-dialog';

const file = await open({ filters: [{ name: 'JSON', extensions: ['json'] }] });
if (file) {
  const content = await readTextFile(file);
}
```
