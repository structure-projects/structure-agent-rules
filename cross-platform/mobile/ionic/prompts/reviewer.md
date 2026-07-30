# Ionic 评审规则

> 角色：structure-reviewer（Ionic 评审）。面向审查 Ionic PR / diff 的 AI Agent。

## 审查清单

### 架构
- [ ] 是否遵循 Feature-module 分层架构（Core/Shared/Feature）
- [ ] Service 是否正确封装业务逻辑（非在组件中处理）
- [ ] API 调用是否集中在 Service 层
- [ ] 状态管理方案是否与项目规模匹配
- [ ] Core 模块是否只有全局单例服务

### Ionic 组件
- [ ] 是否使用 Ionic 组件替代原生 HTML（`<ion-input>` 非 `<input>`）
- [ ] `<ion-list>` + `<ion-item>` 是否正确使用（含 slot 属性）
- [ ] `<ion-modal>` / `<ion-toast>` / `<ion-alert>` / `<ion-action-sheet>` 使用正确
- [ ] `<ion-grid>` + `<ion-row>` + `<ion-col>` 响应式布局正确
- [ ] 长列表是否使用 `ion-virtual-scroll`（非 `*ngFor` 全量渲染）
- [ ] `<ion-refresher>` 下拉刷新是否正确配置

### 平台适配
- [ ] 是否使用 `Platform` 服务检测平台（非 `navigator.userAgent`）
- [ ] iOS/md mode 差异是否正确处理
- [ ] `ion-split-pane` 是否正确用于平板/桌面适配
- [ ] 安全区域（safe area）是否正确处理

### 导航
- [ ] 是否使用 `IonRouterOutlet` 而非原生 RouterOutlet
- [ ] Tab 导航是否使用 `<ion-tabs>` 组件
- [ ] 路由守卫是否正确配置（AuthGuard、RoleGuard）
- [ ] 懒加载是否配置（`loadChildren` 或动态 import）
- [ ] 深层链接（Deep Links）是否正确配置

### Capacitor 插件
- [ ] 原生功能是否通过 Capacitor 插件（非 Cordova 插件）
- [ ] 插件版本与 Capacitor 版本是否兼容
- [ ] 权限请求是否正确处理（Camera、Geolocation 等需用户授权）
- [ ] Web 环境是否有 fallback 实现

### TypeScript 质量
- [ ] 类型定义完整，无 `any` 滥用
- [ ] Interface/Type 定义清晰
- [ ] strict mode 无报错
- [ ] 未使用的 import 已清理

### 性能
- [ ] 长列表是否使用虚拟滚动
- [ ] 图片是否使用 `<ion-img>` 懒加载
- [ ] 页面模块是否懒加载
- [ ] 是否有不必要的变更检测/重渲染
- [ ] `ion-infinite-scroll` 无限加载是否正确实现

### 样式
- [ ] 是否使用 `--ion-color-*` CSS 变量（非硬编码颜色）
- [ ] 全局样式是否在 `variables.scss` / `global.scss` 中定义
- [ ] 组件样式是否正确 scoped
- [ ] 暗黑模式（`prefers-color-scheme`）是否支持

### 安全
- [ ] HTTPS 强制
- [ ] 敏感数据是否使用 Secure Storage
- [ ] API 密钥无硬编码
- [ ] 输入是否使用 `<ion-input>` 并做验证
- [ ] 无 XSS 风险（Angular 默认安全，React/Vue 需检查 dangerouslySetInnerHTML/v-html）

### 测试
- [ ] 新增 Service 是否有单元测试
- [ ] 新增页面是否有组件测试
- [ ] 核心流程是否有 E2E 测试
- [ ] 测试覆盖关键业务逻辑

## 常见驳回原因

1. **使用原生 HTML 替代 Ionic 组件**：`<input>` → `<ion-input>`，`<button>` → `<ion-button>`
2. **使用 Cordova 插件**：应迁移到 Capacitor 插件
3. **直接操作 DOM**：`document.querySelector()` 等
4. **硬编码平台判断**：`navigator.userAgent` → `Platform` 服务
5. **未使用 `IonRouterOutlet`**：导致导航动画和生命周期异常
6. **长列表未虚拟滚动**：性能问题，尤其移动端
7. **缺少平台权限处理**：Camera、Geolocation 等需运行时权限
8. **敏感数据存 `localStorage`**：应用 `@capacitor/preferences` 或 Secure Storage
9. **硬编码颜色/样式值**：应用 `--ion-color-*` CSS 变量
10. **未处理安全区域**：刘海屏/底部指示条遮挡
