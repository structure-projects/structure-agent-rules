# Flutter 开发规则

## 角色与触发

本目录包含 Flutter 开发的 AI 规则。文件以 `flutter-` 为前缀，与其他技术栈规则天然不冲突。

### 按角色触发

| 角色 | 规则文件 | 触发条件 |
|---|---|---|
| **developer** | `prompts/developer.md` | 编写 Dart/Widget 代码 |
| **architect** | `prompts/architect.md` | 架构选型、模块设计 |
| **reviewer** | `prompts/reviewer.md` | 审查 PR / diff |
| **tester** | `prompts/tester.md` | 编写测试代码 |
| **components** | `prompts/components.md` | 使用 Flutter 组件/库 |
| **project-scaffolding** | `prompts/project-scaffolding.md` | 创建新项目 |
| **ci-cd** | `prompts/ci-cd.md` | 配置 CI/CD 流水线 |

### 技术栈约束

- **MUST** Dart 3+ + Flutter 3.22+
- **MUST** Riverpod 2.x（`@riverpod` code generation）
- **MUST** GoRouter + Freezed + Dio
- **MUST** `dart format` + `flutter analyze`
- **禁止** ChangeNotifier、Navigator.push()

详细规则请阅读各 `prompts/` 文件。
