# Flask Architecture Rules

> 本规则适用于 Flask 项目的架构设计决策。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. 应用工厂模式

- **MUST** 使用 Flask Application Factory 模式（`create_app()` 函数）。
- **MUST** 在 `create_app()` 中完成所有初始化：配置加载、扩展初始化、Blueprint 注册、错误处理注册。
- **SHOULD** 支持通过参数或环境变量切换配置（`development`、`testing`、`production`）。

## 2. 项目结构

- **MUST** 按以下结构组织项目：

```
myapp/
├── app/
│   ├── __init__.py            # create_app() 工厂函数
│   ├── config.py              # 多环境配置类
│   ├── extensions.py          # Flask 扩展实例（db、migrate、jwt）
│   ├── api/
│   │   ├── __init__.py
│   │   └── v1/
│   │       ├── __init__.py    # v1 Blueprint 聚合
│   │       ├── users.py       # 用户 Blueprint
│   │       ├── orders.py
│   │       └── auth.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── order.py
│   ├── schemas/               # Marshmallow Schema
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── order.py
│   ├── services/              # 业务逻辑层
│   │   ├── __init__.py
│   │   ├── user_service.py
│   │   └── order_service.py
│   ├── errors.py              # 全局错误处理器
│   └── utils/
│       ├── __init__.py
│       └── helpers.py
├── migrations/                # Flask-Migrate 迁移
├── tests/
│   ├── conftest.py
│   ├── unit/
│   └── integration/
├── wsgi.py                    # 生产入口
├── requirements/
│   ├── base.txt
│   ├── development.txt
│   └── production.txt
├── Dockerfile
└── .env.example
```

## 3. Blueprint 组织

- **MUST** 使用 Blueprints 按业务领域拆分路由。
- **MUST** 每个 Blueprint 注册到 `create_app()` 中，带 `url_prefix`。
- **SHOULD** 使用 Blueprint 嵌套：API 版本 Blueprint 下注册资源 Blueprint。

```python
# app/api/v1/__init__.py
from flask import Blueprint
from app.api.v1.users import users_bp
from app.api.v1.orders import orders_bp

api_v1_bp = Blueprint("api_v1", __name__)
api_v1_bp.register_blueprint(users_bp)
api_v1_bp.register_blueprint(orders_bp)
```

## 4. 分层架构

- **SHOULD** 在复杂业务中引入 Service 层（`services/`），Blueprint 路由函数仅处理 HTTP 请求/响应。
- **MUST** Blueprint 路由函数职责：参数解析、权限检查、调用 Service、格式化响应。
- **MUST** Service 层职责：业务逻辑编排、事务管理、调用外部服务。
- **MUST** Model 层职责：数据定义、ORM 映射、简单属性方法。

## 5. 扩展管理

- **MUST** 使用 `extensions.py` 集中管理 Flask 扩展实例。
- **MUST** 在 `create_app()` 中调用 `init_app()` 初始化扩展。

```python
# app/extensions.py
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from flask_cors import CORS

db = SQLAlchemy()
migrate = Migrate()
jwt = JWTManager()
cors = CORS()
```

## 6. 配置管理

- **MUST** 使用类继承管理多环境配置。
- **MUST** 生产环境配置从环境变量读取。
- **SHOULD** 使用 `python-dotenv` 加载 `.env` 文件。

```python
# app/config.py
import os

class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY", "dev-key")
    SQLALCHEMY_TRACK_MODIFICATIONS = False

class DevelopmentConfig(Config):
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = os.environ.get("DEV_DATABASE_URL")

class ProductionConfig(Config):
    DEBUG = False
    SQLALCHEMY_DATABASE_URI = os.environ["DATABASE_URL"]

config_by_name = {
    "development": DevelopmentConfig,
    "production": ProductionConfig,
}
```

## 7. 认证架构

- **SHOULD** 使用 `Flask-JWT-Extended` 实现 API JWT 认证。
- **SHOULD** 使用 `Flask-Login` 实现传统 Session 认证。
- **MUST** 使用 `@jwt_required()` 或 `@login_required` 保护端点。
- **MAY** 使用 `Flask-Principal` 实现细粒度权限控制。

## 8. 后台任务

- **SHOULD** 使用 Celery + Redis 处理异步任务。
- **SHOULD** 在 `create_app()` 中创建 Celery 实例并使用 `make_celery()` 工厂函数。
- **MUST** 任务函数幂等，支持重试。

```python
from celery import Celery

def make_celery(app: Flask) -> Celery:
    celery = Celery(app.import_name, broker=app.config["CELERY_BROKER_URL"])
    celery.conf.update(app.config)

    class ContextTask(celery.Task):
        def __call__(self, *args, **kwargs):
            with app.app_context():
                return self.run(*args, **kwargs)

    celery.Task = ContextTask
    return celery
```

## 9. 部署架构

- **SHOULD** 使用 Gunicorn + Uvicorn workers 部署。
- **SHOULD** 使用 Nginx 作为反向代理。
- **MUST** 使用 Docker 容器化部署。
- **MUST** 生产环境使用 WSGI 入口（`wsgi.py`）。

```python
# wsgi.py
from app import create_app
app = create_app("production")
```
