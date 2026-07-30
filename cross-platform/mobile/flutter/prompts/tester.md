# Flutter 测试规则

> 角色：structure-tester（Flutter 测试）。面向编写 Flutter 测试代码的 AI Agent。

## 测试分层

| 层级 | 工具 | 覆盖范围 | 速度 |
|---|---|---|---|
| **单元测试** | flutter_test | Repository、Service、Provider | 快 |
| **Widget 测试** | flutter_test | Widget 渲染、交互 | 中 |
| **集成测试** | integration_test | 完整页面流程 | 慢 |

## 单元测试

### Repository 测试

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late AuthRepositoryImpl repository;
  late MockDioClient mockDio;

  setUp(() {
    mockDio = MockDioClient();
    repository = AuthRepositoryImpl(mockDio);
  });

  group('login', () {
    test('returns User on success', () async {
      // Arrange
      when(() => mockDio.dio).thenReturn(Dio());
      // Mock HTTP response...

      // Act
      final user = await repository.login('test@test.com', 'password');

      // Assert
      expect(user.email, 'test@test.com');
    });

    test('throws on network error', () async {
      when(() => mockDio.dio).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
      ));

      expect(
        () => repository.login('test@test.com', 'wrong'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
```

- **MUST** 使用 `flutter_test` 包
- **MUST** 使用 `mocktail` 创建 Mock（支持 null safety）
- **MUST** 使用 `group()` 组织相关测试
- **MUST** Arrange-Act-Assert 模式

### Provider 测试

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('AuthNotifier login updates state', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      ],
    );

    final notifier = container.read(authNotifierProvider.notifier);
    
    expect(container.read(authNotifierProvider), isA<AsyncLoading>());
    
    await notifier.login('test@test.com', 'password');
    
    final state = container.read(authNotifierProvider);
    expect(state.value?.email, 'test@test.com');
  });
}
```

- **MUST** 使用 `ProviderContainer` 测试 Provider
- **MUST** 使用 `overrideWithValue()` 替换依赖为 Mock

## Widget 测试

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('UserCard displays user info', (tester) async {
    final user = User(id: 1, name: '张三', email: 'zhang@test.com');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: UserCard(user: user)),
        ),
      ),
    );

    expect(find.text('张三'), findsOneWidget);
    expect(find.text('zhang@test.com'), findsOneWidget);
  });

  testWidgets('UserCard triggers onTap', (tester) async {
    var tapped = false;
    final user = User(id: 1, name: '张三', email: 'zhang@test.com');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: UserCard(user: user, onTap: () => tapped = true),
          ),
        ),
      ),
    );

    await tester.tap(find.text('张三'));
    expect(tapped, isTrue);
  });
}
```

- **MUST** 使用 `testWidgets()` 函数
- **MUST** 使用 `tester.pumpWidget()` 渲染 Widget
- **MUST** 包裹 `ProviderScope` + `MaterialApp`
- **MUST** 使用 `find.text()` / `find.byType()` 查找 Widget
- **MUST** 使用 `tester.tap()` / `tester.enterText()` 模拟交互

## 集成测试

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full login flow', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // 输入凭证
    await tester.enterText(find.byKey(const Key('email_field')), 'test@test.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'password');
    
    // 点击登录
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    // 验证进入主页
    expect(find.byKey(const Key('home_screen')), findsOneWidget);
  });
}
```

- **MUST** 集成测试使用 `integration_test` 包
- **MUST** 使用 `tester.pumpAndSettle()` 等待动画完成
- **MUST** 使用 `Key` 定位关键 Widget

## 测试工作流

- **MUST** 每开发一个功能立即写单元测试，通过才能做下一个功能
- **MUST** 功能修改时同步修改测试并通过
- **MUST** 核心 Widget 写 Widget 测试
- **MUST** 核心流程写集成测试
- **MUST** 提交前 `flutter analyze` + `flutter test` 全部通过
- **禁止** 分析/测试失败仍提交

## 测试文件命名

| 类型 | 命名 | 位置 |
|---|---|---|
| 单元测试 | `{target}_test.dart` | `test/` 目录（镜像 lib/ 结构） |
| Widget 测试 | `{widget}_test.dart` | `test/` 目录 |
| 集成测试 | `{feature}_test.dart` | `integration_test/` 目录 |

## 关键依赖

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
  integration_test:
    sdk: flutter
```
