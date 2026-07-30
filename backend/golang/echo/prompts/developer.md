# Echo 开发规则

> 适用场景：编写 Go/Echo 代码时始终生效。

## 硬约束

- Go 版本 MUST >= 1.21，使用 `go.mod` 管理依赖。
- 包名 MUST 全部小写、单数、无下划线、无驼峰。
- 导出符号 MUST 有文档注释。
- 错误 MUST 被处理（`errcheck` 零容忍）。
- 函数参数 MUST <= 5，超过用 struct 封装。

## 代码风格

- **MUST** 使用 `gofmt` / `goimports` 格式化代码。
- **MUST** 变量命名：驼峰式，缩写全大写（`userID`、`HTTPServer`）。
- **SHOULD** 函数体不超过 50 行。

## Handler 层（HTTP 层）

```go
type UserHandler struct {
    userService service.UserService
}

func NewUserHandler(userService service.UserService) *UserHandler {
    return &UserHandler{userService: userService}
}

func (h *UserHandler) GetUser(c echo.Context) error {
    id, err := strconv.ParseInt(c.Param("id"), 10, 64)
    if err != nil {
        return c.JSON(400, ErrorResponse{Code: 40001, Message: "invalid id"})
    }
    user, err := h.userService.GetByID(c.Request().Context(), id)
    if err != nil {
        if errors.Is(err, ErrNotFound) {
            return c.JSON(404, ErrorResponse{Code: 40401, Message: "not found"})
        }
        return c.JSON(500, ErrorResponse{Code: 50000, Message: "internal error"})
    }
    return c.JSON(200, user)
}
```

**Handler 约束**：
- **MUST** 只做三件事：绑定参数 → 调用 service → 渲染响应。
- **MUST** 使用 `c.Request().Context()` 传递上下文。
- **MUST** 返回 `error`（Echo 风格），使用 `c.JSON()` 渲染响应。
- **禁止** 在 handler 中编写业务逻辑、直接操作数据库。

## Service 层

```go
type UserService interface {
    GetByID(ctx context.Context, id int64) (*model.User, error)
    Create(ctx context.Context, req *CreateUserReq) (*model.User, error)
}

type userServiceImpl struct {
    userRepo repository.UserRepository
}

func NewUserService(userRepo repository.UserRepository) UserService {
    return &userServiceImpl{userRepo: userRepo}
}
```

**Service 约束**：
- **MUST** 定义接口，实现放独立 struct。
- **MUST** 使用 `context.Context` 作为第一个参数。
- **MUST** 使用 `fmt.Errorf("...: %w", err)` 包装错误。
- **禁止** 引用 `echo.Context` 或任何 HTTP 框架类型。

## Repository 层

```go
// 接口
type UserRepository interface {
    FindByID(ctx context.Context, id int64) (*model.User, error)
    Save(ctx context.Context, user *model.User) error
}

// ent 实现
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

// sqlx 实现
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

**Repository 约束**：
- **MUST** 接口在 `repository/` 包，实现在子包（`ent/`、`sqlx/`）。
- **MUST** 将框架级 "not found" 映射为业务哨兵错误。
- **禁止** 在 repository 中编写业务逻辑。

## Echo 专属特性

### 自定义 Binder

```go
type CustomBinder struct{}

func (cb *CustomBinder) Bind(i interface{}, c echo.Context) error {
    // 先使用默认 binder
    if err := new(echo.DefaultBinder).Bind(i, c); err != nil {
        return err
    }
    // 额外校验
    if v, ok := i.(interface{ Validate() error }); ok {
        return v.Validate()
    }
    return nil
}

e.Binder = &CustomBinder{}
```

### 自定义 HTTPError Handler

```go
e.HTTPErrorHandler = func(err error, c echo.Context) {
    var (
        code = http.StatusInternalServerError
        msg  = "Internal Server Error"
    )
    if he, ok := err.(*echo.HTTPError); ok {
        code = he.Code
        msg = fmt.Sprintf("%v", he.Message)
    }
    if appErr, ok := err.(*AppError); ok {
        code = appErr.HTTPStatus
        msg = appErr.Message
    }
    c.JSON(code, ErrorResponse{Code: code, Message: msg})
}
```

## 错误处理

```go
var (
    ErrNotFound     = errors.New("resource not found")
    ErrDuplicate    = errors.New("resource already exists")
    ErrUnauthorized = errors.New("unauthorized")
)

type AppError struct {
    Code       int    `json:"code"`
    Message    string `json:"message"`
    HTTPStatus int    `json:"-"`
}

func (e *AppError) Error() string { return e.Message }
```

## 依赖注入

- **MUST** 使用构造器注入。
- **SHOULD** 使用 Wire 编译时生成依赖注入代码。
- **禁止** 使用全局变量持有依赖。

## 数据库迁移

- **MUST** 使用版本化迁移工具（atlas 或 golang-migrate）。
- **禁止** 使用 `AutoMigrate` 用于生产环境。

## 测试工作流（MUST）

- 每开发一个功能 **立即** 写单元测试，**单测通过才能做下一个功能**。
- 功能有修改时 **同步修改测试** 并通过。
- 业务完成后写 **业务流程集成测试**，通过才算交付。
- **提交前**：`go test -race ./...` 全部通过 + `go build ./cmd/server` 编译通过。
- **禁止** 测试/编译失败仍提交。

## 提交前自检

- [ ] 所有导出符号是否有文档注释？
- [ ] handler 是否只做绑定→调用→渲染？
- [ ] service 接口是否定义？是否使用 context.Context？
- [ ] 错误是否使用预定义哨兵错误或 AppError？
- [ ] 依赖是否通过构造器注入？
- [ ] Echo 是否配置了自定义 HTTPErrorHandler？
- [ ] `go test -race ./...` 是否全部通过？
- [ ] `golangci-lint run` 是否无错误？
