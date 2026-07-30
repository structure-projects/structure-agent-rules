# Actix-web Rust 后端 — AI 规则索引

> 本文件是 Codex 安装目标项目时合并到根 `AGENTS.md` 的内容。

## 技术栈
actix-web 4.x / actix-rt / sqlx / serde / thiserror / tracing-actix-web / utoipa

## 关键规则速查
- **硬约束**：`unwrap()` 禁止用于业务错误；Handler 不写业务逻辑；Service 不引用 `actix_web` 类型；禁止全局 static 依赖
- **分层**：`handlers → services → repositories → models`
- **错误**：`thiserror` 定义 `AppError` → `ResponseError` trait 统一转换
- **数据库**：`sqlx::query_as!` 编译时 SQL 校验；同步操作用 `web::block`
- **状态注入**：`web::Data<T>` + `app_data()`
- **中间件**：`App::wrap()` 注册；`actix-cors` 处理 CORS
- **测试**：`#[actix_rt::test]` + `actix_web::test` + `tests/` 集成测试（真实 DB）
- **配置**：`config` crate + 环境变量，禁止硬编码
- **API 文档**：`utoipa` + `utoipa-swagger-ui`
- **校验**：`validator` crate + handler 内手动触发校验
- **HTTP 客户端**：`awc`（actix actors 客户端）

完整规范见 `.structure-rules/prompts/` 目录下各 `.md` 文件：
- `developer.md` — 开发规范（分层、错误处理、数据库）
- `architect.md` — 架构设计（模块划分、技术选型、API 设计）
- `reviewer.md` — 评审规范（硬性驳回项、常见陷阱）
- `tester.md` — 测试规范（单元测试、集成测试、Mock 边界）
- `components.md` — 组件参考（中间件、提取器、认证、Redis、awc）
- `project-scaffolding.md` — 项目脚手架（Cargo.toml、目录结构）
- `swagger.md` — API 文档规范（utoipa 注解）
- `validation.md` — 参数校验规范（validator crate）
- `ci-cd.md` — CI/CD 流水线（GitHub Actions、Docker）
