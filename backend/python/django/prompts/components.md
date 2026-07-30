# Django Ecosystem Components

> 本规则汇总 Django 生态中常用组件的选型与使用规范。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. 核心框架

| 组件 | 版本要求 | 说明 |
|---|---|---|
| **Django** | ≥ 4.2 LTS | Web 框架 |
| **Django REST Framework** | ≥ 3.15 | RESTful API 框架 |
| **django-filter** | ≥ 24.1 | DRF 过滤后端 |

## 2. 数据库

### PostgreSQL（MUST）

- **MUST** 使用 PostgreSQL 作为主数据库。
- **MUST** 使用 `django.db.backends.postgresql` 引擎。
- **SHOULD** 使用 `CONN_MAX_AGE` 启用持久连接。

### Redis（SHOULD）

- **SHOULD** 使用 `django-redis` 作为 Redis 缓存后端。
- **SHOULD** 配置 Redis 作为 Celery broker 和 result backend。

```python
CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": os.environ.get("REDIS_URL", "redis://localhost:6379/1"),
        "OPTIONS": {"CLIENT_CLASS": "django_redis.client.DefaultClient"},
    }
}
```

## 3. 认证与安全

### JWT（SHOULD）

- **SHOULD** 使用 `djangorestframework-simplejwt` 实现 JWT 认证。
- **MUST** access_token 有效期 ≤ 30 分钟，refresh_token 有效期 ≤ 7 天。

```python
from datetime import timedelta

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=30),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
    "ROTATE_REFRESH_TOKENS": True,
    "AUTH_HEADER_TYPES": ("Bearer",),
}
```

### django-cors-headers（MUST）

- **MUST** 使用 `django-cors-headers` 管理 CORS。
- **禁止** 生产环境 `CORS_ALLOW_ALL_ORIGINS = True`。

```python
INSTALLED_APPS += ["corsheaders"]
MIDDLEWARE.insert(0, "corsheaders.middleware.CorsMiddleware")

CORS_ALLOWED_ORIGINS = os.environ.get("CORS_ORIGINS", "").split(",")
```

## 4. DRF 扩展

| 组件 | 用途 |
|---|---|
| **djangorestframework-simplejwt** | JWT 认证 |
| **django-filter** | 查询过滤 |
| **drf-spectacular** | OpenAPI 3.0 文档生成 |
| **drf-nested-routers** | 嵌套路由 |
| **djangorestframework-camel-case** | camelCase 响应 |

### drf-spectacular（SHOULD）

- **SHOULD** 使用 `drf-spectacular` 生成 OpenAPI 3.0 文档。
- **MAY** 使用 Swagger UI（`/api/docs/`）和 ReDoc（`/api/redoc/`）。

```python
REST_FRAMEWORK["DEFAULT_SCHEMA_CLASS"] = "drf_spectacular.openapi.AutoSchema"

SPECTACULAR_SETTINGS = {
    "TITLE": "My API",
    "VERSION": "1.0.0",
    "SERVE_INCLUDE_SCHEMA": False,
}
```

## 5. 后台任务

### Celery（MUST）

- **MUST** 使用 Celery + Redis/RabbitMQ 处理异步任务。
- **MUST** 任务函数幂等，支持 `autoretry_for` 和 `max_retries`。
- **SHOULD** 使用 `django-celery-beat` 管理定时任务。

```python
CELERY_BROKER_URL = os.environ.get("CELERY_BROKER_URL", "redis://localhost:6379/0")
CELERY_RESULT_BACKEND = os.environ.get("CELERY_RESULT_BACKEND", "redis://localhost:6379/1")
CELERY_TASK_ALWAYS_EAGER = False
CELERY_TASK_TRACK_STARTED = True
```

## 6. 文件存储

### django-storages（SHOULD）

- **SHOULD** 使用 `django-storages` + S3/MinIO 管理文件存储。
- **MUST** 生产环境文件存储与计算分离。

```python
DEFAULT_FILE_STORAGE = "storages.backends.s3boto3.S3Boto3Storage"
AWS_ACCESS_KEY_ID = os.environ["AWS_ACCESS_KEY_ID"]
AWS_SECRET_ACCESS_KEY = os.environ["AWS_SECRET_ACCESS_KEY"]
AWS_STORAGE_BUCKET_NAME = os.environ["AWS_STORAGE_BUCKET_NAME"]
```

## 7. 测试

| 工具 | 用途 |
|---|---|
| **pytest-django** | Django 测试集成 |
| **pytest-cov** | 覆盖率报告 |
| **model_bakery** | 测试数据生成 |
| **factory_boy** | 工厂模式测试数据 |
| **pytest-xdist** | 并行测试 |

## 8. 监控与调试

| 工具 | 用途 |
|---|---|
| **django-debug-toolbar** | 开发环境调试面板 |
| **sentry-sdk** | 错误追踪 |
| **django-structlog** | 结构化日志 |
| **django-prometheus** | Prometheus 指标导出 |

## 9. 管理后台增强

| 组件 | 用途 |
|---|---|
| **django-import-export** | 数据导入导出 |
| **django-admin-interface** | 管理后台主题 |
| **django-admin-sortable2** | 拖拽排序 |

## 10. 禁止使用的组件

- **禁止** 使用 `psycopg2` 同步驱动（Django 4.2+ 推荐异步就绪配置）。
- **禁止** 使用 `pickle` 序列化用户输入数据。
- **禁止** 使用 `django-jsonfield`（Django 3.1+ 内置 `JSONField`）。
