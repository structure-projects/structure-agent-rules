# Quarkus 开发规范

> 基于 Quarkus 3.x 的 Java/Kotlin 后端开发完整规范。

---

## 1. 项目环境

### 1.1 技术要求

| 项 | 要求 |
|---|---|
| JDK | 17+ |
| 语言 | Java / Kotlin |
| 构建工具 | Maven（推荐）或 Gradle |
| Quarkus 版本 | 3.x |
| 响应式 | Mutiny（SmallRye Mutiny）— `Uni<T>` / `Multi<T>` |
| ORM | Hibernate with Panache |
| REST | RESTEasy Reactive（JAX-RS） |

### 1.2 pom.xml 模板

```xml
<properties>
    <quarkus.version>3.15.0</quarkus.version>
    <maven.compiler.release>17</maven.compiler.release>
</properties>

<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>io.quarkus</groupId>
            <artifactId>quarkus-bom</artifactId>
            <version>${quarkus.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>

<dependencies>
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-resteasy-reactive-jackson</artifactId>
    </dependency>
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-hibernate-orm-panache</artifactId>
    </dependency>
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-hibernate-validator</artifactId>
    </dependency>
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-smallrye-openapi</artifactId>
    </dependency>
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-smallrye-jwt</artifactId>
    </dependency>
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-jdbc-postgresql</artifactId>
    </dependency>
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-rest-client-reactive-jackson</artifactId>
    </dependency>

    <!-- Test -->
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-junit5</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>rest-assured</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

---

## 2. 项目结构

```
src/main/java/com/example/
├── api/                             # JAX-RS Resource（HTTP 接入层）
│   ├── resource/
│   │   └── UserResource.java        # @Path + JAX-RS 注解
│   └── dto/
│       ├── CreateUserDTO.java
│       └── UserVO.java
├── domain/                          # 领域层
│   ├── entity/
│   │   └── User.java                # PanacheEntity / Entity
│   └── service/
│       └── UserDomainService.java   # 领域服务
├── application/                     # 应用层
│   └── service/
│       └── UserApplicationService.java  # 应用服务（事务边界）
└── infrastructure/                  # 基础设施层
    └── client/
        └── OrderClient.java         # MicroProfile REST Client
```

---

## 3. 核心组件规范

### 3.1 JAX-RS Resource（HTTP 接入层）

```java
@Path("/api/v1/users")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Authenticated
public class UserResource {

    @Inject
    UserApplicationService userApplicationService;

    @POST
    @Operation(summary = "创建用户")
    @APIResponse(responseCode = "201", description = "创建成功")
    @APIResponse(responseCode = "400", description = "参数校验失败")
    public Response create(@Valid CreateUserDTO dto) {
        UserVO user = userApplicationService.createUser(dto);
        return Response.status(Response.Status.CREATED).entity(user).build();
    }

    @GET
    @Path("/{id}")
    @Operation(summary = "根据 ID 查询用户")
    public Response findById(@PathParam("id") Long id) {
        UserVO user = userApplicationService.findById(id);
        if (user == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        return Response.ok(user).build();
    }

    @GET
    @Path("/page")
    @Operation(summary = "分页查询用户")
    public Response page(
            @QueryParam("pageNum") @DefaultValue("1") @Min(1) Integer pageNum,
            @QueryParam("pageSize") @DefaultValue("20") @Min(1) @Max(100) Integer pageSize) {
        return Response.ok(userApplicationService.page(pageNum, pageSize)).build();
    }

    @PUT
    @Path("/{id}")
    @Operation(summary = "更新用户")
    public Response update(@PathParam("id") Long id, @Valid UpdateUserDTO dto) {
        userApplicationService.update(id, dto);
        return Response.noContent().build();
    }

    @DELETE
    @Path("/{id}")
    @Operation(summary = "删除用户")
    public Response delete(@PathParam("id") Long id) {
        userApplicationService.delete(id);
        return Response.noContent().build();
    }
}
```

**规范要求**：
- Resource 方法返回 `Response`（同步）或 `Uni<Response>`（响应式）
- 类级别使用 `@Authenticated` / `@RolesAllowed` 声明安全策略
- 使用 JAX-RS 标准注解：`@Path`、`@GET`、`@POST`、`@PUT`、`@DELETE`

### 3.2 ApplicationService（应用层，事务边界）

```java
@ApplicationScoped
public class UserApplicationService {

    @Inject
    UserRepository userRepository;

    @Inject
    UserDomainService userDomainService;

    @Transactional
    public UserVO createUser(CreateUserDTO dto) {
        userDomainService.validateEmailUnique(dto.getEmail());
        User user = new User();
        user.username = dto.getUsername();
        user.email = dto.getEmail();
        user.createdAt = LocalDateTime.now();
        userRepository.persist(user);
        return UserVO.from(user);
    }

    @Transactional(readOnly = true)
    public UserVO findById(Long id) {
        User user = userRepository.findById(id);
        return user != null ? UserVO.from(user) : null;
    }

    @Transactional(readOnly = true)
    public List<UserVO> page(Integer pageNum, Integer pageSize) {
        return userRepository.findAll().page(pageNum - 1, pageSize).stream()
            .map(UserVO::from)
            .toList();
    }

    @Transactional
    public void update(Long id, UpdateUserDTO dto) {
        User user = userRepository.findById(id);
        if (user == null) {
            throw new NotFoundException("用户不存在: " + id);
        }
        user.username = dto.getUsername();
        user.email = dto.getEmail();
        user.updatedAt = LocalDateTime.now();
        userRepository.persist(user);
    }

    @Transactional
    public void delete(Long id) {
        userRepository.deleteById(id);
    }
}
```

### 3.3 Panache Entity（领域实体）

```java
// Active Record 模式
@Entity
@Table(name = "users")
public class User extends PanacheEntity {

    @Column(nullable = false, length = 50)
    public String username;

    @Column(nullable = false, unique = true, length = 100)
    public String email;

    @Column(name = "created_at", nullable = false)
    public LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    public LocalDateTime updatedAt;

    public static User findByEmail(String email) {
        return find("email", email).firstResult();
    }

    public static PanacheQuery<User> findRecent(LocalDateTime since) {
        return find("createdAt >= ?1 ORDER BY createdAt DESC", since);
    }
}
```

或 Repository 模式：

```java
@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    public Long id;

    @Column(nullable = false, length = 50)
    public String username;

    @Column(nullable = false, unique = true, length = 100)
    public String email;

    @Column(name = "created_at", nullable = false)
    public LocalDateTime createdAt;
}

@ApplicationScoped
public class UserRepository implements PanacheRepository<User> {

    public User findByEmail(String email) {
        return find("email", email).firstResult();
    }

    public List<User> findRecent(LocalDateTime since) {
        return find("createdAt >= ?1", since).list();
    }
}
```

### 3.4 DTO / VO

```java
public class CreateUserDTO {

    @NotBlank(message = "用户名不能为空")
    @Size(min = 2, max = 50, message = "用户名长度为 2-50 个字符")
    public String username;

    @NotBlank(message = "邮箱不能为空")
    @Email(message = "邮箱格式不正确")
    public String email;

    public CreateUserDTO() {}

    public CreateUserDTO(String username, String email) {
        this.username = username;
        this.email = email;
    }
}

public class UserVO {

    public Long id;
    public String username;
    public String email;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    public LocalDateTime createdAt;

    public static UserVO from(User user) {
        UserVO vo = new UserVO();
        vo.id = user.id;
        vo.username = user.username;
        vo.email = user.email;
        vo.createdAt = user.createdAt;
        return vo;
    }
}
```

**注意**：Quarkus RESTEasy Reactive 默认支持 public 字段序列化（无需 Getter/Setter），但推荐使用 Getter/Setter 以保持一致性。

---

## 4. REST 客户端（MicroProfile REST Client）

```java
@Path("/api/v1/orders")
@RegisterRestClient(configKey = "order-service")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public interface OrderClient {

    @GET
    @Path("/user/{userId}")
    List<OrderVO> listByUserId(@PathParam("userId") Long userId);

    @POST
    Response create(@Valid CreateOrderDTO dto);
}
```

配置：

```properties
# application.properties
order-service/mp-rest/url=http://order-service:8080
order-service/mp-rest/connectTimeout=3000
order-service/mp-rest/readTimeout=10000
```

**规范**：
- **禁止**使用 `RestTemplate` / `WebClient`
- `@RegisterRestClient` 接口 MUST 放在 `infrastructure/client/` 包下

---

## 5. 响应式编程（Mutiny）

```java
// 同步
@GET
@Path("/{id}")
public Response findById(@PathParam("id") Long id) { ... }

// 响应式（Uni — 单值）
@GET
@Path("/{id}")
public Uni<Response> findById(@PathParam("id") Long id) {
    return userRepository.findById(id)
        .onItem().ifNotNull().transform(user -> Response.ok(UserVO.from(user)).build())
        .onItem().ifNull().continueWith(() -> Response.status(404).build());
}

// 响应式流（Multi — 多值）
@GET
public Multi<UserVO> list() {
    return userRepository.streamAll()
        .map(UserVO::from);
}
```

**规范**：
- Uni 链中**禁止**调用 `.await().indefinitely()`（在 HTTP 线程中）
- 数据库响应式操作使用 `quarkus-hibernate-reactive-panache`

---

## 6. 异常处理

### 6.1 JAX-RS ExceptionMapper

```java
@Provider
public class NotFoundExceptionMapper implements ExceptionMapper<NotFoundException> {

    @Override
    public Response toResponse(NotFoundException exception) {
        return Response.status(Response.Status.NOT_FOUND)
            .entity(new ErrorResponse(404, exception.getMessage()))
            .build();
    }
}

@Provider
public class ValidationExceptionMapper implements ExceptionMapper<ConstraintViolationException> {

    @Override
    public Response toResponse(ConstraintViolationException exception) {
        String message = exception.getConstraintViolations().stream()
            .map(v -> v.getPropertyPath() + ": " + v.getMessage())
            .collect(Collectors.joining("; "));
        return Response.status(Response.Status.BAD_REQUEST)
            .entity(new ErrorResponse(400, message))
            .build();
    }
}

@Provider
public class GenericExceptionMapper implements ExceptionMapper<Exception> {

    private static final Logger log = LoggerFactory.getLogger(GenericExceptionMapper.class);

    @Override
    public Response toResponse(Exception exception) {
        log.error("未处理异常", exception);
        return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
            .entity(new ErrorResponse(500, "服务器内部错误"))
            .build();
    }
}
```

---

## 7. 配置管理

### 7.1 application.properties

```properties
quarkus.application.name=user-service
quarkus.http.port=8080

# 数据源
quarkus.datasource.db-kind=postgresql
quarkus.datasource.jdbc.url=jdbc:postgresql://localhost:5432/user_db
quarkus.datasource.username=${DB_USERNAME:postgres}
quarkus.datasource.password=${DB_PASSWORD:postgres}

# Hibernate
quarkus.hibernate-orm.database.generation=validate
quarkus.hibernate-orm.log.sql=false
```

### 7.2 @ConfigProperty

```java
@ApplicationScoped
public class JwtService {
    @ConfigProperty(name = "jwt.secret")
    String secret;

    @ConfigProperty(name = "jwt.expiration", defaultValue = "3600")
    long expiration;
}
```

### 7.3 @ConfigMapping（批量配置）

```java
@ConfigMapping(prefix = "app.mail")
public interface MailConfig {
    String host();
    int port();
    String username();
    String password();
}
```

---

## 8. 日志规范

```java
import org.jboss.logging.Logger;

@ApplicationScoped
public class UserApplicationService {
    private static final Logger log = Logger.getLogger(UserApplicationService.class);

    public UserVO createUser(CreateUserDTO dto) {
        log.infof("创建用户: %s", dto.email);
        // ...
    }
}
```

**规范**：
- Quarkus 默认使用 JBoss Logging，也可使用 SLF4J
- **禁止**使用 `System.out.println` / `System.err.println`
- 异常日志 MUST 包含完整堆栈

---

## 9. 安全检查清单

- [ ] 所有 Resource MUST 有 `@Authenticated` 或 `@RolesAllowed` 注解
- [ ] JWT Token 校验使用 `quarkus-smallrye-jwt`
- [ ] 敏感配置 MUST 使用环境变量
- [ ] 生产环境 MUST 关闭 Swagger UI
- [ ] 输入校验 MUST 使用 `jakarta.validation` 注解
- [ ] CORS 配置 MUST 限制允许的域名

---

## 10. Commit 前检查清单

- [ ] 所有导入使用 `jakarta.*` 命名空间
- [ ] REST 端点使用 JAX-RS 注解
- [ ] CDI 注入使用 `@Inject` + `@ApplicationScoped`
- [ ] ORM 使用 Panache
- [ ] REST 客户端使用 `@RegisterRestClient`
- [ ] 测试类使用 `@QuarkusTest`
- [ ] 配置使用 `@ConfigProperty` / `@ConfigMapping`
- [ ] 无 Spring 框架依赖
- [ ] 无 `System.out.println`
