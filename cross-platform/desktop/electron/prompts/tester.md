# Electron 测试规则

> 角色：structure-tester（Electron 测试）。面向编写 Electron 测试代码的 AI Agent。

## 测试分层

| 层级 | 工具 | 覆盖范围 |
|---|---|---|
| 主进程单元测试 | Jest | Main Process 模块、IPC Handler |
| 渲染进程单元测试 | Jest / Vitest | Hooks、Utils |
| 渲染进程组件测试 | Testing Library | 组件渲染与交互 |
| E2E | Playwright + `_electron` | 完整桌面流程 |

## 主进程单元测试

```typescript
// src/main/ipc/__tests__/greet.handler.test.ts
import { greet } from '../greet.handler';

describe('IPC Handler: greet', () => {
  it('should return greeting for valid name', () => {
    const result = greet('World');
    expect(result).toBe('你好, World!');
  });

  it('should throw on empty name', () => {
    expect(() => greet('')).toThrow('名称不能为空');
  });

  it('should throw on whitespace name', () => {
    expect(() => greet('   ')).toThrow('名称不能为空');
  });
});
```

- **MUST** IPC Handler 逻辑提取为纯函数便于测试
- **MUST** 测试正常输入和边界/错误输入
- **SHOULD** Mock `dialog`、`shell`、`app` 等 Electron 模块

### Mock Electron 模块

```typescript
jest.mock('electron', () => ({
  app: {
    getPath: jest.fn((name: string) => `/mock/path/${name}`),
    quit: jest.fn(),
    whenReady: jest.fn().mockResolvedValue(undefined),
  },
  BrowserWindow: jest.fn().mockImplementation(() => ({
    loadFile: jest.fn(),
    loadURL: jest.fn(),
    webContents: {
      send: jest.fn(),
      openDevTools: jest.fn(),
    },
    on: jest.fn(),
    show: jest.fn(),
    close: jest.fn(),
  })),
  ipcMain: {
    handle: jest.fn(),
    on: jest.fn(),
  },
  Menu: {
    buildFromTemplate: jest.fn(),
    setApplicationMenu: jest.fn(),
  },
  dialog: {
    showOpenDialog: jest.fn(),
    showSaveDialog: jest.fn(),
    showMessageBox: jest.fn(),
  },
}));
```

## 数据库服务测试

```typescript
import Database from 'better-sqlite3';
import { DbService } from '../services/db.service';

jest.mock('better-sqlite3');

describe('DbService', () => {
  let dbService: DbService;
  let mockDb: jest.Mocked<Database.Database>;

  beforeEach(() => {
    mockDb = {
      prepare: jest.fn().mockReturnValue({
        all: jest.fn().mockReturnValue([{ id: 1, name: '张三' }]),
        get: jest.fn(),
        run: jest.fn(),
      }),
      exec: jest.fn(),
      pragma: jest.fn(),
    } as any;

    (Database as jest.Mock).mockReturnValue(mockDb);
    dbService = new DbService();
  });

  it('should get all users', () => {
    const users = dbService.getUsers();
    expect(users).toHaveLength(1);
    expect(users[0].name).toBe('张三');
  });
});
```

- **MUST** Mock `better-sqlite3` 避免真实数据库依赖
- **MUST** 测试 CRUD 操作的正常和异常路径

## Preload 安全测试

```typescript
describe('Preload Security', () => {
  it('should not expose Node.js modules', () => {
    const preloadExports = require('../preload/index');
    
    // 验证不包含危险模块
    expect(preloadExports).not.toHaveProperty('fs');
    expect(preloadExports).not.toHaveProperty('child_process');
    expect(preloadExports).not.toHaveProperty('path');
    expect(preloadExports).not.toHaveProperty('os');
  });

  it('should only expose defined API methods', () => {
    // 验证暴露的 API 是白名单中的
    const allowedMethods = ['greet', 'saveFile', 'readFile', 'onEvent', 'removeListener'];
    // ... 验证逻辑
  });
});
```

## 渲染进程组件测试

```tsx
// React 示例
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { App } from './App';

const mockElectronAPI = {
  greet: jest.fn(),
  saveFile: jest.fn(),
  readFile: jest.fn(),
};

beforeAll(() => {
  (window as any).electronAPI = mockElectronAPI;
});

afterEach(() => {
  jest.clearAllMocks();
});

describe('App', () => {
  it('should greet on button click', async () => {
    mockElectronAPI.greet.mockResolvedValue('你好, World!');
    
    render(<App />);
    fireEvent.click(screen.getByText('打招呼'));

    await waitFor(() => {
      expect(screen.getByText('你好, World!')).toBeInTheDocument();
    });
  });

  it('should show error on greet failure', async () => {
    mockElectronAPI.greet.mockRejectedValue(new Error('网络错误'));
    
    render(<App />);
    fireEvent.click(screen.getByText('打招呼'));

    await waitFor(() => {
      expect(screen.getByText(/网络错误/)).toBeInTheDocument();
    });
  });
});
```

- **MUST** Mock `window.electronAPI` 在测试中
- **MUST** 测试成功和失败两种路径
- **MUST** 使用 Testing Library 测试用户交互

## E2E 测试（Playwright + Electron）

```typescript
import { test, expect, _electron as electron } from '@playwright/test';
import type { ElectronApplication, Page } from '@playwright/test';

let electronApp: ElectronApplication;
let page: Page;

test.beforeAll(async () => {
  electronApp = await electron.launch({
    args: ['.'],
  });
  page = await electronApp.firstWindow();
  await page.waitForSelector('[data-testid="app-ready"]');
});

test.afterAll(async () => {
  await electronApp.close();
});

test('greet flow', async () => {
  await page.fill('[data-testid="name-input"]', 'World');
  await page.click('[data-testid="greet-button"]');

  await expect(page.locator('[data-testid="greeting"]')).toContainText('你好, World!');
});

test('file save flow', async () => {
  // Mock 原生对话框
  await electronApp.evaluate(({ dialog }) => {
    dialog.showSaveDialog = async () => ({
      filePath: '/mock/path/test.txt',
      canceled: false,
    });
  });

  await page.click('[data-testid="save-button"]');
  await expect(page.locator('[data-testid="save-success"]')).toBeVisible();
});
```

- **MUST** E2E 使用 Playwright 的 `_electron` API
- **MUST** 使用 `data-testid` 定位元素
- **MUST** `beforeAll` / `afterAll` 管理 Electron 生命周期
- **SHOULD** Mock 原生对话框（无法在 CI 中交互）

## CI 测试配置

```yaml
- name: Unit Tests (Main Process)
  run: npx jest --config jest.main.config.js

- name: Unit Tests (Renderer)
  run: npx jest --config jest.renderer.config.js

- name: TypeScript Check
  run: npx tsc --noEmit

- name: E2E Tests
  run: xvfb-run npx playwright test
```

## 测试工作流

- **MUST** 每开发功能立即写测试，通过才能做下一个
- **MUST** 功能修改时同步改测试
- **MUST** 主进程 IPC Handler 写单元测试
- **MUST** 渲染进程组件写组件测试
- **MUST** 核心流程写 E2E
- **MUST** 提交前 `npm run test` + `npm run lint` + `npx tsc --noEmit` 全部通过
- **禁止** 测试/Lint/类型检查失败仍提交

## 文件命名

| 类型 | 命名 | 位置 |
|---|---|---|
| 主进程单测 | `{name}.test.ts` | 与源文件同目录或 `__tests__/` |
| 渲染进程单测 | `{name}.test.ts` / `{name}.spec.ts` | 与源文件同目录 |
| 渲染进程组件测试 | `{component}.test.tsx` | 与源文件同目录 |
| E2E | `{feature}.e2e.ts` | `e2e/` 或 `tests/e2e/` |
