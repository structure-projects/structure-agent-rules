# FastAPI OpenAPI / Swagger Rules

> 本规则适用于 FastAPI 项目的 OpenAPI 文档和 Swagger UI 配置。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. 自动文档生成

- **MUST** 利用 FastAPI 自动生成 OpenAPI schema，无需手动编写 OpenAPI 规范文件。
- **MUST** 确保 `/docs`（Swagger UI）和 `/redoc`（ReDoc）在生产环境中可选择性启用。
- **SHOULD** 在生产环境中通过环境变量控制文档页面的可见性。

```python
app = FastAPI(
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
    openapi_url="/openapi.json" if settings.debug else None,
)
```

## 2. 端点文档化

- **MUST** 每个端点使用 `summary` 和 `description` 添加文档。
- **SHOULD** 使用 `response_description` 描述成功响应。
- **MUST** 使用 `responses` 参数文档化可能的错误状态码。

```python
@router.post(
    "/users/",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="创建用户",
    description="创建一个新用户账号。用户名和邮箱必须唯一。",
    responses={
        201: {"description": "用户创建成功"},
        400: {"description": "请求参数无效"},
        409: {"description": "用户名或邮箱已存在"},
    },
)
async def create_user(...):
    ...
```

## 3. Pydantic 模型与 Schema

- **MUST** 使用 `Field(description=...)` 为每个字段添加说明。
- **MUST** 使用 `Field(examples=[...])` 或 `json_schema_extra` 提供示例值。
- **SHOULD** 为枚举字段使用 `Literal` 类型以在 OpenAPI schema 中生成枚举选项。

```python
from pydantic import BaseModel, Field
from typing import Literal

class UserCreateRequest(BaseModel):
    username: str = Field(
        ..., min_length=3, max_length=50,
        description="用户名，3-50 个字符，仅允许字母数字和下划线",
        examples=["john_doe"],
    )
    role: Literal["admin", "editor", "viewer"] = Field(
        default="viewer",
        description="用户角色",
    )
    is_active: bool = Field(default=True, description="是否激活")
```

## 4. 响应模型

- **MUST** 使用 `response_model` 参数显式声明每个端点的响应类型。
- **MUST** 使用 `response_model_exclude` 或 `response_model_exclude_unset` 控制敏感字段不返回。
- **SHOULD** 使用 `response_model_by_alias` 当需要返回 snake_case 转 camelCase 时。

```python
@router.get("/users/me", response_model=UserResponse)
async def read_current_user(current_user: User = Depends(get_current_active_user)):
    return current_user

# 排除敏感字段
@router.get("/users/{user_id}", response_model=UserResponse, response_model_exclude={"password_hash"})
async def get_user(user_id: int, db: AsyncSession = Depends(get_db)):
    ...
```

## 5. 标签分组

- **MUST** 使用 `tags` 参数对端点进行分组。
- **SHOULD** 在 `app.include_router()` 中统一设置 tags，或在 `APIRouter` 级别设置。

```python
router = APIRouter(tags=["users"])

# 或在 include_router 时设置
app.include_router(users_router, prefix="/users", tags=["users"])
app.include_router(orders_router, prefix="/orders", tags=["orders"])
```

## 6. FastAPI 应用元数据

- **MUST** 设置应用级别的 `title`、`description`、`version`。
- **SHOULD** 设置 `contact`、`license_info`、`terms_of_service`。
- **MAY** 添加 `openapi_tags` 元数据为标签组添加描述。

```python
app = FastAPI(
    title="My Service API",
    description="## 用户管理服务\n\n提供用户注册、登录、信息管理等功能。",
    version="1.0.0",
    contact={"name": "API Support", "email": "support@example.com"},
    license_info={"name": "MIT", "url": "https://opensource.org/licenses/MIT"},
    openapi_tags=[
        {"name": "users", "description": "用户管理相关接口"},
        {"name": "auth", "description": "认证与授权接口"},
        {"name": "health", "description": "健康检查接口"},
    ],
)
```

## 7. 自定义 OpenAPI Schema

- **MAY** 使用 `app.openapi()` 方法自定义 OpenAPI schema。
- **SHOULD** 使用 `fastapi.openapi.utils.get_openapi` 扩展默认 schema。

```python
from fastapi.openapi.utils import get_openapi

def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    openapi_schema = get_openapi(
        title=app.title, version=app.version, routes=app.routes,
    )
    openapi_schema["info"]["x-logo"] = {"url": "https://example.com/logo.png"}
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi
```

## 8. 安全 Schema

- **MUST** 如果使用 JWT 认证，在 OpenAPI schema 中声明 Bearer Token 安全方案。
- **SHOULD** 使用 `dependencies` 参数在 `APIRouter` 级别添加认证要求。

```python
from fastapi.security import HTTPBearer

security = HTTPBearer()

@app.get("/users/me", dependencies=[Depends(security)])
async def read_current_user(...):
    ...
```
