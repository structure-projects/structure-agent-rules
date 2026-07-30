# Ionic 开发规则

本目录包含 Ionic 跨平台开发的完整 AI 规则集合。

## 规则文件

| 文件 | 说明 |
|---|---|
| `prompts/developer.md` | Ionic 开发约束 |
| `prompts/architect.md` | Ionic 架构与选型 |
| `prompts/components.md` | Ionic 组件与 Capacitor 插件使用规范 |
| `prompts/tester.md` | Ionic 测试规范 |
| `prompts/reviewer.md` | Ionic 评审规则 |
| `prompts/project-scaffolding.md` | Ionic 项目脚手架 |
| `prompts/ci-cd.md` | Ionic CI/CD 规范 |

## 技术栈

- **框架**：Ionic 7+ + Capacitor 5+
- **语言**：TypeScript strict
- **前端框架**：Angular 17+（推荐）/ React 18+ / Vue 3+
- **UI 组件**：Ionic 组件（ion-button、ion-list、ion-card 等）
- **原生能力**：Capacitor 插件（Camera、Filesystem、Storage、Push）
- **存储**：`@capacitor/preferences` / `@ionic/storage`
- **构建**：`ionic build` + `ionic cap sync`

## 关键约束

- **MUST** Ionic 组件替代原生 HTML 元素
- **MUST** Capacitor 插件（非 Cordova 插件）
- **MUST** TypeScript strict mode
- **MUST** `Platform` 服务做平台检测
- **禁止** Cordova、直接操作 DOM、硬编码样式
