# Micronaut 核心组件用法

> Micronaut 4.x 框架核心组件使用指南与最佳实践。

---

## 1. Bean 管理

### 1.1 Bean Scope

| Scope | 注解 | 说明 |
|---|---|---|
| Singleton | `@Singleton` | 单例（默认推荐） |
| Prototype | `@Prototype` | 每次注入创建新实例 |
| Request | `@RequestScope` | 每个 HTTP 请求一个实例 |
| Refreshable | `@Refreshable` | 配置刷新时重新创建 |

```java
@Singleton  // 默认单例
public class UserService { ... }

@Prototype  // 每次注入创建新实例
public class OrderProcessor { ... }

@RequestScope  // 每个请求一个实例
public class RequestContext { ... }

@Refreshable  // 配置刷新时重建
@ConfigurationProperties("app.config")
public class AppConfig { ... }
```

### 1.2 条件 Bean

```java
@Singleton
@Requires(property = "app.feature.x.enabled", value = "true")
public class FeatureXService { ... }

@Singleton
@Requires(beans = DataSource.class)
public class DatabaseHealthCheck { ... }

@Singleton
@Requires(env = {"dev", "staging"})
public class DebugController { ... }
```

### 1.3 Bean 替换

```java
@Singleton
@Replaces(UserRepository.class)
public class CachedUserRepository implements UserRepository { ... }
```

---

## 2. Controller

### 2.1 路由映射

```java
@Controller("/api/v1/users")
public class UserController {

    // GET /api/v1/users/{id}
    @Get("/{id}")
    public HttpResponse<UserVO> findById(@PathVariable Long id) { ... }

    // POST /api/v1/users
    @Post
    public HttpResponse<UserVO> create(@Body @Valid CreateUserDTO dto) { ... }

    // PUT /api/v1/users/{id}
    @Put("/{id}")
    public HttpResponse<Void> update(@PathVariable Long id, @Body @Valid UpdateUserDTO dto) { ... }

    // DELETE /api/v1/users/{id}
    @Delete("/{id}")
    public HttpResponse<Void> delete(@PathVariable Long id) { ... }

    // GET /api/v1/users/page?pageNum=1&pageSize=20
    @Get("/page{?pageNum,pageSize}")
    public HttpResponse<Page<UserVO>> page(
            @QueryValue(defaultValue = "1") Integer pageNum,
            @QueryValue(defaultValue = "20") Integer pageSize) { ... }
}
```

### 2.2 请求绑定

| 注解 | 绑定来源 | 示例 |
|---|---|---|
| `@Body` | 请求体 | `@Body CreateUserDTO dto` |
| `@PathVariable` | 路径变量 | `@PathVariable Long id` |
| `@QueryValue` | 查询参数 | `@QueryValue String keyword` |
| `@Header` | 请求头 | `@Header("X-Request-Id") String requestId` |
| `@CookieValue` | Cookie | `@CookieValue("session") String session` |

### 2.3 响应类型

```java
// 标准响应
HttpResponse.ok(body)           // 200
HttpResponse.created(body)      // 201
HttpResponse.noContent()        // 204
HttpResponse.badRequest()       // 400
HttpResponse.notFound()         // 404
HttpResponse.serverError()      // 500

// 响应式
Mono<HttpResponse<UserVO>>     // Project Reactor
Single<HttpResponse<UserVO>>   // RxJava 3
```

### 2.4 内容协商

```java
@Controller("/api/v1/users")
public class UserController {

    @Get("/{id}")
    @Produces(MediaType.APPLICATION_JSON)
    public HttpResponse<UserVO> findById(@PathVariable Long id) { ... }

    @Get("/export")
    @Produces(MediaType.APPLICATION_OCTET_STREAM)
    public HttpResponse<byte[]> export() { ... }
}
```

---

## 3. Micronaut Data（ORM）

### 3.1 JPA Repository

```java
@JpaRepository
public interface UserRepository extends CrudRepository<User, Long> {

    Optional<User> findByEmail(String email);

    List<User> findByUsernameLike(String keyword);

    @Query("FROM User u WHERE u.createdAt >= :since ORDER BY u.createdAt DESC")
    Page<User> findRecent(@Parameter("since") LocalDateTime since, Pageable pageable);

    long countByCreatedAtBetween(LocalDateTime start, LocalDateTime end);

    boolean existsByEmail(String email);

    @Transactional
    @Modifying
    @Query("UPDATE User u SET u.status = :status WHERE u.id IN (:ids)")
    int updateStatusBatch(@Parameter("ids") List<Long> ids, @Parameter("status") String status);
}
```

### 3.2 JDBC Repository

```java
@JdbcRepository
public interface UserRepository extends CrudRepository<User, Long> {

    @Query("SELECT * FROM users WHERE email = :email")
    Optional<User> findByEmail(String email);

    @Query("SELECT COUNT(*) FROM users WHERE created_at >= :since")
    long countRecent(@Parameter("since") LocalDateTime since);
}
```

### 3.3 分页

```java
// Controller
@Get("/page{?pageNum,pageSize}")
public HttpResponse<Page<UserVO>> page(
        @QueryValue(defaultValue = "1") Integer pageNum,
        @QueryValue(defaultValue = "20") Integer pageSize) {
    Pageable pageable = Pageable.from(pageNum - 1, pageSize);
    return HttpResponse.ok(userRepository.findAll(pageable).map(UserVO::from));
}
```

---

## 4. HTTP 客户端（声明式 @Client）

### 4.1 基本用法

```java
@Client(id = "order-service")
public interface OrderClient {

    @Get("/api/v1/orders/{id}")
    OrderVO findById(Long id);

    @Post("/api/v1/orders")
    HttpResponse<OrderVO> create(@Body CreateOrderDTO dto);

    @Get("/api/v1/orders/user/{userId}")
    List<OrderVO> listByUserId(Long userId);
}
```

### 4.2 请求头与认证

```java
@Client(id = "payment-service")
@Header(name = "Authorization", value = "Bearer ${payment.service.token}")
public interface PaymentClient {

    @Post("/api/v1/payments")
    @Header(name = "Idempotency-Key", value = "${payment.idempotency.key}")
    PaymentVO create(@Body CreatePaymentDTO dto);
}
```

### 4.3 错误处理

```java
@Client(id = "inventory-service")
public interface InventoryClient {

    @Get("/api/v1/inventory/{productId}")
    @Retryable(attempts = "3", delay = "500ms")
    InventoryVO check(@PathVariable Long productId);

    @Post("/api/v1/inventory/deduct")
    @Retryable(attempts = "2", delay = "1s",
        includes = {RetryableException.class})
    void deduct(@Body DeductInventoryDTO dto);
}
```

### 4.4 响应式客户端

```java
@Client(id = "user-service")
public interface ReactiveUserClient {

    @Get("/api/v1/users/{id}")
    Mono<UserVO> findById(Long id);

    @Get("/api/v1/users")
    Flux<UserVO> list();
}
```

---

## 5. 安全

### 5.1 JWT 认证

```yaml
micronaut:
  security:
    authentication: bearer
    token:
      jwt:
        signatures:
          secret:
            generator:
              secret: ${JWT_SECRET}
```

### 5.2 权限注解

```java
@Controller("/api/v1/admin")
@Secured("ROLE_ADMIN")
public class AdminController { ... }

@Controller("/api/v1/users")
@Secured(SecurityRule.IS_AUTHENTICATED)
public class UserController {

    @Get("/me")
    public HttpResponse<UserVO> currentUser(@Nullable Authentication authentication) {
        String username = authentication.getName();
        return HttpResponse.ok(userService.findByUsername(username));
    }

    @Get("/admin/list")
    @Secured("ROLE_ADMIN")
    public HttpResponse<List<UserVO>> listAll() { ... }
}
```

### 5.3 自定义安全规则

```java
@Singleton
public class CustomSecurityRule implements SecurityRule {

    @Override
    public SecurityRuleResult check(HttpRequest<?> request, RouteMatch<?> routeMatch,
                                      Map<String, Object> claims) {
        // 自定义安全逻辑
        if (request.getPath().startsWith("/public")) {
            return SecurityRuleResult.ALLOWED;
        }
        return SecurityRuleResult.UNKNOWN;
    }
}
```

---

## 6. 事件系统

```java
// 发布事件
@Singleton
public class OrderService {
    private final ApplicationEventPublisher eventPublisher;

    public OrderService(ApplicationEventPublisher eventPublisher) {
        this.eventPublisher = eventPublisher;
    }

    @Transactional
    public void createOrder(CreateOrderDTO dto) {
        Order order = save(dto);
        eventPublisher.publishEvent(new OrderCreatedEvent(order));
    }
}

// 同步监听
@Singleton
public class InventoryListener {
    @EventListener
    public void onOrderCreated(OrderCreatedEvent event) {
        inventoryService.reserve(event.getOrder());
    }
}

// 异步监听
@Singleton
public class NotificationListener {
    @EventListener
    @Async
    public void onOrderCreated(OrderCreatedEvent event) {
        notificationService.sendOrderConfirmation(event.getOrder());
    }
}
```

---

## 7. Filter

### 7.1 HTTP Filter

```java
@Filter("/api/**")
public class RequestLoggingFilter extends OncePerRequestHttpServerFilter {

    private static final Logger log = LoggerFactory.getLogger(RequestLoggingFilter.class);

    @Override
    protected void doFilterOnce(HttpRequest<?> request, ServerFilterChain chain) {
        long start = System.currentTimeMillis();
        chain.proceed();
        long duration = System.currentTimeMillis() - start;
        log.info("{} {} - {}ms", request.getMethod(), request.getPath(), duration);
    }
}
```

### 7.2 Filter 顺序

```java
@Filter(value = "/api/**", priority = FilterPriority.HIGH)
public class AuthFilter extends OncePerRequestHttpServerFilter { ... }

@Filter(value = "/api/**", priority = FilterPriority.LOW)
public class LoggingFilter extends OncePerRequestHttpServerFilter { ... }
```

---

## 8. 配置管理

### 8.1 @ConfigurationProperties

```java
@ConfigurationProperties("app.mail")
public class MailProperties {
    private String host = "localhost";
    private int port = 25;
    private String username;
    private String password;

    // getters / setters
}
```

```yaml
app:
  mail:
    host: smtp.example.com
    port: 587
    username: ${MAIL_USERNAME}
    password: ${MAIL_PASSWORD}
```

### 8.2 @Property

```java
@Singleton
public class SmsService {
    private final String apiKey;

    public SmsService(@Property(name = "sms.api-key") String apiKey) {
        this.apiKey = apiKey;
    }
}
```

### 8.3 环境配置

```yaml
# application.yml（公共配置）
micronaut:
  application:
    name: user-service

# application-dev.yml（开发环境）
datasources:
  default:
    url: jdbc:postgresql://localhost:5432/dev_db

# application-prod.yml（生产环境）
datasources:
  default:
    url: jdbc:postgresql://prod-db:5432/user_db
```

---

## 9. 服务发现

```yaml
micronaut:
  discovery:
    client:
      consul:
        default:
          registration:
            enabled: true
            health-check: true
```

---

## 10. 定时任务

```java
@Singleton
public class ScheduledTasks {

    @Scheduled(fixedDelay = "30m")
    public void cleanExpiredSessions() {
        // 每 30 分钟执行
    }

    @Scheduled(cron = "0 0 2 * * ?")
    public void dailyReport() {
        // 每天凌晨 2 点执行
    }
}
```
