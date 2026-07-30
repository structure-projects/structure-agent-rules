# Spring Boot 测试规范

> 通用 Spring Boot 项目测试约束与最佳实践。

---

## 1. 测试策略

### 1.1 测试金字塔

```
         /\
        /E2E\         少量：关键业务流程
       /------\
      / 集成测试 \      适量：模块间交互
     /----------\
    /  单元测试    \    大量：函数/方法级别
   /--------------\
```

### 1.2 覆盖率目标

| 层级 | 覆盖率目标 | 说明 |
|---|---|---|
| 单元测试 | ≥ 70% | Service、工具类、领域逻辑 |
| 集成测试 | 核心流程 100% | 数据库、缓存、MQ 交互 |
| E2E | 关键路径 | 用户核心操作链路 |

---

## 2. 测试框架

### 2.1 核心框架

- **JUnit 5**：测试框架（Jupiter API）
- **Mockito**：Mock 框架
- **AssertJ** / **Hamcrest**：断言库（推荐 AssertJ，流式 API 更直观）
- **Testcontainers**：集成测试容器（数据库、Redis、MQ）

### 2.2 依赖配置（Maven）

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>testcontainers</artifactId>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>mysql</artifactId>
    <scope>test</scope>
</dependency>
```

---

## 3. 单元测试

### 3.1 命名规范

```
测试类：{被测类名}Test
测试方法：{方法名}_{场景}_{期望结果}

示例：
- UserServiceTest
- createUser_ValidInput_ReturnsUser()
- createUser_DuplicateEmail_ThrowsException()
```

### 3.2 编写规范（MUST）

- 使用 `@ExtendWith(MockitoExtension.class)` 或 Mockito 注解
- 被测对象用 `@InjectMocks`，依赖用 `@Mock`
- 每个测试方法测试一个场景
- 使用 Given-When-Then 模式：

```java
@Test
void createUser_ValidInput_ReturnsUser() {
    // Given
    CreateUserDTO dto = new CreateUserDTO("张三", "zhangsan@example.com");
    when(userRepository.save(any())).thenReturn(mockUser);

    // When
    UserDTO result = userService.createUser(dto);

    // Then
    assertThat(result.getName()).isEqualTo("张三");
    verify(userRepository).save(any());
}
```

### 3.3 覆盖场景（MUST）

- 正常路径：合法输入得到预期输出
- 异常路径：非法输入抛出正确异常
- 边界条件：空值、空集合、最大值、最小值
- Mock 验证：`verify()` 确认依赖调用

### 3.4 禁止

- **禁止** 启动 Spring 上下文（不使用 `@SpringBootTest`）
- **禁止** Mock 被测对象本身
- **禁止** 僵尸断言（`assertNotNull` 无其他验证）
- **禁止** `Thread.sleep` 等待异步（使用 `Awaitility`）

---

## 4. 集成测试

### 4.1 命名规范

```
测试类：{功能名}IT 或 {被测类名}IntegrationTest
测试方法：{场景描述}

示例：
- UserServiceIT
- OrderServiceIntegrationTest
```

### 4.2 编写规范（MUST）

- 使用 `@SpringBootTest` + `@Transactional`（测试后自动回滚）
- 数据库 MUST 使用 Testcontainers 或 H2（内存数据库）
- 缓存/消息队列 MUST 使用 Testcontainers
- **禁止** Mock 数据库、Redis、MQ

```java
@SpringBootTest
@Transactional
@Testcontainers
class UserServiceIT {

    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0");

    @DynamicPropertySource
    static void configure(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", mysql::getJdbcUrl);
        registry.add("spring.datasource.username", mysql::getUsername);
        registry.add("spring.datasource.password", mysql::getPassword);
    }

    @Autowired
    private UserService userService;

    @Test
    void shouldCreateUserAndRetrieveById() {
        CreateUserDTO dto = new CreateUserDTO("张三", "zhangsan@example.com");
        Long id = userService.createUser(dto);
        UserDTO result = userService.findById(id);
        assertThat(result.getName()).isEqualTo("张三");
    }
}
```

### 4.3 Web 层测试

```java
@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserService userService;

    @Test
    void getUser_ReturnsUser() throws Exception {
        when(userService.findById(1L)).thenReturn(mockUserDTO);

        mockMvc.perform(get("/api/v1/users/1"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.name").value("张三"));
    }
}
```

### 4.4 覆盖场景

- CRUD 完整链路
- 事务回滚验证
- 缓存命中/未命中
- 并发场景（乐观锁冲突）
- 消息发送与消费

---

## 5. 测试数据管理

### 5.1 测试数据隔离

- 每个测试方法 SHOULD 独立准备数据
- 使用 `@BeforeEach` / `@AfterEach` 管理测试数据生命周期
- 集成测试使用 `@Transactional` 自动回滚

### 5.2 测试数据构造

- 使用 Builder 模式或工厂方法构造测试数据
- 推荐使用 Test Data Builder 模式或工具库（如 EasyRandom）

```java
// Builder 模式
User user = User.builder()
    .name("张三")
    .email("zhangsan@example.com")
    .build();
```

---

## 6. 测试工作流（MUST）

### 6.1 开发阶段

1. 编写功能代码前先思考测试场景
2. 每完成一个功能，**立即**编写单元测试
3. 单元测试通过后，继续下一个功能

### 6.2 提测阶段

1. 功能完成后，编写业务流程集成测试（`XxxIT`）
2. 集成测试通过才算功能交付

### 6.3 提交前

- [ ] `mvn clean test` 全部通过
- [ ] `mvn clean package -DskipTests` 编译通过
- [ ] 无 `@Disabled` 测试（除非有对应 issue 追踪）
- [ ] 覆盖率满足目标

### 6.4 禁止

- **禁止** 测试/编译失败仍提交代码
- **禁止** 无关联 issue 的 `@Disabled` 测试
- **禁止** 跳过测试合并 PR

---

## 7. 常用断言示例

### 7.1 AssertJ

```java
// 对象断言
assertThat(user.getName()).isEqualTo("张三");
assertThat(user.getEmail()).contains("@");

// 集合断言
assertThat(userList).hasSize(3);
assertThat(userList).extracting(User::getName).contains("张三");

// 异常断言
assertThatThrownBy(() -> userService.createUser(invalidDTO))
    .isInstanceOf(BusinessException.class)
    .hasMessageContaining("邮箱已存在");
```

### 7.2 Mockito

```java
// 行为验证
verify(userRepository).save(any(User.class));
verify(userRepository, times(1)).findById(1L);
verify(userRepository, never()).deleteById(any());

// 参数捕获
ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
verify(userRepository).save(captor.capture());
assertThat(captor.getValue().getName()).isEqualTo("张三");
```

---

## 8. 性能测试

### 8.1 基准测试

- 关键方法使用 JMH（Java Microbenchmark Harness）
- 关注吞吐量和延迟

### 8.2 压力测试

- 接口压力测试使用 JMeter / Gatling
- 关注 QPS、P99 延迟、错误率
