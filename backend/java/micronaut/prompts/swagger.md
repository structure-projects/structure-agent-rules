# Micronaut API 文档规范（OpenAPI）

> Micronaut 4.x 项目 API 文档生成规范，基于 micronaut-openapi。

---

## 1. 依赖配置

### Gradle

```kotlin
dependencies {
    annotationProcessor("io.micronaut.openapi:micronaut-openapi")
    implementation("io.micronaut.openapi:micronaut-openapi")
}
```

### Maven

```xml
<dependency>
    <groupId>io.micronaut.openapi</groupId>
    <artifactId>micronaut-openapi</artifactId>
    <scope>compile</scope>
</dependency>
```

---

## 2. 基础配置

### application.yml

```yaml
micronaut:
  router:
    static-resources:
      swagger:
        paths: classpath:META-INF/swagger
        mapping: /swagger/**
      swagger-ui:
        paths: classpath:META-INF/swagger/views/swagger-ui
        mapping: /swagger-ui/**
  openapi:
    views:
      spec: swagger-ui.enabled=true,rapidoc.enabled=true,redoc.enabled=true
```

### OpenAPI 配置类

```java
@OpenAPIDefinition(
    info = @Info(
        title = "用户服务 API",
        version = "1.0.0",
        description = "用户管理 RESTful API 接口文档",
        contact = @Contact(name = "开发团队", email = "dev@company.com")
    ),
    security = @SecurityRequirement(name = "bearer-jwt")
)
public class OpenApiConfig {
}
```

---

## 3. 注解使用

### 3.1 Controller 层

```java
@Controller("/api/v1/users")
public class UserController {

    private final UserApplicationService userApplicationService;

    public UserController(UserApplicationService userApplicationService) {
        this.userApplicationService = userApplicationService;
    }

    @Post
    @Operation(summary = "创建用户", description = "创建新用户，邮箱不能重复")
    @ApiResponse(responseCode = "201", description = "创建成功")
    @ApiResponse(responseCode = "400", description = "参数校验失败")
    @ApiResponse(responseCode = "409", description = "邮箱已存在")
    public HttpResponse<UserVO> create(@Body @Valid CreateUserDTO dto) {
        UserVO user = userApplicationService.createUser(dto);
        return HttpResponse.created(user);
    }

    @Get("/{id}")
    @Operation(summary = "根据 ID 查询用户")
    @ApiResponse(responseCode = "200", description = "查询成功")
    @ApiResponse(responseCode = "404", description = "用户不存在")
    public HttpResponse<UserVO> findById(
            @PathVariable @Parameter(description = "用户 ID", required = true, example = "1") Long id) {
        return userApplicationService.findById(id)
            .map(HttpResponse::ok)
            .orElse(HttpResponse.notFound());
    }

    @Get("/page{?pageNum,pageSize,keyword}")
    @Operation(summary = "分页查询用户")
    public HttpResponse<Page<UserVO>> page(
            @QueryValue(defaultValue = "1")
            @Parameter(description = "页码", example = "1")
            @Min(1) Integer pageNum,
            @QueryValue(defaultValue = "20")
            @Parameter(description = "每页数量", example = "20")
            @Min(1) @Max(100) Integer pageSize,
            @QueryValue
            @Parameter(description = "用户名关键词")
            @Nullable String keyword) {
        return HttpResponse.ok(userApplicationService.page(pageNum, pageSize, keyword));
    }

    @Put("/{id}")
    @Operation(summary = "更新用户")
    @ApiResponse(responseCode = "204", description = "更新成功")
    @ApiResponse(responseCode = "404", description = "用户不存在")
    public HttpResponse<Void> update(
            @PathVariable @Parameter(description = "用户 ID") Long id,
            @Body @Valid UpdateUserDTO dto) {
        userApplicationService.update(id, dto);
        return HttpResponse.noContent();
    }

    @Delete("/{id}")
    @Operation(summary = "删除用户")
    @ApiResponse(responseCode = "204", description = "删除成功")
    @ApiResponse(responseCode = "404", description = "用户不存在")
    public HttpResponse<Void> delete(
            @PathVariable @Parameter(description = "用户 ID") Long id) {
        userApplicationService.delete(id);
        return HttpResponse.noContent();
    }
}
```

### 3.2 DTO 层

```java
@Introspected
@Schema(description = "创建用户请求")
public class CreateUserDTO {

    @NotBlank(message = "用户名不能为空")
    @Size(min = 2, max = 50, message = "用户名长度为 2-50 个字符")
    @Schema(description = "用户名", requiredMode = Schema.RequiredMode.REQUIRED, example = "张三")
    private String username;

    @NotBlank(message = "邮箱不能为空")
    @Email(message = "邮箱格式不正确")
    @Schema(description = "邮箱", requiredMode = Schema.RequiredMode.REQUIRED, example = "zhangsan@example.com")
    private String email;

    public CreateUserDTO() {}

    // Getters / Setters
}
```

### 3.3 VO 层

```java
@Introspected
@Schema(description = "用户信息")
public class UserVO {

    @Schema(description = "用户 ID", example = "1")
    private Long id;

    @Schema(description = "用户名", example = "张三")
    private String username;

    @Schema(description = "邮箱", example = "zhangsan@example.com")
    private String email;

    @Schema(description = "创建时间", example = "2024-01-01T12:00:00")
    private LocalDateTime createdAt;

    public UserVO() {}

    // Getters / Setters
}
```

---

## 4. 常用注解速查

| 注解 | 位置 | 说明 |
|---|---|---|
| `@Operation` | Controller 方法 | 接口描述 |
| `@ApiResponse` | Controller 方法 | 响应说明 |
| `@Parameter` | 方法参数 | 参数说明 |
| `@Schema` | DTO / VO 字段 | 模型字段说明 |
| `@Hidden` | 方法/字段 | 隐藏接口或字段 |

---

## 5. 安全配置

### 5.1 JWT 认证

```java
@OpenAPIDefinition(
    info = @Info(title = "用户服务 API", version = "1.0.0"),
    security = @SecurityRequirement(name = "bearer-jwt")
)
@SecurityScheme(
    name = "bearer-jwt",
    type = SecuritySchemeType.HTTP,
    scheme = "bearer",
    bearerFormat = "JWT",
    description = "输入 JWT Token"
)
public class OpenApiConfig {
}
```

### 5.2 环境控制

```yaml
# application.yml — 仅开发环境启用
micronaut:
  router:
    static-resources:
      swagger:
        enabled: false
      swagger-ui:
        enabled: false
```

或通过 `@Requires`：

```java
@OpenAPIDefinition(...)
@Requires(env = {"dev", "staging"})
public class OpenApiConfig {
}
```

---

## 6. 分组配置

```java
@OpenAPIDefinition(
    info = @Info(title = "用户服务", version = "1.0.0")
)
public class UserOpenApiConfig {
}

@OpenAPIDefinition(
    info = @Info(title = "订单服务", version = "1.0.0")
)
public class OrderOpenApiConfig {
}
```

---

## 7. 访问地址

启动项目后访问：
- Swagger UI：`http://localhost:8080/swagger-ui/`
- OpenAPI JSON：`http://localhost:8080/swagger/user-service-1.0.0.yml`

---

## 8. 规范要求（MUST）

- 所有 Controller 公开方法 MUST 有 `@Operation` 注解
- 所有 DTO/VO 字段 SHOULD 有 `@Schema` 注解
- 异常响应 SHOULD 用 `@ApiResponse` 声明
- 生产环境 MUST 关闭 Swagger UI
- 敏感字段（密码等）MUST 使用 `@Schema(hidden = true)` 或 `@JsonIgnore`
- DTO/VO 类 MUST 标注 `@Introspected`（Micronaut AOT 要求）
