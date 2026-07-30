# Spring Boot 开发规范

你正在使用 **spring-boot** 技术栈开发 Java 后端项目。

## 技术基线
- Spring Boot 3.x + JDK 17+（`jakarta.*` 命名空间）
- 构建：Maven 或 Gradle
- 持久化：JPA / MyBatis / MyBatis-Plus

## 核心规则

### 分层架构
```
controller → service → repository
```
- Controller：接收请求、参数校验、返回响应，不含业务逻辑
- Service：业务逻辑，接口与实现分离
- Repository：数据访问封装

### 注入优先级
1. 构造器注入（`@RequiredArgsConstructor`）
2. `@Resource`
3. `@Autowired`（谨慎）

### POJO 规范
- Entity / DTO / VO / Query 各司其职
- 所有 POJO MUST 有无参构造
- JPA Entity 禁止 `@Data`

### 异常处理
- `@RestControllerAdvice` 统一异常处理
- 业务异常定义错误码枚举
- 统一响应体 `Result<T>`

### 持久化
- JPA：`JpaRepository<T, ID>`，注意 N+1
- MyBatis：XML 在 `resources/mapper/`
- `@Transactional` 在 Service 层，禁止 Controller 层

### 安全
- SecurityFilterChain 配置
- BCrypt 加密密码
- 禁止 SQL 拼接
- 敏感信息不入日志

### 远程调用
- MUST 用 `@FeignClient`
- MUST 声明 `fallback`/`fallbackFactory`
- 强一致性 fallback MUST 抛异常

### 测试
- 单测：JUnit 5 + Mockito，不启动 Spring
- 集成测试：`@SpringBootTest` + Testcontainers
- 提交前 `mvn clean test` 全部通过

详细规则请查阅 `prompts/` 目录下的完整文档。
