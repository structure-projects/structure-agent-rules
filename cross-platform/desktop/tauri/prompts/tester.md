# Tauri 测试规则

> 角色：structure-tester（Tauri 测试）。面向编写 Tauri 测试代码的 AI Agent。

## 测试分层

| 层级 | 工具 | 覆盖范围 |
|---|---|---|
| Rust 单元测试 | `cargo test` + `#[cfg(test)]` | Rust 命令、Service、Utils |
| Rust 集成测试 | `cargo test --test '*'` | IPC 命令端到端 |
| 前端单元测试 | Jest / Vitest | Hooks、Service、Utils |
| 前端组件测试 | Testing Library | 组件渲染与交互 |
| E2E | Playwright + `tauri-driver` | 完整桌面流程 |

## Rust 单元测试

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_greet_valid_input() {
        let result = greet("World").unwrap();
        assert_eq!(result.message, "你好, World!");
    }

    #[test]
    fn test_greet_empty_input() {
        let result = greet("");
        assert!(result.is_err());
    }

    #[test]
    fn test_greet_whitespace_input() {
        let result = greet("   ");
        assert!(result.is_err());
    }
}
```

- **MUST** 单元测试写在同文件的 `#[cfg(test)] mod tests` 中
- **MUST** 覆盖正常输入和边界/错误输入
- **MUST** 使用 `assert_eq!` / `assert!` / `assert!(result.is_err())`
- **禁止** 在测试外使用 `unwrap()`（测试内允许）

## Rust 异步测试

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_async_command_success() {
        let result = fetch_data("https://api.example.com/data").await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_async_command_timeout() {
        // 使用 tokio::time::timeout 测试超时
        let result = tokio::time::timeout(
            std::time::Duration::from_millis(100),
            slow_operation(),
        ).await;
        assert!(result.is_err());
    }
}
```

- **MUST** 异步测试使用 `#[tokio::test]`
- **SHOULD** 测试超时行为

## Tauri 命令集成测试

```rust
// src-tauri/tests/commands_test.rs
use tauri::test::{mock_context, mock_builder};

#[test]
fn test_command_with_state() {
    let app = tauri::Builder::default()
        .manage(AppState::default())
        .invoke_handler(tauri::generate_handler![commands::increment_counter])
        .build(mock_context!())
        .unwrap();

    let state = app.state::<AppState>();
    assert_eq!(*state.counter.lock().unwrap(), 0);
}
```

- **MUST** 集成测试放在 `src-tauri/tests/` 目录
- **MUST** 使用 `tauri::test::mock_context` 模拟上下文

## 前端 IPC Service 测试

```typescript
import { mockIPC } from '@tauri-apps/api/mocks';
import { ipcService } from '@/services/ipc.service';

// Mock IPC
beforeAll(() => {
  mockIPC((cmd, args) => {
    switch (cmd) {
      case 'greet':
        return `你好, ${args.name}!`;
      case 'increment_counter':
        return 42;
      default:
        throw new Error(`Unknown command: ${cmd}`);
    }
  });
});

afterAll(() => {
  mockIPC(() => {});
});

describe('ipcService', () => {
  it('should call greet command', async () => {
    const result = await ipcService.greet('World');
    expect(result).toBe('你好, World!');
  });

  it('should call increment_counter command', async () => {
    const result = await ipcService.incrementCounter();
    expect(result).toBe(42);
  });

  it('should throw on unknown command', async () => {
    // @ts-expect-error - testing unknown command
    await expect(ipcService.unknownCommand()).rejects.toThrow();
  });
});
```

- **MUST** 使用 `@tauri-apps/api/mocks` 的 `mockIPC` Mock
- **MUST** 测试正常返回和错误返回
- **MUST** `afterAll` 中清除 Mock

## 事件监听测试

```typescript
import { mockIPC, mockWindows } from '@tauri-apps/api/mocks';

describe('event handling', () => {
  it('should receive emitted event', async () => {
    const handler = jest.fn();
    const unlisten = await listen('test-event', handler);

    // 模拟 Rust 端 emit
    mockWindows('main').emit('test-event', { data: 'hello' });

    expect(handler).toHaveBeenCalledWith(
      expect.objectContaining({ payload: { data: 'hello' } })
    );

    await unlisten();
  });
});
```

## 前端组件测试

```tsx
// React 示例
import { render, screen, fireEvent } from '@testing-library/react';
import { App } from './App';

describe('App', () => {
  it('should greet on button click', async () => {
    render(<App />);
    
    fireEvent.click(screen.getByText('打招呼'));
    
    expect(await screen.findByText('你好, World!')).toBeInTheDocument();
  });
});
```

- **MUST** 使用 `@testing-library/react`（React）或对应框架工具
- **MUST** 测试用户交互流程

## E2E 测试（Playwright）

```typescript
import { test, expect } from '@playwright/test';

test('complete greet flow', async ({ page }) => {
  // 使用 tauri://localhost 协议
  await page.goto('tauri://localhost/');

  // 等待应用加载
  await page.waitForSelector('[data-testid="app-ready"]');

  // 执行操作
  await page.fill('[data-testid="name-input"]', 'Tauri');
  await page.click('[data-testid="greet-button"]');

  // 断言结果
  await expect(page.locator('[data-testid="greeting"]')).toContainText('你好, Tauri!');
});

test('window controls', async ({ page }) => {
  await page.goto('tauri://localhost/');

  // 测试窗口标题
  const title = await page.title();
  expect(title).toBe('My Tauri App');
});
```

- **MUST** E2E 使用 Playwright + `tauri-driver`
- **MUST** 使用 `data-testid` 定位元素
- **MUST** CI 中使用 `xvfb-run` 运行（无头 Linux）

## CI 测试配置

```yaml
- name: Rust Tests
  run: cargo test --manifest-path src-tauri/Cargo.toml

- name: Rust Clippy
  run: cargo clippy --manifest-path src-tauri/Cargo.toml -- -D warnings

- name: Frontend Tests
  run: npm run test

- name: E2E Tests
  run: xvfb-run npx playwright test
```

- **MUST** CI 中同时运行 Rust 和前端测试
- **MUST** `cargo clippy` 检查（`-D warnings`）
- **MUST** E2E 在无头环境中运行

## 测试工作流

- **MUST** 每开发功能立即写测试，通过才能做下一个
- **MUST** 功能修改时同步改测试
- **MUST** Rust 命令写单元测试
- **MUST** 前端 IPC Service 写单元测试
- **MUST** 核心流程写 E2E
- **MUST** 提交前 `cargo test` + `npm run test` + `npm run lint` + `cargo clippy` 全部通过
- **禁止** 测试/Lint/Clippy 失败仍提交

## 文件命名

| 类型 | 命名 | 位置 |
|---|---|---|
| Rust 单测 | `#[cfg(test)]` 同文件 | `src-tauri/src/` |
| Rust 集成测试 | `tests/{name}_test.rs` | `src-tauri/tests/` |
| 前端单测 | `{name}.test.ts` / `{name}.spec.ts` | 与源文件同目录 |
| E2E | `{feature}.spec.ts` | `e2e/` 或 `tests/e2e/` |
