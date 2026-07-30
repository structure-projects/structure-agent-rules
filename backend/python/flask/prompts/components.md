# Flask Ecosystem Components

> 本规则汇总 Flask 生态中常用组件的选型与使用规范。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. 核心框架

| 组件 | 版本要求 | 说明 |
|---|---|---|
| **Flask** | ≥ 3.0 | Web 微框架 |
| **Werkzeug** | ≥ 3.0 | WSGI 工具库 |
| **Jinja2** | ≥ 3.1 | 模板引擎 |

## 2. 数据库

### Flask-SQLAlchemy（MUST）

- **MUST** 使用 `Flask-SQLAlchemy` 进行 ORM 操作。
- **MUST** 通过 `SQLALCHEMY_DATABASE_URI` 配置数据库连接。
- **MUST** 使用 `SQLALCHEMY_TRACK_MODIFICATIONS = False`。

```python
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

def create_app():
    app = Flask(__name__)
    app.config["SQLALCHEMY_DATABASE_URI"] = os.environ["DATABASE_URL"]
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    db.init_app(app)
    return app
```

### Flask-Migrate（MUST）

- **MUST** 使用 `Flask-Migrate`（Alembic 包装）管理数据库迁移。
- **MUST** 迁移命令：`flask db migrate -m "description"`、`flask db upgrade`、`flask db downgrade`。

```python
from flask_migrate import Migrate
migrate = Migrate()

# 在 create_app() 中
migrate.init_app(app, db)
```

## 3. 序列化与验证

### Marshmallow（MUST）

- **MUST** 使用 Marshmallow 进行请求/响应序列化和反序列化。
- **MUST** 使用 `Schema.load()` 验证输入，`Schema.dump()` 序列化输出。
- **SHOULD** 使用 `marshmallow-sqlalchemy` 自动从 SQLAlchemy Model 生成 Schema。

```python
from marshmallow_sqlalchemy import SQLAlchemyAutoSchema

class UserSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = User
        load_instance = True
        exclude = ("password_hash",)
```

### Flask-Marshmallow（MAY）

- **MAY** 使用 `Flask-Marshmallow` 简化 Marshmallow 与 Flask 的集成。

## 4. REST API

### Flask-RESTX（SHOULD）

- **SHOULD** 使用 `Flask-RESTX` 构建 RESTful API（自动生成 Swagger 文档）。
- **MUST** 使用 `Namespace` + `Resource` 模式组织 API。

### Flask-RESTful（MAY）

- **MAY** 使用 `Flask-RESTful` 作为更轻量的 REST API 方案。

```python
from flask_restx import Api
from app.api.v1.users import users_ns

api = Api(title="My API", version="1.0", doc="/api/docs/")
api.add_namespace(users_ns, path="/api/v1/users")
api.init_app(app)
```

## 5. 认证

### Flask-JWT-Extended（MUST）

- **MUST** 使用 `Flask-JWT-Extended` 实现 JWT 认证。
- **MUST** access_token 有效期 ≤ 30 分钟。

### Flask-Login（SHOULD）

- **SHOULD** 使用 `Flask-Login` 管理传统 Session 认证。
- **MUST** 实现 `UserMixin` 的 `is_authenticated`、`is_active` 等属性。

## 6. CORS

### Flask-CORS（MUST）

- **MUST** 使用 `Flask-CORS` 管理跨域请求。
- **禁止** 生产环境 `CORS(app, origins="*")` 配合 `supports_credentials=True`。

```python
from flask_cors import CORS

CORS(app, origins=os.environ.get("CORS_ORIGINS", "").split(","))
```

## 7. 后台任务

### Celery（SHOULD）

- **SHOULD** 使用 Celery + Redis/RabbitMQ 处理异步任务。
- **MUST** 使用 `make_celery()` 工厂函数在 Flask 应用上下文中创建 Celery 实例。

## 8. 配置管理

### python-dotenv（MUST）

- **MUST** 使用 `python-dotenv` 加载 `.env` 文件。
- **MUST** 使用 `os.environ.get()` 读取环境变量，提供合理的默认值。

## 9. 测试

| 工具 | 用途 |
|---|---|
| **pytest** | 测试框架 |
| **pytest-flask** | Flask 测试 fixture |
| **pytest-cov** | 覆盖率报告 |
| **factory_boy** | 测试数据工厂 |
| **mixer** | 轻量级 Model fixture |

## 10. 其他常用扩展

| 扩展 | 用途 |
|---|---|
| **Flask-Admin** | 管理后台 |
| **Flask-Mail** | 邮件发送 |
| **Flask-Caching** | 缓存 |
| **Flask-SocketIO** | WebSocket 支持 |
| **Flask-APScheduler** | 定时任务 |
| **Flask-Limiter** | 速率限制 |
| **Flask-Bcrypt** | 密码哈希 |

## 11. 禁止使用的组件

- **禁止** 使用 `flask-script`（已废弃，使用 Flask CLI）。
- **禁止** 使用 `pickle` 序列化用户输入数据。
- **禁止** 使用 `flask-restless`（长期未维护）。
