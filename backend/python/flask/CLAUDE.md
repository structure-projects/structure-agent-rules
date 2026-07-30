# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 本仓库的定位（重要）

`structure-agent-rules` **不是业务代码仓库**，它是 [structure-projects](https://github.com/structure-projects) 开源生态的 **AI 规则与提示词工程仓库**。目标是：

1. 让 AI（Claude Code / Cursor / 其他 Agent）能快速理解 Flask 生态并正确选型。
2. 用规则与提示词约束 AI 在 Flask 项目内的 **设计、开发、测试、评审** 行为，使其符合社区规范。

本仓库的产出物是 **规则文件、Agent 提示词、生态说明文档**，不产出可运行的业务代码。

## Flask 技术栈核心约束

| 维度 | 值 |
|---|---|
| **Python 版本** | ≥ 3.10 |
| **Web 框架** | Flask ≥ 3.0 |
| **WSGI 服务器** | Gunicorn |
| **ORM** | Flask-SQLAlchemy |
| **迁移** | Flask-Migrate (Alembic) |
| **序列化/验证** | Marshmallow |
| **REST API** | Flask-RESTX 或 Flask-RESTful |
| **认证** | Flask-JWT-Extended / Flask-Login |
| **后台任务** | Celery + Redis |
| **测试** | pytest + pytest-flask |
| **包管理** | pip + requirements/ 或 Poetry |

## 架构约定

- **MUST** 使用 Application Factory 模式（`create_app()` 函数）。
- **MUST** 使用 Blueprints 按业务领域组织路由。
- **MUST** 扩展实例在 `extensions.py` 集中管理，在 `create_app()` 中 `init_app()`。
- **MUST** 使用类继承管理多环境配置。
- **SHOULD** 复杂业务引入 Service 层，Blueprint 路由函数仅处理 HTTP。
- **MUST** 使用 Marshmallow Schema 进行请求验证和响应序列化。

## 关键优先级

- **Application Factory**：`create_app()` + 扩展 `init_app()` + Blueprint 注册。
- **数据库**：Flask-SQLAlchemy + Flask-Migrate，`joinedload()` 避免 N+1。
- **验证**：Marshmallow Schema + `@validates` 自定义验证器。
- **认证**：JWT (`@jwt_required()`) 或 Session (`@login_required`)。
- **上下文**：理解 Application Context 和 Request Context 的区别。

## 本目录文件结构

- **`prompts/<role>.md`** — 各角色规则的 single source of truth（工具无关）。
- **`flask-*.mdc`** — Cursor 规则包装，含 `globs` 与 `alwaysApply` 配置。
- **`AGENTS.md`** — 规则索引、使用方式、维护约定。
- **`CLAUDE.md`** — 本文件，Claude Code 入口。
- **`codex/AGENTS.md`** — Codex 通用 Agent 规则。
