# Micronaut 代码评审规范

> Micronaut 4.x 项目代码评审检查清单与最佳实践。

---

## 1. 评审流程

```
开发者提交 PR → 自动 CI 检查 → 人工代码评审 → 修复问题 → 合并
```

评审者关注点优先级：
1. **安全性** — 是否有安全漏洞
2. **AOT 兼容性** — 是否兼容 Micronaut 编译时 DI
3. **正确性** — 业务逻辑是否正确
4. **性能** — 是否有性能问题
5. **可维护性** — 代码是否清晰、可读

---

## 2. AOT 兼容性检查（MUST）

### 2.1 禁止反射

```java
// ❌ 禁止：反射
Class<?> clazz = Class.forName("com.example.User");
Method method = clazz.getMethod("getName");
Object result = method.invoke(user);

// ✅ 正确：使用多态或策略模式
User user = userRepository.findById(id);
String name = user.getName();
```

### 2.2 禁止字段注入

```java
// ❌ 禁止
@Inject
private UserService userService;

// ✅ 正确
private final UserService userService;

public OrderController(UserService userService) {
    this.userService = userService;
}
```

### 2.3 禁止动态代理

```java
// ❌ 禁止：CGLIB / JDK 动态代理
Enhancer enhancer = new Enhancer();

// ✅ 正确：使用 Micronaut AOP
@Singleton
@Introduction
public class LoggingInterceptor implements MethodInterceptor { ... }
```

### 2.4 DTO/VO 必须标注 @Introspected

```java
// ✅ 正确
@Introspected
public class CreateUserDTO { ... }

// ❌ 错误：缺少 @Introspected（AOT 无法识别 Bean 属性）
public class CreateUserDTO { ... }
```

---

## 3. Micronaut 专属检查

### 3.1 注解使用

| 检查项 | 正确注解 | 错误注解 |
|---|---|---|
| Bean 声明 | `@Singleton` | `@Service` / `@Component` / `@Repository` |
| Controller | `@Controller` | `@RestController` |
| 请求体绑定 | `@Body` | `@RequestBody` |
| HTTP 方法 | `@Get` / `@Post` / `@Put` / `@Delete` | `@GetMapping` / etc |
| 配置注入 | `@ConfigurationProperties` / `@Property` | `@Value` |
| 安全注解 | `@Secured` | `@PreAuthorize` |

### 3.2 HTTP 客户端

```java
// ❌ 禁止：Spring 风格 HTTP 调用
RestTemplate restTemplate = new RestTemplate();
UserVO user = restTemplate.getForObject(url, UserVO.class);

// ✅ 正确：Micronaut 声明式 Client
@Client(id = "user-service")
public interface UserClient {
    @Get("/api/v1/users/{id}")
    UserVO findById(Long id);
}
```

### 3.3 响应式链检查

```java
// ❌ 禁止：在响应式链中 block
Mono<User> userMono = userRepository.findById(id);
User user = userMono.block();  // 阻塞！

// ✅ 正确：组合响应式链
return userRepository.findById(id)
    .map(user -> UserVO.from(user))
    .map(HttpResponse::ok);
```

### 3.4 事务边界

```java
// ❌ 错误：事务在 Controller 层
@Controller
public class UserController {
    @Transactional  // 不应该在 Controller 层
    public HttpResponse<Void> create(@Body CreateUserDTO dto) { ... }
}

// ✅ 正确：事务在 Application 层
@Singleton
public class UserApplicationService {
    @Transactional
    public UserVO createUser(CreateUserDTO dto) { ... }
}
```

---

## 4. 安全性检查

### 4.1 认证与授权

- [ ] 所有 Controller MUST 有 `@Secured` 注解
- [ ] JWT Token 校验 MUST 在 Filter 层
- [ ] **禁止**在 Controller 中手动解析 JWT

```java
// ✅ 正确：类级别声明安全策略
@Controller("/api/v1/users")
@Secured(SecurityRule.IS_AUTHENTICATED)
public class UserController { ... }

// ✅ 正确：方法级别覆盖
@Get("/admin")
@Secured("ROLE_ADMIN")
public HttpResponse<List<UserVO>> listAll() { ... }
```

### 4.2 输入校验

- [ ] 所有入参 MUST 有 `@Valid` + `jakarta.validation` 注解
- [ ] **禁止**在 Controller 方法体中手写 `if-else` 校验

### 4.3 SQL 注入

- [ ] Micronaut Data 默认参数化查询（安全），但自定义 `@Query` 需检查
- [ ] **禁止**拼接 SQL 字符串

### 4.4 敏感信息

- [ ] 密码字段 MUST 标记 `@JsonIgnore` 或 `@Schema(hidden = true)`
- [ ] 日志中 MUST NOT 包含密码、Token 等敏感信息
- [ ] 配置文件中的密钥 MUST 使用环境变量

---

## 5. 性能检查

- [ ] 数据库查询是否有 N+1 问题？
- [ ] 是否在循环中调用外部服务？
- [ ] HTTP 客户端是否配置了连接池和超时？
- [ ] 是否有不必要的 `.block()` 调用？

---

## 6. 代码质量

### 6.1 命名规范

| 类型 | 规范 | 示例 |
|---|---|---|
| Controller | `{Entity}Controller` | `UserController` |
| ApplicationService | `{Entity}ApplicationService` | `UserApplicationService` |
| DomainService | `{Entity}DomainService` | `UserDomainService` |
| Repository | `{Entity}Repository` | `UserRepository` |
| DTO | `{Action}{Entity}DTO` | `CreateUserDTO` |
| VO | `{Entity}VO` | `UserVO` |
| HTTP Client | `{Service}Client` | `OrderClient` |

### 6.2 日志规范

- [ ] MUST 使用 SLF4J Logger
- [ ] **禁止** `System.out.println`
- [ ] 异常日志 MUST 包含完整堆栈

### 6.3 异常处理

- [ ] 使用 `@Produces` + `ExceptionHandler` 全局处理
- [ ] 业务异常继承 `RuntimeException`
- [ ] 不在 Controller 中 try-catch 吞掉异常

---

## 7. 评审检查清单（完整）

### 必检项（MUST）

- [ ] AOT 兼容性（无反射、无字段注入、DTO 有 @Introspected）
- [ ] 无 Spring 框架依赖混入
- [ ] HTTP 客户端使用 `@Client`
- [ ] Controller 有 `@Secured` 注解
- [ ] 输入校验使用 `jakarta.validation`
- [ ] 事务边界在 Application 层

### 应检项（SHOULD）

- [ ] 构造器注入（所有 Bean）
- [ ] 无响应式链 `.block()` 调用
- [ ] 配置使用 `@ConfigurationProperties`
- [ ] 日志使用 SLF4J
- [ ] 异常全局处理
- [ ] 测试类使用 `@MicronautTest`

### 建议项（MAY）

- [ ] 代码覆盖率 ≥ 80%
- [ ] 无过长方法（> 50 行）
- [ ] 无过多参数（> 5 个）
- [ ] 注释完整（公共 API 有 Javadoc）
