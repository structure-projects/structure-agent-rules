# iOS 原生开发规则

本目录包含 iOS 原生开发的完整 AI 规则集合。

## 规则文件

| 文件 | 说明 |
|---|---|
| `prompts/developer.md` | iOS 开发约束 |
| `prompts/architect.md` | iOS 架构与选型 |
| `prompts/components.md` | iOS 组件使用规范 |
| `prompts/tester.md` | iOS 测试规范 |
| `prompts/reviewer.md` | iOS 评审规则 |
| `prompts/project-scaffolding.md` | iOS 项目脚手架 |
| `prompts/ci-cd.md` | iOS CI/CD 规范 |

## 技术栈

- **语言**：Swift 5.9+
- **UI**：SwiftUI（UIKit 仅互操作）
- **架构**：MVVM
- **异步**：Swift Concurrency（async/await、Task、Actor）
- **数据库**：Core Data / SwiftData + Keychain
- **网络**：URLSession async/await
- **依赖管理**：Swift Package Manager（SPM）
- **部署目标**：iOS 16.0+

## 关键约束

- **MUST** SwiftUI + MVVM + async/await
- **MUST** SPM 管理依赖
- **MUST** Keychain 存储敏感数据
- **禁止** CocoaPods / Carthage
- **禁止** `try!` / `as!` 强制解包
