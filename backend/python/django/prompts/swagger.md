# Django API Documentation Rules

> 本规则适用于 Django 项目的 API 文档生成（drf-spectacular / Swagger / OpenAPI）。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. drf-spectacular 配置

- **MUST** 使用 `drf-spectacular` 生成 OpenAPI 3.0 文档。
- **MUST** 在 `INSTALLED_APPS` 中注册 `drf_spectacular`。
- **MUST** 配置 `DEFAULT_SCHEMA_CLASS` 为 `drf_spectacular.openapi.AutoSchema`。

```python
INSTALLED_APPS += ["drf_spectacular"]

REST_FRAMEWORK["DEFAULT_SCHEMA_CLASS"] = "drf_spectacular.openapi.AutoSchema"

SPECTACULAR_SETTINGS = {
    "TITLE": "My Project API",
    "DESCRIPTION": "用户管理与订单系统 API",
    "VERSION": "1.0.0",
    "SERVE_INCLUDE_SCHEMA": False,
    "COMPONENT_SPLIT_REQUEST": True,
}
```

## 2. URL 配置

- **MUST** 配置 `/api/schema/` 和 `/api/docs/` 端点。

```python
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView, SpectacularRedocView

urlpatterns = [
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),
    path("api/redoc/", SpectacularRedocView.as_view(url_name="schema"), name="redoc"),
]
```

## 3. ViewSet 文档化

- **MUST** 为每个 ViewSet 添加 `@extend_schema_view` 或 docstring 描述。
- **SHOULD** 使用 `@extend_schema` 为 `@action` 端点添加文档。

```python
from drf_spectacular.utils import extend_schema, extend_schema_view, OpenApiParameter, OpenApiExample

@extend_schema_view(
    list=extend_schema(
        summary="获取用户列表",
        description="分页获取所有用户，支持按用户名搜索和状态过滤。",
        parameters=[
            OpenApiParameter(name="username", description="用户名搜索", required=False, type=str),
            OpenApiParameter(name="is_active", description="激活状态", required=False, type=bool),
        ],
    ),
    create=extend_schema(
        summary="创建用户",
        description="创建一个新用户账号。",
        responses={201: UserSerializer, 400: None},
    ),
)
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

    @extend_schema(
        summary="获取当前用户信息",
        description="返回已认证用户的个人信息。",
    )
    @action(detail=False, methods=["get"])
    def me(self, request):
        ...
```

## 4. Serializer 文档化

- **MUST** 使用 `help_text` 参数为 Serializer 字段添加说明。
- **SHOULD** 在 `Meta` 类中使用 `extra_kwargs` 添加字段级文档。

```python
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "username", "email", "is_active", "date_joined"]
        extra_kwargs = {
            "username": {"help_text": "用户名，3-50 个字符"},
            "email": {"help_text": "有效的邮箱地址"},
        }
```

## 5. 请求/响应示例

- **SHOULD** 使用 `OpenApiExample` 为端点添加请求和响应示例。

```python
from drf_spectacular.utils import OpenApiExample

@extend_schema(
    examples=[
        OpenApiExample(
            "有效请求",
            value={"username": "john_doe", "email": "john@example.com", "password": "Str0ng!Pass"},
            request_only=True,
        ),
        OpenApiExample(
            "成功响应",
            value={"id": 1, "username": "john_doe", "email": "john@example.com", "is_active": True},
            response_only=True,
        ),
    ],
)
```

## 6. 生产环境控制

- **SHOULD** 通过环境变量控制文档页面的可见性。

```python
# config/urls.py
from django.conf import settings

urlpatterns = [...]
if settings.DEBUG:
    urlpatterns += [
        path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
        path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),
    ]
```

## 7. 认证 Schema

- **MUST** 在 `SPECTACULAR_SETTINGS` 中声明 JWT 认证方案。

```python
SPECTACULAR_SETTINGS = {
    "SECURITY": [{"BearerAuth": []}],
    "SECURITY_DEFINITIONS": {
        "BearerAuth": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT",
        },
    },
}
```

## 8. 自定义 Schema

- **MAY** 使用 `@extend_schema` 的 `operation_id` 自定义操作 ID。
- **MAY** 使用 `preprocessing_hooks` 或 `postprocessing_hooks` 修改生成的 Schema。
