# React Native 开发规则

本目录包含 React Native 开发的完整 AI 规则集合。

## 规则文件

| 文件 | 说明 |
|---|---|
| `prompts/developer.md` | React Native 开发约束 |
| `prompts/architect.md` | React Native 架构与选型 |
| `prompts/components.md` | React Native 组件使用规范 |
| `prompts/tester.md` | React Native 测试规范 |
| `prompts/reviewer.md` | React Native 评审规则 |
| `prompts/project-scaffolding.md` | React Native 项目脚手架 |
| `prompts/ci-cd.md` | React Native CI/CD 规范 |

## 技术栈

- **框架**：React Native 0.73+（New Architecture）
- **语言**：TypeScript strict
- **导航**：React Navigation 6.x（Native Stack）
- **状态**：Zustand + TanStack Query
- **样式**：StyleSheet / NativeWind
- **引擎**：Hermes
- **构建**：Expo / RN CLI + EAS Build

## 关键约束

- **MUST** TypeScript strict + Hermes
- **MUST** TanStack Query + Zustand
- **MUST** FastImage + Reanimated
- **禁止** `any`、内联样式、直接 API 调用
