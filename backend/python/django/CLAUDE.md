# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 本仓库的定位（重要）

`structure-agent-rules` **不是业务代码仓库**，它是 [structure-projects](https://github.com/structure-projects) 开源生态的 **AI 规则与提示词工程仓库**。目标是：

1. 让 AI（Claude Code / Cursor / 其他 Agent）能快速理解 Django 生态并正确选型。
2. 用规则与提示词约束 AI 在 Django 项目内的 **设计、开发、测试、评审** 行为，使其符合社区规范。

本仓库的产出物是 **规则文件、Agent 提示词、生态说明文档**，不产出可运行的业务代码。

## Django 技术栈核心约束

| 维度 | 值 |
|---|---|
| **Python 版本** | ≥ 3.10 |
| **Web 框架** | Django ≥ 4.2 LTS |
| **API 框架** | Django REST Framework (DRF) |
| **数据库** | PostgreSQL (psycopg2) |
| **后台任务** | Celery + Redis/RabbitMQ |
| **测试** | pytest-django + model_bakery |
| **文档** | drf-spectacular (OpenAPI 3.0) |
| **包管理** | pip + requirements/ 或 Poetry |

## 架构约定

- **MUST** 按业务领域拆分 Django App。
- **MUST** View → Service → Model 分层，View 层不包含业务逻辑。
- **MUST** 使用 DRF `ModelViewSet` + `Router` 构建 RESTful API。
- **MUST** API 版本化使用 URL 前缀：`/api/v1/`。
- **MUST** 使用 `select_related()` / `prefetch_related()` 避免 N+1 查询。
- **MUST** Celery 处理后台任务，任务幂等设计。

## 关键优先级

- **安全**：`DEBUG=False`、CSRF/CORS/HTTPS Cookie 配置。
- **ORM**：QuerySet 链式调用、关联预加载、避免 N+1。
- **验证**：DRF Serializer + Model validators。
- **迁移**：每次模型变更生成迁移文件，纳入版本控制。
- **测试**：pytest-django + API 测试 + 覆盖率 ≥ 80%。

## 本目录文件结构

- **`prompts/<role>.md`** — 各角色规则的 single source of truth（工具无关）。
- **`django-*.mdc`** — Cursor 规则包装，含 `globs` 与 `alwaysApply` 配置。
- **`AGENTS.md`** — 规则索引、使用方式、维护约定。
- **`CLAUDE.md`** — 本文件，Claude Code 入口。
- **`codex/AGENTS.md`** — Codex 通用 Agent 规则。
