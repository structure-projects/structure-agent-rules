# Spring Boot 开发规范

> 通用 Spring Boot 项目开发约束，适用于标准 Spring Boot 技术栈。

---

## 1. 基础约束

### 1.1 技术版本（参考）

- Spring Boot 3.x + JDK 17+（`jakarta.*` 命名空间）
- 构建工具：Maven 或 Gradle
- 持久化：Spring Data JPA / MyBatis / MyBatis-Plus
- JSON 库：统一项目内只用一种（Jackson 或 FastJSON），**禁止**混用
- 工具库：优先使用 Apache Commons / Guava / Hutool

### 1.2 包名与坐标

- `groupId` MUST 遵循反向域名约定（如 `com.example`）
- 包名 MUST 与 `groupId` 保持一致
- 基础包名建议格式：`com.{company}.{project}`

---

## 2. 分层架构

### 2.1 Controller-Service-Repository 模式

```
controller  →  service  →  repository
   ↓              ↓
  DTO/VO       Entity/PO
```

- **Controller**：接收请求、参数校验、调用 Service、返回响应。MUST 不包含业务逻辑。
- **Service**：业务逻辑层。接口与实现分离（`XxxService` + `XxxServiceImpl`）。
- **Repository**：数据访问层。封装对数据库/缓存/外部 API 的访问。

### 2.2 依赖方向（MUST）

- Controller → Service（接口）→ ServiceImpl → Repository
- **禁止** Controller 直接调用 Repository
- **禁止** Service 层之间循环依赖
- 跨模块调用 MUST 通过 Feign 或 Service 接口

---

## 3. Bean 注入规范

### 3.1 注入方式优先级

1. **构造器注入**（推荐）：配合 Lombok `@RequiredArgsConstructor`，字段 `private final`
2. **`@Resource`**：按名称注入，Spring 官方推荐替代 `@Autowired`
3. **`@Autowired`**：谨慎使用，仅在没有构造器注入条件时

```java
// 推荐：构造器注入
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {
    private final UserRepository userRepository;
}

// 可接受
@Resource
private UserRepository userRepository;
```

### 3.2 禁止

- **禁止** 在 `@Configuration` 类之外使用 `new` 创建 Service/Repository 实例
- **禁止** 静态字段注入 Bean

---

## 4. POJO 规范

### 4.1 Entity

- 使用 JPA 注解（`@Entity`、`@Table`、`@Id` 等）或 MyBatis-Plus 注解
- MUST 有无参构造（public 或 protected）
- 建议使用 `@Builder` + `@AllArgsConstructor(access = AccessLevel.PRIVATE)`
- 日期字段使用 `LocalDateTime` / `LocalDate`（JDK 8+）

### 4.2 DTO / VO / Query

- 请求体使用 DTO（Data Transfer Object）
- 响应体使用 VO（View Object）
- 查询参数使用 Query 对象
- 所有 POJO MUST 有无参构造
- 方法参数数量 SHOULD ≤ 5，超过用包装对象

### 4.3 Lombok 使用

推荐使用以下注解：
- `@Data` / `@Getter` / `@Setter`
- `@Builder`
- `@NoArgsConstructor` / `@AllArgsConstructor`
- `@RequiredArgsConstructor`
- `@Slf4j`

**禁止**：在包含懒加载关联的 JPA Entity 上使用 `@Data`（`equals/hashCode` 可能触发懒加载）。

---

## 5. 异常处理

### 5.1 全局异常处理

MUST 使用 `@RestControllerAdvice` + `@ExceptionHandler` 统一处理异常：

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(BusinessException.class)
    public Result<Void> handleBusinessException(BusinessException e) {
        return Result.fail(e.getCode(), e.getMessage());
    }
}
```

### 5.2 业务异常

- 定义业务异常类（如 `BusinessException`），含错误码和消息
- Service 层 MUST 抛业务异常，不返回 null 或 magic number
- Controller 层 SHOULD 通过全局异常处理返回错误响应，不手动 try-catch
- 建议定义异常枚举（`ErrorCode`），统一管理错误码

### 5.3 统一响应体

```java
public class Result<T> {
    private Integer code;
    private String message;
    private T data;

    public static <T> Result<T> success(T data) { ... }
    public static <T> Result<T> fail(Integer code, String message) { ... }
}
```

---

## 6. 持久化规范

### 6.1 JPA

- Repository 接口继承 `JpaRepository<T, ID>`
- 复杂查询使用 `@Query` 或 Specification
- 注意 N+1 查询问题：使用 `@EntityGraph` 或 JOIN FETCH

### 6.2 MyBatis / MyBatis-Plus

- Mapper 接口使用 `@Mapper` 或 `@MapperScan`
- XML 文件放在 `resources/mapper/` 下
- 复杂查询优先使用 XML 而非注解
- MyBatis-Plus：Service 继承 `IService<T>`，ServiceImpl 继承 `ServiceImpl<M, T>`

### 6.3 事务管理

- Service 层方法使用 `@Transactional`
- 只读操作使用 `@Transactional(readOnly = true)`
- 注意事务传播行为（默认 `REQUIRED`）
- **禁止** 在 Controller 层使用 `@Transactional`

---

## 7. 安全规范

### 7.1 Spring Security

- 使用 SecurityFilterChain 配置（Spring Security 5.7+）
- 密码 MUST 使用 `BCryptPasswordEncoder` 或 `DelegatingPasswordEncoder`
- API 鉴权使用 JWT 或 OAuth2
- 敏感接口 MUST 进行权限校验

### 7.2 常见安全约束

- 禁止 SQL 拼接，MUST 使用参数化查询
- 用户输入 MUST 校验和转义（防 XSS）
- 文件上传 MUST 校验类型和大小
- 敏感配置（密码、密钥）MUST 使用配置加密或环境变量

---

## 8. 配置管理

### 8.1 application.yml

- 多环境配置：`application-dev.yml`、`application-prod.yml`
- 敏感信息 MUST 不硬编码，使用 `${}` 占位符或环境变量
- 自定义配置使用 `@ConfigurationProperties` 绑定

### 8.2 配置优先级

1. 命令行参数
2. 环境变量
3. application-{profile}.yml
4. application.yml

---

## 9. 日志规范

- 使用 Lombok `@Slf4j` 或 `LoggerFactory.getLogger()`
- 日志级别：`ERROR`（错误）、`WARN`（警告）、`INFO`（关键业务流程）、`DEBUG`（调试信息）
- 生产环境 MUST 使用 `INFO` 及以上
- 禁止使用 `System.out.println`
- 敏感信息（密码、token）MUST 不打印到日志

---

## 10. 远程调用

- 微服务间调用 MUST 使用 Feign（`@FeignClient`）
- MUST 配置 `fallback` 或 `fallbackFactory`
- 强一致性场景 fallback MUST 抛出异常，禁止静默兜底
- 禁止直接使用 `RestTemplate` 或 `WebClient` 做服务间调用

---

## 11. 测试要求

- 每开发一个功能 MUST 编写对应的单元测试
- 单元测试：JUnit 5 + Mockito，不启动 Spring 上下文
- 集成测试：`@SpringBootTest`，测试完整的请求-响应链路
- 提交前 MUST `mvn clean test` 全部通过
- 禁止测试/编译失败仍提交代码

---

## 12. 提交前自检清单

- [ ] 包名与 `groupId` 一致
- [ ] Controller 无业务逻辑
- [ ] Service 无 SQL/HTTP 细节
- [ ] 异常处理统一
- [ ] 响应体统一封装
- [ ] 注入方式优先构造器注入
- [ ] POJO 有无参构造
- [ ] 无硬编码敏感信息
- [ ] 日志级别合理
- [ ] `mvn clean test` 全部通过
- [ ] `mvn clean package -DskipTests` 编译通过
