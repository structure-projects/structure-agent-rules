# Echo 组件与依赖速查

> 适用场景：Echo 项目中使用生态组件时的配置参考、最佳实践。

## 核心框架

### Echo

```go
import "github.com/labstack/echo/v4"

e := echo.New()
e.HideBanner = true
e.HidePort = true

// 注册校验器
e.Validator = &CustomValidator{validator: validator.New()}

// 优雅关闭
ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
defer cancel()
e.Shutdown(ctx)
```

### ent（代码生成 ORM）

```go
import "entgo.io/ent"

// 创建 schema：go run entgo.io/ent/cmd/ent new User
// 生成代码：go generate ./ent

// 连接
client, err := ent.Open("postgres", dsn)
defer client.Close()

// 自动迁移（开发环境）
client.Schema.Create(ctx)

// CRUD
user, err := client.User.Create().
    SetUsername("test").
    SetEmail("test@example.com").
    Save(ctx)

user, err = client.User.Query().
    Where(user.UsernameEQ("test")).
    Only(ctx)
```

### sqlx（轻量 SQL 库）

```go
import "github.com/jmoiron/sqlx"

db, err := sqlx.Connect("postgres", dsn)
db.SetMaxOpenConns(100)
db.SetMaxIdleConns(10)
db.SetConnMaxLifetime(time.Hour)

// 查询
var users []model.User
err = db.SelectContext(ctx, &users, "SELECT * FROM users WHERE status = $1", "active")

// 单条
var user model.User
err = db.GetContext(ctx, &user, "SELECT * FROM users WHERE id = $1", id)
```

### Viper

```go
import "github.com/spf13/viper"

viper.SetConfigName("config")
viper.SetConfigType("yaml")
viper.AddConfigPath("./configs")
viper.AutomaticEnv()

var cfg Config
viper.Unmarshal(&cfg)
```

### Zerolog（高性能日志）

```go
import "github.com/rs/zerolog"
import "github.com/rs/zerolog/log"

// 生产配置
zerolog.TimeFieldFormat = zerolog.TimeFormatUnix
log.Logger = zerolog.New(os.Stdout).With().Timestamp().Logger()

// 结构化日志
log.Info().
    Int64("user_id", user.ID).
    Str("username", user.Username).
    Msg("user created")
```

### go-playground/validator

```go
import "github.com/go-playground/validator/v10"

type CustomValidator struct {
    validator *validator.Validate
}

func (cv *CustomValidator) Validate(i interface{}) error {
    return cv.validator.Struct(i)
}

// 注册到 Echo
e.Validator = &CustomValidator{validator: validator.New()}

// handler 中使用
if err := c.Validate(req); err != nil {
    return c.JSON(400, map[string]string{"error": err.Error()})
}
```

### swaggo/echo-swagger

```go
import "github.com/swaggo/echo-swagger"
import _ "my-service/docs"

// 注册路由
e.GET("/swagger/*", echoSwagger.WrapHandler)

// 生成：swag init -g cmd/server/main.go
```

## Echo 内置中间件

| 中间件 | 导入路径 | 用途 |
|---|---|---|
| Recover | `echo.MiddlewareFunc(Recover())` | Panic 恢复 |
| Logger | `echo.MiddlewareFunc(Logger())` | 请求日志 |
| CORS | `github.com/labstack/echo/v4/middleware.CORS()` | 跨域 |
| BodyLimit | `middleware.BodyLimit("2M")` | 限制请求体大小 |
| RateLimiter | `middleware.RateLimiter(...)` | 限流 |
| RequestID | `middleware.RequestID()` | 请求追踪 |
| Timeout | `middleware.Timeout()` | 超时控制 |
| Secure | `middleware.Secure()` | 安全头 |

## 测试组件

```go
import (
    "github.com/stretchr/testify/assert"
    "net/http/httptest"
)

// Echo handler 测试
func TestGetUser(t *testing.T) {
    e := echo.New()
    req := httptest.NewRequest(http.MethodGet, "/users/1", nil)
    rec := httptest.NewRecorder()
    c := e.NewContext(req, rec)
    c.SetPath("/users/:id")
    c.SetParamNames("id")
    c.SetParamValues("1")

    err := handler.GetUser(c)
    assert.NoError(t, err)
    assert.Equal(t, 200, rec.Code)
}
```

## 禁止事项

- **禁止** 在 handler 中直接使用 `ent.Client` 或 `*sqlx.DB`。
- **禁止** 使用 `panic` 处理业务错误。
- **禁止** 硬编码配置值。
- **禁止** ent 的 `AutoMigrate` 用于生产环境（用 atlas 版本化迁移）。
