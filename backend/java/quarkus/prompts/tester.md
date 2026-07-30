# Quarkus 测试规范

> Quarkus 3.x 项目单元测试、集成测试、Native 测试编写规范。

---

## 1. 测试框架与工具

| 工具 | 用途 |
|---|---|
| JUnit 5（Jupiter） | 测试引擎 |
| REST Assured | HTTP 集成测试（Quarkus 内置） |
| Mockito | 单元测试 Mock |
| `@InjectMock` | Quarkus CDI Mock |
| Testcontainers | 集成测试（数据库、消息队列） |
| `@QuarkusIntegrationTest` | Native Image 集成测试 |

---

## 2. 测试分类

### 2.1 单元测试

```java
@QuarkusTest
class UserApplicationServiceTest {

    @Inject
    UserApplicationService userApplicationService;

    @InjectMock
    UserRepository userRepository;

    @Test
    void createUser_validInput_shouldReturnUserVO() {
        CreateUserDTO dto = new CreateUserDTO("张三", "zhangsan@example.com");
        Mockito.when(userRepository.findByEmail("zhangsan@example.com")).thenReturn(null);
        Mockito.doNothing().when(userRepository).persist(Mockito.any(User.class));

        UserVO result = userApplicationService.createUser(dto);

        assertThat(result.getUsername()).isEqualTo("张三");
    }
}
```

### 2.2 HTTP 集成测试（REST Assured）

```java
@QuarkusTest
class UserResourceTest {

    @Test
    void findById_existingUser_shouldReturn200() {
        given()
            .when().get("/api/v1/users/1")
            .then()
            .statusCode(200)
            .body("username", notNullValue());
    }

    @Test
    void findById_nonExistingUser_shouldReturn404() {
        given()
            .when().get("/api/v1/users/99999")
            .then()
            .statusCode(404);
    }

    @Test
    void createUser_validInput_shouldReturn201() {
        CreateUserDTO dto = new CreateUserDTO("李四", "lisi@example.com");
        given()
            .contentType(MediaType.APPLICATION_JSON)
            .body(dto)
            .when().post("/api/v1/users")
            .then()
            .statusCode(201)
            .body("username", equalTo("李四"));
    }

    @Test
    void createUser_invalidEmail_shouldReturn400() {
        CreateUserDTO dto = new CreateUserDTO("李四", "invalid-email");
        given()
            .contentType(MediaType.APPLICATION_JSON)
            .body(dto)
            .when().post("/api/v1/users")
            .then()
            .statusCode(400);
    }
}
```

### 2.3 Testcontainers 集成测试

```java
@QuarkusTest
@QuarkusTestResource(PostgresResource.class)
class UserRepositoryTest {

    @Inject
    UserRepository userRepository;

    @Test
    void shouldPersistAndFindByEmail() {
        User user = new User();
        user.username = "张三";
        user.email = "zhangsan@example.com";
        user.createdAt = LocalDateTime.now();
        userRepository.persist(user);

        User found = userRepository.findByEmail("zhangsan@example.com");
        assertThat(found).isNotNull();
        assertThat(found.username).isEqualTo("张三");
    }
}

public class PostgresResource implements QuarkusTestResourceLifecycleManager {
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16")
        .withDatabaseName("testdb").withUsername("test").withPassword("test");

    @Override
    public Map<String, String> start() {
        postgres.start();
        return Map.of(
            "quarkus.datasource.jdbc.url", postgres.getJdbcUrl(),
            "quarkus.datasource.username", postgres.getUsername(),
            "quarkus.datasource.password", postgres.getPassword()
        );
    }

    @Override
    public void stop() {
        postgres.stop();
    }
}
```

### 2.4 Native 集成测试

```java
@QuarkusIntegrationTest  // 在 Native Image 中运行
class NativeUserResourceIT extends UserResourceTest {
    // 继承 HTTP 集成测试，在 Native 模式下执行
}
```

```bash
# 运行 Native 测试
./mvnw verify -Pnative
```

---

## 3. Mock 规范

### 3.1 @InjectMock vs Mockito @Mock

```java
// ✅ 正确：使用 @InjectMock（Quarkus CDI Mock）
@InjectMock
UserRepository userRepository;

// ❌ 错误：使用 Mockito @Mock（无法被 Quarkus 容器识别）
@Mock
UserRepository userRepository;
```

### 3.2 @TestHTTPResource

```java
@QuarkusTest
class UserResourceTest {

    @TestHTTPResource("/api/v1/users")
    URL usersUrl;

    @Test
    void shouldAccessUsers() {
        given()
            .when().get(usersUrl)
            .then()
            .statusCode(200);
    }
}
```

---

## 4. 测试命名规范

```
方法名_场景_期望结果

示例：
findById_userExists_return200()
findById_userNotExists_return404()
createUser_validInput_return201()
createUser_duplicateEmail_return409()
```

---

## 5. 测试覆盖率要求

| 层级 | 测试类型 | 最低覆盖率 |
|---|---|---|
| Resource | HTTP 集成测试（REST Assured） | 80% |
| ApplicationService | 单元测试（@InjectMock） | 90% |
| DomainService | 单元测试 | 90% |
| Repository | 集成测试（Testcontainers） | 80% |
| Native Image | 关键路径集成测试 | 必须通过 |

---

## 6. 测试配置

```properties
# src/test/resources/application.properties
quarkus.datasource.db-kind=h2
quarkus.datasource.jdbc.url=jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1
quarkus.datasource.username=sa
quarkus.datasource.password=
quarkus.hibernate-orm.database.generation=drop-and-create
quarkus.hibernate-orm.log.sql=true

# 测试中禁用安全
quarkus.http.auth.basic=false
```

---

## 7. 测试数据管理

### 7.1 测试工厂方法

```java
public class UserTestFactory {
    public static User createDefaultUser() {
        User user = new User();
        user.username = "测试用户";
        user.email = "test@example.com";
        user.createdAt = LocalDateTime.now();
        return user;
    }

    public static CreateUserDTO createUserDTO() {
        return new CreateUserDTO("测试用户", "test@example.com");
    }
}
```

### 7.2 测试隔离

- 每个测试方法 MUST 独立，不依赖执行顺序
- 使用 `@Transactional` + 自动回滚 或 `@BeforeEach`/`@AfterEach` 清理数据
- **禁止**使用 `Thread.sleep()`（使用 Awaitility）

---

## 8. 响应式测试

```java
@QuarkusTest
class ReactiveUserResourceTest {

    @Test
    void shouldReturnUserAsync() {
        given()
            .when().get("/api/v1/users/1")
            .then()
            .statusCode(200)
            .body("username", notNullValue());
    }
}
```

---

## 9. Dev 模式测试

```bash
# Dev 模式持续运行测试
./mvnw quarkus:dev

# Dev UI 查看测试结果
# 访问 http://localhost:8080/q/dev
```

---

## 10. 测试检查清单

- [ ] 测试类使用 `@QuarkusTest`
- [ ] Mock 使用 `@InjectMock`
- [ ] HTTP 测试使用 REST Assured
- [ ] 集成测试使用 `@QuarkusTestResource` + Testcontainers
- [ ] Native 测试使用 `@QuarkusIntegrationTest`
- [ ] 每个测试方法独立，可任意顺序运行
- [ ] 核心业务逻辑单元测试覆盖率 ≥ 90%
- [ ] 无 `Thread.sleep()` 调用
- [ ] CI 流水线自动运行测试
