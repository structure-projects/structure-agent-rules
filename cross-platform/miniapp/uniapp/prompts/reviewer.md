# UniApp 前端评审规则

> 角色：uniapp-reviewer（前端评审）。面向审查 UniApp 前端 PR / diff 的 AI Agent。

## 审查清单

### 组件规范
- [ ] 是否使用 `<script setup lang="ts">`
- [ ] Props/Emits 是否有完整 TypeScript 类型
- [ ] 样式是否使用 `rpx` 单位
- [ ] 样式是否 scoped
- [ ] 文本是否包裹在 `<text>` 中

### 平台适配
- [ ] 平台差异代码是否使用条件编译（`#ifdef` / `#ifndef`）
- [ ] 小程序特有 API 是否在条件编译块中
- [ ] H5 代码是否兼容移动端浏览器

### 路由
- [ ] `pages.json` 配置是否正确（pages、tabBar、subPackages）
- [ ] 路由跳转是否使用 UniApp API（非 Vue Router）
- [ ] Tab 页跳转是否使用 `switchTab`
- [ ] URL 参数传递是否合理

### 状态管理
- [ ] 跨页面共享状态是否使用 Pinia
- [ ] Store 是否使用 Setup Store 语法
- [ ] Token 是否持久化到 Storage

### API 请求
- [ ] 是否使用封装的 request 函数（非直接 `uni.request`）
- [ ] 401 是否有统一处理跳转登录页
- [ ] 错误是否有 `uni.showToast` 提示

### 性能
- [ ] 长列表是否使用虚拟滚动
- [ ] 图片是否懒加载
- [ ] 是否有不必要的全局状态
- [ ] 分包加载是否合理配置

### 安全
- [ ] 用户输入是否经过验证
- [ ] Token 是否安全存储
- [ ] API 请求是否携带 Token
- [ ] 敏感数据是否不通过 URL query 传递

### 小程序特有
- [ ] `appid` 配置是否正确
- [ ] 分包大小是否超过 2MB 限制
- [ ] 是否使用了小程序不支持的 HTML 标签
- [ ] 是否在小程序环境使用了 `window`/`document`

### 样式
- [ ] 是否使用 `rpx`（非 `px`）
- [ ] 全局变量是否在 `uni.scss` 中定义
- [ ] 是否无全局样式污染

### 测试
- [ ] 是否在至少一个目标平台验证过功能
- [ ] 新增功能是否包含单元测试
- [ ] 测试用例是否有有意义的断言

## 常见驳回原因

1. **使用 Vue Router 替代 pages.json**：UniApp 路由由 pages.json 管理
2. **使用 px 单位**：应使用 rpx 响应式单位
3. **平台 API 未条件编译**：小程序 API 在 H5 中不可用
4. **直接调用 uni.request**：应使用封装的 request 函数
5. **使用 HTML 标签**：小程序不支持 div/span/img，应使用 view/text/image
6. **分包超限**：单个分包超过 2MB
7. **引入新 UI 库**（如同时使用 uView + Vant Weapp）而未评审
