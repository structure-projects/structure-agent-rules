# FastAPI Ecosystem Components

> 本规则汇总 FastAPI 生态中常用组件的选型与使用规范。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. 核心框架

| 组件 | 版本要求 | 说明 |
|---|---|---|
| **FastAPI** | ≥ 0.110.0 | Web 框架本体 |
| **Uvicorn** | ≥ 0.27.0 | ASGI 服务器 |
| **Starlette** | ≥ 0.36.0 | FastAPI 底层依赖 |

## 2. 数据库

### SQLAlchemy 2.0（MUST）

- **MUST** 使用 SQLAlchemy 2.0 异步 API：`create_async_engine` + `async_sessionmaker`。
- **MUST** 使用 `asyncpg` 作为 PostgreSQL 异步驱动。
- **MUST** ORM 模型继承 `DeclarativeBase`。

```python
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    pass

engine = create_async_engine(settings.database_url, echo=False)
async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
```

### Alembic（MUST）

- **MUST** 使用 Alembic 管理数据库迁移。
- **MUST** 迁移命令：`alembic revision --autogenerate -m "description"`、`alembic upgrade head`、`alembic downgrade -1`。
- **MUST** `alembic.ini` 中配置异步数据库 URL。

### Redis（SHOULD）

- **SHOULD** 使用 `redis-py`（异步模式：`redis.asyncio.Redis`）连接 Redis。
- **MAY** 使用 `fastapi-limiter` 实现基于 Redis 的速率限制。

## 3. 认证与安全

### JWT（MUST）

- **MUST** 使用 `python-jose[cryptography]` 生成和验证 JWT。
- **MUST** 使用 `passlib[bcrypt]` 哈希密码。
- **MUST** access_token 有效期 ≤ 30 分钟，refresh_token 有效期 ≤ 7 天。

```python
from jose import JWTError, jwt
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def create_access_token(data: dict, expires_delta: timedelta | None = None) -> str:
    to_encode = data.copy()
    expire = datetime.now(UTC) + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.secret_key, algorithm="HS256")
```

### OAuth2（MAY）

- **MAY** 使用 `fastapi.security.OAuth2PasswordBearer` 实现 OAuth2 密码流。
- **MAY** 使用 `authlib` 实现第三方 OAuth2 登录（Google、GitHub 等）。

## 4. 后台任务

### Celery（SHOULD）

- **SHOULD** 使用 Celery + Redis/RabbitMQ 处理异步任务。
- **MUST** 任务函数幂等，支持 `autoretry_for` 和 `max_retries`。
- **MUST** 在 `pyproject.toml` 中声明 `celery[redis]` 依赖。

### ARQ（MAY）

- **MAY** 使用 ARQ（Async Redis Queue）作为轻量级 Celery 替代，适合纯 Redis 场景。

## 5. 日志

### structlog（MUST）

- **MUST** 使用 `structlog` 进行结构化日志记录。
- **SHOULD** 配置 JSON 渲染器用于生产环境，彩色控制台渲染器用于开发环境。

```python
import structlog

structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.dev.ConsoleRenderer() if settings.debug else structlog.processors.JSONRenderer(),
    ],
    wrapper_class=structlog.stdlib.BoundLogger,
    context_class=dict,
    logger_factory=structlog.PrintLoggerFactory(),
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()
```

## 6. 序列化与验证

### Pydantic v2（MUST）

- **MUST** 使用 Pydantic v2（≥ 2.0），利用 Rust 内核的性能提升。
- **MUST** 使用 `model_validate()` 和 `model_dump()` 替代 v1 的 `parse_obj()` 和 `dict()`。

## 7. HTTP 客户端

### httpx（SHOULD）

- **SHOULD** 使用 `httpx.AsyncClient` 进行服务间 HTTP 调用。
- **MUST** 设置超时：`httpx.Timeout(10.0, connect=5.0)`。
- **SHOULD** 使用连接池复用：通过 `async with httpx.AsyncClient()` 上下文管理。

## 8. 测试

| 工具 | 用途 |
|---|---|
| **pytest** | 测试框架 |
| **httpx** | 异步 HTTP 测试客户端 |
| **pytest-asyncio** | 异步测试支持 |
| **pytest-cov** | 覆盖率报告 |
| **factory_boy** | 测试数据工厂 |
| **pytest-alembic** | 迁移脚本测试 |

## 9. 文档

### OpenAPI（MUST）

- **MUST** 使用 FastAPI 自动生成的 `/docs`（Swagger UI）和 `/redoc`（ReDoc）。
- **SHOULD** 为每个端点添加 `summary`、`description`、`responses` 元数据。

## 10. 禁止使用的组件

- **禁止** 使用同步 `psycopg2` 驱动（应用 asyncpg）。
- **禁止** 使用 `requests` 库进行 HTTP 调用（应用 httpx）。
- **禁止** 使用 `pickle` 序列化用户输入数据。
- **禁止** 使用 Python 内置 `logging` 直接输出（应用 structlog）。
