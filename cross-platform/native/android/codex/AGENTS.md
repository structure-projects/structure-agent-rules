# Android 原生开发规则

本目录包含 Android 原生开发的完整 AI 规则集合。

## 规则文件

| 文件 | 说明 |
|---|---|
| `prompts/developer.md` | Android 开发约束 |
| `prompts/architect.md` | Android 架构与选型 |
| `prompts/components.md` | Android 组件使用规范 |
| `prompts/tester.md` | Android 测试规范 |
| `prompts/reviewer.md` | Android 评审规则 |
| `prompts/project-scaffolding.md` | Android 项目脚手架 |
| `prompts/ci-cd.md` | Android CI/CD 规范 |

## 技术栈

- **语言**：Kotlin（Java 兼容）
- **UI**：Jetpack Compose + Material 3
- **架构**：MVVM + Repository
- **DI**：Hilt
- **数据库**：Room + DataStore
- **网络**：Retrofit + OkHttp
- **异步**：Kotlin Coroutines + Flow
- **构建**：Gradle Kotlin DSL + Version Catalog
- **minSdk**：>= 26 (Android 8.0)

## 关键约束

- **MUST** MVVM + Compose + Hilt + Room + Retrofit
- **MUST** HTTPS 强制，敏感数据加密
- **MUST** 测试驱动：JUnit + MockK + Compose Testing
- **禁止** 主线程阻塞、`!!` 非空断言、`GlobalScope`
