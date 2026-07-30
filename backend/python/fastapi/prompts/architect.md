# FastAPI Architecture Rules

> 本规则适用于 FastAPI 项目的架构设计决策。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. 分层架构

- **MUST** 采用 **router → service → repository** 三层架构。
- **MUST** 每层职责明确，不可跨层调用（router 不可直接调用 repository）。
- **SHOULD** 在大型项目中引入 DDD 分层：`domain` / `application` / `infrastructure` / `interfaces`。

```
project/
├── api/                    # FastAPI 路由层（interfaces）
│   ├── __init__.py
│   ├── deps.py             # 依赖注入
│   └── v1/
│       ├── __init__.py
│       ├── router.py       # v1 路由聚合
│       └── endpoints/
│           ├── users.py
│           └── orders.py
├── core/                   # 核心配置
│   ├── config.py           # pydantic-settings
│   ├── security.py         # JWT / 密码
│   └── logging.py          # structlog 配置
├── models/                 # SQLAlchemy ORM 模型
│   ├── base.py
│   ├── user.py
│   └── order.py
├── schemas/                # Pydantic 请求/响应模型
│   ├── user.py
│   └── order.py
├── services/               # 业务逻辑层
│   ├── user_service.py
│   └── order_service.py
├── repositories/           # 数据访问层
│   ├── user_repository.py
│   └── order_repository.py
├── db/
│   ├── session.py          # 异步数据库会话
│   └── migrations/         # Alembic 迁移
└── main.py                 # FastAPI 应用入口
```

## 2. 依赖方向

- **MUST** 依赖方向为：`router → service → repository → models`。
- **禁止** 反向依赖：repository 不可 import service，service 不可 import router。
- **MUST** 共享类型（schemas）定义在独立模块，供 router 和 service 共同引用。

## 3. API 版本化

- **MUST** 使用 URL 路径前缀进行 API 版本化：`/api/v1/`、`/api/v2/`。
- **SHOULD** 每个版本有独立的 `APIRouter`，通过 `app.include_router()` 注册。
- **MAY** 在需要时使用请求头版本化作为补充策略。

## 4. 中间件模式

- **MUST** 按以下顺序注册中间件：CORS → 请求日志 → 认证 → 业务中间件。
- **SHOULD** 中间件使用 `@app.middleware("http")` 装饰器，或实现 ASGI 中间件协议。
- **MUST** 请求日志中间件记录：method、path、status_code、duration_ms、request_id。

```python
@app.middleware("http")
async def log_requests(request: Request, call_next):
    request_id = str(uuid.uuid4())
    request.state.request_id = request_id
    start = time.time()
    response = await call_next(request)
    duration = (time.time() - start) * 1000
    logger.info("request completed", method=request.method,
                path=request.url.path, status=response.status_code,
                duration_ms=round(duration, 2), request_id=request_id)
    return response
```

## 5. 后台任务

- **MUST** 轻量级后台任务使用 FastAPI `BackgroundTasks`。
- **MUST** 重量级/长时间异步任务使用 Celery（Redis/RabbitMQ broker）或 ARQ。
- **禁止** 在请求处理线程中执行超过 5 秒的同步阻塞操作。
- **SHOULD** Celery 任务幂等设计，支持重试。

## 6. 数据库架构

- **MUST** 使用 SQLAlchemy 2.0 异步风格：`select(User).where(User.id == id)`。
- **SHOULD** 读写分离场景使用不同的数据库会话工厂。
- **MUST** 数据库连接池配置：`pool_size=20`、`max_overflow=10`、`pool_recycle=3600`。
- **SHOULD** 使用 `asyncpg` 作为 PostgreSQL 异步驱动。

## 7. OpenAPI 文档

- **MUST** FastAPI 自动生成 OpenAPI 文档（`/docs` Swagger UI、`/redoc` ReDoc）。
- **SHOULD** 使用 `summary` 和 `description` 为每个端点添加文档。
- **SHOULD** 使用 `response_model` 显式声明响应类型以生成准确的 OpenAPI schema。

## 8. 缓存策略

- **SHOULD** 读多写少的查询使用 Redis 缓存。
- **MUST** 缓存 Key 命名规范：`{service}:{resource}:{id}`。
- **MUST** 设置合理的 TTL，避免内存溢出。
- **SHOULD** 使用 Cache-Aside 模式：先查缓存，未命中再查数据库并回填缓存。

## 9. 部署架构

- **SHOULD** 使用 Gunicorn + Uvicorn workers 部署生产环境。
- **SHOULD** worker 数量 = `(2 * CPU核心数) + 1`。
- **MUST** 使用 Docker 容器化，多阶段构建减小镜像体积。
- **SHOULD** 使用 Traefik 或 Nginx 作为反向代理。
