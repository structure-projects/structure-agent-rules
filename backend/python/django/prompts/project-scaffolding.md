# Django Project Scaffolding Rules

> 本规则适用于使用 Django 创建新 Python 项目的脚手架搭建。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. 项目初始化

- **MUST** 使用 `django-admin startproject` 创建项目骨架。
- **MUST** Python 版本要求 ≥ 3.10。
- **SHOULD** 使用 `pip` + `requirements/` 目录或 Poetry 管理依赖。

```bash
# 创建项目
django-admin startproject config .
python manage.py startapp apps/users
python manage.py startapp apps/orders

# 安装核心依赖
pip install django>=4.2 djangorestframework django-filter djangorestframework-simplejwt
pip install django-cors-headers django-redis celery[redis] psycopg2-binary
pip install django-storages[boto3] drf-spectacular

# 安装开发依赖
pip install pytest pytest-django pytest-cov model-bakery ruff
```

## 2. 目录结构

- **MUST** 按以下标准结构组织项目：

```
myproject/
├── config/                        # Django 项目配置
│   ├── __init__.py
│   ├── settings/
│   │   ├── __init__.py
│   │   ├── base.py                # 公共配置
│   │   ├── development.py         # 开发环境
│   │   ├── staging.py             # 预发布
│   │   ├── production.py          # 生产环境
│   │   └── test.py                # 测试环境
│   ├── urls.py                    # 根 URL 配置
│   ├── wsgi.py
│   └── asgi.py
├── apps/                          # Django 应用
│   ├── __init__.py
│   ├── users/
│   │   ├── __init__.py
│   │   ├── models.py
│   │   ├── views.py               # ViewSets
│   │   ├── serializers.py         # DRF Serializers
│   │   ├── services.py            # 业务逻辑层
│   │   ├── urls.py
│   │   ├── admin.py
│   │   ├── filters.py             # django-filter
│   │   ├── permissions.py
│   │   ├── signals.py
│   │   └── tasks.py               # Celery 任务
│   ├── orders/
│   └── products/
├── core/                          # 公共模块
│   ├── __init__.py
│   ├── models.py                  # 抽象基类
│   ├── pagination.py
│   ├── permissions.py
│   ├── exceptions.py
│   └── mixins.py
├── templates/
├── static/
├── media/
├── manage.py
├── requirements/
│   ├── base.txt
│   ├── development.txt
│   └── production.txt
├── Dockerfile
├── docker-compose.yml
├── .env.example
└── pyproject.toml
```

## 3. Settings 配置

- **MUST** 使用 `base.py` 定义公共配置，环境特定配置继承自 `base.py`。

```python
# config/settings/base.py
from pathlib import Path
import os

BASE_DIR = Path(__file__).resolve().parent.parent.parent
SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    # 第三方
    "rest_framework",
    "corsheaders",
    "django_filters",
    "drf_spectacular",
    # 本地
    "core",
    "apps.users",
    "apps.orders",
    "apps.products",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"
WSGI_APPLICATION = "config.wsgi.application"
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# DRF 配置
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated",
    ],
    "DEFAULT_PAGINATION_CLASS": "core.pagination.StandardPagination",
    "DEFAULT_FILTER_BACKENDS": [
        "django_filters.rest_framework.DjangoFilterBackend",
        "rest_framework.filters.SearchFilter",
        "rest_framework.filters.OrderingFilter",
    ],
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
}
```

```python
# config/settings/production.py
from .base import *

DEBUG = False
ALLOWED_HOSTS = os.environ["ALLOWED_HOSTS"].split(",")
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
```

## 4. URL 配置

- **MUST** 使用 `include()` 按 App 拆分 URL 配置。
- **MUST** API 版本化使用 URL 前缀。

```python
# config/urls.py
from django.urls import path, include
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/", include("apps.users.urls")),
    path("api/v1/", include("apps.orders.urls")),
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),
]
```

## 5. Dockerfile 模板

- **MUST** 使用多阶段构建。

```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements/production.txt .
RUN pip install --no-cache-dir -r production.txt

FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY . .
RUN python manage.py collectstatic --noinput
EXPOSE 8000
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "4"]
```

## 6. 环境变量

- **MUST** 提供 `.env.example` 作为环境变量模板。
- **禁止** 将 `.env` 提交到版本控制。

```bash
# .env.example
DJANGO_SECRET_KEY=change-me-to-a-random-secret
DJANGO_SETTINGS_MODULE=config.settings.development
DJANGO_DEBUG=True
DB_NAME=myproject
DB_USER=postgres
DB_PASSWORD=password
DB_HOST=localhost
DB_PORT=5432
REDIS_URL=redis://localhost:6379/0
ALLOWED_HOSTS=localhost,127.0.0.1
CORS_ORIGINS=http://localhost:3000
```
