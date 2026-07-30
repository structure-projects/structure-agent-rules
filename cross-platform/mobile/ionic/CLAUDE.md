# Ionic 开发规则

## 角色与触发

本目录包含 Ionic 跨平台开发的 AI 规则。文件以 `ionic-` 为前缀，与其他技术栈规则天然不冲突。

### 按角色触发

| 角色 | 规则文件 | 触发条件 |
|---|---|---|
| **developer** | `prompts/developer.md` | 编写 TypeScript/HTML/SCSS 代码 |
| **architect** | `prompts/architect.md` | 架构选型、模块设计 |
| **reviewer** | `prompts/reviewer.md` | 审查 PR / diff |
| **tester** | `prompts/tester.md` | 编写测试代码 |
| **components** | `prompts/components.md` | 使用 Ionic 组件/Capacitor 插件 |
| **project-scaffolding** | `prompts/project-scaffolding.md` | 创建新项目 |
| **ci-cd** | `prompts/ci-cd.md` | 配置 CI/CD 流水线 |

### 技术栈约束

- **MUST** Ionic 7+ + Capacitor 5+（非 Cordova）
- **MUST** TypeScript strict + Angular（推荐）/React/Vue
- **MUST** 使用 Ionic 组件（`ion-button`、`ion-list`、`ion-card` 等），禁止裸 HTML 元素
- **MUST** Capacitor 插件访问原生能力（Camera、Filesystem、Storage）
- **MUST** `@capacitor/preferences` 或 `@ionic/storage` 存储数据
- **禁止** Cordova 插件、直接操作 DOM、硬编码样式

详细规则请阅读各 `prompts/` 文件。
