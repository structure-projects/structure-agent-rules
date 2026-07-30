# Flutter 开发规则

> 角色：structure-developer（Flutter）。面向开发 Flutter 应用的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。IDE 包装文件使用 `flutter-` 前缀。

## 硬约束

- **MUST** Dart 3+（records、patterns、sealed classes）
- **MUST** Flutter 3.x+ stable channel
- **MUST** 状态管理：Riverpod 2.x（`@riverpod` code generation）
- **MUST** 路由：GoRouter 声明式路由
- **MUST** 网络：Dio
- **MUST** 数据类：Freezed + json_serializable
- **MUST** 代码生成：`build_runner build`
- **MUST** 代码风格：`dart format` + `flutter analyze`

## 关键优先级

- **状态管理**：Riverpod > Bloc > Provider（旧版）
- **数据库**：Drift（SQLite）> Isar
- **路由**：GoRouter > Navigator 2.0 裸用
- **Widget**：ConsumerWidget > ConsumerStatefulWidget > StatefulWidget > StatelessWidget
- **DI**：Riverpod Provider > 手动注入

## 命名规范

- **MUST** 文件名 snake_case（`user_card.dart`、`user_repository.dart`）
- **MUST** 类名 PascalCase（`UserCard`、`UserRepository`）
- **MUST** 变量/函数名 camelCase（`userName`、`fetchUsers()`）
- **MUST** 常量 camelCase 或 SCREAMING_SNAKE_CASE（`maxRetryCount`、`API_BASE_URL`）
- **MUST** 私有成员以下划线开头（`_userName`、`_handleTap()`）
- **MUST** Provider 名以 `Provider` 结尾（`userListNotifierProvider`）

## 文件组织

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── network/
│   │   ├── dio_client.dart
│   │   └── interceptors/
│   ├── storage/
│   │   └── secure_storage.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── colors.dart
│   │   └── typography.dart
│   ├── router/
│   │   └── app_router.dart
│   └── utils/
│       ├── extensions.dart
│       └── validators.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── user_dto.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_provider.dart
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   └── register_screen.dart
│   │       └── widgets/
│   │           └── login_form.dart
│   └── home/
│       └── presentation/
│           └── screens/
│               └── home_screen.dart
└── shared/
    ├── widgets/
    │   ├── loading_indicator.dart
    │   └── error_view.dart
    └── extensions/
        └── context_extensions.dart
```

## 编码规范

### Widget 规范

```dart
// ✅ 正确：ConsumerWidget + Freezed model
@freezed
class User with _$User {
  const factory User({
    required int id,
    required String name,
    required String email,
  }) = _User;
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

class UserCard extends ConsumerWidget {
  final User user;
  final VoidCallback? onTap;
  
  const UserCard({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(child: Text(user.name[0])),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: Theme.of(context).textTheme.titleMedium),
                  Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- **MUST** 使用 `const` 构造函数（`const UserCard(...)`）
- **MUST** 使用 `Theme.of(context)` 获取主题样式
- **MUST** `const EdgeInsets.all(16)` 使用 const 常量
- **MUST** 使用 `SizedBox` 控制间距

### Provider 规范

```dart
// providers/auth_provider.dart
part 'auth_provider.g.dart';

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl(ref.watch(dioClientProvider));
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<User?> build() async {
    final token = await ref.watch(secureStorageProvider).read(key: 'token');
    if (token == null) return null;
    return ref.watch(authRepositoryProvider).getCurrentUser();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).login(email, password);
      await ref.read(secureStorageProvider).write(key: 'token', value: user.token);
      return user;
    });
  }

  Future<void> logout() async {
    await ref.read(secureStorageProvider).delete(key: 'token');
    ref.invalidateSelf();
  }
}
```

- **MUST** 使用 `part 'xxx.g.dart'` + `@riverpod` 注解
- **MUST** `build()` 方法返回初始状态
- **MUST** 使用 `AsyncValue.guard()` 安全处理异步

### Repository 规范

```dart
// domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User> getCurrentUser();
  Future<void> logout();
}

// data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final DioClient _dio;
  AuthRepositoryImpl(this._dio);

  @override
  Future<User> login(String email, String password) async {
    final response = await _dio.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return UserDTO.fromJson(response.data).toDomain();
  }
}
```

- **MUST** Repository 接口定义在 `domain/`，实现在 `data/`
- **MUST** DTO 在 data 层，Entity 在 domain 层
- **MUST** DTO 提供 `toDomain()` 方法转换

## 测试工作流

- **MUST** 每开发一个功能立即写单元测试（`flutter_test`）
- **MUST** 功能修改时同步修改测试并通过
- **MUST** Widget 测试使用 `pumpWidget` + `Finder`
- **MUST** 提交前 `flutter analyze` + `flutter test` 全部通过
- **禁止** 分析/测试失败仍提交

## 禁止事项

- **禁止** 使用 `ChangeNotifier` / `StateNotifier`（迁移到 Riverpod 2.x）
- **禁止** 使用旧版 `Navigator.push()`（使用 GoRouter）
- **禁止** 使用 `http` package（使用 Dio）
- **禁止** 在 Widget 中直接调用网络请求（通过 Provider）
- **禁止** 硬编码字符串、颜色、尺寸
- **禁止** 在 `build` 方法中进行异步操作
- **禁止** 使用 `late` 修饰未初始化变量（用 `late final` 或懒加载）
