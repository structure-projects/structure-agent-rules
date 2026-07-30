# Micronaut 架构与设计规范

> Micronaut 4.x 项目架构设计指导，基于 DDD 四层分层架构。

---

## 1. DDD 四层架构

```
┌─────────────────────────────────────────┐
│                  api                     │  HTTP 接入层
│  Controller + DTO/VO                    │  @Controller
├─────────────────────────────────────────┤
│              application                 │  应用服务层
│  ApplicationService（事务边界）          │  @Singleton + @Transactional
├─────────────────────────────────────────┤
│                domain                    │  领域层
│  Entity + ValueObject + Repository接口   │  纯 POJO
│  DomainService（领域逻辑）               │
├─────────────────────────────────────────┤
│           infrastructure                 │  基础设施层
│  Repository 实现（JPA/JDBC）             │  @Singleton
│  HTTP Client（@Client）                  │
│  MQ / Cache / 外部集成                   │
└─────────────────────────────────────────┘
```

### 各层职责

| 层 | 职责 | 注解 | 禁止 |
|---|---|---|---|
| **api** | HTTP 协议转换、参数校验 | `@Controller` | 业务逻辑 |
| **application** | 编排领域服务、事务边界 | `@Singleton` + `@Transactional` | HTTP 相关代码 |
| **domain** | 核心业务逻辑、领域规则 | 纯 POJO | 框架依赖 |
| **infrastructure** | 技术实现、外部集成 | `@Singleton` | 业务逻辑 |

---

## 2. 模块化设计

### 2.1 单模块（中小型项目）

```
src/main/java/com/example/
├── Application.java
├── api/
├── domain/
├── application/
└── infrastructure/
```

### 2.2 多模块（大型项目）

```
order-module/
├── order-api/              # Controller + DTO
│   └── build.gradle.kts
├── order-domain/           # Entity + Repository 接口
│   └── build.gradle.kts
├── order-application/      # ApplicationService
│   └── build.gradle.kts
└── order-infrastructure/   # Repository 实现 + Client
    └── build.gradle.kts
```

每个模块 `build.gradle.kts`：

```kotlin
// order-api/build.gradle.kts
dependencies {
    implementation(project(":order-application"))
    implementation("io.micronaut:micronaut-http-server-netty")
}
```

---

## 3. 核心架构决策

### 3.1 依赖注入策略

**原则**：全部使用构造器注入（Micronaut AOT 强制要求）

```java
// ✅ 正确：构造器注入
@Singleton
public class OrderApplicationService {
    private final OrderRepository orderRepository;
    private final UserClient userClient;
    private final EventPublisher eventPublisher;

    public OrderApplicationService(OrderRepository orderRepository,
                                     UserClient userClient,
                                     EventPublisher eventPublisher) {
        this.orderRepository = orderRepository;
        this.userClient = userClient;
        this.eventPublisher = eventPublisher;
    }
}
```

**禁止**：
- `@Inject` 字段注入
- `@jakarta.inject.Inject` 方法注入
- Lombok `@RequiredArgsConstructor`（AOT 兼容性不确定）

### 3.2 数据访问策略

**JPA 方式（推荐）**：

```java
@JpaRepository
public interface OrderRepository extends CrudRepository<Order, Long> {
    List<Order> findByUserId(Long userId);

    @Query("FROM Order o WHERE o.status = :status ORDER BY o.createdAt DESC")
    Page<Order> findByStatus(@Parameter("status") OrderStatus status, Pageable pageable);
}
```

**JDBC 方式（编译时生成 SQL）**：

```java
@JdbcRepository
public interface OrderRepository extends CrudRepository<Order, Long> {
    @Query("SELECT * FROM orders WHERE user_id = :userId")
    List<Order> findByUserId(Long userId);
}
```

**选择建议**：
- 复杂对象关系 → JPA（Hibernate）
- 简单 CRUD + 高性能 → JDBC（编译时 SQL 生成）
- 响应式 → R2DBC

### 3.3 事件驱动

```java
// 领域事件
public class OrderCreatedEvent extends ApplicationEvent {
    private final Order order;

    public OrderCreatedEvent(Order order) {
        super(order);
        this.order = order;
    }

    public Order getOrder() { return order; }
}

// 发布事件
@Singleton
public class OrderApplicationService {
    private final ApplicationEventPublisher eventPublisher;

    public OrderApplicationService(ApplicationEventPublisher eventPublisher) {
        this.eventPublisher = eventPublisher;
    }

    @Transactional
    public OrderVO createOrder(CreateOrderDTO dto) {
        Order order = Order.create(dto);
        orderRepository.save(order);
        eventPublisher.publishEvent(new OrderCreatedEvent(order));
        return OrderVO.from(order);
    }
}

// 监听事件
@Singleton
public class OrderEventListener {

    @EventListener
    @Async  // 异步处理
    public void onOrderCreated(OrderCreatedEvent event) {
        // 发送通知、更新统计等
    }
}
```

### 3.4 服务间通信

```java
// infrastructure/client/UserClient.java
@Client(id = "user-service")
public interface UserClient {

    @Get("/api/v1/users/{id}")
    UserVO findById(Long id);

    @Get("/api/v1/users/batch{?ids}")
    List<UserVO> findByIds(@QueryValue List<Long> ids);
}
```

**超时与重试配置**：

```yaml
micronaut:
  http:
    services:
      user-service:
        urls:
          - http://user-service:8080
        read-timeout: 10s
        connect-timeout: 3s
        retry:
          attempts: 3
          delay: 500ms
```

### 3.5 Filter 链（安全、日志、追踪）

```java
@Filter("/api/**")
public class AuthFilter extends OncePerRequestHttpServerFilter {

    private final JwtValidator jwtValidator;

    public AuthFilter(JwtValidator jwtValidator) {
        this.jwtValidator = jwtValidator;
    }

    @Override
    protected void doFilterOnce(HttpRequest<?> request, ServerFilterChain chain) {
        String token = request.getHeaders().get(HttpHeaders.AUTHORIZATION);
        if (token == null || !token.startsWith("Bearer ")) {
            throw new AuthenticationException("缺少 Token");
        }
        Authentication authentication = jwtValidator.validate(token.substring(7));
        ServerRequestContext.currentRequest()
            .ifPresent(req -> req.setAttribute("auth", authentication));
        chain.proceed();
    }
}
```

---

## 4. 设计检查清单

### 架构层面

- [ ] 是否采用 DDD 四层分层？
- [ ] 各层职责是否清晰（api 无业务逻辑、domain 无框架依赖）？
- [ ] 模块划分是否合理（避免循环依赖）？

### 技术层面

- [ ] 所有 Bean 是否使用构造器注入？
- [ ] 数据访问是否使用 Micronaut Data？
- [ ] 服务间调用是否使用 `@Client`？
- [ ] 事务边界是否在 Application 层？
- [ ] 事件发布是否使用 `ApplicationEventPublisher`？
- [ ] 安全校验是否在 Filter 层完成？

### 性能层面

- [ ] 是否有不必要的 `.block()` 调用？
- [ ] 数据库查询是否有 N+1 问题？
- [ ] HTTP 客户端是否配置了超时和重试？
- [ ] 是否启用了编译时 AOT 优化？

---

## 5. 常见架构反模式

| 反模式 | 问题 | 正确做法 |
|---|---|---|
| Controller 中写业务逻辑 | 破坏分层 | 移到 ApplicationService |
| Entity 中包含 Jackson 注解 | 领域层污染 | 使用 VO 隔离 |
| 跨模块循环依赖 | 编译/部署困难 | 抽取公共接口到 domain |
| `@Inject` 字段注入 | AOT 不兼容 | 构造器注入 |
| 同步阻塞响应式链 | 性能退化 | 全链路响应式 |
| 直接在 Entity 上用 `@Introspected` | 不必要 | 仅 DTO/VO 需要 |
