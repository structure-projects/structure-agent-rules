# FastAPI Project Scaffolding Rules

> 本规则适用于使用 FastAPI 创建新 Python 项目的脚手架搭建。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. 项目初始化

- **MUST** 使用 Poetry 或 pip + `pyproject.toml` 初始化项目。
- **MUST** Python 版本要求 ≥ 3.10。
- **SHOULD** 使用 `fastapi-cli` 或项目模板快速启动。

```bash
# Poetry 方式
poetry new my-service
cd my-service
poetry add fastapi uvicorn[standard] sqlalchemy[asyncio] asyncpg alembic pydantic-settings structlog

# pip 方式
mkdir my-service && cd my-service
python -m venv .venv && source .venv/bin/activate
pip install fastapi uvicorn[standard] sqlalchemy[asyncio] asyncpg alembic pydantic-settings structlog
```

## 2. 目录结构

- **MUST** 按以下标准结构组织项目：

```
my-service/
├── app/
│   ├── __init__.py
│   ├── main.py                  # FastAPI 应用入口
│   ├── api/
│   │   ├── __init__.py
│   │   ├── deps.py              # 公共依赖注入
│   │   └── v1/
│   │       ├── __init__.py
│   │       ├── router.py        # v1 路由聚合
│   │       └── endpoints/
│   │           ├── __init__.py
│   │           ├── users.py
│   │           └── health.py
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py            # pydantic-settings
│   │   ├── security.py          # JWT + 密码
│   │   └── logging_config.py    # structlog
│   ├── models/
│   │   ├── __init__.py
│   │   ├── base.py              # DeclarativeBase
│   │   └── user.py
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── user.py              # Pydantic models
│   │   └── common.py            # 通用 schema（分页等）
│   ├── services/
│   │   ├── __init__.py
│   │   └── user_service.py
│   ├── repositories/
│   │   ├── __init__.py
│   │   └── user_repository.py
│   └── db/
│       ├── __init__.py
│       ├── session.py           # 异步数据库会话
│       └── migrations/          # Alembic 迁移目录
│           ├── env.py
│           └── versions/
├── tests/
│   ├── __init__.py
│   ├── conftest.py              # 公共 fixtures
│   ├── unit/
│   │   ├── test_user_service.py
│   │   └── test_user_repository.py
│   └── integration/
│       └── test_user_api.py
├── alembic.ini
├── pyproject.toml
├── Dockerfile
├── docker-compose.yml
└── .env.example
```

## 3. pyproject.toml 配置

- **MUST** 在 `pyproject.toml` 中声明项目元数据和依赖分组。

```toml
[project]
name = "my-service"
version = "0.1.0"
description = "FastAPI Service"
requires-python = ">=3.10"
dependencies = [
    "fastapi>=0.110.0",
    "uvicorn[standard]>=0.27.0",
    "sqlalchemy[asyncio]>=2.0",
    "asyncpg>=0.29.0",
    "alembic>=1.13.0",
    "pydantic-settings>=2.1.0",
    "structlog>=24.1.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "pytest-asyncio>=0.23.0",
    "pytest-cov>=4.1.0",
    "httpx>=0.27.0",
    "ruff>=0.3.0",
    "mypy>=1.8.0",
]

[tool.ruff]
target-version = "py310"
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP", "B", "SIM"]

[tool.mypy]
strict = true
python_version = "3.10"

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
```

## 4. 数据库初始化

- **MUST** 使用 Alembic 初始化数据库迁移环境。

```bash
alembic init -t async app/db/migrations
# 修改 alembic.ini 中的 sqlalchemy.url
# 修改 env.py 中的 target_metadata = Base.metadata
alembic revision --autogenerate -m "initial"
alembic upgrade head
```

## 5. Dockerfile 模板

- **MUST** 使用多阶段构建。

```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
COPY pyproject.toml ./
RUN pip install --no-cache-dir .

FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY app/ ./app/
COPY alembic.ini .
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## 6. main.py 入口

- **MUST** 在 `app/main.py` 中创建 FastAPI 应用实例并注册路由和中间件。

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.router import api_router
from app.core.config import settings
from app.db.session import engine
from app.core.logging_config import setup_logging

setup_logging()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # startup
    yield
    # shutdown
    await engine.dispose()

app = FastAPI(
    title=settings.project_name,
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api/v1")

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
```

## 7. 环境变量

- **MUST** 提供 `.env.example` 文件作为环境变量模板。
- **禁止** 将 `.env` 文件提交到版本控制（加入 `.gitignore`）。

```bash
# .env.example
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/dbname
SECRET_KEY=change-me-to-a-random-secret
DEBUG=false
ALLOWED_ORIGINS=["http://localhost:3000"]
```
