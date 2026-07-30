# Quarkus 核心组件用法

> Quarkus 3.x 框架核心组件使用指南与最佳实践。

---

## 1. CDI Bean 管理

### 1.1 Bean Scope

| Scope | 注解 | 说明 |
|---|---|---|
| Application | `@ApplicationScoped` | 应用生命周期单例（默认推荐） |
| Request | `@RequestScoped` | 每个 HTTP 请求一个实例 |
| Session | `@SessionScoped` | 每个 HTTP Session 一个实例 |
| Dependent | `@Dependent` | 伪 Scope，随注入者生命周期 |
| Singleton | `@Singleton` | 伪 Scope（非真正的单例） |

```java
@ApplicationScoped  // 应用范围（推荐）
public class UserService { ... }

@RequestScoped  // 每个请求一个实例
public class RequestContext { ... }
```

### 1.2 Bean 生产者

```java
@ApplicationScoped
public class BeanProducers {

    @Produces
    @ApplicationScoped
    public ObjectMapper objectMapper() {
        return new ObjectMapper()
            .registerModule(new JavaTimeModule());
    }
}
```

### 1.3 条件 Bean

```java
@ApplicationScoped
@IfBuildProperty(name = "app.feature.x.enabled", stringValue = "true")
public class FeatureXService { ... }
```

---

## 2. JAX-RS Resource（REST 端点）

### 2.1 路由映射

```java
@Path("/api/v1/users")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class UserResource {

    @GET
    @Path("/{id}")
    public Response findById(@PathParam("id") Long id) { ... }

    @POST
    public Response create(@Valid CreateUserDTO dto) { ... }

    @PUT
    @Path("/{id}")
    public Response update(@PathParam("id") Long id, @Valid UpdateUserDTO dto) { ... }

    @DELETE
    @Path("/{id}")
    public Response delete(@PathParam("id") Long id) { ... }
}
```

### 2.2 参数绑定

| 注解 | 绑定来源 | 示例 |
|---|---|---|
| `@PathParam` | 路径变量 | `@PathParam("id") Long id` |
| `@QueryParam` | 查询参数 | `@QueryParam("keyword") String keyword` |
| `@HeaderParam` | 请求头 | `@HeaderParam("X-Request-Id") String requestId` |
| `@CookieParam` | Cookie | `@CookieParam("session") String session` |
| `@FormParam` | 表单参数 | `@FormParam("username") String username` |
| `@DefaultValue` | 默认值 | `@DefaultValue("1") @QueryParam("page") int page` |

### 2.3 响应式端点

```java
@Path("/api/v1/users")
public class ReactiveUserResource {

    @GET
    @Path("/{id}")
    public Uni<Response> findById(@PathParam("id") Long id) {
        return userRepository.findById(id)
            .onItem().ifNotNull().transform(user -> Response.ok(UserVO.from(user)).build())
            .onItem().ifNull().continueWith(() -> Response.status(404).build());
    }

    @GET
    public Multi<UserVO> list() {
        return userRepository.streamAll().map(UserVO::from);
    }
}
```

---

## 3. Panache（ORM）

### 3.1 Active Record 模式

```java
@Entity
public class User extends PanacheEntity {

    @Column(nullable = false, length = 50)
    public String username;

    @Column(nullable = false, unique = true, length = 100)
    public String email;

    public static User findByEmail(String email) {
        return find("email", email).firstResult();
    }

    public static List<User> findRecent(LocalDateTime since) {
        return find("createdAt >= ?1 ORDER BY createdAt DESC", since).list();
    }

    public static long deleteInactive(LocalDateTime before) {
        return delete("lastLoginAt < ?1", before);
    }
}
```

使用：

```java
// 直接通过 Entity 操作
User user = User.findById(1L);
List<User> users = User.list("email", email);
User.deleteById(1L);
```

### 3.2 Repository 模式

```java
@ApplicationScoped
public class UserRepository implements PanacheRepository<User> {

    public User findByEmail(String email) {
        return find("email", email).firstResult();
    }

    public List<User> findRecent(LocalDateTime since) {
        return find("createdAt >= ?1", since).list();
    }

    public PanacheQuery<User> findByStatus(Status status, Sort sort) {
        return find("status", status, sort);
    }
}
```

### 3.3 分页

```java
@GET
@Path("/page")
public Response page(
        @QueryParam("pageNum") @DefaultValue("1") int pageNum,
        @QueryParam("pageSize") @DefaultValue("20") int pageSize) {
    PanacheQuery<User> query = User.findAll();
    List<User> users = query.page(pageNum - 1, pageSize).list();
    long total = query.count();
    return Response.ok(new PageResult<>(users.map(UserVO::from), total, pageNum, pageSize)).build();
}
```

### 3.4 HQL 查询

```java
List<User> users = User.find(
    "FROM User u WHERE u.createdAt >= :since ORDER BY u.createdAt DESC",
    Parameters.with("since", since)
).list();
```

---

## 4. REST Client（服务间调用）

### 4.1 基本用法

```java
@Path("/api/v1/orders")
@RegisterRestClient(configKey = "order-service")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public interface OrderClient {

    @GET
    @Path("/{id}")
    OrderVO findById(@PathParam("id") Long id);

    @GET
    @Path("/user/{userId}")
    List<OrderVO> listByUserId(@PathParam("userId") Long userId);

    @POST
    Response create(OrderDTO dto);
}
```

### 4.2 请求头与认证

```java
@RegisterRestClient(configKey = "payment-service")
public interface PaymentClient {

    @POST
    @Path("/api/v1/payments")
    @ClientHeaderParam(name = "Authorization", value = "Bearer ${payment.service.token}")
    PaymentVO create(@HeaderParam("Idempotency-Key") String idempotencyKey, PaymentDTO dto);
}
```

### 4.3 响应式客户端

```java
@RegisterRestClient(configKey = "user-service")
public interface ReactiveUserClient {

    @GET
    @Path("/{id}")
    Uni<UserVO> findById(@PathParam("id") Long id);
}
```

### 4.4 配置

```properties
order-service/mp-rest/url=http://order-service:8080
order-service/mp-rest/connectTimeout=3000
order-service/mp-rest/readTimeout=10000
```

---

## 5. 安全

### 5.1 JWT 认证

```properties
quarkus.smallrye-jwt.enabled=true
mp.jwt.verify.publickey.location=META-INF/resources/publicKey.pem
mp.jwt.verify.issuer=https://auth.example.com
```

### 5.2 权限注解

```java
@Path("/api/v1/admin")
@RolesAllowed("ADMIN")
public class AdminResource { ... }

@Path("/api/v1/users")
@Authenticated
public class UserResource {

    @GET
    @Path("/me")
    public Response currentUser(@Context SecurityContext ctx) {
        String username = ctx.getUserPrincipal().getName();
        return Response.ok(userService.findByUsername(username)).build();
    }
}
```

---

## 6. 响应式消息（Kafka）

```properties
mp.messaging.outgoing.orders-out.connector=smallrye-kafka
mp.messaging.outgoing.orders-out.topic=orders
mp.messaging.outgoing.orders-out.value.serializer=io.quarkus.kafka.client.serialization.ObjectMapperSerializer

mp.messaging.incoming.orders-in.connector=smallrye-kafka
mp.messaging.incoming.orders-in.topic=orders
```

```java
@ApplicationScoped
public class OrderEventPublisher {
    @Inject
    @Channel("orders-out")
    Emitter<OrderEvent> emitter;

    public CompletionStage<Void> publish(OrderEvent event) {
        return emitter.send(event);
    }
}

@ApplicationScoped
public class OrderEventConsumer {
    @Incoming("orders-in")
    public CompletionStage<Void> consume(OrderEvent event) {
        // 处理逻辑
        return CompletableFuture.completedFuture(null);
    }
}
```

---

## 7. 可观测性

### 7.1 健康检查

```java
@Liveness
@ApplicationScoped
public class DatabaseHealthCheck implements HealthCheck {

    @Override
    public HealthCheckResponse call() {
        return HealthCheckResponse.up("database");
    }
}
```

访问：`/q/health`、`/q/health/live`、`/q/health/ready`

### 7.2 Metrics

```properties
quarkus.micrometer.export.prometheus.path=/metrics
```

```java
@GET
@Path("/{id}")
@Timed(name = "user.findById", description = "查询用户耗时")
@Counted(name = "user.findById.count", description = "查询用户次数")
public Response findById(@PathParam("id") Long id) { ... }
```

---

## 8. 配置管理

### 8.1 @ConfigProperty

```java
@ConfigProperty(name = "app.mail.host", defaultValue = "localhost")
String mailHost;

@ConfigProperty(name = "app.mail.port", defaultValue = "25")
int mailPort;
```

### 8.2 @ConfigMapping

```java
@ConfigMapping(prefix = "app.mail")
public interface MailConfig {
    String host();
    @WithDefault("25")
    int port();
    String username();
    String password();
}
```

---

## 9. 定时任务

```java
@ApplicationScoped
public class ScheduledTasks {

    @Scheduled(every = "30m")
    public void cleanExpiredSessions() { ... }

    @Scheduled(cron = "0 0 2 * * ?")
    public void dailyReport() { ... }
}
```

---

## 10. Dev 模式

```bash
# 启动 Dev 模式（热重载）
./mvnw quarkus:dev

# Dev UI
# http://localhost:8080/q/dev
# 可查看：配置、端点、健康检查、OpenAPI、测试结果
```
