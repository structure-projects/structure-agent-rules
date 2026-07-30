# Android 组件使用规范

> 本文件描述 Android 原生开发中的 UI 组件、架构组件与第三方库使用规范。
> 本规则自包含，不依赖其他技术栈目录。

## Jetpack Compose 组件（推荐）

### 基础组件

```kotlin
// 文本
Text(
    text = "Hello Android",
    style = MaterialTheme.typography.bodyLarge,
    color = MaterialTheme.colorScheme.onSurface
)

// 按钮
Button(onClick = { /* action */ }) {
    Text("确认")
}

// 输入框
var text by remember { mutableStateOf("") }
OutlinedTextField(
    value = text,
    onValueChange = { text = it },
    label = { Text("用户名") }
)
```

- **MUST** 文本样式使用 `MaterialTheme.typography`，颜色使用 `MaterialTheme.colorScheme`
- **MUST** 使用 `remember` 管理 Composable 内部状态
- **MUST** 回调函数使用 trailing lambda 语法

### 列表

```kotlin
LazyColumn {
    items(users) { user ->
        UserCard(user = user, onClick = { navigateToDetail(user.id) })
    }
}
```

- **MUST** 使用 `LazyColumn` / `LazyRow` 替代 `Column(verticalScroll(...))`
- **MUST** 使用 `key` 参数为列表项提供稳定 ID（数据类有 `id` 时自动）
- **SHOULD** 使用 `items` / `itemsIndexed` 扩展函数

### 状态收集

```kotlin
@Composable
fun UserListScreen(viewModel: UserListViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    
    when (val state = uiState) {
        is UiState.Loading -> CircularProgressIndicator()
        is UiState.Success -> UserList(state.users)
        is UiState.Error -> ErrorMessage(state.message)
    }
}
```

- **MUST** ViewModel StateFlow 使用 `collectAsStateWithLifecycle()` 收集
- **MUST** UI 状态使用 sealed class/interface 封装（Loading / Success / Error）

## Jetpack 架构组件

### ViewModel

```kotlin
@HiltViewModel
class UserViewModel @Inject constructor(
    private val userRepository: UserRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow<UiState>(UiState.Loading)
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()
    
    fun loadUsers() {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            try {
                val users = userRepository.getUsers()
                _uiState.value = UiState.Success(users)
            } catch (e: Exception) {
                _uiState.value = UiState.Error(e.message ?: "未知错误")
            }
        }
    }
}
```

- **MUST** ViewModel 继承 `androidx.lifecycle.ViewModel`
- **MUST** 使用 `@HiltViewModel` + `@Inject constructor` 注入依赖
- **MUST** StateFlow 的 Mutable 版本设为 private，对外暴露只读 StateFlow
- **MUST** 使用 `viewModelScope` 管理协程生命周期

### Room Database

```kotlin
@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey val id: Long,
    val name: String,
    val email: String
)

@Dao
interface UserDao {
    @Query("SELECT * FROM users")
    fun getAll(): Flow<List<UserEntity>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(users: List<UserEntity>)
}
```

- **MUST** Entity 使用 `@Entity` 注解，声明 `tableName`
- **MUST** DAO 使用 `@Dao` 接口，查询返回 Flow 实现响应式
- **MUST** 数据库操作在 `Dispatchers.IO` 上执行
- **禁止** 在主线程执行 Room 写操作

## 第三方库使用

### Retrofit + OkHttp

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(HttpLoggingInterceptor().apply {
                level = HttpLoggingInterceptor.Level.BODY
            })
            .addInterceptor { chain ->
                val request = chain.request().newBuilder()
                    .addHeader("Authorization", "Bearer ${getToken()}")
                    .build()
                chain.proceed(request)
            }
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build()
    }
}
```

- **MUST** OkHttpClient 使用 Hilt `@Module` + `@Provides @Singleton` 提供
- **MUST** 配置连接超时（connect/read/write）
- **MUST** 认证 Token 通过 Interceptor 统一注入

### Coil（图片加载）

```kotlin
AsyncImage(
    model = "https://example.com/avatar.jpg",
    contentDescription = "用户头像",
    modifier = Modifier.size(48.dp).clip(CircleShape)
)
```

- **MUST** Compose 项目使用 Coil 加载图片
- **SHOULD** 配置 placeholder / error / crossfade

### Hilt 依赖注入

```kotlin
@HiltAndroidApp
class MyApplication : Application()

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MyAppTheme {
                MainNavGraph()
            }
        }
    }
}
```

- **MUST** Application 类注解 `@HiltAndroidApp`
- **MUST** Activity 注解 `@AndroidEntryPoint`
- **MUST** ViewModel 注解 `@HiltViewModel`
- **MUST** Module 使用 `@Module` + `@InstallIn` 声明作用域
