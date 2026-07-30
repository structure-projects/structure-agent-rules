# Spring Boot API 文档规范（Springdoc OpenAPI）

> 通用 Spring Boot 项目 API 文档生成规范，基于 Springdoc OpenAPI 3。

---

## 1. 依赖配置

### 1.1 Maven

```xml
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.6.0</version>
</dependency>
```

### 1.2 Gradle

```groovy
implementation 'org.springdoc:springdoc-openapi-starter-webmvc-ui:2.6.0'
```

---

## 2. 基础配置

### 2.1 application.yml

```yaml
springdoc:
  api-docs:
    path: /v3/api-docs
  swagger-ui:
    path: /swagger-ui.html
    tags-sorter: alpha
    operations-sorter: alpha
  packages-to-scan: com.company.project.controller
```

### 2.2 OpenAPI Bean 配置

```java
@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("项目 API 文档")
                .version("1.0.0")
                .description("RESTful API 接口文档")
                .contact(new Contact()
                    .name("开发团队")
                    .email("dev@company.com")))
            .addSecurityItem(new SecurityRequirement().addList("JWT"))
            .components(new Components()
                .addSecuritySchemes("JWT", new SecurityScheme()
                    .type(SecurityScheme.Type.HTTP)
                    .scheme("bearer")
                    .bearerFormat("JWT")));
    }
}
```

---

## 3. 注解使用

### 3.1 Controller 层

```java
@RestController
@RequestMapping("/api/v1/users")
@Tag(name = "用户管理", description = "用户 CRUD 接口")
public class UserController {

    @Operation(summary = "创建用户", description = "创建新用户，邮箱不能重复")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "创建成功"),
        @ApiResponse(responseCode = "400", description = "参数校验失败"),
        @ApiResponse(responseCode = "409", description = "邮箱已存在")
    })
    @PostMapping
    public Result<UserVO> createUser(@Valid @RequestBody CreateUserDTO dto) {
        return Result.success(userService.createUser(dto));
    }

    @Operation(summary = "分页查询用户")
    @GetMapping("/page")
    public Result<PageResult<UserVO>> page(
            @Parameter(description = "页码", example = "1") @RequestParam(defaultValue = "1") Integer pageNum,
            @Parameter(description = "每页数量", example = "20") @RequestParam(defaultValue = "20") Integer pageSize,
            @Parameter(description = "用户名关键词") @RequestParam(required = false) String keyword) {
        return Result.success(userService.page(pageNum, pageSize, keyword));
    }

    @Operation(summary = "根据 ID 查询用户")
    @GetMapping("/{id}")
    public Result<UserVO> findById(
            @Parameter(description = "用户 ID", required = true, example = "1")
            @PathVariable Long id) {
        return Result.success(userService.findById(id));
    }

    @Operation(summary = "更新用户")
    @PutMapping("/{id}")
    public Result<Void> update(
            @Parameter(description = "用户 ID") @PathVariable Long id,
            @Valid @RequestBody UpdateUserDTO dto) {
        userService.update(id, dto);
        return Result.success(null);
    }

    @Operation(summary = "删除用户")
    @DeleteMapping("/{id}")
    public Result<Void> delete(
            @Parameter(description = "用户 ID") @PathVariable Long id) {
        userService.delete(id);
        return Result.success(null);
    }
}
```

### 3.2 DTO 层

```java
@Data
@Schema(description = "创建用户请求")
public class CreateUserDTO {

    @Schema(description = "用户名", requiredMode = Schema.RequiredMode.REQUIRED, example = "张三")
    @NotBlank(message = "用户名不能为空")
    @Size(min = 2, max = 50, message = "用户名长度为 2-50 个字符")
    private String username;

    @Schema(description = "邮箱", requiredMode = Schema.RequiredMode.REQUIRED, example = "zhangsan@example.com")
    @NotBlank(message = "邮箱不能为空")
    @Email(message = "邮箱格式不正确")
    private String email;

    @Schema(description = "手机号", example = "13800138000")
    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
    private String phone;

    @Schema(description = "年龄", example = "25")
    @Min(value = 0, message = "年龄不能小于 0")
    @Max(value = 150, message = "年龄不能大于 150")
    private Integer age;
}
```

### 3.3 VO 层

```java
@Data
@Schema(description = "用户信息")
public class UserVO {

    @Schema(description = "用户 ID", example = "1")
    private Long id;

    @Schema(description = "用户名", example = "张三")
    private String username;

    @Schema(description = "邮箱", example = "zhangsan@example.com")
    private String email;

    @Schema(description = "创建时间", example = "2024-01-01 12:00:00")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createTime;
}
```

---

## 4. 常用注解速查

| 注解 | 位置 | 说明 |
|---|---|---|
| `@Tag` | Controller 类 | 接口分组标签 |
| `@Operation` | Controller 方法 | 接口描述 |
| `@ApiResponse` | Controller 方法 | 响应说明 |
| `@Parameter` | 方法参数 | 参数说明 |
| `@Schema` | DTO / VO 字段 | 模型字段说明 |
| `@Hidden` | 方法/字段 | 隐藏接口或字段 |

---

## 5. 安全配置

### 5.1 JWT 认证

```java
@Bean
public OpenAPI openAPI() {
    return new OpenAPI()
        .components(new Components()
            .addSecuritySchemes("bearer-jwt", new SecurityScheme()
                .type(SecurityScheme.Type.HTTP)
                .scheme("bearer")
                .bearerFormat("JWT")
                .description("输入 JWT Token")))
        .addSecurityItem(new SecurityRequirement().addList("bearer-jwt"));
}
```

### 5.2 环境控制

```yaml
# 生产环境关闭 Swagger UI
springdoc:
  api-docs:
    enabled: false
  swagger-ui:
    enabled: false
```

或通过 Profile：

```java
@Profile({"dev", "staging"})
@Configuration
public class OpenApiConfig {
    // 仅在开发和预发布环境启用
}
```

---

## 6. 分组配置

多模块或多版本 API 可使用分组：

```java
@Bean
public GroupedOpenApi publicApi() {
    return GroupedOpenApi.builder()
        .group("public")
        .pathsToMatch("/api/public/**")
        .build();
}

@Bean
public GroupedOpenApi adminApi() {
    return GroupedOpenApi.builder()
        .group("admin")
        .pathsToMatch("/api/admin/**")
        .addOpenApiCustomizer(openApi -> openApi.info(
            new Info().title("管理端 API").version("v1")))
        .build();
}
```

---

## 7. 访问地址

启动项目后访问：
- Swagger UI：`http://localhost:8080/swagger-ui.html`
- OpenAPI JSON：`http://localhost:8080/v3/api-docs`

---

## 8. 规范要求（MUST）

- 所有 Controller 公开方法 MUST 有 `@Operation` 注解
- 所有 DTO/VO 字段 SHOULD 有 `@Schema` 注解
- 异常响应 SHOULD 用 `@ApiResponse` 声明
- 生产环境 MUST 关闭 Swagger UI
- 敏感字段（密码等）MUST 使用 `@Schema(accessMode = Schema.AccessMode.WRITE_ONLY)` 或 `@JsonProperty(access = Access.WRITE_ONLY)`
