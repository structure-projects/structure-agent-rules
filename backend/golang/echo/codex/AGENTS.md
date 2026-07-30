# AGENTS.md — Echo 项目规则

> 本文件是 **Codex / 通用 AI Agent** 在 Echo 项目中的工作规则。
> **详细规则**：`prompts/developer.md` / `prompts/architect.md` / `prompts/components.md` / `prompts/tester.md` / `prompts/reviewer.md` / `prompts/validation.md` / `prompts/swagger.md` / `prompts/ci-cd.md`。

---

## 1. 硬约束

- Go 版本 MUST >= 1.21，使用 `go.mod` 管理依赖。
- 包名 MUST 全部小写、单数、无下划线、无驼峰。
- 导出符号 MUST 有文档注释。
- 错误 MUST 被处理，禁止 `_ = someFunc()` 吞错误。

## 2. 模块布局

```
project/
├── cmd/server/main.go
├── internal/
│   ├── handler/          # Echo handlers (func(c echo.Context) error)
│   ├── middleware/        # 自定义中间件
│   ├── service/ + impl/  # 业务逻辑
│   ├── repository/       # 数据接口 + ent/ + sqlx/
│   ├── model/            # 领域模型
│   ├── config/           # 配置
│   └── router/           # 路由注册
├── ent/schema/           # ent schema
├── migrations/           # 数据库迁移
├── configs/              # YAML 配置
├── Makefile
├── Dockerfile
└── go.mod
```

依赖方向：`handler → service → repository → model`。

## 3. 关键优先级

- **DI**：构造器注入 → Wire → 禁止全局变量
- **错误**：哨兵错误 → AppError → `fmt.Errorf(": %w", err)`
- **JSON**：`encoding/json`（标准库）

## 4. Handler 规范（Echo 专属）

```go
func (h *UserHandler) GetByID(c echo.Context) error {
    id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
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

- **MUST** handler 返回 `error`
- **MUST** 使用 `c.Request().Context()` 传递上下文
- **MUST** 自定义 `e.HTTPErrorHandler` 统一错误响应
- **MUST** 注册 `e.Validator` 校验器

## 5. 持久化

### ent 方案
```go
// Repository 实现
func (r *userRepoEnt) FindByID(ctx context.Context, id int64) (*model.User, error) {
    u, err := r.client.User.Get(ctx, id)
    if ent.IsNotFound(err) {
        return nil, ErrNotFound
    }
    return toModel(u), err
}
```

### sqlx 方案
```go
func (r *userRepoSqlx) FindByID(ctx context.Context, id int64) (*model.User, error) {
    var user model.User
    err := r.db.GetContext(ctx, &user, "SELECT * FROM users WHERE id = $1", id)
    if errors.Is(err, sql.ErrNoRows) {
        return nil, ErrNotFound
    }
    return &user, err
}
```

## 6. 命名约定

| 类型 | 模式 |
|---|---|
| Handler | `{X}Handler` |
| Service 接口 | `{X}Service`（interface） |
| Service 实现 | `{x}ServiceImpl`（struct） |
| Repository 接口 | `{X}Repository`（interface） |
| ent 实现 | `{x}RepoEnt` |
| sqlx 实现 | `{x}RepoSqlx` |
| Model | `{X}` |

## 7. 错误处理

```go
var (
    ErrNotFound     = errors.New("resource not found")
    ErrDuplicate    = errors.New("resource already exists")
)

type AppError struct {
    Code       int    `json:"code"`
    Message    string `json:"message"`
    HTTPStatus int    `json:"-"`
}
```

## 8. Echo 中间件

- **MUST** Recover（panic 恢复）
- **MUST** BodyLimit（防大请求攻击）
- **MUST** CORS（白名单，禁止生产 `*`）
- **SHOULD** RequestID（链路追踪）
- **SHOULD** Timeout（超时控制）

## 9. 测试

- 单测：`xxx_test.go`（同包），testify mock
- Handler 测试：`httptest` + `e.NewContext(req, rec)`
- 集成测试：`//go:build integration`，Testcontainers
- **MUST** 覆盖率 >= 70%
- **禁止** 僵尸断言、`time.Sleep`、Mock 数据库

## 10. 提交前自检

- [ ] 包名全部小写、单数、无下划线？
- [ ] 导出符号有文档注释？
- [ ] Handler 只做绑定→调用→渲染？返回 error？
- [ ] 自定义了 HTTPErrorHandler？
- [ ] 注册了 Validator？
- [ ] Recover + BodyLimit 中间件已注册？
- [ ] 依赖通过构造器注入？
- [ ] `go test -race ./...` 全部通过？
- [ ] `go build ./cmd/server` 编译通过？

---

**详细规则**：`prompts/developer.md` / `prompts/components.md` / `prompts/tester.md` / `prompts/reviewer.md` / `prompts/architect.md` / `prompts/project-scaffolding.md` / `prompts/validation.md` / `prompts/swagger.md` / `prompts/ci-cd.md` / `CLAUDE.md`。
