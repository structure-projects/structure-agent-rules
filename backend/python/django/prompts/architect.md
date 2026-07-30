# Django Architecture Rules

> 本规则适用于 Django 项目的架构设计决策。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. Django 应用组织

- **MUST** 按业务领域拆分 Django App（每个 App 对应一个业务领域）。
- **MUST** 每个 App 内按职责组织文件：`models.py` / `views.py` / `serializers.py` / `services.py` / `urls.py`。
- **SHOULD** 大型 App 内拆分为子模块（`views/`、`services/`、`api/`）。

```
project/
├── config/                    # Django 项目配置
│   ├── settings/
│   │   ├── base.py
│   │   ├── development.py
│   │   └── production.py
│   ├── urls.py                # 根 URL 配置
│   └── wsgi.py
├── apps/
│   ├── users/                 # 用户 App
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── serializers.py
│   │   ├── services.py
│   │   ├── urls.py
│   │   ├── admin.py
│   │   ├── signals.py
│   │   └── tasks.py           # Celery 任务
│   ├── orders/                # 订单 App
│   └── products/              # 商品 App
├── core/                      # 公共模块
│   ├── models.py              # 抽象基类
│   ├── pagination.py
│   ├── permissions.py
│   └── exceptions.py
├── manage.py
└── requirements/
    ├── base.txt
    ├── development.txt
    └── production.txt
```

## 2. 分层架构

- **SHOULD** 在复杂业务中引入 Service 层（`services.py`），View 层仅处理 HTTP 请求/响应。
- **MUST** View 层职责：参数解析、权限检查、调用 Service、返回响应。
- **MUST** Service 层职责：业务逻辑编排、事务管理、调用外部服务。
- **MUST** Model 层职责：数据定义、简单查询方法、属性计算。

```python
# apps/users/services.py
class UserService:
    @staticmethod
    def create_user(*, username: str, email: str, password: str) -> User:
        if User.objects.filter(username=username).exists():
            raise ValidationError("username already exists")
        user = User.objects.create_user(
            username=username, email=email, password=password
        )
        send_welcome_email.delay(user.id)  # Celery 异步任务
        return user

# apps/users/views.py
class UserViewSet(viewsets.ModelViewSet):
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = UserService.create_user(**serializer.validated_data)
        return Response(UserSerializer(user).data, status=201)
```

## 3. DRF API 设计

- **MUST** 使用 DRF `Router` 自动生成 URL 路由。
- **MUST** API 版本化使用 URL 前缀：`/api/v1/`、`/api/v2/`。
- **SHOULD** 使用 `ModelViewSet` 提供标准 CRUD，用 `@action` 添加自定义端点。
- **SHOULD** 统一分页类：`PageNumberPagination`，默认 `page_size=20`。

```python
from rest_framework.pagination import PageNumberPagination

class StandardPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 100
```

## 4. 依赖方向

- **MUST** 依赖方向：`View → Service → Model`。
- **禁止** Model 层依赖 View 或 Service 层。
- **禁止** App 之间循环依赖，使用 Signals 或 Service 层解耦。
- **SHOULD** 公共功能提取到 `core/` 模块。

## 5. 认证与权限

- **MUST** 使用 Django 认证系统 + DRF 认证类。
- **SHOULD** JWT 认证使用 `djangorestframework-simplejwt`。
- **MUST** 使用 DRF `permission_classes` 进行权限控制。
- **SHOULD** 自定义 Permission 类实现业务权限逻辑。

```python
from rest_framework.permissions import BasePermission

class IsOwnerOrAdmin(BasePermission):
    def has_object_permission(self, request, view, obj):
        return request.user.is_staff or obj.user == request.user
```

## 6. 后台任务

- **MUST** 异步任务使用 Celery + Redis/RabbitMQ。
- **MUST** Celery 任务幂等，支持重试（`autoretry_for` + `max_retries`）。
- **SHOULD** 使用 `django-celery-results` 或 `django-celery-beat` 管理任务结果和定时任务。

```python
from celery import shared_task

@shared_task(autoretry_for=(Exception,), max_retries=3, retry_backoff=True)
def send_welcome_email(user_id: int):
    user = User.objects.get(id=user_id)
    # 发送邮件逻辑
```

## 7. 缓存策略

- **SHOULD** 使用 Django Cache Framework + Redis 作为缓存后端。
- **MUST** 缓存 Key 命名规范：`{app}:{resource}:{identifier}`。
- **SHOULD** 视图层缓存使用 `@cache_page`，数据层缓存使用 `cache.get/set`。

## 8. 文件存储

- **SHOULD** 使用 Django `FileField` + `django-storages` 对接 S3/MinIO。
- **MUST** 生产环境文件存储与计算分离。

## 9. 部署架构

- **SHOULD** 使用 Gunicorn + Uvicorn workers（ASGI 模式）部署生产环境。
- **SHOULD** 使用 Nginx 作为反向代理 + 静态文件服务。
- **MUST** 使用 Docker 容器化部署。
