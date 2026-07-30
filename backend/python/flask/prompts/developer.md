# Flask Developer Rules

> 本规则适用于使用 Flask 框架进行 Python 后端开发的 AI 开发者角色。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. 项目基础配置

- **MUST** 使用 Python 3.10+。
- **MUST** 使用 Poetry 或 pip + `requirements.txt` 管理依赖。
- **MUST** 使用 `python-dotenv` 或 `Flask-Env` 管理环境变量。
- **MUST** 敏感配置从环境变量读取，**禁止**硬编码在代码中。

```python
import os
from flask import Flask

def create_app():
    app = Flask(__name__)
    app.config.update(
        SECRET_KEY=os.environ["FLASK_SECRET_KEY"],
        SQLALCHEMY_DATABASE_URI=os.environ["DATABASE_URL"],
        SQLALCHEMY_TRACK_MODIFICATIONS=False,
    )
    return app
```

## 2. 应用工厂模式

- **MUST** 使用 Flask Application Factory 模式创建应用实例。
- **MUST** 在 `create_app()` 函数中注册 Blueprints、初始化扩展、配置日志。
- **SHOULD** 将配置类独立为 `config.py`，支持多环境切换。

```python
# app/__init__.py
from flask import Flask
from app.extensions import db, migrate, jwt
from app.config import config_by_name

def create_app(config_name="development") -> Flask:
    app = Flask(__name__)
    app.config.from_object(config_by_name[config_name])

    # 初始化扩展
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)

    # 注册 Blueprints
    from app.api.v1 import api_v1_bp
    app.register_blueprint(api_v1_bp, url_prefix="/api/v1")

    # 注册错误处理器
    from app.errors import register_error_handlers
    register_error_handlers(app)

    return app
```

## 3. Flask Blueprints

- **MUST** 使用 Blueprints 按业务领域组织路由。
- **MUST** 每个 Blueprint 有明确的 `url_prefix`。
- **SHOULD** Blueprint 内路由使用 `@bp.route()` 装饰器。

```python
# app/api/v1/users.py
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required

users_bp = Blueprint("users", __name__)

@users_bp.route("/users", methods=["GET"])
@jwt_required()
def list_users():
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)
    users = User.query.paginate(page=page, per_page=per_page)
    return jsonify({
        "items": [user.to_dict() for user in users.items],
        "total": users.total,
        "page": page,
    })

@users_bp.route("/users/<int:user_id>", methods=["GET"])
@jwt_required()
def get_user(user_id: int):
    user = User.query.get_or_404(user_id)
    return jsonify(user.to_dict())
```

## 4. 数据库 (Flask-SQLAlchemy)

- **MUST** 使用 `Flask-SQLAlchemy` 进行数据库操作。
- **MUST** 使用 `Flask-Migrate`（Alembic 包装）管理数据库迁移。
- **SHOULD** Model 定义 `to_dict()` 方法用于序列化。

```python
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime, timezone

db = SQLAlchemy()

class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False, index=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, onupdate=lambda: datetime.now(timezone.utc))

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "username": self.username,
            "email": self.email,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat(),
        }
```

## 5. 序列化与验证 (Marshmallow)

- **MUST** 使用 Marshmallow 进行请求/响应的序列化和反序列化。
- **MUST** 使用 `Schema.load()` 验证输入，`Schema.dump()` 序列化输出。
- **SHOULD** 使用 `fields.Nested()` 处理关联对象。

```python
from marshmallow import Schema, fields, validate, validates, ValidationError

class UserSchema(Schema):
    id = fields.Integer(dump_only=True)
    username = fields.String(required=True, validate=validate.Length(min=3, max=50))
    email = fields.Email(required=True)
    password = fields.String(required=True, load_only=True, validate=validate.Length(min=8))
    is_active = fields.Boolean(dump_only=True)
    created_at = fields.DateTime(dump_only=True)

    @validates("username")
    def validate_username(self, value):
        reserved = {"admin", "root", "system"}
        if value.lower() in reserved:
            raise ValidationError(f"username '{value}' is reserved")

user_schema = UserSchema()
users_schema = UserSchema(many=True)
```

## 6. REST API (Flask-RESTX)

- **SHOULD** 使用 `Flask-RESTX` 构建 RESTful API（自动生成 Swagger 文档）。
- **SHOULD** 使用 `Namespace` + `Resource` 模式组织 API。
- **MAY** 使用原生 Flask Blueprints + Marshmallow（更轻量的场景）。

```python
from flask_restx import Namespace, Resource, fields

users_ns = Namespace("users", description="用户管理")

user_model = users_ns.model("User", {
    "id": fields.Integer(readonly=True),
    "username": fields.String(required=True, min_length=3, max_length=50),
    "email": fields.String(required=True),
    "is_active": fields.Boolean(readonly=True),
})

@users_ns.route("/")
class UserList(Resource):
    @users_ns.marshal_list_with(user_model)
    def get(self):
        """获取用户列表"""
        return User.query.all()

    @users_ns.expect(user_model)
    @users_ns.marshal_with(user_model, code=201)
    def post(self):
        """创建用户"""
        ...
```

## 7. 认证

- **MUST** 使用 `Flask-JWT-Extended` 实现 JWT 认证。
- **SHOULD** 使用 `Flask-Login` 管理 Session 认证（传统 Web 应用）。
- **MUST** access_token 有效期 ≤ 30 分钟，refresh_token 有效期 ≤ 7 天。

```python
from flask_jwt_extended import create_access_token, create_refresh_token, jwt_required, get_jwt_identity

@app.route("/auth/login", methods=["POST"])
def login():
    data = request.get_json()
    user = User.query.filter_by(username=data["username"]).first()
    if not user or not check_password_hash(user.password_hash, data["password"]):
        return {"error": "invalid credentials"}, 401
    access_token = create_access_token(identity=str(user.id))
    refresh_token = create_refresh_token(identity=str(user.id))
    return {"access_token": access_token, "refresh_token": refresh_token}
```

## 8. 应用上下文

- **MUST** 理解 Flask Application Context 和 Request Context 的区别。
- **MUST** 在应用上下文外使用 `with app.app_context():` 访问 `current_app`。
- **禁止** 在请求上下文外访问 `request`、`g`、`session` 对象。

## 9. 错误处理

- **MUST** 使用 `@app.errorhandler()` 注册全局错误处理器。
- **SHOULD** 定义自定义异常类和对应的 HTTP 状态码。
- **禁止** 返回裸字典作为错误响应，应使用统一格式。

```python
class AppException(Exception):
    def __init__(self, message: str, status_code: int = 400):
        self.message = message
        self.status_code = status_code

@app.errorhandler(AppException)
def handle_app_exception(error: AppException):
    return {"error": error.message, "code": error.status_code}, error.status_code

@app.errorhandler(404)
def handle_not_found(error):
    return {"error": "resource not found"}, 404
```

## 10. 日志

- **MUST** 使用 Python `logging` 模块配置日志。
- **SHOULD** 生产环境使用 JSON 格式日志输出到 stdout。
- **MUST** 配置不同级别的 logger：`app`、`sqlalchemy`、`werkzeug`。
