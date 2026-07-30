# Echo Swagger/OpenAPI 规则

> 适用场景：Echo 项目的 API 文档生成（swaggo/echo-swagger）。

## 硬约束

- **MUST** 使用 `swaggo/swag` + `swaggo/echo-swagger` 生成 OpenAPI 文档。
- **MUST** 每个公开 API handler 有完整的 Swagger 注解。
- **MUST** 在 CI 中验证 `swag init` 无错误。
- **SHOULD** 生产环境可关闭 Swagger UI。

## 主入口注解（`cmd/server/main.go`）

```go
// @title           My Service API
// @version         1.0.0
// @description     Echo 微服务 API
//
// @host      localhost:8080
// @BasePath  /api/v1
//
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
func main() {
    // ...
}
```

## Handler 注解

```go
// @Summary      创建用户
// @Description  创建新用户
// @Tags         用户管理
// @Accept       json
// @Produce      json
// @Param        body  body      CreateUserRequest  true  "创建用户请求"
// @Success      201   {object}  UserResponse
// @Failure      400   {object}  ErrorResponse
// @Security     BearerAuth
// @Router       /users [post]
func (h *UserHandler) Create(c echo.Context) error { ... }

// @Summary      获取用户详情
// @Tags         用户管理
// @Param        id   path      int64  true  "用户ID"
// @Success      200  {object}  UserResponse
// @Failure      404  {object}  ErrorResponse
// @Security     BearerAuth
// @Router       /users/{id} [get]
func (h *UserHandler) GetByID(c echo.Context) error { ... }

// @Summary      分页查询用户
// @Tags         用户管理
// @Param        page      query     int     false  "页码"
// @Param        pageSize  query     int     false  "每页条数"
// @Param        keyword   query     string  false  "搜索关键词"
// @Success      200  {object}  PageResponse
// @Security     BearerAuth
// @Router       /users [get]
func (h *UserHandler) List(c echo.Context) error { ... }
```

## 通用响应结构

```go
type ErrorResponse struct {
    Code    int    `json:"code" example:"40001"`
    Message string `json:"message" example:"参数校验失败"`
}

type PageResponse struct {
    Total    int64       `json:"total"`
    Page     int         `json:"page"`
    PageSize int         `json:"pageSize"`
    Data     interface{} `json:"data"`
}
```

## 模型注解

```go
type CreateUserRequest struct {
    Username string `json:"username" validate:"required,min=3,max=32" example:"zhangsan"`
    Email    string `json:"email" validate:"required,email" example:"zhangsan@example.com"`
}

type UserResponse struct {
    ID        int64     `json:"id" example:"1"`
    Username  string    `json:"username" example:"zhangsan"`
    Email     string    `json:"email" example:"zhangsan@example.com"`
    CreatedAt time.Time `json:"createdAt"`
}
```

## 路由注册

```go
import (
    echoSwagger "github.com/swaggo/echo-swagger"
    _ "my-service/docs"
)

func SetupRouter(e *echo.Echo, cfg *config.Config) {
    if cfg.Swagger.Enabled {
        e.GET("/swagger/*", echoSwagger.WrapHandler)
    }
}
```

## CI 集成

```makefile
swagger:
	swag init -g cmd/server/main.go -o docs --parseDependency --parseInternal

check-swagger:
	swag init -g cmd/server/main.go -o docs --parseDependency --parseInternal
	git diff --exit-code docs/ || (echo "Swagger docs out of date" && exit 1)
```

## 禁止事项

- **禁止** 在生产环境默认暴露 Swagger UI。
- **禁止** 注解参数类型与实际 handler 不一致。
- **禁止** 公共 API 省略 `@Security` 注解。
- **禁止** `docs/` 目录加入 `.gitignore`。
