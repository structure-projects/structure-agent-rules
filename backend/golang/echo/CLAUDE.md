# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 本仓库的定位（重要）

`structure-agent-rules` **不是业务代码仓库**，它是 [structure-projects](https://github.com/structure-projects) 开源生态的 **AI 规则与提示词工程仓库**。

## Echo 技术栈概览

Echo 是 Go 语言的高性能、极简 Web 框架，以简洁 API 和丰富内置功能著称。本规则适用于使用 Echo + ent/sqlx 技术栈的 Go 后端项目。

### 核心依赖

| 依赖 | 用途 |
|---|---|
| `github.com/labstack/echo/v4` | Web 框架 |
| `entgo.io/ent` | 代码生成 ORM |
| `github.com/jmoiron/sqlx` | 轻量 SQL 库（替代方案） |
| `github.com/spf13/viper` | 配置管理 |
| `github.com/rs/zerolog` | 高性能结构化日志 |
| `github.com/go-playground/validator/v10` | 请求校验 |
| `github.com/golang-jwt/jwt/v5` | JWT 认证 |
| `github.com/swaggo/swag` + `github.com/swaggo/echo-swagger` | API 文档 |
| `github.com/stretchr/testify` | 测试 |
| `github.com/google/wire` | 编译时依赖注入 |

### 项目结构

```
project/
├── cmd/server/main.go
├── internal/
│   ├── handler/          # Echo handlers (func(c echo.Context) error)
│   ├── middleware/        # 自定义中间件
│   ├── service/          # 业务接口 + impl/
│   ├── repository/       # 数据接口 + ent/ + sqlx/
│   ├── model/            # 领域模型
│   ├── config/           # Viper 配置
│   └── router/           # 路由注册
├── ent/schema/           # ent schema 定义
├── migrations/           # 数据库迁移
├── configs/              # YAML 配置
├── Makefile
└── Dockerfile
```

### Echo 与 Gin 的关键差异

| 特性 | Echo | Gin |
|---|---|---|
| Handler 签名 | `func(c echo.Context) error` | `func(c *gin.Context)` |
| 绑定 | `c.Bind(&req)` 自动检测 Content-Type | `c.ShouldBindJSON(&req)` |
| 校验器 | 通过 `e.Validator` 接口注册 | `binding` 标签内置 |
| 错误处理 | 自定义 `e.HTTPErrorHandler` | Recovery 中间件 |
| Context | `c.Request().Context()` | `c.Request.Context()` |

### 关键约束

1. **Handler 返回 error**：Echo handler 返回 `error`，不是 `void`
2. **自定义 HTTPErrorHandler**：MUST 自定义统一错误响应格式
3. **Validator 注册**：通过 `e.Validator` 接口注册 `go-playground/validator`
4. **ent 代码生成**：schema 在 `ent/schema/`，运行 `go generate ./ent`
5. **中间件链**：Recover → Logger → RequestID → CORS → Auth → RateLimit

### 本目录文件结构

- **`prompts/<role>.md`** — 各角色规则的 single source of truth
- **`.cursor/rules/<role>.mdc`** — Cursor 规则包装
- **`AGENTS.md`** — 规则索引
- **`CLAUDE.md`** — 本文件
- **`codex/AGENTS.md`** — Codex 合并规则
