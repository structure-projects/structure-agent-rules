# AGENTS.md — React 前端规则（Codex 自包含模板）

> 本文件自包含，可直接拷贝到 React 前端项目根目录，供 Codex / 通用 AI Agent 自动加载。
> 修改规则时，请同步更新 `prompts/` 目录下的对应角色文件。

## 1. 硬约束

- **MUST** React 18+ + TypeScript strict + Vite
- **MUST** Functional Components + Hooks（**禁止** Class Component）
- **MUST** ESLint + Prettier 统一代码风格
- **MUST** 环境变量通过 `.env` 文件管理（`VITE_` 前缀暴露给客户端）

## 2. 组件规范

- 文件名 PascalCase（`UserTable.tsx`）
- Props 通过 `interface` 声明完整 TypeScript 类型
- 事件回调以 `on` 前缀命名
- 优先命名导出 `export const Xxx`
- L1: `components/ui/`，L2: `components/business/`，L3: `pages/`

## 3. Hooks

- `useEffect` 必须有正确依赖数组和清理函数
- 可复用业务逻辑提取到 `hooks/useXxx.ts`
- 自定义 Hook 以 `use` 开头
- **禁止** 在条件/循环中调用 Hook

## 4. 状态管理

| 数据类型 | 方案 |
|---|---|
| 服务端状态 | TanStack Query（React Query） |
| 客户端全局（轻量） | Zustand |
| 客户端全局（复杂） | Redux Toolkit |
| 组件局部 | useState / useReducer |

- **MUST** 服务端数据用 TanStack Query，禁止手动管理 loading/error
- **MUST** mutation 成功后 invalidate 相关 queries

## 5. 路由

- React Router v6（`createBrowserRouter`）
- 懒加载：`React.lazy(() => import('./pages/Xxx'))` + `<Suspense>`
- 嵌套路由用 `<Outlet />`

## 6. 样式

- Tailwind CSS 或 CSS Modules
- **禁止** 内联 `style={{}}`

## 7. Error Handling

- 关键路由/组件包裹 Error Boundary
- API 请求有错误处理

## 8. 构建

- Vite + `@vitejs/plugin-react`
- TypeScript strict mode（`strict: true`）
- `vite-tsconfig-paths` 路径别名

## 9. 测试

| 层级 | 工具 |
|---|---|
| 单元测试 | Vitest |
| 组件测试 | Vitest + React Testing Library |
| E2E | Playwright |

- 组件测试优先 `getByRole`、`getByLabelText`
- E2E 用 `data-testid` 选择器
- 每功能开发后立即写单测，通过才能做下一个
- 业务完成后写 E2E
- 提交前 `npm run test` 全通过 + `npm run build` 编译通过

## 10. CI/CD

- GitHub Actions
- `test.yml`：npm ci + lint + tsc + vitest + build
- `build-and-push.yml`：Docker 多阶段构建（nginx）
- `e2e.yml`：Playwright E2E 测试

## 11. 项目结构

```
src/
├── api/          # API 请求函数
├── components/
│   ├── ui/       # L1 通用 UI
│   └── business/ # L2 领域组件
├── hooks/        # 自定义 Hooks
├── layouts/      # 布局
├── pages/        # L3 页面
├── router/       # React Router
├── stores/       # Zustand/RTK stores
├── styles/       # 全局样式
├── types/        # 共享类型
├── utils/        # 工具函数
├── App.tsx
└── main.tsx
```
