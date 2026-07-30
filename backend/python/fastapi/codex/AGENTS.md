# AGENTS.md — FastAPI 业务项目规则

> 本文件是 **Codex / 通用 AI Agent** 在 FastAPI 业务项目中的工作规则。
> 由 [structure-agent-rules](https://github.com/structure-projects/structure-agent-rules) 仓库的 `codex/AGENTS.md` 模板复制而来。
>
> **使用方式**：将本文件放在业务项目根目录，Codex 启动时自动加载。
> **详细规则**（如能访问 structure-agent-rules 仓库）：`prompts/developer.md` / `prompts/architect.md` / `prompts/components.md` / `prompts/tester.md` / `prompts/reviewer.md` / `prompts/validation.md` / `prompts/swagger.md` / `prompts/ci-cd.md`。

---

## 1. 技术栈硬约束（任何任务都必须遵守）

- Python 版本 ≥ 3.10，使用 `|` 联合类型和 `X | None` 语法。
- FastAPI ≥ 0.110.0 + Uvicorn ≥ 0.27.0。
- SQLAlchemy 2.0 异步 API + asyncpg 驱动。
- Pydantic v2 进行数据验证。
- Alembic 管理数据库迁移。
- structlog 结构化日志。
- pytest + httpx + TestClient 测试。

## 2. 项目结构

```
my-service/
├── app/
│   ├── main.py                  # FastAPI 应用入口
│   ├── api/
│   │   ├── deps.py              # 公共依赖注入
│   │   └── v1/
│   │       ├── router.py        # v1 路由聚合
│   │       └── endpoints/       # 端点模块
│   ├── core/
│   │   ├── config.py            # pydantic-settings
│   │   ├── security.py          # JWT + 密码
│   │   └── logging_config.py    # structlog
│   ├── models/                  # SQLAlchemy ORM 模型
│   ├── schemas/                 # Pydantic 请求/响应模型
│   ├── services/                # 业务逻辑层
│   ├── repositories/            # 数据访问层
│   └── db/
│       ├── session.py           # 异步数据库会话
│       └── migrations/          # Alembic 迁移
├── tests/
│   ├── conftest.py
│   ├── unit/
│   └── integration/
├── alembic.ini
├── pyproject.toml
├── Dockerfile
└── .env.example
```

依赖方向：`router → service → repository → models`。**禁止**反向/跨层依赖。

## 3. 关键优先级（顺序不可乱）

- **类型注解**：所有函数必须完整注解 → `mypy --strict`。
- **异步**：`async def` 端点 → SQLAlchemy 2.0 异步 → `asyncpg`。
- **验证**：Pydantic v2 模型 → `Field()` 约束 → 自定义 `@field_validator`。
- **错误处理**：`HTTPException` → 全局异常处理器 → 自定义业务异常。

## 4. 持久化

- **MUST** 使用 SQLAlchemy 2.0 异步 API：`select(User).where(User.id == id)`。
- **MUST** 使用 `async_session_factory` 管理会话生命周期。
- **MUST** Repository 层封装数据访问，Service 层不直接使用 `session.execute()`。
- **MUST** 使用 `selectinload()` / `joinedload()` 预加载关联数据，避免 N+1 查询。
- **禁止** 在 `async def` 中使用同步 ORM 操作。

## 5. 数据模型规范

- **MUST** 请求/响应使用 Pydantic v2 模型（`model_config = {"from_attributes": True}`）。
- **MUST** 字段使用 `Field()` 声明约束（`min_length`、`max_length`、`gt`、`pattern`）。
- **MUST** 跨字段验证使用 `@model_validator(mode="after")`。
- **MUST** 响应模型排除敏感字段（`password_hash`、`secret_key`）。

## 6. 异常与响应

- **MUST** 使用 `HTTPException` 返回 HTTP 错误（`status_code` + `detail`）。
- **MUST** Service 层抛出自定义业务异常，Router 层或全局处理器转换为 HTTP 响应。
- **SHOULD** 定义全局异常处理器捕获未处理异常。
- **禁止** 返回裸 `{"error": "..."}` 字典。
- **禁止** `try: ... except: pass` 吞掉异常。

## 7. API 出入参与命名

- **MUST** API 入参用 Pydantic 模型：`{Resource}CreateRequest`、`{Resource}UpdateRequest`。
- **MUST** API 出参用 Pydantic 模型：`{Resource}Response`。
- **MUST** 分页统一：`page: int = Query(1, ge=1)` + `size: int = Query(20, ge=1, le=100)`。
- **MUST** CRUD 函数命名统一：`create` / `update` / `delete` / `get_by_id` / `list_items`。

## 8. 命名约定

| 类型 | 模式 |
|---|---|
| ORM 模型 | `{X}` (如 `User`、`Order`) |
| 请求 Schema | `{X}CreateRequest` / `{X}UpdateRequest` / `{X}Query` |
| 响应 Schema | `{X}Response` / `{X}DetailResponse` |
| Repository | `{x}_repository` 模块 + `{X}Repository` 类 |
| Service | `{x}_service` 模块 + `{X}Service` 类 |
| Router 模块 | `{x}s.py` (如 `users.py`、`orders.py`) |

## 9. 认证与安全

- **MUST** 使用 JWT + bcrypt 进行认证。
- **MUST** 认证端点使用 `Depends(get_current_user)` 保护。
- **MUST** 敏感配置从环境变量读取（`pydantic-settings`），**禁止**硬编码。
- **MUST** CORS 配置明确限制 `allow_origins`。
- **MUST** access_token 有效期 ≤ 30 分钟。

## 10. 测试

- **MUST** 每开发一个功能，立即编写对应测试。
- **MUST** 单元测试 mock 外部依赖，集成测试使用真实测试数据库。
- **MUST** 测试覆盖正常路径 + 异常路径 + 边界条件。
- **MUST** 目标覆盖率 ≥ 80%。
- **禁止** mock 自己项目的 Repository 或 Service。
- **禁止** 在测试失败的情况下提交/合入代码。

## 11. 提交前自检

- [ ] 所有函数是否有完整类型注解？`mypy --strict` 是否通过？
- [ ] Pydantic 模型是否使用 v2 API（`model_config`）？
- [ ] 端点是否使用 `async def`？
- [ ] 数据库操作是否使用 SQLAlchemy 2.0 异步 API？
- [ ] 敏感配置是否从环境变量读取？
- [ ] 是否使用 `HTTPException` 而非裸字典返回错误？
- [ ] 是否有 Alembic 迁移脚本对应数据库变更？
- [ ] 是否有对应测试用例？`pytest` 是否全部通过？
- [ ] CORS 配置是否安全（非 `["*"]` + `allow_credentials=True`）？

---

**详细规则**（如能访问 structure-agent-rules 仓库）：`prompts/developer.md` / `prompts/architect.md` / `prompts/components.md` / `prompts/tester.md` / `prompts/reviewer.md` / `prompts/validation.md` / `prompts/swagger.md` / `prompts/ci-cd.md` / `CLAUDE.md`。
