# Flutter 架构规则

> 角色：structure-architect（移动端架构）。面向需要做 Flutter 架构选型与技术决策的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。IDE 包装文件使用 `flutter-` 前缀。

## 架构模式

### 分层架构 + Riverpod

- **MUST** 采用 Feature-first 分层架构
- **MUST** 使用 Riverpod 进行状态管理和依赖注入
- **MUST** Repository 层封装数据源（本地数据库 + 远程 API）
- **MUST** 使用 Freezed 生成不可变数据类 + JSON 序列化

```
lib/
├── app.dart                      # MaterialApp 配置
├── main.dart                     # ProviderScope 入口
├── core/
│   ├── network/                  # Dio 客户端配置
│   ├── storage/                  # 本地存储封装
│   ├── theme/                    # 主题定义
│   ├── router/                   # GoRouter 配置
│   └── utils/                    # 工具函数
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/      # 远程/本地数据源
│   │   │   ├── models/           # DTO (Freezed)
│   │   │   └── repositories/     # Repository 实现
│   │   ├── domain/
│   │   │   ├── entities/         # 领域实体
│   │   │   └── repositories/     # Repository 接口
│   │   └── presentation/
│   │       ├── providers/        # Riverpod Providers
│   │       ├── screens/          # 页面
│   │       └── widgets/          # 页面级组件
│   └── home/
└── shared/
    ├── widgets/                  # 通用 Widget
    └── extensions/               # Dart 扩展
```

### 依赖注入

- **MUST** 使用 Riverpod 进行依赖注入（替代 Provider 的 `ChangeNotifier`）
- **MUST** `ProviderScope` 包裹 `MaterialApp.router()`
- **MUST** Repository 通过 `Provider<T>` 暴露，Service 通过 `Provider` 暴露
- **禁止** 使用 `ChangeNotifier` / `StateNotifier`（迁移到 Riverpod 2.x AsyncNotifier）

## 状态管理

- **MUST** 全局状态使用 Riverpod（`StateNotifierProvider` / `AsyncNotifierProvider`）
- **MUST** 服务端状态使用 Riverpod 的 `FutureProvider` / `AsyncNotifier`
- **MUST** Widget 内部状态使用 `StatefulWidget` + `setState` 或 `flutter_hooks`
- **SHOULD** 使用 `flutter_hooks` 简化 Widget 状态管理

```dart
// Riverpod AsyncNotifier
@riverpod
class UserListNotifier extends _$UserListNotifier {
  @override
  Future<List<User>> build() async {
    return ref.watch(userRepositoryProvider).getUsers();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(userRepositoryProvider).getUsers(),
    );
  }
}
```

## 路由

- **MUST** 使用 GoRouter 声明式路由
- **MUST** 类型安全路由参数
- **MUST** 使用 `ShellRoute` 实现嵌套导航（BottomNavigationBar）
- **MUST** 使用 `redirect` 实现路由守卫（认证检查）

```dart
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = ref.read(authProvider).isLoggedIn;
      final isLoginRoute = state.matchedLocation == '/login';
      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: '/detail/:id',
            builder: (_, state) => DetailScreen(id: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});
```

## 数据持久化

- **MUST** 结构化数据使用 Drift（SQLite，推荐）或 Isar
- **MUST** 简单键值对使用 `flutter_secure_storage`（敏感）或 `shared_preferences`（非敏感）
- **MUST** 数据库操作通过 Repository 封装

## 网络层

- **MUST** 使用 Dio 作为 HTTP 客户端
- **MUST** 配置 Interceptor（日志、Token 注入、错误处理）
- **MUST** 网络请求通过 Repository 封装

```dart
@singleton
class DioClient {
  late final Dio dio;

  DioClient() {
    dio = Dio(BaseOptions(
      baseUrl: 'https://api.example.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
    dio.interceptors.addAll([
      LogInterceptor(requestBody: true, responseBody: true),
      AuthInterceptor(),
    ]);
  }
}
```

## 环境配置

- **MUST** 使用 `--dart-define` 或 `.env` 文件配置环境变量
- **MUST** 区分 dev / staging / production 环境
- **禁止** 硬编码 API 地址和密钥

```bash
flutter run --dart-define=API_BASE_URL=https://api.dev.example.com
```

## 安全

- **MUST** 敏感数据使用 `flutter_secure_storage`
- **MUST** API 密钥通过 `--dart-define` 或环境变量注入
- **MUST** HTTPS 强制
- **SHOULD** 使用 `flutter_ssl_pinning` 防止中间人攻击

## 多平台考虑

- **MUST** 使用 `Platform.isIOS` / `Platform.isAndroid` 处理平台差异
- **MUST** Material Design 3（Android）+ Cupertino（iOS 特定组件）
- **SHOULD** Web 和 Desktop 平台按需启用
