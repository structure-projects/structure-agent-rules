# Micronaut 测试规范

> Micronaut 4.x 项目单元测试、集成测试、端到端测试编写规范。

---

## 1. 测试框架与工具

| 工具 | 用途 |
|---|---|
| JUnit 5（Jupiter） | 测试引擎 |
| AssertJ | 流畅断言库 |
| Mockito | 单元测试 Mock |
| `@MockBean` | Micronaut 内置 Mock |
| Testcontainers | 集成测试（数据库、消息队列） |
| Awaitility | 异步测试等待 |

---

## 2. 测试分类

### 2.1 单元测试

测试单个类（Service、DomainService），Mock 所有外部依赖。

```java
@MicronautTest
class UserApplicationServiceTest {

    @Inject
    private UserApplicationService userApplicationService;

    @MockBean(UserRepository.class)
    private UserRepository userRepository;

    @Test
    void createUser_validInput_shouldReturnUserVO() {
        // Given
        CreateUserDTO dto = new CreateUserDTO();
        dto.setUsername("张三");
        dto.setEmail("zhangsan@example.com");

        User savedUser = new User();
        savedUser.setId(1L);
        savedUser.setUsername("张三");
        savedUser.setEmail("zhangsan@example.com");

        when(userRepository.save(any(User.class))).thenReturn(savedUser);

        // When
        UserVO result = userApplicationService.createUser(dto);

        // Then
        assertThat(result.getId()).isEqualTo(1L);
        assertThat(result.getUsername()).isEqualTo("张三");
        assertThat(result.getEmail()).isEqualTo("zhangsan@example.com");
        verify(userRepository).save(any(User.class));
    }

    @Test
    void findById_userNotExists_shouldReturnEmpty() {
        // Given
        when(userRepository.findById(999L)).thenReturn(Optional.empty());

        // When
        Optional<UserVO> result = userApplicationService.findById(999L);

        // Then
        assertThat(result).isEmpty();
    }
}
```

### 2.2 集成测试（数据库）

```java
@MicronautTest
@JpaProperties(hbm2ddlAuto = "create-drop")  // 测试用内存数据库
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class UserRepositoryTest {

    @Inject
    private UserRepository userRepository;

    @Test
    void findByEmail_existingEmail_shouldReturnUser() {
        // Given
        User user = User.create("张三", "zhangsan@example.com");
        userRepository.save(user);

        // When
        Optional<User> found = userRepository.findByEmail("zhangsan@example.com");

        // Then
        assertThat(found).isPresent();
        assertThat(found.get().getUsername()).isEqualTo("张三");
    }

    @Test
    void findByEmail_nonExistingEmail_shouldReturnEmpty() {
        Optional<User> found = userRepository.findByEmail("nonexist@example.com");
        assertThat(found).isEmpty();
    }
}
```

### 2.3 HTTP 集成测试

```java
@MicronautTest
class UserControllerTest {

    @Inject
    @Client("/")
    private HttpClient httpClient;

    @Inject
    private UserRepository userRepository;

    @Test
    void findById_existingUser_shouldReturn200() {
        // Given
        User user = User.create("张三", "zhangsan@example.com");
        userRepository.save(user);

        // When
        HttpResponse<UserVO> response = httpClient.toBlocking()
            .exchange(HttpRequest.GET("/api/v1/users/" + user.getId()), UserVO.class);

        // Then
        assertThat(response.getStatus()).isEqualTo(HttpStatus.OK);
        assertThat(response.body().getUsername()).isEqualTo("张三");
    }

    @Test
    void findById_nonExistingUser_shouldReturn404() {
        HttpResponse<UserVO> response = httpClient.toBlocking()
            .exchange(HttpRequest.GET("/api/v1/users/99999"), UserVO.class);

        assertThat(response.getStatus()).isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void createUser_validInput_shouldReturn201() {
        CreateUserDTO dto = new CreateUserDTO();
        dto.setUsername("李四");
        dto.setEmail("lisi@example.com");

        HttpRequest<CreateUserDTO> request = HttpRequest.POST("/api/v1/users", dto);
        HttpResponse<UserVO> response = httpClient.toBlocking()
            .exchange(request, UserVO.class);

        assertThat(response.getStatus()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.body().getId()).isNotNull();
    }
}
```

### 2.4 Testcontainers 集成测试

```java
@MicronautTest
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class UserRepositoryWithPostgresTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16")
        .withDatabaseName("testdb")
        .withUsername("test")
        .withPassword("test");

    @Inject
    private UserRepository userRepository;

    @Test
    void shouldPersistAndRetrieveUser() {
        User user = User.create("王五", "wangwu@example.com");
        userRepository.save(user);

        Optional<User> found = userRepository.findByEmail("wangwu@example.com");
        assertThat(found).isPresent();
    }
}
```

---

## 3. Mock 规范

### 3.1 @MockBean vs Mockito @Mock

```java
// ✅ 正确：使用 @MockBean（Micronaut 内置）
@MockBean(UserRepository.class)
private UserRepository userRepository;

// ❌ 错误：使用 Mockito @Mock（无法被 Micronaut 容器识别）
@Mock
private UserRepository userRepository;
```

### 3.2 Mock 最佳实践

```java
@Test
void updateUser_userNotFound_shouldThrowException() {
    // Given：Mock 不存在的用户
    when(userRepository.findById(999L)).thenReturn(Optional.empty());

    UpdateUserDTO dto = new UpdateUserDTO();
    dto.setUsername("新名称");

    // When & Then
    assertThatThrownBy(() -> userApplicationService.update(999L, dto))
        .isInstanceOf(NotFoundException.class)
        .hasMessageContaining("用户不存在");
}
```

---

## 4. 异步测试

```java
@Test
void publishEvent_shouldTriggerAsyncListener() {
    // Given
    CreateUserDTO dto = new CreateUserDTO();
    dto.setUsername("赵六");
    dto.setEmail("zhaoliu@example.com");

    // When
    userApplicationService.createUser(dto);

    // Then：等待异步处理完成
    await().atMost(5, TimeUnit.SECONDS)
        .untilAsserted(() -> {
            // 验证异步效果
            verify(emailService).sendWelcomeEmail(anyString());
        });
}
```

---

## 5. 测试命名规范

```
方法名_场景_期望结果

示例：
findById_userExists_returnUser()
findById_userNotExists_returnEmpty()
createUser_validInput_returnCreatedUser()
createUser_duplicateEmail_throwException()
updateUser_userNotFound_throwNotFoundException()
```

---

## 6. 测试覆盖率要求

| 层级 | 测试类型 | 最低覆盖率 |
|---|---|---|
| Controller | HTTP 集成测试 | 80% |
| ApplicationService | 单元测试 | 90% |
| DomainService | 单元测试 | 90% |
| Repository | 集成测试（Testcontainers/H2） | 80% |
| Entity 领域行为 | 单元测试 | 90% |

---

## 7. 测试数据管理

### 7.1 测试工厂方法

```java
public class UserTestFactory {

    public static User createDefaultUser() {
        return User.create("测试用户", "test@example.com");
    }

    public static CreateUserDTO createUserDTO() {
        CreateUserDTO dto = new CreateUserDTO();
        dto.setUsername("测试用户");
        dto.setEmail("test@example.com");
        return dto;
    }
}
```

### 7.2 测试隔离

- 每个测试方法 MUST 独立，不依赖执行顺序
- 集成测试 MUST 在每次测试后清理数据（`@AfterEach`）
- **禁止**在测试中使用 `Thread.sleep()`（使用 Awaitility 或 `CountDownLatch`）

---

## 8. 测试配置

```yaml
# src/test/resources/application-test.yml
datasources:
  default:
    url: jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1
    username: sa
    password: ""
    driver-class-name: org.h2.Driver

jpa:
  default:
    properties:
      hibernate:
        hbm2ddl:
          auto: create-drop
```

---

## 9. 测试检查清单

- [ ] 测试类使用 `@MicronautTest`
- [ ] Mock 使用 `@MockBean`（非 Mockito `@Mock`）
- [ ] 集成测试使用 Testcontainers 或 H2
- [ ] 每个测试方法独立，可任意顺序运行
- [ ] 测试命名遵循 `方法名_场景_期望结果`
- [ ] 核心业务逻辑单元测试覆盖率 ≥ 90%
- [ ] 无 `Thread.sleep()` 调用
- [ ] CI 流水线自动运行测试
