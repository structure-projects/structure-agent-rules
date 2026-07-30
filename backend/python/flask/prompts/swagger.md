# Flask API Documentation Rules

> 本规则适用于 Flask 项目的 API 文档生成（Flask-RESTX / Swagger / OpenAPI）。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. Flask-RESTX 自动文档

- **SHOULD** 使用 `Flask-RESTX` 自动生成 Swagger 文档（OpenAPI 2.0）。
- **MUST** 配置 `Api` 实例并设置 `doc` 路径。
- **MAY** 使用 `flasgger` 或 `apispec` 生成 OpenAPI 3.0 文档（如不需要 Flask-RESTX）。

```python
from flask_restx import Api

api = Api(
    title="My API",
    version="1.0",
    description="Flask REST API 文档",
    doc="/api/docs/",
)

# 在 create_app() 中
api.init_app(app)
```

## 2. Namespace 与 Model 文档化

- **MUST** 使用 `Namespace` 为 API 分组并添加描述。
- **MUST** 使用 `Namespace.model()` 定义请求/响应模型。
- **SHOULD** 为每个字段添加 `description`、`example`、`required`。

```python
from flask_restx import Namespace, fields

users_ns = Namespace("users", description="用户管理操作")

user_model = users_ns.model("User", {
    "id": fields.Integer(readonly=True, description="用户 ID"),
    "username": fields.String(
        required=True, min_length=3, max_length=50,
        description="用户名", example="john_doe",
    ),
    "email": fields.String(
        required=True,
        description="邮箱地址", example="john@example.com",
    ),
    "is_active": fields.Boolean(
        readonly=True, description="是否激活",
    ),
    "created_at": fields.DateTime(readonly=True, description="创建时间"),
})

user_create_model = users_ns.model("UserCreate", {
    "username": fields.String(required=True, min_length=3, max_length=50),
    "email": fields.String(required=True),
    "password": fields.String(required=True, min_length=8),
})
```

## 3. Resource 文档化

- **MUST** 为每个 Resource 方法添加 docstring（作为端点描述）。
- **MUST** 使用 `@ns.expect()` 声明请求体模型。
- **MUST** 使用 `@ns.marshal_with()` 声明响应模型。
- **SHOULD** 使用 `@ns.doc()` 添加额外文档参数。

```python
@users_ns.route("/")
class UserList(Resource):
    @users_ns.doc("list_users", params={
        "page": "页码 (default: 1)",
        "per_page": "每页数量 (default: 20, max: 100)",
    })
    @users_ns.marshal_list_with(user_model)
    def get(self):
        """获取用户列表

        分页获取所有用户，支持按用户名搜索和状态过滤。
        """
        ...

    @users_ns.doc("create_user", responses={
        201: "创建成功",
        400: "请求参数无效",
        409: "用户名或邮箱已存在",
    })
    @users_ns.expect(user_create_model)
    @users_ns.marshal_with(user_model, code=201)
    def post(self):
        """创建新用户

        创建一个新用户账号。用户名和邮箱必须唯一。
        """
        ...
```

## 4. 认证文档

- **MUST** 在 `Api` 初始化时声明认证方案。

```python
authorizations = {
    "BearerAuth": {
        "type": "apiKey",
        "in": "header",
        "name": "Authorization",
        "description": "JWT Bearer Token. Example: Bearer eyJhbGciOi...",
    }
}

api = Api(
    title="My API",
    authorizations=authorizations,
    security="BearerAuth",
)
```

## 5. 原生 Flask + Marshmallow 方案

- **MAY** 使用 `apispec` + `flask-apispec` 为原生 Flask Blueprints 生成 OpenAPI 文档。
- **SHOULD** 使用 `marshmallow` Schema 自动生成 OpenAPI schema。

```python
from apispec import APISpec
from apispec.ext.marshmallow import MarshmallowPlugin

spec = APISpec(
    title="My API",
    version="1.0.0",
    openapi_version="3.0.2",
    plugins=[MarshmallowPlugin()],
)

spec.components.schema("User", schema=UserSchema)
```

## 6. Flasgger 方案

- **MAY** 使用 `Flasgger` 从 YAML docstring 生成 Swagger 文档。
- **SHOULD** 使用 `swag_from` 装饰器引用外部 YAML 文件。

```python
from flasgger import swag_from

@app.route("/users/<int:user_id>")
@swag_from("docs/get_user.yml")
def get_user(user_id):
    ...
```

## 7. 生产环境控制

- **SHOULD** 通过配置控制文档页面的可见性。

```python
# 仅在非生产环境启用文档
if app.config.get("ENV") != "production":
    api = Api(doc="/api/docs/")
else:
    api = Api(doc=False)
```

## 8. 响应 Schema

- **SHOULD** 定义统一的错误响应模型。

```python
error_model = api.model("Error", {
    "error": fields.String(description="错误描述"),
    "code": fields.Integer(description="HTTP 状态码"),
})
```
