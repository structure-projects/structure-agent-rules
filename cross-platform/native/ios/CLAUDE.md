# iOS 原生开发规则

## 角色与触发

本目录包含 iOS 原生开发的 AI 规则。文件以 `ios-` 为前缀，与其他技术栈规则天然不冲突。

### 按角色触发

| 角色 | 规则文件 | 触发条件 |
|---|---|---|
| **developer** | `prompts/developer.md` | 编写 Swift/SwiftUI 代码 |
| **architect** | `prompts/architect.md` | 架构选型、模块设计 |
| **reviewer** | `prompts/reviewer.md` | 审查 PR / diff |
| **tester** | `prompts/tester.md` | 编写测试代码 |
| **components** | `prompts/components.md` | 使用 iOS 组件/框架 |
| **project-scaffolding** | `prompts/project-scaffolding.md` | 创建新项目 |
| **ci-cd** | `prompts/ci-cd.md` | 配置 CI/CD 流水线 |

### 技术栈约束

- **MUST** Swift 5.9+ + SwiftUI + MVVM
- **MUST** Swift Concurrency（async/await、Task、Actor）
- **MUST** URLSession + SPM + SwiftLint
- **MUST** Deployment Target >= iOS 16.0
- **MUST** Keychain 存储敏感数据
- **禁止** CocoaPods / Carthage

详细规则请阅读各 `prompts/` 文件。
