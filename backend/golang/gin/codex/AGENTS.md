# AGENTS.md — Gin 项目规则

> 本文件是 **Codex / 通用 AI Agent** 在 Gin 项目中的工作规则。
> 由 [structure-agent-rules](https://github.com/structure-projects/structure-agent-rules) 仓库的 `codex/AGENTS.md` 模板复制而来。
>
> **使用方式**：将本文件放在业务项目根目录，Codex 启动时自动加载。
> **详细规则**（如能访问 structure-agent-rules 仓库）：`prompts/developer.md` / `prompts/architect.md` / `prompts/components.md` / `prompts/tester.md` / `prompts/reviewer.md` / `prompts/validation.md` / `prompts/swagger.md` / `prompts/ci-cd.md`。

---

## 1. 硬约束（任何任务都必须遵守）

- Go 版本 MUST >= 1.21（推荐 1.23+），使用 `go.mod` 管理依赖。
- 包名 MUST 全部小写、单数、无下划线、无驼峰。
- 导出符号 MUST 有文档注释（`// FuncName does X.`）。
- 错误 MUST 被处理（`errcheck` 零容忍），禁止 `_ = someFunc()` 吞错误。
- 项目 MUST 遵循 Go 标准布局：`cmd/`、`internal/`、`pkg/`。

## 2. 模块布局（Clean Architecture）

```
project/
├── cmd/server/main.go           # 入口，组装依赖
├── internal/
│   ├── handler/                 # Gin handlers
│   │   └── middleware/          # 中间件
│   ├── service/                 # 业务逻辑接口
│   │   └── impl/                # 实现
│   ├── repository/              # 数据访问接口
│   │   └── gorm/                # GORM 实现
│   ├── model/                   # 领域模型、错误定义
│   ├── config/                  # 配置结构体与加载
│   └── router/                  # 路由注册
├── pkg/                         # 可复用的公共库
├── migrations/                  # 数据库迁移脚本
├── configs/                     # 配置文件（YAML）
├── Makefile
├── Dockerfile
└── go.mod
```

依赖方向：`handler → service → repository → model`（model 无外部依赖）。**禁止** 反向 / 跨层依赖。

## 3. 关键优先级（顺序不可乱）

- **依赖注入**：构造器注入（`NewXxx(dep) *Xxx`）→ Wire（编译时生成）→ **禁止** 全局变量持有依赖。
- **错误处理**：哨兵错误（`var ErrNotFound = errors.New(...)`）→ `AppError` 结构体（携带业务码）→ `fmt.Errorf("...: %w", err)` 包装。
- **JSON**：使用 `encoding/json`（标准库），**禁止** 混用第三方 JSON 库。

## 4. 持久化（GORM）

- **MUST** Repository 接口定义在 `repository/` 包，GORM 实现在 `repository/gorm/` 子包。
- **MUST** 所有数据库操作使用 `db.WithContext(ctx)` 传递上下文。
- **MUST** 将 `gorm.ErrRecordNotFound` 映射为业务哨兵错误（`ErrNotFound`）。
- **MUST** 生产环境使用版本化迁移工具（`golang-migrate`），**禁止** `AutoMigrate`。
- **MUST** 显式设置连接池参数：
  ```go
  sqlDB, _ := db.DB()
  sqlDB.SetMaxOpenConns(100)
  sqlDB.SetMaxIdleConns(10)
  sqlDB.SetConnMaxLifetime(time.Hour)
  ```
- **禁止** 在 Service/Handler 中直接注入 `*gorm.DB`。

## 5. Handler 规范

- **MUST** Handler 只做三件事：绑定参数 → 调用 service → 渲染响应。
- **MUST** 使用 `c.Request.Context()` 传递上下文给 service 层。
- **MUST** 参数校验使用 `binding` 标签（`go-playground/validator`）。
- **禁止** 在 handler 中编写业务逻辑、直接操作数据库。
- **禁止** 使用 `panic` 处理请求级错误。

```go
func (h *UserHandler) GetByID(c *gin.Context) {
    id, err := strconv.ParseInt(c.Param("id"), 10, 64)
    if err != nil {
        c.JSON(400, ErrorResponse{Code: 40001, Message: "invalid id"})
        return
    }
    user, err := h.userService.GetByID(c.Request.Context(), id)
    if err != nil {
        if errors.Is(err, ErrNotFound) {
            c.JSON(404, ErrorResponse{Code: 40401, Message: "user not found"})
            return
        }
        c.JSON(500, ErrorResponse{Code: 50000, Message: "internal error"})
        return
    }
    c.JSON(200, user)
}
```

## 6. Service 规范

- **MUST** 定义接口（interface），实现放独立 struct。
- **MUST** 使用 `context.Context` 作为第一个参数。
- **MUST** 使用 `fmt.Errorf("...: %w", err)` 包装错误，保留调用链。
- **禁止** 引用 `gin.Context` 或任何 HTTP 框架类型。

## 7. 命名约定

| 类型 | 模式 |
|---|---|
| Handler | `{X}Handler`（struct） |
| Service 接口 | `{X}Service`（interface） |
| Service 实现 | `{x}ServiceImpl`（struct，小写开头） |
| Repository 接口 | `{X}Repository`（interface） |
| Repository GORM 实现 | `{x}RepoGorm`（struct，小写开头） |
| Model | `{X}`（无前后缀） |
| 请求 DTO | `Create{X}Req` / `Update{X}Req` / `{X}Query` |
| 响应 VO | `{X}Resp` / `{X}VO` |
| 错误 | `ErrXxx`（哨兵错误）/ `AppError`（业务错误） |

## 8. 错误处理

- **MUST** 在 `model/errors.go` 统一定义哨兵错误：`ErrNotFound`、`ErrDuplicate`、`ErrUnauthorized`、`ErrForbidden`。
- **MUST** handler 层捕获所有错误，转换为 HTTP 状态码。
- **SHOULD** 定义 `AppError` 结构体，携带业务错误码和消息。
- **禁止** 返回裸 `errors.New("something wrong")`。
- **禁止** 使用 `panic` 处理请求级错误（仅用于不可恢复的初始化失败）。

## 9. 配置管理

- **MUST** 使用 Viper 统一管理配置，支持 YAML + 环境变量覆盖。
- **MUST** 定义类型安全的配置结构体。
- **MUST** 按环境拆分配置文件：`config.dev.yaml`、`config.prod.yaml`。
- **禁止** 硬编码数据库连接串、端口号、密钥等。

## 10. 中间件

- **MUST** 注册 Recovery 中间件（`gin.Recovery()`）。
- **MUST** CORS 中间件白名单配置，**禁止** 生产环境使用 `*` 通配符。
- **MUST** JWT 认证中间件放在需要认证的路由组上。
- **SHOULD** 启用 Request ID 中间件（链路追踪）。

## 11. API 文档（Swagger）

- **MUST** 使用 swaggo/swag 生成 OpenAPI 文档。
- **MUST** 每个公开 API handler 有完整的 Swagger 注解。
- **MUST** `swag init` 生成的 `docs/` 目录纳入版本管理。
- **SHOULD** 生产环境通过配置开关控制 Swagger UI 可见性。

## 12. 测试

### 测试工作流（MUST —— 与开发同步进行）

- **MUST** 每开发一个功能，**立即**编写对应单元测试；**单测通过后才能开始下一个功能**。
- **MUST** 功能代码有修改时，**同步修改对应测试代码**并保证通过。
- **MUST** 业务模块编写完成后，编写 **业务流程集成测试**，通过后业务才算交付。
- **MUST** 提交代码前：`go test -race ./...` 全部通过 + `go build ./cmd/server` 编译通过。
- **禁止** 在测试失败或编译失败的情况下提交/合入/发布代码。

### 测试分层与有效性

- `xxx_test.go`（同包）— 单元测试，不启动外部依赖。
- `xxx_integration_test.go` + `//go:build integration` — 集成测试，**必须** 用真实中间件（Testcontainers）。
- **禁止** Mock 数据库 / Redis / MQ；**允许** Mock 自己项目的 Repository/Service 接口。
- **MUST** 覆盖：正常路径 + 异常路径 + 边界条件。
- **MUST** 断言有效（验证行为与数据）；**禁止** 僵尸断言（只 `assert.NotNil` / 只看返回码 200）。
- **禁止** `time.Sleep` 等待异步（用 `sync.WaitGroup` 或 channel）。
- **禁止** 无注释说明的 `t.Skip`。

## 13. CI/CD

- **MUST** CI 流水线阶段：Lint → Test → Build → Image。
- **MUST** 使用 `golangci-lint`，至少启用：`govet`、`staticcheck`、`errcheck`、`gosimple`、`ineffassign`。
- **MUST** `go test -race -coverprofile=coverage.out ./...`，覆盖率 >= 70%。
- **MUST** 使用多阶段 Docker 构建，`CGO_ENABLED=0` 编译静态二进制。
- **MUST** Docker 运行阶段使用 `alpine`，非 root 用户。

## 14. 提交前自检

- [ ] 包名是否全部小写、单数、无下划线？
- [ ] 导出符号是否有文档注释？
- [ ] Handler 是否只做绑定 → 调用 → 渲染？
- [ ] Service 是否定义接口？是否使用 context.Context？
- [ ] Repository 是否将 gorm.ErrRecordNotFound 映射为业务错误？
- [ ] 错误是否使用预定义哨兵错误或 AppError？
- [ ] 依赖是否通过构造器注入？
- [ ] 配置是否通过 Viper 加载，无硬编码？
- [ ] 数据库连接池参数是否显式设置？
- [ ] **本次开发的功能是否都有对应单元测试并通过？**
- [ ] **修改的既有功能，其测试是否已同步更新并通过？**
- [ ] **业务流程完成后是否有流程级集成测试并通过？**
- [ ] **本地 `go test -race ./...` 全部通过 + `go build ./cmd/server` 编译通过？**

---

**详细规则**（如能访问 structure-agent-rules 仓库）：`prompts/developer.md` / `prompts/components.md` / `prompts/tester.md` / `prompts/reviewer.md` / `prompts/architect.md` / `prompts/project-scaffolding.md` / `prompts/validation.md` / `prompts/swagger.md` / `prompts/ci-cd.md` / `CLAUDE.md`。
