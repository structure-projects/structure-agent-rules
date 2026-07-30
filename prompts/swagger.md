# Swagger — structure-projects OpenAPI 文档规范

> 角色：在 structure-projects 生态内做 **API 文档生成** 的 AI。
> 本文件是工具无关的单一内容源。

## 1. 依赖配置

**artifact**：`org.springdoc:springdoc-openapi-starter-webmvc-ui`
**当前版本**：`3.0.3`（与 Spring Boot 4.0.6 兼容）

```xml
<!-- structure-{X}-dependencies/pom.xml -->
<properties>
    <springdoc.version>3.0.3</springdoc.version>
</properties>

<dependencyManagement>
<dependencies>
    <dependency>
        <groupId>org.springdoc</groupId>
        <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
        <version>${springdoc.version}</version>
    </dependency>
</dependencies>
</dependencyManagement>

<!-- structure-{X}-interfaces/pom.xml 或 structure-{X}-boot/pom.xml -->
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
</dependency>
```

## 2. 配置文件

```yaml
springdoc:
  api-docs:
    enabled: true
    path: /v3/api-docs
  swagger-ui:
    enabled: true
    path: /swagger-ui.html
    tags-sorter: alpha
    operations-sorter: alpha
  group-configs:
    - group: '{X}'
      packages-to-scan: cn.structured.{X}.interfaces.controller
```

**约束**：
- **SHOULD** 生产环境通过 `springdoc.api-docs.enabled=false` + `springdoc.swagger-ui.enabled=false` 关闭文档（或加访问控制）。
- **SHOULD** `group-configs.packages-to-scan` 指向 `interfaces.controller` 包（DDD 布局），不是旧的 `controller` 包。

## 3. 常用注解速查

| 注解 | 位置 | 说明 | 示例 |
|---|---|---|---|
| `@Tag` | Controller 类 | 接口模块分组 | `@Tag(name = "用户管理")` |
| `@Operation` | 方法 | 接口功能描述 | `@Operation(summary = "创建用户")` |
| `@Parameter` | 参数 | 参数说明 | `@Parameter(description = "用户ID", example = "1")` |
| `@Schema` | DTO/VO 字段 | 字段说明 | `@Schema(description = "用户名", example = "zhangsan")` |
| `@ApiResponse` / `@ApiResponses` | 方法 | 响应说明 | `@ApiResponse(responseCode = "200", description = "成功")` |
| `@RequestBody`（swagger 注解） | 参数 | 请求体说明 | `@RequestBody(description = "创建参数")` |

⚠️ 使用 `io.swagger.v3.oas.annotations.*`（OpenAPI 3），**不是** 旧的 `io.swagger.annotations.*`（Swagger 2）。

## 4. 全局 OpenAPI 配置

```java
package cn.structured.example.boot.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("{X}服务 API")
                .description("{X}服务 API 文档")
                .version("1.0.0")
                .contact(new Contact()
                    .name("structure-projects")
                    .url("https://www.structured.cn")))
            .servers(List.of(
                new Server().url("http://localhost:8080").description("开发环境"),
                new Server().url("https://api.example.com").description("生产环境")
            ));
    }
}
```

**约束**：
- **MUST** `OpenApiConfig` 放在 `boot/config/` 或 `interfaces/config/` 包。
- **SHOULD** 多环境时通过 `spring.profiles.active` 区分 servers 列表。

## 5. Controller 文档模板

```java
package cn.structured.example.interfaces.controller.api;

import cn.structure.common.entity.ResResultVO;
import cn.structure.common.utils.ResultUtilSimpleImpl;
import cn.structure.common.vo.ReqPage;
import cn.structure.common.vo.ResPage;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@Tag(name = "用户管理", description = "用户生命周期管理接口")
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final IUserService userService;

    @Operation(summary = "分页查询用户列表", description = "支持按用户名、姓名、手机号等条件分页")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "查询成功"),
        @ApiResponse(responseCode = "400", description = "参数错误")
    })
    @GetMapping("/page")
    public ResResultVO<ResPage<UserVO>> page(UserQuery query, ReqPage reqPage) {
        return ResultUtilSimpleImpl.success(userService.page(query, reqPage));
    }

    @Operation(summary = "获取用户详情")
    @GetMapping("/{id}")
    public ResResultVO<UserVO> findById(
            @Parameter(description = "用户ID", required = true, example = "1")
            @PathVariable Long id) {
        return ResultUtilSimpleImpl.success(userService.findById(id));
    }

    @Operation(summary = "创建用户")
    @PostMapping
    public ResResultVO<Long> create(@Valid @RequestBody UserDTO dto) {
        return ResultUtilSimpleImpl.success(userService.create(dto));
    }
}
```

## 6. DTO / VO 文档模板

```java
@Data
@Schema(description = "创建用户请求参数")
public class UserDTO {

    @NotBlank(message = "用户名不能为空")
    @Size(min = 3, max = 32)
    @Pattern(regexp = "^[a-zA-Z][a-zA-Z0-9_]*$")
    @Schema(description = "用户名", example = "zhangsan")
    private String username;

    @NotBlank(message = "手机号不能为空")
    @Pattern(regexp = "^1[3-9]\\d{9}$")
    @Schema(description = "手机号", example = "13800138000")
    private String phone;
}

@Data
@Schema(description = "用户信息")
public class UserVO {

    @Schema(description = "用户ID", example = "1")
    private Long id;

    @Schema(description = "用户名", example = "zhangsan")
    private String username;

    @Schema(description = "状态：0-禁用，1-启用", example = "1")
    private Integer status;

    @Schema(description = "创建时间", example = "2026-01-01 10:00:00")
    private LocalDateTime createTime;
}
```

**约束**：
- **MUST** DTO / VO 类级 `@Schema(description = "...")` 必填。
- **MUST** 字段 `@Schema(description = "...", example = "...")` 必填 description，**SHOULD** 填 example。
- **SHOULD** 枚举字段在 description 中说明取值含义（如 `"状态：0-禁用，1-启用"`）。

## 7. 访问地址

| 地址 | 用途 |
|---|---|
| `http://host:port/swagger-ui.html` | Swagger UI 界面 |
| `http://host:port/v3/api-docs` | OpenAPI JSON |
| `http://host:port/v3/api-docs.yaml` | OpenAPI YAML |
| `http://host:port/swagger-ui.html?urls.primaryName={group}` | 指定分组 |

## 8. 提交前自检

- [ ] 依赖是 `springdoc-openapi-starter-webmvc-ui` 而非旧版 `springfox-*`？
- [ ] 注解来自 `io.swagger.v3.oas.annotations.*` 而非 `io.swagger.annotations.*`？
- [ ] Controller 类有 `@Tag`？方法有 `@Operation`？参数有 `@Parameter`？
- [ ] DTO/VO 类与字段都有 `@Schema` + `description` + `example`？
- [ ] 生产环境已通过配置关闭或加访问控制？
- [ ] `OpenApiConfig` 已配置 info（title/description/version/contact）与 servers？
