# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 本仓库的定位（重要）

`structure-agent-rules` **不是业务代码仓库**，它是 [structure-projects](https://github.com/structure-projects) 开源生态的 **AI 规则与提示词工程仓库**。

本仓库的产出物是 **规则文件、Agent 提示词、生态说明文档**，不产出可运行的业务代码。

## Gin 技术栈概览

Gin 是 Go 语言的高性能 HTTP Web 框架。本规则适用于使用 Gin + GORM 技术栈的 Go 后端项目。

### 核心依赖版本

| 依赖 | 用途 |
|---|---|
| `github.com/gin-gonic/gin` | Web 框架 |
| `gorm.io/gorm` | ORM |
| `gorm.io/driver/postgres` (或 mysql/sqlite) | 数据库驱动 |
| `github.com/spf13/viper` | 配置管理 |
| `go.uber.org/zap` | 结构化日志 |
| `github.com/go-playground/validator/v10` | 请求校验 |
| `github.com/golang-jwt/jwt/v5` | JWT 认证 |
| `github.com/swaggo/swag` + `github.com/swaggo/gin-swagger` | API 文档 |
| `github.com/stretchr/testify` | 测试断言 |
| `github.com/google/wire` | 依赖注入（编译时） |

### 项目结构（标准布局）

```
project/
├── cmd/server/main.go           # 入口，组装依赖
├── internal/
│   ├── handler/                 # Gin handlers + middleware
│   ├── service/                 # 业务逻辑接口
│   │   └── impl/                # 实现
│   ├── repository/              # 数据访问接口
│   │   └── gorm/                # GORM 实现
│   ├── model/                   # 领域实体、错误定义
│   ├── config/                  # Viper 配置结构体
│   └── router/                  # 路由注册
├── pkg/                         # 可复用公共库
├── migrations/                  # 数据库迁移 SQL
├── configs/                     # YAML 配置文件
├── Makefile
├── Dockerfile
└── go.mod
```

### 分层架构

依赖方向（内层不依赖外层）：

```
handler（HTTP 层） → service（业务层） → repository（数据层）
           ↓                    ↓
        model（领域模型，无外部依赖）
```

**关键约束**：
- Handler 只做：绑定参数 → 调用 service → 渲染响应
- Service 接口定义 + 实现分离，第一参数为 `context.Context`
- Repository 接口在 `repository/` 包，GORM 实现在子包
- Model 层禁止引用任何框架类型

### 关键优先级

1. **依赖注入**：构造器注入（`NewXxx(dep) *Xxx`）→ Wire → 禁止全局变量
2. **错误处理**：哨兵错误 → `AppError` 结构体 → `fmt.Errorf(": %w", err)` 包装
3. **配置管理**：Viper → 类型安全结构体 → 环境变量覆盖

### 命名约定

| 类型 | 模式 |
|---|---|
| Handler | `{X}Handler` |
| Service 接口 | `{X}Service`（interface） |
| Service 实现 | `{x}ServiceImpl`（struct，小写开头） |
| Repository 接口 | `{X}Repository`（interface） |
| Repository GORM 实现 | `{x}RepoGorm`（struct，小写开头） |
| Model | `{X}`（无前后缀） |
| 请求 DTO | `Create{X}Req` / `Update{X}Req` / `{X}Query` |
| 响应 VO | `{X}Resp` / `{X}VO` |

### 测试

- 单元测试：`xxx_test.go`（同包），使用 testify mock
- Handler 测试：`httptest` + `gin.CreateTestContext`
- 集成测试：`xxx_integration_test.go` + `//go:build integration`，使用 Testcontainers

### 构建

```makefile
build:
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
        -ldflags="-s -w -X main.Version=$(VERSION)" \
        -o bin/server ./cmd/server
```

### 本目录文件结构

- **`prompts/<role>.md`** — 各角色规则的 single source of truth
- **`.cursor/rules/<role>.mdc`** — Cursor 规则包装
- **`AGENTS.md`** — 规则索引
- **`CLAUDE.md`** — 本文件
- **`codex/AGENTS.md`** — Codex 合并规则

### 维护约定

- 修改规则时 **先改 `prompts/`**，再同步包装文件中的内联摘要
- 规则使用 RFC 2119 关键词标注强制级别
- 引用 Go 标准库或第三方库版本时，以各库最新稳定版为准
