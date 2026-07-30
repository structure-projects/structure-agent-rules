# Micronaut 4.x — Codex 合并规则

> 本文件由 `install.sh` 安装时合并到目标项目的 `AGENTS.md` 中。

## 技术栈

- **Micronaut**: 4.x
- **JDK**: 17+
- **语言**: Java
- **构建工具**: Gradle（Kotlin DSL）
- **响应式**: Project Reactor / RxJava 3
- **ORM**: Micronaut Data（JPA / JDBC）
- **测试**: JUnit 5 + AssertJ + Testcontainers

## 核心原则

1. **编译时 DI**：所有 Bean MUST 使用构造器注入（`private final` 字段）
2. **声明式 HTTP 客户端**：使用 `@Client`，**禁止**使用 `RestTemplate` / `WebClient`
3. **DDD 四层分层**：api → domain → application → infrastructure
4. **响应式优先**：Controller 返回 `Mono<T>` / `Flowable<T>` 或 `HttpResponse<T>`
5. **AOT 兼容**：**禁止**反射、动态代理、字段注入

## 关键注解

| 注解 | 说明 | 替代 Spring 注解 |
|---|---|---|
| `@Singleton` | 单例 Bean | `@Service` / `@Component` |
| `@Controller` | HTTP 控制器 | `@RestController` |
| `@Client` | 声明式 HTTP 客户端 | `@FeignClient` |
| `@Get` / `@Post` / `@Put` / `@Delete` | HTTP 方法映射 | `@GetMapping` / etc |
| `@Body` | 请求体绑定 | `@RequestBody` |
| `@PathVariable` | 路径变量 | `@PathVariable` |
| `@Secured` | 安全注解 | `@PreAuthorize` |
| `@ConfigurationProperties` | 配置绑定 | `@ConfigurationProperties` |
| `@Property` | 属性注入 | `@Value` |
| `@MicronautTest` | 测试注解 | `@SpringBootTest` |
| `@MockBean` | Mock Bean | `@MockBean` |
| `@JpaRepository` / `@JdbcRepository` | 数据仓库 | `@Repository` |

## 禁止事项

- **禁止** 引入 Spring 框架依赖
- **禁止** 使用 `@Inject` 字段注入
- **禁止** 在响应式链中调用 `.block()`
- **禁止** 使用 `RestTemplate` / `WebClient`
- **禁止** 使用 `javax.*` 命名空间（Micronaut 4.x 使用 `jakarta.*`）

## 检查清单

- [ ] 所有 Bean 使用构造器注入
- [ ] HTTP 调用使用 `@Client` 声明式接口
- [ ] 校验使用 `jakarta.validation` 注解
- [ ] 测试使用 `@MicronautTest` + `@MockBean`
- [ ] 配置使用 `@ConfigurationProperties`
- [ ] API 有 `@Secured` 安全注解
