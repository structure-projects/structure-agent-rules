# Spring Boot 架构规范

> 通用 Spring Boot 项目架构与设计约束。

---

## 1. 模块划分

### 1.1 多模块项目结构（推荐）

```
{project}/
├── {project}-api/          # 对外暴露的接口和 DTO
├── {project}-biz/          # 业务逻辑实现
├── {project}-core/         # 领域模型、仓储接口
├── {project}-infra/        # 基础设施（数据库、缓存、消息）
├── {project}-boot/         # 启动入口、全局配置
└── {project}-client/       # Feign 客户端（可选）
```

### 1.2 模块依赖方向（MUST）

```
boot → biz → core
  ↓      ↓      ↓
infra   api   (common)
```

- `boot` 依赖所有模块
- `biz` 依赖 `core` + `api` + `infra`
- `core` 不依赖任何业务模块（最内层）
- `api` 不依赖 `biz` / `infra`（纯接口定义）
- **禁止** 反向依赖：`core` → `biz`、`api` → `biz`

### 1.3 DDD 分层（可选，复杂业务推荐）

```
interfaces/    →  application/  →  domain/
                    ↓
                 infrastructure/
```

- `domain`：实体、值对象、领域服务、仓储接口（不依赖外部）
- `application`：应用服务，编排领域对象
- `infrastructure`：仓储实现、外部服务适配器
- `interfaces`：Controller、DTO、消息监听器

**关键约束**：
- `domain` MUST 不依赖任何框架（纯 POJO）
- `application`/`domain` 禁止直接注入 Mapper/PO
- 仓储接口定义在 `domain`，实现在 `infrastructure`

---

## 2. API 设计

### 2.1 RESTful 规范

- URL：小写、复数名词、短横线分隔（如 `/api/v1/user-orders`）
- HTTP 方法：GET（查询）、POST（创建）、PUT（全量更新）、PATCH（部分更新）、DELETE（删除）
- 状态码：200（成功）、201（创建成功）、204（删除成功）、400（参数错误）、401（未认证）、403（无权限）、404（不存在）、500（服务错误）

### 2.2 分页接口

统一分页参数和响应：

```java
// 请求
public class PageQuery {
    private Integer pageNum = 1;
    private Integer pageSize = 20;
}

// 响应
public class PageResult<T> {
    private Long total;
    private Integer pageNum;
    private Integer pageSize;
    private List<T> records;
}
```

### 2.3 CRUD 命名统一

- `create` — 创建
- `update` — 更新
- `delete` — 删除
- `findById` — 根据 ID 查询
- `page` / `list` — 分页查询 / 列表查询

### 2.4 API 版本管理

- URL 路径版本：`/api/v1/users`、`/api/v2/users`
- 或请求头版本：`Accept: application/vnd.company.v1+json`
- 项目启动时 SHOULD 明确版本策略

---

## 3. 微服务架构

### 3.1 服务注册与发现

- 推荐 Nacos / Consul / Eureka
- 所有服务实例 MUST 注册到注册中心
- 健康检查 MUST 配置（`/actuator/health`）

### 3.2 配置中心

- 推荐 Nacos Config / Spring Cloud Config
- 公共配置与私有配置分离
- 配置变更 SHOULD 支持热刷新（`@RefreshScope`）

### 3.3 服务调用

- MUST 使用 Feign（`@FeignClient`）
- 每个 `@FeignClient` MUST 声明 `fallback` 或 `fallbackFactory`
- 超时配置 MUST 合理设置（连接超时 + 读取超时）
- 建议配合 Sentinel 做熔断降级

### 3.4 网关

- 推荐 Spring Cloud Gateway
- 统一鉴权、限流、日志、跨域处理放在网关层
- 后端服务 MUST 不重复实现网关职责

### 3.5 消息队列

- 异步解耦场景使用 MQ（RocketMQ / Kafka / RabbitMQ）
- 消息 MUST 保证幂等性（消费端去重）
- 关键消息 SHOULD 有重试和死信队列

---

## 4. 数据库设计

### 4.1 表设计

- 表名：小写 + 下划线，复数形式（如 `user_orders`）
- 主键：推荐自增 ID 或雪花 ID（`BIGINT`）
- 必备字段：`id`、`create_time`、`update_time`、`is_deleted`（逻辑删除）
- 索引：高频查询字段建索引，避免过多索引影响写入

### 4.2 读写分离

- 读写分离方案：ShardingSphere-JDBC / 动态数据源
- 读操作 SHOULD 走从库
- 写后立即读 MUST 走主库（避免主从延迟）

### 4.3 分库分表

- 数据量预估：单表 > 500 万行时考虑分表
- 分片键选择：均匀分布、查询高频字段
- 推荐 ShardingSphere-JDBC

---

## 5. 缓存设计

### 5.1 缓存策略

- 本地缓存：Caffeine（高性能、短生命周期）
- 分布式缓存：Redis
- 缓存模式：Cache-Aside（先查缓存，未命中查 DB 并回写）

### 5.2 缓存规范

- Key 命名：`{服务}:{业务}:{标识}`（如 `user:info:123`）
- 过期时间 MUST 设置，禁止永久缓存
- 批量操作 SHOULD 使用 Pipeline
- 注意缓存穿透（布隆过滤器）、缓存击穿（互斥锁）、缓存雪崩（过期时间加随机值）

---

## 6. 安全架构

### 6.1 认证与授权

- 认证：JWT / OAuth2 / Session
- 授权：RBAC（角色-权限）或 ABAC（属性-权限）
- API 鉴权：`@PreAuthorize` 或自定义注解

### 6.2 数据权限

- 行级数据权限：拦截 SQL 或 MyBatis 拦截器注入租户/部门条件
- 接口级权限：注解 + AOP

### 6.3 多租户

- 方案：独立数据库 / 共享数据库独立 Schema / 共享表加租户字段
- 租户标识从 Token 上下文获取，**禁止**从请求参数读取
- ORM 层通过拦截器自动注入租户条件

---

## 7. 可观测性

### 7.1 指标

- Spring Boot Actuator + Micrometer
- 暴露：`/actuator/health`、`/actuator/metrics`、`/actuator/prometheus`

### 7.2 链路追踪

- 推荐 SkyWalking / Zipkin / Jaeger
- 日志 MUST 包含 TraceId
- 跨服务调用 MUST 传递 TraceId

### 7.3 日志收集

- ELK（Elasticsearch + Logstash + Kibana）或 Loki + Grafana
- 日志格式统一为 JSON（方便检索）
- 生产环境 MUST 将日志输出到文件而非控制台

---

## 8. 部署架构

### 8.1 容器化

- MUST 提供 Dockerfile
- 使用多阶段构建减小镜像体积
- JVM 参数 MUST 配置（`-Xms`、`-Xmx`、GC 策略）

### 8.2 容器编排

- Kubernetes：Deployment + Service + ConfigMap + Secret
- 健康检查 MUST 配置 Liveness Probe 和 Readiness Probe
- 资源限制 MUST 配置 `requests` 和 `limits`

---

## 9. 技术选型参考

| 类别 | 推荐方案 | 备选 |
|---|---|---|
| 框架 | Spring Boot 3.x | - |
| JDK | 17+ | 21 |
| 构建 | Maven | Gradle |
| ORM | MyBatis-Plus | Spring Data JPA |
| 数据库 | MySQL 8.0+ | PostgreSQL |
| 缓存 | Redis + Caffeine | - |
| 消息队列 | RocketMQ | Kafka / RabbitMQ |
| 注册中心 | Nacos | Consul |
| 网关 | Spring Cloud Gateway | - |
| 熔断 | Sentinel | Resilience4j |
| 链路追踪 | SkyWalking | Zipkin |
| 容器化 | Docker + K8s | - |
