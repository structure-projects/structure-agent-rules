# Flutter 组件使用规范

> 本文件描述 Flutter 开发中的 Widget、状态管理和第三方库使用规范。
> 本规则自包含，不依赖其他技术栈目录。

## Riverpod（状态管理 + DI）

### Provider 定义

```dart
// 简单 Provider：Repository/Service
@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  return UserRepository(ref.watch(dioClientProvider));
}

// FutureProvider：一次性异步数据
@riverpod
Future<List<User>> users(UsersRef ref) {
  return ref.watch(userRepositoryProvider).getUsers();
}

// AsyncNotifier：可变的异步状态
@riverpod
class UserListNotifier extends _$UserListNotifier {
  @override
  Future<List<User>> build() async {
    return ref.watch(userRepositoryProvider).getUsers();
  }
  
  Future<void> addUser(CreateUserDTO dto) async {
    final newUser = await ref.read(userRepositoryProvider).createUser(dto);
    ref.invalidate(usersProvider); // 刷新列表
  }
}
```

- **MUST** 使用 Riverpod 2.x + code generation（`@riverpod` 注解）
- **MUST** Repository 通过 `@riverpod` 暴露
- **MUST** 使用 `ref.watch()` 读取，`ref.read()` 调用方法
- **MUST** 使用 `ref.invalidate()` 刷新缓存

### Widget 中使用

```dart
class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(userListNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('用户列表')),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('错误: $error')),
        data: (users) => ListView.builder(
          itemCount: users.length,
          itemBuilder: (_, i) => UserCard(user: users[i]),
        ),
      ),
    );
  }
}
```

- **MUST** Widget 使用 `ConsumerWidget` / `ConsumerStatefulWidget`
- **MUST** 使用 `asyncValue.when()` 处理 loading/error/data 三态

## GoRouter（路由）

```dart
// 类型安全路由
@TypedGoRoute<DetailRoute>(path: '/detail/:id')
class DetailRoute extends GoRouteData {
  final String id;
  const DetailRoute({required this.id});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return DetailScreen(id: id);
  }
}

// 导航
context.pushNamed('detail', pathParameters: {'id': '123'});
// 或
const DetailRoute(id: '123').go(context);
```

- **MUST** 使用 GoRouter + GoRouteData 实现类型安全路由
- **MUST** 路由守卫使用 `redirect`
- **MUST** 嵌套导航使用 `ShellRoute`

## Freezed（不可变数据类）

```dart
@freezed
class User with _$User {
  const factory User({
    required int id,
    required String name,
    required String email,
    @Default('') String avatarUrl,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

- **MUST** 数据模型使用 `@freezed` 注解
- **MUST** 配合 `json_serializable` 生成 JSON 序列化代码
- **MUST** 使用 `@Default` 设置默认值

## Dio（网络层）

```dart
@singleton
class DioClient {
  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DioClient() {
    dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment('API_BASE_URL'),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.addAll([
      _AuthInterceptor(_storage),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }
}

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  _AuthInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
```

- **MUST** 使用 Dio + Interceptor 封装网络层
- **MUST** Token 自动注入通过 Interceptor 实现
- **MUST** 使用 `const String.fromEnvironment()` 读取环境变量

## 本地存储

```dart
// 敏感数据
final secureStorage = FlutterSecureStorage();
await secureStorage.write(key: 'token', value: token);
final token = await secureStorage.read(key: 'token');

// 非敏感数据
final prefs = await SharedPreferences.getInstance();
await prefs.setString('language', 'zh-CN');
```

- **MUST** Token/密码使用 `flutter_secure_storage`
- **MAY** 简单配置使用 `shared_preferences`

## flutter_hooks

```dart
class SearchScreen extends HookConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final debouncedQuery = useDebounce(searchController.text, duration: 300.ms);
    
    // debouncedQuery 变化时自动触发搜索
    return TextField(controller: searchController);
  }
}
```

- **SHOULD** 使用 `flutter_hooks` 简化 Widget 状态管理
- **MUST** 使用 `useTextEditingController` 等 Hook 管理资源生命周期

## 响应式布局

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 600) {
      return MobileLayout();
    } else if (constraints.maxWidth < 1200) {
      return TabletLayout();
    } else {
      return DesktopLayout();
    }
  },
)
```

- **MUST** 使用 `LayoutBuilder` + `MediaQuery` 实现响应式
- **SHOULD** 使用 `Breakpoint` 类统一管理断点
