# Micronaut 开发规范

> 基于 Micronaut 4.x 的 Java 后端开发完整规范。

---

## 1. 项目环境

### 1.1 技术要求

| 项 | 要求 |
|---|---|
| JDK | 17+ |
| 语言 | Java（仅 Java，不使用 Kotlin） |
| 构建工具 | Gradle（Kotlin DSL，推荐） |
| Micronaut 版本 | 4.x |
| 响应式 | Project Reactor（推荐）或 RxJava 3 |
| ORM | Micronaut Data（JPA/Hibernate 或 JDBC） |

### 1.2 build.gradle.kts 模板

```kotlin
plugins {
    id("io.micronaut.application") version "4.4.0"
}

version = "0.1"
group = "com.example"

repositories {
    mavenCentral()
}

micronaut {
    version.set("4.4.0")
    runtime.set(io.micronaut.gradle.MicronautRuntime.NETTY)
}

dependencies {
    annotationProcessor("io.micronaut:micronaut-inject-java")
    annotationProcessor("io.micronaut.data:micronaut-data-processor")
    annotationProcessor("io.micronaut.openapi:micronaut-openapi")
    annotationProcessor("io.micronaut.validation:micronaut-validation-processor")

    implementation("io.micronaut:micronaut-http-server-netty")
    implementation("io.micronaut.data:micronaut-data-hibernate-jpa")
    implementation("io.micronaut.reactor:micronaut-reactor")
    implementation("io.micronaut.security:micronaut-security-jwt")
    implementation("io.micronaut.openapi:micronaut-openapi")
    implementation("jakarta.validation:jakarta.validation-api")

    runtimeOnly("org.postgresql:postgresql")
    runtimeOnly("io.micronaut.sql:micronaut-jdbc-hikari")

    testImplementation("io.micronaut.test:micronaut-test-junit5")
    testImplementation("org.assertj:assertj-core")
    testImplementation("org.testcontainers:testcontainers")
    testImplementation("org.testcontainers:postgresql")
    testRuntimeOnly("org.junit.jupiter:junit-jupiter-engine")
}

application {
    mainClass.set("com.example.Application")
}
```

---

## 2. 项目结构（DDD 四层）

```
src/main/java/com/example/
├── Application.java                 # 入口类
├── api/                             # HTTP 接入层
│   ├── controller/
│   │   └── UserController.java      # @Controller
│   └── dto/
│       ├── CreateUserDTO.java
│       └── UserVO.java
├── domain/                          # 领域层
│   ├── entity/
│   │   └── User.java                # JPA Entity
│   ├── repository/
│   │   └── UserRepository.java      # Repository 接口
│   └── service/
│       └── UserDomainService.java   # 领域服务
├── application/                     # 应用层
│   └── service/
│       └── UserApplicationService.java  # 应用服务（事务边界）
└── infrastructure/                  # 基础设施层
    ├── repository/
    │   └── UserRepositoryImpl.java  # 仅 JDBC Repository 需要实现
    └── client/
        └── OrderClient.java         # 外部服务 @Client
```

---

## 3. 核心组件规范

### 3.1 Controller（HTTP 接入层）

```java
@Controller("/api/v1/users")
@Secured(SecurityRule.IS_AUTHENTICATED)
public class UserController {

    private final UserApplicationService userApplicationService;

    public UserController(UserApplicationService userApplicationService) {
        this.userApplicationService = userApplicationService;
    }

    @Post
    @Operation(summary = "创建用户")
    public HttpResponse<UserVO> create(@Body @Valid CreateUserDTO dto) {
        UserVO user = userApplicationService.createUser(dto);
        return HttpResponse.created(user);
    }

    @Get("/{id}")
    @Operation(summary = "根据 ID 查询用户")
    public HttpResponse<UserVO> findById(@PathVariable Long id) {
        return userApplicationService.findById(id)
            .map(HttpResponse::ok)
            .orElse(HttpResponse.notFound());
    }

    @Get("/page{?pageNum,pageSize}")
    @Operation(summary = "分页查询用户")
    public HttpResponse<Page<UserVO>> page(
            @QueryValue(defaultValue = "1") @Min(1) Integer pageNum,
            @QueryValue(defaultValue = "20") @Min(1) @Max(100) Integer pageSize) {
        return HttpResponse.ok(userApplicationService.page(pageNum, pageSize));
    }

    @Put("/{id}")
    @Operation(summary = "更新用户")
    public HttpResponse<Void> update(
            @PathVariable Long id,
            @Body @Valid UpdateUserDTO dto) {
        userApplicationService.update(id, dto);
        return HttpResponse.noContent();
    }

    @Delete("/{id}")
    @Operation(summary = "删除用户")
    public HttpResponse<Void> delete(@PathVariable Long id) {
        userApplicationService.delete(id);
        return HttpResponse.noContent();
    }
}
```

**规范要求**：
- Controller 方法 MUST 返回 `HttpResponse<T>`（同步）或 `Mono<HttpResponse<T>>`（响应式）
- `@Body` 绑定请求体，`@PathVariable` 绑定路径参数，`@QueryValue` 绑定查询参数
- 类级别使用 `@Secured` 声明安全策略

### 3.2 ApplicationService（应用层，事务边界）

```java
@Singleton
public class UserApplicationService {

    private final UserRepository userRepository;
    private final UserDomainService userDomainService;

    public UserApplicationService(UserRepository userRepository,
                                   UserDomainService userDomainService) {
        this.userRepository = userRepository;
        this.userDomainService = userDomainService;
    }

    @Transactional
    public UserVO createUser(CreateUserDTO dto) {
        userDomainService.validateEmailUnique(dto.getEmail());
        User user = User.create(dto.getUsername(), dto.getEmail());
        userRepository.save(user);
        return UserVO.from(user);
    }

    @Transactional(readOnly = true)
    public Optional<UserVO> findById(Long id) {
        return userRepository.findById(id).map(UserVO::from);
    }

    @Transactional(readOnly = true)
    public Page<UserVO> page(Integer pageNum, Integer pageSize) {
        return userRepository.findAll(Pageable.from(pageNum - 1, pageSize))
            .map(UserVO::from);
    }

    @Transactional
    public void update(Long id, UpdateUserDTO dto) {
        User user = userRepository.findById(id)
            .orElseThrow(() -> new NotFoundException("用户不存在: " + id));
        user.update(dto.getUsername(), dto.getEmail());
        userRepository.update(user);
    }

    @Transactional
    public void delete(Long id) {
        userRepository.deleteById(id);
    }
}
```

### 3.3 Entity（领域实体）

```java
@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 50)
    private String username;

    @Column(nullable = false, unique = true, length = 100)
    private String email;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    // 工厂方法
    public static User create(String username, String email) {
        User user = new User();
        user.username = username;
        user.email = email;
        user.createdAt = LocalDateTime.now();
        user.updatedAt = LocalDateTime.now();
        return user;
    }

    // 领域行为
    public void update(String username, String email) {
        this.username = username;
        this.email = email;
        this.updatedAt = LocalDateTime.now();
    }

    // Getters（Lombok 可选）
    public Long getId() { return id; }
    public String getUsername() { return username; }
    public String getEmail() { return email; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
```

### 3.4 Repository（数据访问）

```java
// JPA 风格（推荐）
@JpaRepository
public interface UserRepository extends CrudRepository<User, Long> {

    Optional<User> findByEmail(String email);

    @Query("FROM User u WHERE u.username LIKE :keyword")
    Page<User> search(@Parameter("keyword") String keyword, Pageable pageable);
}
```

### 3.5 DTO / VO

```java
@Introspected
public class CreateUserDTO {

    @NotBlank(message = "用户名不能为空")
    @Size(min = 2, max = 50, message = "用户名长度为 2-50 个字符")
    private String username;

    @NotBlank(message = "邮箱不能为空")
    @Email(message = "邮箱格式不正确")
    private String email;

    // 必须有无参构造器（Micronaut AOT 要求）
    public CreateUserDTO() {}

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
}

@Introspected
public class UserVO {

    private Long id;
    private String username;
    private String email;
    private LocalDateTime createdAt;

    public UserVO() {}

    public static UserVO from(User user) {
        UserVO vo = new UserVO();
        vo.id = user.getId();
        vo.username = user.getUsername();
        vo.email = user.getEmail();
        vo.createdAt = user.getCreatedAt();
        return vo;
    }

    // Getters / Setters
}
```

**注意**：Micronaut AOT 要求 DTO/VO 类标注 `@Introspected` 注解（启用 Bean Introspection），**禁止**使用 `record` 作为 DTO（需要 `@Introspected` 支持）。

---

## 4. HTTP 客户端（声明式 `@Client`）

```java
@Client(id = "order-service")
@Header(name = "Authorization", value = "Bearer ${order.service.token}")
public interface OrderClient {

    @Get("/api/v1/orders/user/{userId}")
    List<OrderVO> listByUserId(Long userId);

    @Post("/api/v1/orders")
    OrderVO create(@Body CreateOrderDTO dto);
}
```

配置：

```yaml
micronaut:
  http:
    services:
      order-service:
        urls:
          - http://order-service:8080
        read-timeout: 5s
        connect-timeout: 2s
```

**规范**：
- **禁止**使用 `RestTemplate` / `WebClient`（Spring 风格）
- `@Client` 接口 MUST 放在 `infrastructure/client/` 包下
- 超时、重试 MUST 在 `application.yml` 中显式配置

---

## 5. 响应式编程

```java
// 同步
@Get("/api/v1/users/{id}")
public HttpResponse<UserVO> findById(@PathVariable Long id) { ... }

// 响应式（返回 Mono）
@Get("/api/v1/users")
public Mono<List<UserVO>> list() { ... }

// 响应式流（返回 Flowable）
@Get("/api/v1/users/stream")
public Flowable<UserEvent> stream() { ... }
```

**规范**：
- 响应式链中**禁止**调用 `.block()`
- 数据库操作使用 R2DBC（响应式驱动）或保持同步

---

## 6. 异常处理

### 6.1 全局异常处理器

```java
@Singleton
@Produces
public class GlobalExceptionHandler implements ExceptionHandler<Exception, HttpResponse<ErrorResponse>> {

    @Override
    public HttpResponse<ErrorResponse> handle(HttpRequest request, Exception exception) {
        if (exception instanceof NotFoundException) {
            return HttpResponse.notFound(new ErrorResponse(404, exception.getMessage()));
        }
        if (exception instanceof ConstraintViolationException) {
            return HttpResponse.badRequest(new ErrorResponse(400, "参数校验失败: " + exception.getMessage()));
        }
        log.error("未处理异常", exception);
        return HttpResponse.serverError(new ErrorResponse(500, "服务器内部错误"));
    }
}
```

### 6.2 特定异常处理

```java
@Singleton
@Produces
public class NotFoundExceptionHandler implements ExceptionHandler<NotFoundException, HttpResponse<ErrorResponse>> {

    @Override
    public HttpResponse<ErrorResponse> handle(HttpRequest request, NotFoundException exception) {
        return HttpResponse.notFound(new ErrorResponse(404, exception.getMessage()));
    }
}
```

---

## 7. 配置管理

### 7.1 application.yml

```yaml
micronaut:
  application:
    name: user-service
  server:
    port: 8080

datasources:
  default:
    url: jdbc:postgresql://localhost:5432/user_db
    username: ${DB_USERNAME:postgres}
    password: ${DB_PASSWORD:postgres}
    driver-class-name: org.postgresql.Driver

jpa:
  default:
    properties:
      hibernate:
        hbm2ddl:
          auto: validate
        show_sql: false
```

### 7.2 @ConfigurationProperties

```java
@ConfigurationProperties("app.jwt")
public class JwtProperties {
    private String secret;
    private long expiration = 3600;  // 默认 1 小时

    public String getSecret() { return secret; }
    public void setSecret(String secret) { this.secret = secret; }
    public long getExpiration() { return expiration; }
    public void setExpiration(long expiration) { this.expiration = expiration; }
}
```

---

## 8. 日志规范

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Singleton
public class UserApplicationService {
    private static final Logger log = LoggerFactory.getLogger(UserApplicationService.class);

    public UserVO createUser(CreateUserDTO dto) {
        log.info("创建用户: {}", dto.getEmail());
        // ...
    }
}
```

**规范**：
- MUST 使用 SLF4J（`org.slf4j.Logger`）
- **禁止**使用 `System.out.println` / `System.err.println`
- 异常日志 MUST 包含完整堆栈：`log.error("操作失败", exception)`

---

## 9. 安全检查清单

- [ ] 所有 Controller MUST 有 `@Secured` 注解
- [ ] JWT Token 校验 MUST 在 Filter 层完成
- [ ] 敏感配置（密码、密钥）MUST 使用环境变量或外部 Secret
- [ ] 生产环境 MUST 关闭 Swagger/OpenAPI 端点
- [ ] 输入校验 MUST 使用 `jakarta.validation` 注解
- [ ] SQL 参数 MUST 使用参数化查询（Micronaut Data 默认安全）
- [ ] CORS 配置 MUST 限制允许的域名

---

## 10. Commit 前检查清单

- [ ] 所有 Bean 使用构造器注入（`private final`）
- [ ] HTTP 调用使用 `@Client` 声明式接口
- [ ] 校验注解使用 `jakarta.validation`
- [ ] DTO/VO 标注 `@Introspected`
- [ ] Controller 方法返回 `HttpResponse<T>` 或 `Mono<HttpResponse<T>>`
- [ ] 测试类使用 `@MicronautTest`
- [ ] 无 Spring 框架依赖
- [ ] 无 `System.out.println`
- [ ] 配置使用 `@ConfigurationProperties` 而非 `@Value`
