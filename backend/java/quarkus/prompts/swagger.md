# Quarkus API 文档规范（SmallRye OpenAPI）

> Quarkus 3.x 项目 API 文档生成规范，基于 SmallRye OpenAPI（MicroProfile OpenAPI 实现）。

---

## 1. 依赖配置

### Maven

```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-smallrye-openapi</artifactId>
</dependency>
```

**注意**：`quarkus-smallrye-openapi` 已包含 Swagger UI，无需额外依赖。

---

## 2. 基础配置

### application.properties

```properties
# OpenAPI 基本信息
quarkus.smallrye-openapi.info-title=用户服务 API
quarkus.smallrye-openapi.info-version=1.0.0
quarkus.smallrye-openapi.info-description=用户管理 RESTful API 接口文档

# Swagger UI
quarkus.swagger-ui.always-include=true
quarkus.swagger-ui.path=/swagger-ui

# 扫描路径
quarkus.smallrye-openapi.scan-packages=com.example.api.resource
```

---

## 3. 注解使用

### 3.1 Resource 层

```java
@Path("/api/v1/users")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "用户管理", description = "用户 CRUD 接口")
public class UserResource {

    @Inject
    UserApplicationService userApplicationService;

    @POST
    @Operation(summary = "创建用户", description = "创建新用户，邮箱不能重复")
    @APIResponse(responseCode = "201", description = "创建成功")
    @APIResponse(responseCode = "400", description = "参数校验失败")
    @APIResponse(responseCode = "409", description = "邮箱已存在")
    public Response create(@Valid CreateUserDTO dto) {
        UserVO user = userApplicationService.createUser(dto);
        return Response.status(Response.Status.CREATED).entity(user).build();
    }

    @GET
    @Path("/{id}")
    @Operation(summary = "根据 ID 查询用户")
    @APIResponse(responseCode = "200", description = "查询成功")
    @APIResponse(responseCode = "404", description = "用户不存在")
    public Response findById(
            @PathParam("id")
            @Parameter(description = "用户 ID", required = true, example = "1")
            Long id) {
        UserVO user = userApplicationService.findById(id);
        if (user == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        return Response.ok(user).build();
    }

    @GET
    @Path("/page")
    @Operation(summary = "分页查询用户")
    public Response page(
            @QueryParam("pageNum") @DefaultValue("1")
            @Parameter(description = "页码", example = "1")
            @Min(1) Integer pageNum,
            @QueryParam("pageSize") @DefaultValue("20")
            @Parameter(description = "每页数量", example = "20")
            @Min(1) @Max(100) Integer pageSize,
            @QueryParam("keyword")
            @Parameter(description = "用户名关键词")
            String keyword) {
        return Response.ok(userApplicationService.page(pageNum, pageSize, keyword)).build();
    }

    @PUT
    @Path("/{id}")
    @Operation(summary = "更新用户")
    @APIResponse(responseCode = "204", description = "更新成功")
    @APIResponse(responseCode = "404", description = "用户不存在")
    public Response update(
            @PathParam("id") @Parameter(description = "用户 ID") Long id,
            @Valid UpdateUserDTO dto) {
        userApplicationService.update(id, dto);
        return Response.noContent().build();
    }

    @DELETE
    @Path("/{id}")
    @Operation(summary = "删除用户")
    @APIResponse(responseCode = "204", description = "删除成功")
    @APIResponse(responseCode = "404", description = "用户不存在")
    public Response delete(
            @PathParam("id") @Parameter(description = "用户 ID") Long id) {
        userApplicationService.delete(id);
        return Response.noContent().build();
    }
}
```

### 3.2 DTO 层

```java
@Schema(description = "创建用户请求")
public class CreateUserDTO {

    @NotBlank(message = "用户名不能为空")
    @Size(min = 2, max = 50, message = "用户名长度为 2-50 个字符")
    @Schema(description = "用户名", required = true, example = "张三")
    public String username;

    @NotBlank(message = "邮箱不能为空")
    @Email(message = "邮箱格式不正确")
    @Schema(description = "邮箱", required = true, example = "zhangsan@example.com")
    public String email;

    public CreateUserDTO() {}
}
```

### 3.3 VO 层

```java
@Schema(description = "用户信息")
public class UserVO {

    @Schema(description = "用户 ID", example = "1")
    public Long id;

    @Schema(description = "用户名", example = "张三")
    public String username;

    @Schema(description = "邮箱", example = "zhangsan@example.com")
    public String email;

    @Schema(description = "创建时间", example = "2024-01-01T12:00:00")
    public LocalDateTime createdAt;

    public static UserVO from(User user) { ... }
}
```

---

## 4. 常用注解速查

| 注解 | 位置 | 说明 |
|---|---|---|
| `@Tag` | Resource 类 | 接口分组标签 |
| `@Operation` | Resource 方法 | 接口描述 |
| `@APIResponse` | Resource 方法 | 响应说明 |
| `@Parameter` | 方法参数 | 参数说明 |
| `@Schema` | DTO / VO 字段 | 模型字段说明 |
| `@Hidden` | 方法/字段 | 隐藏接口或字段 |

---

## 5. 安全配置

### 5.1 JWT 认证

```java
@ApplicationScoped
public class OpenApiConfig {

    @Inject
    OpenAPI openAPI;

    @PostConstruct
    public void configure() {
        openAPI.getComponents().addSecurityScheme("bearer-jwt",
            new SecurityScheme()
                .type(SecurityScheme.Type.HTTP)
                .scheme("bearer")
                .bearerFormat("JWT")
                .description("输入 JWT Token"));
        openAPI.addSecurityRequirement(new SecurityRequirement().addList("bearer-jwt"));
    }
}
```

### 5.2 环境控制

```properties
# 生产环境关闭 Swagger UI
%prod.quarkus.swagger-ui.always-include=false
%prod.quarkus.smallrye-openapi.enable=false
```

---

## 6. 分组配置

```java
// 通过 @Tag 分组
@Path("/api/v1/public")
@Tag(name = "公开接口")
public class PublicResource { ... }

@Path("/api/v1/admin")
@Tag(name = "管理端接口")
public class AdminResource { ... }
```

---

## 7. 访问地址

启动项目后访问：
- Swagger UI：`http://localhost:8080/swagger-ui/`
- OpenAPI JSON：`http://localhost:8080/q/openapi`

---

## 8. 规范要求（MUST）

- 所有 Resource 公开方法 MUST 有 `@Operation` 注解
- 所有 DTO/VO 字段 SHOULD 有 `@Schema` 注解
- 异常响应 SHOULD 用 `@APIResponse` 声明
- 生产环境 MUST 关闭 Swagger UI
- 敏感字段（密码等）MUST 使用 `@Schema(hidden = true)` 或 `@JsonIgnore`
- Quarkus 使用 `@APIResponse`（非 Springdoc 的 `@ApiResponse`）
