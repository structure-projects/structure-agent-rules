# Android 原生开发规则

> 角色：structure-developer（Android）。面向开发 Android 原生应用的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。IDE 包装文件使用 `android-` 前缀。

## 硬约束

- **MUST** 主语言：Kotlin（Java 仅维护旧代码）
- **MUST** UI 框架：Jetpack Compose（新代码）+ Material 3
- **MUST** 架构：MVVM + Repository + Hilt DI
- **MUST** 异步：Kotlin Coroutines + Flow
- **MUST** 数据库：Room（结构化）+ DataStore（键值对）
- **MUST** 网络：Retrofit + OkHttp + Kotlin Serialization
- **MUST** 构建：Gradle Kotlin DSL + Version Catalog（`libs.versions.toml`）

## 关键优先级

- **工具库**：Jetpack 官方库 > AndroidX > 社区库
- **UI 方式**：Jetpack Compose > XML Views（仅维护旧代码）
- **状态管理**：ViewModel + StateFlow > LiveData（新代码）
- **导航**：Navigation Component（`NavHost` + `composable()`）

## 命名规范

- **MUST** Activity/Fragment 以 `Activity` / `Fragment` 结尾（如 `UserListActivity`）
- **MUST** ViewModel 以 `ViewModel` 结尾（如 `UserViewModel`）
- **MUST** Composable 函数使用 PascalCase 且首字母大写（如 `UserCard`）
- **MUST** Repository 接口以 `Repository` 结尾，实现类加 `Impl` 后缀
- **MUST** 布局文件使用 snake_case（如 `activity_user_list.xml`）
- **MUST** 资源 ID 使用 snake_case（如 `R.string.user_name_label`）

## 文件组织

```
app/src/main/java/com/example/app/
├── App.kt                      # Application 类
├── MainActivity.kt             # 入口 Activity
├── data/
│   ├── local/                  # Room DAO, Entity
│   ├── remote/                 # Retrofit API Service, DTO
│   └── repository/             # Repository 实现
├── domain/
│   ├── model/                  # 领域模型（data class）
│   ├── repository/             # Repository 接口
│   └── usecase/                # UseCase（可选）
├── ui/
│   ├── navigation/             # NavGraph
│   ├── screens/                # 页面 Composable
│   ├── components/             # 可复用 Composable
│   └── theme/                  # Theme, Color, Type, Shape
└── di/                         # Hilt Module
```

## 编码规范

### Kotlin 风格

```kotlin
// ✅ 正确：data class 用于数据模型
data class User(
    val id: Long,
    val name: String,
    val email: String
)

// ✅ 正确：sealed interface 封装 UI 状态
sealed interface UiState<out T> {
    data object Loading : UiState<Nothing>
    data class Success<T>(val data: T) : UiState<T>
    data class Error(val message: String) : UiState<Nothing>
}

// ✅ 正确：使用 when 穷举
fun handleState(state: UiState<*>) {
    when (state) {
        is UiState.Loading -> showLoading()
        is UiState.Success -> showData(state.data)
        is UiState.Error -> showError(state.message)
    }
}
```

- **MUST** 使用 `data class` 定义数据模型
- **MUST** 使用 `sealed class` / `sealed interface` 封装 UI 状态
- **MUST** `when` 表达式穷举所有分支（使用 sealed class 确保编译期检查）
- **禁止** 使用 `!!` 强制非空断言（使用 `?.let {}` 或 `?:`）

### Compose 规范

```kotlin
@Composable
fun UserCard(
    user: User,
    modifier: Modifier = Modifier,
    onClick: () -> Unit = {}
) {
    Card(
        modifier = modifier.fillMaxWidth().clickable(onClick = onClick),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Row(modifier = Modifier.padding(16.dp)) {
            AsyncImage(
                model = user.avatarUrl,
                contentDescription = "头像",
                modifier = Modifier.size(48.dp).clip(CircleShape)
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column {
                Text(user.name, style = MaterialTheme.typography.titleMedium)
                Text(user.email, style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}
```

- **MUST** Composable 函数接收 `modifier: Modifier = Modifier` 参数
- **MUST** 回调使用函数类型参数（如 `onClick: () -> Unit`）
- **MUST** 样式使用 `MaterialTheme`，禁止硬编码颜色/字号
- **MUST** 使用 `Spacer` 控制间距，禁止 `padding` 做间距

## 权限处理

```kotlin
// 使用 accompanist-permissions 或 rememberLauncherForActivityResult
val launcher = rememberLauncherForActivityResult(
    contract = ActivityResultContracts.RequestPermission()
) { isGranted ->
    if (isGranted) { /* proceed */ }
}
```

- **MUST** 运行时权限使用 `rememberLauncherForActivityResult` + `ActivityResultContracts`
- **MUST** 权限拒绝时提供合理的降级体验
- **MUST** 敏感权限（相机、位置、存储）在 Manifest 中声明

## 测试工作流

- **MUST** 每开发一个功能立即写单元测试（JUnit + MockK）
- **MUST** 功能修改时同步修改测试并通过
- **MUST** UI 测试使用 Compose Testing（`createComposeRule()`）
- **MUST** 提交前 `./gradlew test` + `./gradlew lint` 全部通过
- **禁止** 测试/Lint 失败仍提交

## 禁止事项

- **禁止** 在主线程执行网络请求或数据库操作
- **禁止** 在 ViewModel 中持有 Context/View 引用
- **禁止** 使用 `GlobalScope` 启动协程
- **禁止** 硬编码字符串（使用 `strings.xml` 或 Compose `stringResource`）
- **禁止** 在 Composable 中直接调用 suspend 函数（使用 `LaunchedEffect`）
- **禁止** 使用 `!!` 非空断言操作符
