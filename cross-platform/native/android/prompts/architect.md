# Android 原生架构规则

> 角色：structure-architect（移动端架构）。面向需要做 Android 架构选型与技术决策的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。IDE 包装文件使用 `android-` 前缀。

## 架构模式

### MVVM + Repository

- **MUST** 采用 MVVM 架构，ViewModel 负责 UI 状态管理
- **MUST** Repository 层封装数据源（本地 Room + 远程 API），对 ViewModel 暴露统一数据接口
- **MUST** ViewModel 不持有 Context/View 引用，使用 LiveData/StateFlow 暴露不可变状态
- **SHOULD** 使用 UseCase 层封装复杂业务逻辑（可选，简单 CRUD 可省略）

```
ui/
├── screens/          # Composable / Fragment 页面
├── components/       # 可复用 Composable / View
└── theme/            # Material 3 主题

domain/
├── model/            # 领域实体（data class）
├── repository/       # Repository 接口
└── usecase/          # 业务用例（可选）

data/
├── local/            # Room DAO + Entity
├── remote/           # Retrofit API Service + DTO
└── repository/       # Repository 实现
```

### 依赖注入

- **MUST** 使用 Hilt 进行依赖注入
- **MUST** `@HiltAndroidApp` 注解 Application 类
- **MUST** `@AndroidEntryPoint` 注解 Activity/Fragment
- **MUST** `@HiltViewModel` 注解 ViewModel
- **MAY** Service/WorkManager 使用 `@AndroidEntryPoint`

## UI 架构

### Jetpack Compose（推荐）

- **MUST** 新项目使用 Jetpack Compose + Material 3
- **MUST** 使用 `remember` / `mutableStateOf` 管理 Composable 内部状态
- **MUST** ViewModel 通过 `collectAsStateWithLifecycle()` 收集 StateFlow
- **SHOULD** 使用 `Modifier` 链式调用，禁止修改父级 Modifier
- **禁止** 在 Composable 中执行副作用（使用 `LaunchedEffect` / `DisposableEffect`）

### XML Views（维护旧代码）

- **MUST** 使用 ViewBinding，禁止 findViewById
- **MUST** 使用 DataBinding 的 `@{}` 表达式仅用于简单绑定
- **SHOULD** 逐步迁移到 Compose

## 导航

- **MUST** 使用 Navigation Component（`androidx.navigation`）
- **MUST** Compose 项目使用 `NavHost` + `composable()` 声明路由
- **MUST** 类型安全的导航参数使用 `NavType`
- **SHOULD** 深层链接使用 `deepLinks` 参数声明

```kotlin
NavHost(navController, startDestination = "home") {
    composable("home") { HomeScreen(navController) }
    composable("detail/{id}", arguments = listOf(
        navArgument("id") { type = NavType.IntType }
    )) { backStackEntry ->
        DetailScreen(backStackEntry.arguments?.getInt("id") ?: 0)
    }
}
```

## 数据持久化

- **MUST** 结构化数据使用 Room Database
- **MUST** Entity 用 `@Entity` 注解，DAO 用 `@Dao` 接口
- **MUST** 键值对配置使用 DataStore（Preferences DataStore 或 Proto DataStore）
- **禁止** 使用 SharedPreferences（迁移到 DataStore）

## 网络层

- **MUST** 使用 Retrofit + OkHttp 作为 HTTP 客户端
- **MUST** 使用 Kotlin Serialization 或 Moshi 进行 JSON 解析
- **MUST** 配置 OkHttp Interceptor（日志、认证 Header、重试）
- **SHOULD** 网络请求通过 Repository 封装，不在 ViewModel 直接调用

```kotlin
interface UserApiService {
    @GET("api/users")
    suspend fun getUsers(@Query("page") page: Int): Response<UserListResponse>
}
```

## 异步处理

- **MUST** 使用 Kotlin Coroutines + Flow
- **MUST** ViewModel 中使用 `viewModelScope` 启动协程
- **MUST** 使用 `Dispatchers.IO` 执行网络/数据库操作
- **MUST** 使用 `Dispatchers.Main` 更新 UI 状态
- **SHOULD** 使用 `callbackFlow` / `channelFlow` 包装回调 API

## 构建配置

- **MUST** 使用 Gradle Kotlin DSL（`build.gradle.kts`）
- **MUST** 集中管理依赖版本（Version Catalog `libs.versions.toml`）
- **MUST** 配置 `minSdk` / `targetSdk` / `compileSdk`
- **MUST** 开启 R8/ProGuard 代码混淆（release 构建）
- **SHOULD** 使用 `buildTypes` 区分 debug/release 配置

## 安全

- **MUST** 敏感数据存储使用 EncryptedSharedPreferences 或 EncryptedFile
- **MUST** API 密钥通过 BuildConfig 或 local.properties 注入，禁止硬编码
- **MUST** HTTPS 强制开启，禁止明文传输
- **SHOULD** 使用 SafetyNet / Play Integrity 验证设备完整性
- **SHOULD** 使用 ProGuard 规则保护敏感类不被反编译
