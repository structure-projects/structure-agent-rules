# Django Developer Rules

> 本规则适用于使用 Django 框架进行 Python 后端开发的 AI 开发者角色。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. 项目基础配置

- **MUST** 使用 Python 3.10+。
- **MUST** 使用 Poetry 或 pip + `requirements.txt` 管理依赖。
- **MUST** Django 版本 ≥ 4.2 LTS 或 ≥ 5.0。
- **SHOULD** 使用 `django-environ` 或 `python-decouple` 管理环境配置。
- **MUST** 敏感配置从环境变量读取，**禁止**在 `settings.py` 中硬编码密钥。

```python
# settings.py
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]
DEBUG = os.environ.get("DJANGO_DEBUG", "False") == "True"
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ["DB_NAME"],
        "USER": os.environ["DB_USER"],
        "PASSWORD": os.environ["DB_PASSWORD"],
        "HOST": os.environ.get("DB_HOST", "localhost"),
        "PORT": os.environ.get("DB_PORT", "5432"),
        "CONN_MAX_AGE": 60,
    }
}
```

## 2. Settings 模块结构

- **SHOULD** 使用多环境 settings 模块：`settings/base.py`、`settings/development.py`、`settings/production.py`。
- **MUST** 通过 `DJANGO_SETTINGS_MODULE` 环境变量切换环境。

```
config/
├── settings/
│   ├── __init__.py
│   ├── base.py           # 公共配置
│   ├── development.py    # 开发环境
│   ├── staging.py        # 预发布环境
│   └── production.py     # 生产环境
├── urls.py
├── wsgi.py
└── asgi.py
```

## 3. Django REST Framework

- **MUST** 使用 Django REST Framework (DRF) 构建 RESTful API。
- **MUST** 使用 DRF `ModelSerializer` 进行序列化。
- **SHOULD** 使用 `ViewSet` + `Router` 组合减少样板代码。
- **MUST** 使用 `permission_classes` 控制访问权限。

```python
from rest_framework import viewsets, serializers, permissions
from rest_framework.decorators import action
from rest_framework.response import Response

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "username", "email", "is_active", "date_joined"]
        read_only_fields = ["id", "date_joined"]

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=["get"])
    def me(self, request):
        serializer = self.get_serializer(request.user)
        return Response(serializer.data)
```

## 4. Django ORM

- **MUST** 使用 Django ORM 进行数据库操作，**禁止**拼接原生 SQL 字符串。
- **MUST** 使用 `select_related()` 处理外键关联，`prefetch_related()` 处理多对多关联。
- **MUST** 使用 `QuerySet` 链式调用，**禁止**在循环中查询数据库（N+1 问题）。
- **SHOULD** 复杂查询使用 `Q` 对象和 `F` 表达式。

```python
# 正确：使用 select_related 避免 N+1
orders = Order.objects.select_related("user").filter(status="pending")

# 正确：使用 prefetch_related 处理多对多
users = User.objects.prefetch_related("groups", "permissions").all()

# 正确：使用 Q 对象构建复杂查询
from django.db.models import Q
results = Product.objects.filter(
    Q(name__icontains=keyword) | Q(description__icontains=keyword),
    is_active=True,
)
```

## 5. 数据库迁移

- **MUST** 使用 Django 内置迁移系统：`python manage.py makemigrations` + `python manage.py migrate`。
- **MUST** 迁移文件纳入版本控制。
- **MUST** 每次模型变更都生成对应的迁移文件。
- **禁止** 在生产环境使用 `python manage.py migrate --fake` 除非明确了解后果。
- **SHOULD** 在 CI/CD 中自动运行迁移。

## 6. Django Admin

- **SHOULD** 使用 Django Admin 作为管理后台。
- **MUST** 使用 `ModelAdmin` 子类自定义管理界面。
- **SHOULD** 使用 `list_display`、`list_filter`、`search_fields` 提升管理效率。

```python
from django.contrib import admin

@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ["username", "email", "is_active", "date_joined"]
    list_filter = ["is_active", "date_joined"]
    search_fields = ["username", "email"]
    readonly_fields = ["date_joined", "last_login"]
```

## 7. 中间件与信号

- **SHOULD** 使用 Django 中间件处理请求前/后的横切关注点（日志、认证、CORS）。
- **SHOULD** 使用 Django Signals 解耦模块间通信（`post_save`、`pre_delete` 等）。
- **禁止** 在 Signal handler 中执行耗时操作，应通过 Celery 异步处理。

## 8. 安全

- **MUST** 开启 Django 内置安全中间件（`SecurityMiddleware`、`CsrfViewMiddleware`、`XFrameOptionsMiddleware`）。
- **MUST** 生产环境设置：`DEBUG=False`、`SECURE_SSL_REDIRECT=True`、`SESSION_COOKIE_SECURE=True`、`CSRF_COOKIE_SECURE=True`。
- **MUST** 使用 `ALLOWED_HOSTS` 限制允许的主机名。
- **SHOULD** 使用 `django-cors-headers` 管理 CORS。
- **禁止** 在模板中使用 `|safe` 过滤器处理用户输入。

## 9. 日志

- **MUST** 使用 Django `LOGGING` 配置进行日志管理。
- **SHOULD** 生产环境使用 JSON 格式日志输出到 stdout。
- **MUST** 配置不同级别的 logger：`django`、`django.request`、应用 logger。

## 10. 异步支持

- **MAY** 使用 Django 异步视图（`async def`）处理 I/O 密集型端点。
- **MAY** 使用 `sync_to_async` 在异步上下文中调用同步 ORM 代码。
- **SHOULD** 使用 Celery 处理后台异步任务。
