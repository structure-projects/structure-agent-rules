# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 本仓库的定位（重要）

`structure-agent-rules` **不是业务代码仓库**，它是 [structure-projects](https://github.com/structure-projects) 开源生态的 **AI 规则与提示词工程仓库**。目标是：

1. 让 AI（Claude Code / Cursor / 其他 Agent）能快速理解 FastAPI 生态并正确选型。
2. 用规则与提示词约束 AI 在 FastAPI 项目内的 **设计、开发、测试、评审** 行为，使其符合社区规范。

本仓库的产出物是 **规则文件、Agent 提示词、生态说明文档**，不产出可运行的业务代码。

## FastAPI 技术栈核心约束

| 维度 | 值 |
|---|---|
| **Python 版本** | ≥ 3.10 |
| **Web 框架** | FastAPI ≥ 0.110.0 |
| **ASGI 服务器** | Uvicorn ≥ 0.27.0 |
| **ORM** | SQLAlchemy 2.0（异步 API） |
| **数据库驱动** | asyncpg |
| **数据验证** | Pydantic v2 |
| **迁移工具** | Alembic |
| **配置管理** | pydantic-settings |
| **日志** | structlog |
| **测试框架** | pytest + httpx + TestClient |
| **包管理** | Poetry 或 pip + pyproject.toml |
| **后台任务** | Celery（Redis/RabbitMQ）或 ARQ |

## 架构约定

- **MUST** 采用 router → service → repository 三层架构。
- **MUST** 所有端点使用 `async def`。
- **MUST** 数据库操作使用 SQLAlchemy 2.0 异步 API。
- **MUST** 使用 `APIRouter` 按业务领域拆分路由。
- **MUST** 使用 `Depends()` 进行依赖注入。
- **MUST** API 版本化使用 URL 前缀：`/api/v1/`。

## 关键优先级

- **类型注解**：所有函数必须完整注解，`mypy --strict` 通过。
- **数据验证**：Pydantic v2 模型，`Field()` 声明约束。
- **错误处理**：`HTTPException` + 全局异常处理器。
- **日志**：structlog 结构化日志，JSON 输出到 stdout。
- **安全**：JWT + bcrypt，敏感配置从环境变量读取。

## 本目录文件结构

- **`prompts/<role>.md`** — 各角色规则的 single source of truth（工具无关）。
- **`fastapi-*.mdc`** — Cursor 规则包装，含 `globs` 与 `alwaysApply` 配置。
- **`AGENTS.md`** — 规则索引、使用方式、维护约定。
- **`CLAUDE.md`** — 本文件，Claude Code 入口。
- **`codex/AGENTS.md`** — Codex 通用 Agent 规则。

## 本仓库工作方式

- **没有构建、lint、测试命令** —— 产出物是 Markdown 规则与提示词。
- 新增规则时：写清 **目标读者、适用仓库范围、强制级别（MUST / SHOULD / MAY）**。
- 修改规则时 **先改 `prompts/`**，再评估是否同步包装文件中的内联摘要。
- 规则应尽量 **工具中立**，不绑定特定厂商。
