# Flutter 开发规则

本目录包含 Flutter 开发的完整 AI 规则集合。

## 规则文件

| 文件 | 说明 |
|---|---|
| `prompts/developer.md` | Flutter 开发约束 |
| `prompts/architect.md` | Flutter 架构与选型 |
| `prompts/components.md` | Flutter 组件使用规范 |
| `prompts/tester.md` | Flutter 测试规范 |
| `prompts/reviewer.md` | Flutter 评审规则 |
| `prompts/project-scaffolding.md` | Flutter 项目脚手架 |
| `prompts/ci-cd.md` | Flutter CI/CD 规范 |

## 技术栈

- **语言**：Dart 3+（records、patterns、sealed classes）
- **框架**：Flutter 3.22+
- **状态管理**：Riverpod 2.x（`@riverpod` code generation）
- **路由**：GoRouter 声明式路由
- **数据**：Freezed + json_serializable + Dio
- **存储**：flutter_secure_storage + Drift/Isar

## 关键约束

- **MUST** Riverpod 2.x + GoRouter + Freezed
- **MUST** `const` 构造函数 + `Theme.of(context)` 样式
- **禁止** ChangeNotifier、Navigator.push()
