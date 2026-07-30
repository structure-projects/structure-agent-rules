# FastAPI Developer Rules

> 本规则适用于使用 FastAPI 框架进行 Python 后端开发的 AI 开发者角色。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. 项目基础配置

- **MUST** 使用 Python 3.10+，充分利用 `|` 联合类型和 `X | None` 语法。
- **MUST** 使用 Poetry 或 pip + `pyproject.toml` 管理依赖。
- **SHOULD** 使用 `pydantic-settings` 管理环境配置，通过 `BaseSettings` 类加载 `.env` 文件。
- **MUST** 在 `pyproject.toml` 中声明所有依赖及版本范围（上限保护）。

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    secret_key: str
    debug: bool = False

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}

settings = Settings()
```

## 2. 类型注解

- **MUST** 所有函数签名、方法参数和返回值必须使用类型注解。
- **MUST** 使用 `mypy` 进行静态类型检查（配置 `strict = true`）。
- **禁止** 使用 `Any` 除非确实无法确定类型；优先使用 `object` 或泛型约束。
- **SHOULD** 公共 API 使用 `typing.TypeAlias` 声明类型别名。

## 3. Pydantic 模型

- **MUST** 请求体和响应体使用 Pydantic v2 模型定义。
- **MUST** 使用 `model_config = {"from_attributes": True}` 启用 ORM 模式。
- **SHOULD** 使用 `field_validator` 和 `model_validator` 实现自定义验证逻辑。
- **MUST** 使用 `Field()` 声明字段约束（`min_length`、`gt`、`pattern` 等）。

```python
from pydantic import BaseModel, Field, field_validator

class UserCreateRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=50, pattern=r"^[a-zA-Z0-9_]+$")
    email: str = Field(..., pattern=r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$")
    age: int = Field(ge=0, le=150)

    @field_validator("username")
    @classmethod
    def username_must_not_be_reserved(cls, v: str) -> str:
        reserved = {"admin", "root", "system"}
        if v.lower() in reserved:
            raise ValueError(f"username '{v}' is reserved")
        return v
```

## 4. 异步编程

- **MUST** 所有端点处理函数使用 `async def`。
- **MUST** 数据库操作使用 `SQLAlchemy 2.0` 异步引擎 + `asyncpg` 驱动。
- **禁止** 在 `async def` 函数内调用同步阻塞 I/O（如 `requests` 库、同步 ORM 操作）。
- **SHOULD** CPU 密集型任务使用 `run_in_executor` 或后台任务队列处理。

## 5. 依赖注入

- **MUST** 使用 FastAPI `Depends()` 进行依赖注入。
- **MUST** 数据库会话通过 `Depends(get_db)` 注入，确保请求结束后正确关闭。
- **SHOULD** 提取可复用的依赖为独立函数（如 `get_current_user`、`get_pagination`）。

```python
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

async def get_db() -> AsyncSession:
    async with async_session_factory() as session:
        yield session

@router.get("/users/{user_id}")
async def get_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> UserResponse:
    ...
```

## 6. 路由组织

- **MUST** 使用 `APIRouter` 按业务领域拆分路由模块。
- **MUST** 在 `main.py` 中使用 `app.include_router()` 注册路由，并添加 `prefix` 和 `tags`。
- **SHOULD** 按资源组织路由文件：`routers/users.py`、`routers/orders.py`。

## 7. 错误处理

- **MUST** 使用 `HTTPException` 返回标准 HTTP 错误响应。
- **SHOULD** 定义自定义异常类和全局异常处理器（`@app.exception_handler`）。
- **MUST** 在 Service 层抛出自定义业务异常，在 Router 层或全局处理器中转换为 HTTP 响应。
- **禁止** 直接返回裸 `{"error": "..."}` 字典。

## 8. 日志

- **MUST** 使用 `structlog` 进行结构化日志记录。
- **MUST** 在请求中间件中自动注入 `request_id`、`user_id` 等上下文信息。
- **SHOULD** 按日志级别分类：`debug`（开发调试）、`info`（业务流程）、`warning`（可恢复异常）、`error`（需人工介入）。

## 9. 安全

- **MUST** 使用 `python-jose` + `passlib[bcrypt]` 实现 JWT 认证。
- **MUST** 敏感配置（密钥、数据库密码）从环境变量或密钥管理服务读取，**禁止**硬编码。
- **MUST** 启用 CORS 中间件并明确限制允许的源。
- **SHOULD** 使用 `fastapi-limiter` + Redis 实现速率限制。

## 10. 数据库

- **MUST** 使用 Alembic 管理数据库迁移，迁移文件纳入版本控制。
- **MUST** 每个迁移包含 `upgrade()` 和 `downgrade()` 两个方向。
- **禁止** 在生产环境使用 `Base.metadata.create_all()` 自动建表。
