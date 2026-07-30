# Echo 架构与设计规则

> 适用场景：Echo 项目架构设计、模块划分、分层决策、技术选型。

## 硬约束

- Go 版本 MUST >= 1.21（推荐 1.23+），使用 `go.mod` 管理依赖。
- 项目 MUST 遵循 Go 标准项目布局：`cmd/`、`internal/`、`pkg/`。
- 包名 MUST 使用小写、单数、简洁命名，禁止下划线和驼峰。

## 分层架构（Clean Architecture）

依赖方向（内层不依赖外层）：
```
handler（HTTP 层） → service（业务层） → repository（数据层）
           ↓                    ↓
        model（领域模型，无外部依赖）
```

- **handler/**：Echo handler，负责请求绑定、参数校验、响应渲染。**禁止**在 handler 中写业务逻辑。
- **service/**：业务逻辑层，接口定义在 `internal/service/`。
- **repository/**：数据访问接口在 `internal/repository/`，实现放 `internal/repository/ent/` 或 `internal/repository/sqlx/` 等子包。
- **model/**：领域实体、值对象、枚举。**禁止**引用任何框架层类型。

## 目录结构（推荐）

```
project/
├── cmd/server/main.go           # 入口，组装依赖
├── internal/
│   ├── handler/                 # Echo handlers
│   ├── middleware/              # 自定义中间件
│   ├── service/                 # 业务逻辑接口
│   │   └── impl/
│   ├── repository/              # 数据访问接口
│   │   ├── ent/                 # ent 实现
│   │   └── sqlx/                # sqlx 实现
│   ├── model/                   # 领域模型
│   ├── config/                  # 配置结构体与加载
│   └── router/                  # 路由注册
├── ent/                         # ent schema 与生成代码
│   └── schema/                  # ent schema 定义
├── migrations/                  # 数据库迁移（atlas 或 golang-migrate）
├── configs/                     # 配置文件
├── Makefile
├── Dockerfile
└── go.mod
```

## 技术选型（推荐组合）

| 层次 | 推荐方案 | 替代方案 |
|---|---|---|
| Web 框架 | Echo | — |
| ORM | ent（代码生成） | sqlx（轻量）/ GORM |
| 配置管理 | Viper | envconfig |
| 日志 | Zerolog | Zap / Echo 内置 logger |
| 校验 | go-playground/validator | — |
| 依赖注入 | Wire | fx / dig |
| API 文档 | swaggo/echo-swagger | — |
| 测试 | testify + Echo test utils | ginkgo |
| 热重载 | Air | — |

## Echo 路由设计

- **MUST** 使用 `e.Group()` 组织路由，支持路径前缀和中间件分组。
- **MUST** 中间件优先级：Recover → Logger → RequestID → CORS → Auth → RateLimit。
- **SHOULD** API 版本化通过路径前缀：`/api/v1/`。

```go
func SetupRouter() *echo.Echo {
    e := echo.New()
    e.Use(middleware.Recover())
    e.Use(middleware.Logger())
    e.Use(middleware.RequestID())

    v1 := e.Group("/api/v1")
    v1.Use(middleware.JWT([]byte(cfg.JWT.Secret)))
    // 注册业务路由
    return e
}
```

## Echo 核心特性

- **Binder**：Echo 内置 `DefaultBinder` 支持 JSON/XML/Form/Query 绑定，MUST 使用 `c.Bind(&req)`。
- **Renderer**：自定义响应渲染器，统一 JSON 响应格式。
- **HTTPError**：Echo 的 `echo.HTTPError` 用于 HTTP 层面错误，业务错误 SHOULD 定义自定义类型。
- **Validator**：集成 `go-playground/validator`，通过 `e.Validator = &CustomValidator{validator: validator.New()}` 注册。
- **Context**：`echo.Context` 提供比 `gin.Context` 更丰富的功能，如 `c.JSON()`、`c.Bind()`、`c.Param()` 等。

## ent 数据访问

```go
// ent/schema/user.go —— schema 定义
type User struct {
    ent.Schema
}

func (User) Fields() []ent.Field {
    return []ent.Field{
        field.Int64("id"),
        field.String("username").Unique().NotEmpty(),
        field.String("email").Unique().NotEmpty(),
        field.Time("created_at").Default(time.Now),
    }
}

// repository/ent/user_repo_ent.go —— repository 实现
type userRepoEnt struct {
    client *ent.Client
}

func (r *userRepoEnt) FindByID(ctx context.Context, id int64) (*model.User, error) {
    u, err := r.client.User.Get(ctx, id)
    if ent.IsNotFound(err) {
        return nil, ErrNotFound
    }
    return toModel(u), err
}
```

## sqlx 数据访问

```go
// repository/sqlx/user_repo_sqlx.go
type userRepoSqlx struct {
    db *sqlx.DB
}

func (r *userRepoSqlx) FindByID(ctx context.Context, id int64) (*model.User, error) {
    var user model.User
    err := r.db.GetContext(ctx, &user, "SELECT * FROM users WHERE id = $1", id)
    if errors.Is(err, sql.ErrNoRows) {
        return nil, ErrNotFound
    }
    return &user, err
}
```

## 配置管理

- **MUST** 使用 Viper 统一管理配置。
- **MUST** Echo 配置（端口、超时等）从配置结构体读取，禁止硬编码。

## 错误处理

- **MUST** 定义自定义错误类型，包含错误码和 HTTP 状态码。
- **MUST** handler 层统一处理错误，转换为标准 JSON 响应。
- **禁止** 在 service/repository 层使用 `echo.Context`。

## 安全与中间件

- **MUST** 使用 Echo 内置 CORS 中间件或 `echo-contrib/cors`。
- **MUST** JWT 认证使用 `golang-jwt/jwt/v5` + 自定义中间件。
- **SHOULD** 启用 Rate Limiting 中间件。
- **SHOULD** 启用 Body Limit 中间件防止大请求攻击。

## 性能约束

- **MUST** 数据库连接池参数在生产环境显式配置。
- **SHOULD** Echo Server 配置合理的 `ReadTimeout` / `WriteTimeout`。
- **SHOULD** 对热点查询使用 Redis 缓存。

## 构建与部署

- **MUST** 使用多阶段 Docker 构建。
- **MUST** Makefile 提供 `build`、`test`、`lint`、`run`、`ent-gen` 目标。
- **SHOULD** `CGO_ENABLED=0` 编译静态链接二进制。
