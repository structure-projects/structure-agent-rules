# React Native 开发规则

## 角色与触发

本目录包含 React Native 开发的 AI 规则。文件以 `react-native-` 为前缀，与其他技术栈规则天然不冲突。

### 按角色触发

| 角色 | 规则文件 | 触发条件 |
|---|---|---|
| **developer** | `prompts/developer.md` | 编写 TSX/Hooks 代码 |
| **architect** | `prompts/architect.md` | 架构选型、模块设计 |
| **reviewer** | `prompts/reviewer.md` | 审查 PR / diff |
| **tester** | `prompts/tester.md` | 编写测试代码 |
| **components** | `prompts/components.md` | 使用 RN 组件/库 |
| **project-scaffolding** | `prompts/project-scaffolding.md` | 创建新项目 |
| **ci-cd** | `prompts/ci-cd.md` | 配置 CI/CD 流水线 |

### 技术栈约束

- **MUST** RN 0.73+ + TypeScript strict + New Architecture
- **MUST** React Navigation 6.x（Native Stack Navigator）
- **MUST** TanStack Query + Zustand
- **MUST** Hermes 引擎 + FastImage + Reanimated
- **MUST** SecureStore 存储敏感数据
- **禁止** `any` 类型、内联样式、直接 API 调用

详细规则请阅读各 `prompts/` 文件。
