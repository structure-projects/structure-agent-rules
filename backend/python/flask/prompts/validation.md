# Flask Validation Rules

> 本规则适用于 Flask 项目中的数据验证。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. Marshmallow Schema 验证

- **MUST** 使用 Marshmallow Schema 进行请求数据验证。
- **MUST** 使用 `Schema.load()` 验证和反序列化输入数据。
- **MUST** 使用 `Schema.dump()` 序列化输出数据。
- **SHOULD** 使用 `fields` 约束：`validate.Length`、`validate.Range`、`validate.Email`。

```python
from marshmallow import Schema, fields, validate, validates, ValidationError

class UserCreateSchema(Schema):
    username = fields.String(
        required=True,
        validate=validate.And(
            validate.Length(min=3, max=50),
            validate.Regexp(r"^[a-zA-Z0-9_]+$", error="仅允许字母、数字和下划线"),
        ),
    )
    email = fields.Email(required=True)
    password = fields.String(
        required=True,
        load_only=True,
        validate=validate.Length(min=8, max=128),
    )
    password_confirm = fields.String(
        required=True,
        load_only=True,
        validate=validate.Length(min=8, max=128),
    )

    @validates("username")
    def validate_username(self, value):
        reserved = {"admin", "root", "system"}
        if value.lower() in reserved:
            raise ValidationError(f"'{value}' 是保留的用户名")

    @validates("schema")
    def validate_passwords_match(self, data, **kwargs):
        if data.get("password") != data.get("password_confirm"):
            raise ValidationError("两次密码不一致", field_name="password_confirm")
```

## 2. 字段级验证器

- **MUST** 使用 `@validates("field_name")` 装饰器实现字段级自定义验证。
- **SHOULD** 验证器方法名以 `validate_` 开头。
- **MAY** 使用 `@validates_schema` 进行跨字段验证（Marshmallow 3+）。

```python
class ProductSchema(Schema):
    name = fields.String(required=True, validate=validate.Length(min=1, max=200))
    price = fields.Float(required=True)
    stock = fields.Integer(required=True)
    sku = fields.String(required=True, validate=validate.Regexp(r"^[A-Z]{2,4}-\d{4,8}$"))

    @validates("name")
    def validate_name_not_empty(self, value):
        if not value.strip():
            raise ValidationError("名称不能为空")

    @validates("price")
    def validate_price_positive(self, value):
        if value <= 0:
            raise ValidationError("价格必须大于 0")
        return round(value, 2)

    @validates("stock")
    def validate_stock_reasonable(self, value):
        if value < 0:
            raise ValidationError("库存不能为负")
        if value > 1_000_000:
            raise ValidationError("库存超出最大限制 (1,000,000)")
```

## 3. SQLAlchemyAutoSchema

- **SHOULD** 使用 `marshmallow_sqlalchemy.SQLAlchemyAutoSchema` 从 Model 自动生成 Schema。
- **MUST** 手动排除敏感字段（`exclude` 参数）。
- **SHOULD** 使用 `load_instance=True` 支持从验证数据直接创建 Model 实例。

```python
from marshmallow_sqlalchemy import SQLAlchemyAutoSchema
from marshmallow import fields, validates, ValidationError

class UserSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = User
        load_instance = True
        exclude = ("password_hash",)
        include_fk = True

    password = fields.String(required=True, load_only=True, validate=validate.Length(min=8))

    @validates("username")
    def validate_unique_username(self, value):
        if User.query.filter_by(username=value).first():
            raise ValidationError("用户名已存在")
```

## 4. Flask-RESTX 模型验证

- **SHOULD** 使用 Flask-RESTX `api.model()` 定义验证模型（与 Marshmallow 互斥选择）。
- **MUST** 使用 `@ns.expect()` 装饰器进行请求体验证。

```python
user_model = api.model("UserCreate", {
    "username": fields.String(required=True, min_length=3, max_length=50),
    "email": fields.String(required=True, pattern=r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$"),
    "password": fields.String(required=True, min_length=8, max_length=128),
})
```

## 5. 请求参数验证

- **MUST** 使用 `request.args.get("key", type=int)` 或 `reqparse.RequestParser` 验证查询参数。
- **SHOULD** 使用 Flask-RESTX 的 `@ns.doc(params={...})` 声明参数约束。

```python
from flask_restx import reqparse

pagination_parser = reqparse.RequestParser()
pagination_parser.add_argument("page", type=int, default=1, help="页码")
pagination_parser.add_argument("per_page", type=int, default=20, help="每页数量")
pagination_parser.add_argument("username", type=str, help="用户名搜索")

@users_ns.route("/")
class UserList(Resource):
    @users_ns.expect(pagination_parser)
    def get(self):
        args = pagination_parser.parse_args()
        ...
```

## 6. 自定义验证器

- **SHOULD** 将可复用的验证逻辑提取为独立的 validator 函数。
- **MAY** 使用 Marshmallow `validate` 模块内置的验证器组合。

```python
from marshmallow import validate

def validate_phone(value):
    import re
    if not re.match(r"^\+?1?\d{9,15}$", value):
        raise ValidationError(f"无效的电话号码: {value}")
    return value

class ContactSchema(Schema):
    phone = fields.String(required=True, validate=validate_phone)
```

## 7. 验证错误处理

- **MUST** 捕获 `ValidationError` 并返回统一格式的错误响应。
- **SHOULD** 在全局错误处理器中处理 Marshmallow 验证错误。

```python
from marshmallow import ValidationError

@app.errorhandler(ValidationError)
def handle_validation_error(error: ValidationError):
    return {
        "error": "validation_error",
        "messages": error.messages,
    }, 400

# 在 Blueprint 路由中使用
@users_bp.route("/users", methods=["POST"])
def create_user():
    try:
        data = user_create_schema.load(request.get_json())
    except ValidationError as err:
        return {"error": "validation_error", "messages": err.messages}, 400
    ...
```

## 8. 响应序列化

- **MUST** 使用 `Schema.dump()` 序列化响应数据。
- **MUST** 确保敏感字段不在响应中（使用 `load_only` 或 `exclude`）。
- **SHOULD** 使用 `many=True` 处理列表序列化。
