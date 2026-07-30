# Android 原生开发规则

## 角色与触发

本目录包含 Android 原生开发的 AI 规则。文件以 `android-` 为前缀，与其他技术栈规则天然不冲突。

### 按角色触发

| 角色 | 规则文件 | 触发条件 |
|---|---|---|
| **developer** | `prompts/developer.md` | 编写 Kotlin/Compose 代码 |
| **architect** | `prompts/architect.md` | 架构选型、模块设计 |
| **reviewer** | `prompts/reviewer.md` | 审查 PR / diff |
| **tester** | `prompts/tester.md` | 编写测试代码 |
| **components** | `prompts/components.md` | 使用 Android 组件/库 |
| **project-scaffolding** | `prompts/project-scaffolding.md` | 创建新项目 |
| **ci-cd** | `prompts/ci-cd.md` | 配置 CI/CD 流水线 |

### 技术栈约束

- **MUST** Kotlin + Jetpack Compose + Material 3
- **MUST** MVVM + Repository + Hilt DI
- **MUST** Coroutines + Flow 异步
- **MUST** Room + DataStore 持久化
- **MUST** Retrofit + OkHttp 网络
- **MUST** Gradle Kotlin DSL + Version Catalog
- **MUST** minSdk >= 26

详细规则请阅读各 `prompts/` 文件。
