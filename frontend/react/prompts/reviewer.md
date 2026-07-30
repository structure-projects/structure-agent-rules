# React 前端评审规则

> 角色：reviewer（前端评审）。面向审查 React 前端 PR / diff 的 AI Agent。

## 审查清单

### 组件规范
- [ ] 是否使用 Functional Component（**禁止** Class Component）
- [ ] Props 是否有完整 TypeScript `interface` 声明
- [ ] 是否使用命名导出 `export const Xxx`（非默认导出滥用）
- [ ] 文件名是否 PascalCase
- [ ] 事件回调是否以 `on` 前缀命名

### Hooks
- [ ] `useEffect` 是否有正确的依赖数组
- [ ] `useEffect` 是否有清理函数（如订阅、定时器）
- [ ] 是否有提取为自定义 Hook 的可复用逻辑
- [ ] `useCallback` / `useMemo` 是否仅在必要时使用（非滥用）
- [ ] 是否在条件/循环中调用 Hook（**禁止**）

### 状态管理
- [ ] 服务端数据是否使用 TanStack Query（非手动管理 loading/error）
- [ ] 全局状态是否使用 Zustand/Redux Toolkit
- [ ] 组件本地状态是否合理使用 `useState`/`useReducer`
- [ ] mutation 后是否 invalidate 相关 queries

### 性能
- [ ] 路由是否懒加载（`React.lazy` + `Suspense`）
- [ ] 纯展示组件是否用 `React.memo`
- [ ] 大列表是否使用虚拟滚动
- [ ] 是否有不必要的重渲染（缺少 key、内联对象/函数等）
- [ ] 图片是否懒加载

### 安全
- [ ] 用户输入是否经过校验（前端 + 后端）
- [ ] `dangerouslySetInnerHTML` 是否经过 XSS 过滤
- [ ] 敏感信息是否不在客户端环境变量中暴露
- [ ] API Token 是否不在前端代码中硬编码

### 样式
- [ ] 优先使用 Tailwind CSS 或 CSS Modules
- [ ] 无内联 `style={{}}`
- [ ] CSS Module 类名是否有意义

### Error Handling
- [ ] 关键路由/组件是否有 Error Boundary
- [ ] API 请求是否有错误处理（TanStack Query 的 `onError`）
- [ ] 是否有全局错误兜底页面

### 构建
- [ ] `tsconfig.json` `strict: true`
- [ ] 环境变量 `VITE_` 前缀正确
- [ ] `package.json` `private: true`（如适用）
- [ ] 无未使用的 import 或 dead code

### 测试
- [ ] 新增功能是否包含单元测试（Vitest + React Testing Library）
- [ ] E2E 测试是否覆盖核心流程（Playwright）
- [ ] 测试用例是否有有意义的断言（非 `expect(true).toBe(true)`）

## 常见驳回原因

1. **使用 Class Component**：React 项目统一使用函数组件 + Hooks
2. **useEffect 依赖缺失/错误**：导致内存泄漏或无限循环
3. **手写 loading/error 状态**：应使用 TanStack Query 管理服务端状态
4. **Props 无 TypeScript 类型**：所有组件 Props 必须有完整 interface
5. **在条件语句中调用 Hook**：违反 Hook 规则，导致组件状态混乱
6. **引入新的重量级依赖**（如新的 UI 库、状态管理库）而未评审
7. **内联样式滥用**：使用 Tailwind CSS 或 CSS Modules
8. **无 Error Boundary**：关键页面缺少错误兜底
