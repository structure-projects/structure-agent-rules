# Quarkus 3.x — Codex 合并规则

> 本文件由 `install.sh` 安装时合并到目标项目的 `AGENTS.md` 中。

## 技术栈

- **Quarkus**: 3.x
- **JDK**: 17+
- **语言**: Java / Kotlin
- **构建工具**: Maven（推荐）/ Gradle
- **响应式**: Mutiny（`Uni<T>` / `Multi<T>`）
- **ORM**: Hibernate with Panache
- **REST**: RESTEasy Reactive（JAX-RS）
- **测试**: JUnit 5 + REST Assured + Testcontainers

## 核心原则

1. **Jakarta 命名空间**：所有导入 MUST 使用 `jakarta.*`（非 `javax.*`）
2. **JAX-RS 而非 Spring MVC**：使用 `@Path`、`@GET`、`@POST` 等 JAX-RS 注解
3. **CDI 注入**：`@ApplicationScoped` + `@Inject`，**禁止** `@Autowired`
4. **Panache ORM**：Active Record 或 Repository 模式，简化 Hibernate
5. **响应式（Mutiny）**：`Uni<T>` 对应单值，`Multi<T>` 对应流
6. **Dev 模式**：`quarkus dev` 支持热重载和 Dev UI

## 关键注解对照

| Quarkus 注解 | 说明 | 替代 Spring 注解 |
|---|---|---|
| `@ApplicationScoped` | 应用范围 Bean | `@Service` / `@Component` |
| `@Path("/api/users")` | 资源路径 | `@RequestMapping` |
| `@GET` / `@POST` / `@PUT` / `@DELETE` | HTTP 方法 | `@GetMapping` / etc |
| `@PathParam` | 路径参数 | `@PathVariable` |
| `@QueryParam` | 查询参数 | `@RequestParam` |
| `@Inject` | CDI 注入 | `@Autowired` |
| `@ConfigProperty` | 配置属性 | `@Value` |
| `@RolesAllowed` | 角色权限 | `@PreAuthorize` |
| `@RegisterRestClient` | REST 客户端 | `@FeignClient` |
| `@QuarkusTest` | 测试注解 | `@SpringBootTest` |
| `@InjectMock` | Mock Bean | `@MockBean` |

## 禁止事项

- **禁止** 引入 Spring 框架依赖
- **禁止** 使用 `javax.*` 命名空间（Quarkus 3.x 使用 `jakarta.*`）
- **禁止** 使用 `@Autowired`、`@RestController`、`@RequestMapping` 等 Spring 注解
- **禁止** 使用 `RestTemplate` / `WebClient`（使用 MicroProfile REST Client）
- **禁止** 在 Uni 链中调用 `.await().indefinitely()` 在 HTTP 线程中

## 检查清单

- [ ] 所有导入使用 `jakarta.*` 命名空间
- [ ] REST 端点使用 JAX-RS 注解
- [ ] CDI 注入使用 `@Inject` + `@ApplicationScoped`
- [ ] ORM 使用 Panache
- [ ] 响应式返回 `Uni<T>` / `Multi<T>`
- [ ] 测试使用 `@QuarkusTest`
- [ ] 配置使用 `@ConfigProperty` / `@ConfigMapping`
- [ ] API 有安全注解
