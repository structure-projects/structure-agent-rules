# Vue 3 前端评审规则

> 角色：structure-reviewer（前端评审）。面向审查 Vue 3 前端 PR / diff 的 AI Agent。

## 审查清单

### 组件复用
- [ ] 是否复用 `@structure-projects/components` 已有组件，而非重复造轮子
- [ ] 是否复用 element-plus 而非自己实现基础交互
- [ ] L2 组件是否仅在所属 `*-ui-components` 中维护

### 代码规范
- [ ] 是否使用 `<script setup lang="ts">`
- [ ] Props/Emits 是否有完整 TS 类型声明
- [ ] 是否使用 composable 提取可复用逻辑
- [ ] 文件名是否 PascalCase

### 状态管理
- [ ] 跨组件共享状态是否使用 Pinia
- [ ] 组件内部状态是否用 `ref`/`reactive`（而非 Pinia）
- [ ] Store 是否使用 Setup Store 语法

### 性能
- [ ] 路由是否懒加载
- [ ] 大列表是否使用虚拟滚动
- [ ] 图片是否懒加载
- [ ] 是否有不必要的响应式数据

### 安全
- [ ] 用户输入是否使用 element-plus 表单校验（非仅前端校验）
- [ ] v-html 是否经过 XSS 过滤
- [ ] 敏感 API 调用是否通过 wujie 沙箱隔离

### 样式
- [ ] 优先使用 UnoCSS 原子类
- [ ] 无行内 style
- [ ] 无覆盖 element-plus 默认样式的全局 CSS

### 微前端
- [ ] 子应用是否在 `main.ts` 调用 `createWujieSubapp().init()`
- [ ] 是否声明 lifecycle
- [ ] 路由 base 是否正确

### 构建
- [ ] `*-ui` 的 `private: true`
- [ ] `*-ui-components` 的 exports 配置正确
- [ ] Element Plus 作为 external，不打包进组件库

### 测试
- [ ] 新增功能是否包含单元测试
- [ ] E2E 测试是否覆盖核心流程
- [ ] 测试用例是否有有意义的断言（非 `expect(true).toBe(true)`）

## 常见驳回原因

1. **手写已存在的组件**：未复用 `@structure-projects/components` 或 element-plus
2. **不符合 wujie 规范**：未调用 `createWujieSubapp().init()` 或 lifecycle 缺失
3. **types 缺失**：Props/Emits 无类型声明
4. **引入新的 UI 库**（如 ant-design-vue、naive-ui）而未评审
5. **npm 发布配置错误**：`*-ui` 不是 private，或 `*-ui-components` 缺少 exports
