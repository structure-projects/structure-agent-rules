# Svelte 前端评审规则

> 角色：svelte-reviewer（前端评审）。面向审查 Svelte 前端 PR / diff 的 AI Agent。

## 审查清单

### 组件规范
- [ ] `.svelte` 文件结构是否规范（`<script>` → 模板 → `<style>`）
- [ ] `<script>` 是否使用 `lang="ts"`
- [ ] Props 是否有完整 TypeScript 类型
- [ ] `{#each}` 是否使用 key 表达式
- [ ] 组件文件名是否 PascalCase

### Svelte 版本一致性
- [ ] Svelte 4 项目是否统一使用 `$:` 和 `export let`
- [ ] Svelte 5 项目是否统一使用 `$state()`、`$derived()`、`$props()` runes
- [ ] 是否无混用两个版本的语法

### 数据加载
- [ ] `+page.server.ts` 的 `load` 函数是否正确返回数据
- [ ] 敏感数据是否仅在 server load 中获取
- [ ] 是否使用 `$types` 自动生成的类型

### 性能
- [ ] 图片是否懒加载
- [ ] 大列表是否使用虚拟滚动
- [ ] 是否有不必要的响应式声明（`$:` 或 `$derived`）
- [ ] 组件是否过大（超过 300 行应拆分）

### 安全
- [ ] 用户输入是否经过验证（前后端）
- [ ] `{@html}` 是否对内容进行了消毒
- [ ] 私密环境变量是否仅在 `$env/static/private` 中使用
- [ ] API 端点（`+server.ts`）是否有适当的鉴权

### 样式
- [ ] 组件样式是否在 `<style>` 标签内（自动 scoped）
- [ ] 是否无滥用 `:global()` 选择器
- [ ] 是否使用 CSS 变量或 Tailwind 主题化

### SvelteKit 规范
- [ ] adapter 配置是否正确
- [ ] `hooks.server.ts` 是否有鉴权处理
- [ ] 表单是否使用 Form Actions（非纯客户端 fetch）

### 可访问性
- [ ] 图片是否有 `alt` 属性
- [ ] 表单元素是否有 `label`
- [ ] 交互元素是否可通过键盘访问

### 测试
- [ ] 新增功能是否包含单元测试（Vitest）
- [ ] 组件是否有渲染测试（`@testing-library/svelte`）
- [ ] E2E 测试是否覆盖核心流程
- [ ] 测试用例是否有有意义的断言

## 常见驳回原因

1. **Svelte 4/5 语法混用**：同一项目中使用了两种响应式语法
2. **类型缺失**：Props 无 TypeScript 类型声明
3. **安全漏洞**：`{@html}` 未消毒、私密环境变量暴露到客户端
4. **性能问题**：`{#each}` 无 key、大列表无虚拟滚动
5. **SvelteKit 规范违反**：客户端 fetch 替代 Form Actions、无 `hooks.server.ts`
6. **可访问性缺失**：图片无 alt、表单无 label
7. **引入新依赖**（如同时使用 Tailwind + Bootstrap）而未评审
