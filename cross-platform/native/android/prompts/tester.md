# Android 测试规则

> 角色：structure-tester（Android 测试）。面向编写 Android 测试代码的 AI Agent。

## 测试分层

| 层级 | 工具 | 覆盖范围 | 速度 |
|---|---|---|---|
| **单元测试** | JUnit 4 + MockK | ViewModel、Repository、UseCase | 快 |
| **UI 测试** | Compose Testing / Espresso | Composable 渲染、交互 | 中 |
| **集成测试** | AndroidX Test + Hilt Testing | 多组件协作 | 慢 |
| **E2E 测试** | Espresso / UIAutomator | 完整用户流程 | 很慢 |

## 单元测试

### ViewModel 测试

```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class UserViewModelTest {
    
    @get:Rule
    val dispatcherRule = MainDispatcherRule()
    
    private val userRepository: UserRepository = mockk()
    private lateinit var viewModel: UserViewModel
    
    @Before
    fun setup() {
        viewModel = UserViewModel(userRepository)
    }
    
    @Test
    fun `loadUsers success - updates UI state to Success`() = runTest {
        val mockUsers = listOf(User(1, "张三", "zhang@test.com"))
        coEvery { userRepository.getUsers() } returns mockUsers
        
        viewModel.loadUsers()
        
        val state = viewModel.uiState.first()
        assertThat(state).isInstanceOf(UiState.Success::class.java)
        assertThat((state as UiState.Success).data).isEqualTo(mockUsers)
    }
    
    @Test
    fun `loadUsers failure - updates UI state to Error`() = runTest {
        coEvery { userRepository.getUsers() } throws IOException("网络错误")
        
        viewModel.loadUsers()
        
        val state = viewModel.uiState.first()
        assertThat(state).isInstanceOf(UiState.Error::class.java)
        assertThat((state as UiState.Error).message).contains("网络错误")
    }
}
```

- **MUST** ViewModel 测试使用 `runTest` 控制协程
- **MUST** 使用 MockK 的 `coEvery` / `coVerify` 模拟 suspend 函数
- **MUST** 使用 `MainDispatcherRule` 替换主线程调度器
- **MUST** 测试方法名使用反引号描述行为（`` `methodName - condition - expectedResult` ``）
- **MUST** 使用 Truth（`assertThat`）或 kotlin.test 进行断言

### Repository 测试

```kotlin
class UserRepositoryImplTest {
    
    private val userDao: UserDao = mockk()
    private val apiService: UserApiService = mockk()
    private lateinit var repository: UserRepositoryImpl
    
    @Before
    fun setup() {
        repository = UserRepositoryImpl(userDao, apiService)
    }
    
    @Test
    fun `getUsers returns cached data when offline`() = runTest {
        val cachedUsers = listOf(UserEntity(1, "张三", "zhang@test.com"))
        every { userDao.getAll() } returns flowOf(cachedUsers)
        coEvery { apiService.getUsers(any()) } throws IOException()
        
        val result = repository.getUsers().first()
        assertThat(result).isEqualTo(cachedUsers.map { it.toDomain() })
    }
}
```

## Compose UI 测试

```kotlin
class UserCardTest {
    
    @get:Rule
    val composeTestRule = createComposeRule()
    
    @Test
    fun `UserCard displays user name and email`() {
        val user = User(1, "张三", "zhang@test.com")
        
        composeTestRule.setContent {
            MyAppTheme {
                UserCard(user = user)
            }
        }
        
        composeTestRule.onNodeWithText("张三").assertIsDisplayed()
        composeTestRule.onNodeWithText("zhang@test.com").assertIsDisplayed()
    }
    
    @Test
    fun `UserCard click triggers onClick callback`() {
        var clicked = false
        val user = User(1, "张三", "zhang@test.com")
        
        composeTestRule.setContent {
            MyAppTheme {
                UserCard(user = user, onClick = { clicked = true })
            }
        }
        
        composeTestRule.onNodeWithText("张三").performClick()
        assertThat(clicked).isTrue()
    }
}
```

- **MUST** Compose 测试使用 `createComposeRule()`
- **MUST** 使用 `onNodeWithText()` / `onNodeWithTag()` 定位元素
- **MUST** 测试语义（显示内容、交互行为），非实现细节

## Hilt 测试配置

```kotlin
@HiltAndroidTest
class UserListScreenTest {
    
    @get:Rule
    val hiltRule = HiltAndroidRule(this)
    
    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()
    
    @BindValue
    @JvmField
    val userRepository: UserRepository = mockk()
    
    @Before
    fun setup() {
        hiltRule.inject()
    }
}
```

- **MUST** 需要 Hilt 的测试使用 `@HiltAndroidTest` 注解
- **MUST** 使用 `@BindValue` 替换真实依赖为 mock
- **MUST** 添加 `HiltAndroidRule` 规则

## 测试工作流

- **MUST** 每开发一个功能立即写单元测试，通过才能做下一个功能
- **MUST** 功能修改时同步修改测试并通过
- **MUST** 核心页面写 Compose UI 测试
- **MUST** 提交前 `./gradlew test` + `./gradlew lint` 全部通过
- **禁止** 测试/Lint 失败仍提交

## 测试文件命名

| 类型 | 命名 | 位置 |
|---|---|---|
| 单元测试 | `{Target}Test.kt` | `src/test/java/.../` |
| UI 测试 | `{Screen}Test.kt` | `src/androidTest/java/.../` |

## 关键依赖

```kotlin
// build.gradle.kts
dependencies {
    testImplementation(libs.junit)
    testImplementation(libs.mockk)
    testImplementation(libs.kotlinx.coroutines.test)
    
    androidTestImplementation(libs.compose.ui.test)
    androidTestImplementation(libs.hilt.android.testing)
    androidTestImplementation(libs.espresso.core)
}
```
