# Quarkus 代码评审规范

## 评审重点

### CDI 检查

- Bean 作用域正确: `@ApplicationScoped` / `@RequestScoped` / `@Singleton`
- 禁止使用 Spring 注解 (`@Autowired`, `@Component`, `@Service`)
- `@Inject` 用于构造器注入

### JAX-RS 检查

- Resource 类使用 JAX-RS 注解 (`@Path`, `@GET`, `@POST` 等)
- 禁止使用 Spring MVC 注解
- `@PathParam` / `@QueryParam` 使用正确
- `@Valid` 校验请求体

### Panache 检查

- Entity 继承 `PanacheEntity` 或自定义 ID
- Repository 使用 `PanacheRepository<T>` 接口
- 查询方法合理: `find()`, `list()`, `stream()`

### 响应式检查

- 返回 `Uni<T>` / `Multi<T>` 
- 链式调用正确: `map`, `flatMap`, `onFailure`
- 阻塞操作不能同步调用

### 安全

- 敏感端点添加安全约束
- 输入使用 `@Valid` + `jakarta.validation`
- 不硬编码密钥

## 常见问题

| 问题 | 修复 |
|---|---|
| 使用 `@Autowired` | 改为 `@Inject` |
| 使用 `@RestController` | 改为 `@Path` + `@Produces` |
| 同步方法返回 Object | 改为返回 `Uni<T>` |
| Exception 未映射 | 实现 `ExceptionMapper<T>` |
| SQL 拼接 | 使用 Panache 参数化查询 |

## 评审模板

```
## 评审: `UserResource.java`

🔴 **严重**: 使用 `@GetMapping` (Spring 注解) → 改为 `@GET` + `@Path`
🟡 **建议**: 异常处理用 `ExceptionMapper` 替代局部 try-catch
🟢 **优点**: CDI 作用域声明正确
```
