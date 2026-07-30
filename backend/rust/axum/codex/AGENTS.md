# Axum Rust 后端 — AI 规则索引

> 本文件是 Codex 安装目标项目时合并到根 `AGENTS.md` 的内容。

## 技术栈
axum 0.7+ / tokio / tower / sqlx / serde / thiserror / tracing / utoipa

## 关键规则速查
- **硬约束**：`unwrap()` 禁止用于业务错误；Handler 不写业务逻辑；Service 不引用 HTTP 类型；禁止全局 static 依赖
- **分层**：`routes → services → repositories → models`
- **错误**：`thiserror` 定义 `AppError` → `IntoResponse` 统一转换
- **数据库**：`sqlx::query_as!` 编译时 SQL 校验
- **测试**：`#[cfg(test)]` 单元测试 + `tests/` 集成测试（真实 DB）
- **配置**：`config` crate + 环境变量，禁止硬编码
- **API 文档**：`utoipa` + `utoipa-swagger-ui`
- **校验**：`validator` crate + 自定义 `ValidJson` 提取器

完整规范见 `.structure-rules/prompts/` 目录下各 `.md` 文件：
- `developer.md` — 开发规范（分层、错误处理、数据库）
- `architect.md` — 架构设计（模块划分、技术选型、API 设计）
- `reviewer.md` — 评审规范（硬性驳回项、常见陷阱）
- `tester.md` — 测试规范（单元测试、集成测试、Mock 边界）
- `components.md` — 组件参考（中间件、提取器、认证、Redis）
- `project-scaffolding.md` — 项目脚手架（Cargo.toml、目录结构）
- `swagger.md` — API 文档规范（utoipa 注解）
- `validation.md` — 参数校验规范（validator crate）
- `ci-cd.md` — CI/CD 流水线（GitHub Actions、Docker）
