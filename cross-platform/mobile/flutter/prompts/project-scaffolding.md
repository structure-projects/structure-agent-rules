# Flutter 项目脚手架规则

> 面向创建 Flutter 项目的 AI Agent。

## 创建步骤

1. **MUST** 使用 Flutter 3.x+ stable channel
2. **MUST** 创建项目时指定 org 和 platforms

```bash
flutter create \
  --org com.example \
  --platforms android,ios,web \
  --project-name my_app \
  my_app
```

## 项目配置

### pubspec.yaml

```yaml
name: my_app
description: A Flutter application.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'
  flutter: '>=3.22.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # Router
  go_router: ^14.0.0

  # Network
  dio: ^5.4.0

  # Data
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0

  # Storage
  flutter_secure_storage: ^9.2.0
  shared_preferences: ^2.2.0

  # UI
  flutter_hooks: ^0.20.0
  cached_network_image: ^3.3.0
  google_fonts: ^6.2.0

  # Utils
  intl: ^0.19.0
  logger: ^2.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code Generation
  build_runner: ^2.4.0
  riverpod_generator: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0

  # Lint
  flutter_lints: ^4.0.0
  custom_lint: ^0.6.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/fonts/
    - .env
```

- **MUST** SDK constraint >=3.4.0（Dart 3.4+）
- **MUST** Flutter constraint >=3.22.0
- **MUST** 所有依赖使用版本约束
- **MUST** `publish_to: 'none'`（App 项目不发布到 pub.dev）

### analysis_options.yaml

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - avoid_print
    - prefer_const_constructors
    - prefer_const_declarations
    - require_trailing_commas
    - sort_constructors_first
    - unawaited_futures

analyzer:
  errors:
    missing_return: error
    dead_code: error
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
```

- **MUST** 启用 `prefer_const_constructors`
- **MUST** 启用 `require_trailing_commas`
- **MUST** 排除生成文件（`*.g.dart`、`*.freezed.dart`）

## 目录结构

```
my_app/
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── network/
│   │   ├── storage/
│   │   ├── theme/
│   │   ├── router/
│   │   └── utils/
│   ├── features/
│   │   └── home/
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/
│   └── shared/
│       ├── widgets/
│       └── extensions/
├── test/
│   ├── core/
│   └── features/
├── assets/
│   ├── images/
│   └── fonts/
├── .env
├── pubspec.yaml
├── analysis_options.yaml
├── l10n.yaml
└── .gitignore
```

## main.dart 入口

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

- **MUST** `ProviderScope` 包裹根 Widget
- **MUST** `WidgetsFlutterBinding.ensureInitialized()` 在 runApp 前调用

## 环境配置

### .env 文件

```
API_BASE_URL=https://api.example.com
APP_NAME=MyApp
```

### 读取环境变量

```dart
// 使用 --dart-define
const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

// 或使用 flutter_dotenv
await dotenv.load(fileName: '.env');
final apiBaseUrl = dotenv.env['API_BASE_URL']!;
```

- **MUST** 使用 `--dart-define` 或 `.env` 管理环境变量
- **禁止** 将 `.env` 文件提交到 Git（包含敏感信息时）

## 检查清单

- [ ] Flutter 3.22+ stable channel
- [ ] Dart SDK >=3.4.0
- [ ] `ProviderScope` 包裹根 Widget
- [ ] Riverpod code generation 配置
- [ ] GoRouter 配置路由
- [ ] Freezed + json_serializable 配置
- [ ] `analysis_options.yaml` 配置完善
- [ ] `prefer_const_constructors` 启用
- [ ] `.gitignore` 排除 `*.g.dart`（可选，取决于团队策略）、`.env`、`build/`
- [ ] 国际化配置 `l10n.yaml`（如需多语言）

## 禁止事项

- **禁止** 使用旧版 Provider（`ChangeNotifierProvider`）
- **禁止** 使用 Navigator 1.0 API（`Navigator.push()`）
- **禁止** SDK constraint 低于 3.0.0
- **禁止** 在 pubspec.yaml 中硬编码本地路径（使用 relative path 或 git reference）
- **禁止** 将签名密钥、`.env` 等敏感文件提交到 Git
