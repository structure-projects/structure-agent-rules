# Quarkus 架构设计规范

## DDD 分层

```
src/main/java/com/example/
├── api/                 # JAX-RS Resource + DTO
├── domain/              # Entity + Repository 接口 + Domain Service
├── application/         # Application Service (事务编排)
└── infrastructure/      # Repository 实现 + REST Client + Mapper
```

## 模块拆分

大型项目推荐 Maven 多模块：

```xml
<modules>
    <module>my-service-api</module>
    <module>my-service-domain</module>
    <module>my-service-application</module>
    <module>my-service-infrastructure</module>
    <module>my-service-boot</module>
</modules>
```

## 层级约束

| 层 | 依赖 | 职责 |
|---|---|---|
| api | domain, application | HTTP Request/Response 处理 |
| domain | 无 | Entity + Repository 接口 |
| application | domain | 事务编排，业务用例 |
| infrastructure | domain | Repository 实现，外部系统集成 |

- API 层不直接依赖 Infrastructure 层
- Domain 层不依赖任何框架
- Repository 接口定义在 Domain，实现在 Infrastructure
- Application Service 负责 `@Transactional` 边界

## DTO 与 Entity 分离

```java
// Entity — domain layer
@Entity
public class User extends PanacheEntity {
    public String name;
    public String email;
    @CreationTimestamp
    public LocalDateTime createdAt;
}

// DTO — api layer
public record UserResponse(Long id, String name, String email) {}

// Mapper — infrastructure layer
@Mapper(componentModel = "cdi")
public interface UserMapper {
    UserResponse toResponse(User user);
}
```

## 技术选型

| 场景 | 推荐 |
|---|---|
| 同步 ORM | Hibernate + Panache |
| 响应式 ORM | Panache Reactive |
| 消息队列 | SmallRye Reactive Messaging |
| 认证鉴权 | quarkus-oidc / quarkus-smallrye-jwt |
| 配置管理 | SmallRye Config (`@ConfigMapping`) |
| 健康检查 | SmallRye Health (`@Readiness`, `@Liveness`) |
| 指标监控 | Micrometer + Prometheus |
| 分布式追踪 | OpenTelemetry |
| API 文档 | SmallRye OpenAPI + Swagger UI |

## 事务管理

```java
@ApplicationScoped
public class OrderService {
    @Transactional  // 方法级别事务
    public Order createOrder(CreateOrderRequest request) {
        // 多个 Repository 操作在同一事务中
        Order order = orderMapper.toEntity(request);
        orderRepository.persist(order);
        inventoryService.deduct(request.items());
        return order;
    }
}
```
