# Flask Project Scaffolding Rules

> 本规则适用于使用 Flask 创建新 Python 项目的脚手架搭建。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. 项目初始化

- **MUST** 使用 Poetry 或 pip + `requirements/` 目录初始化项目。
- **MUST** Python 版本要求 ≥ 3.10。
- **MUST** 使用 Application Factory 模式（`create_app()` 函数）。

```bash
mkdir myapp && cd myapp
python -m venv .venv && source .venv/bin/activate

pip install flask flask-sqlalchemy flask-migrate flask-jwt-extended
pip install flask-cors marshmallow marshmallow-sqlalchemy
pip install flask-restx python-dotenv

# 开发依赖
pip install pytest pytest-flask pytest-cov ruff
```

## 2. 目录结构

- **MUST** 按以下标准结构组织项目：

```
myapp/
├── app/
│   ├── __init__.py            # create_app() 工厂函数
│   ├── config.py              # 多环境配置类
│   ├── extensions.py          # Flask 扩展实例
│   ├── api/
│   │   ├── __init__.py
│   │   └── v1/
│   │       ├── __init__.py    # v1 Blueprint 聚合
│   │       ├── users.py       # Blueprint + 路由
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
│   ├── tasks/                 # Celery 任务
│   │   ├── __init__.py
│   │   └── email_tasks.py
│   ├── errors.py              # 全局错误处理器
│   └── utils/
│       └── helpers.py
├── migrations/                # Flask-Migrate 自动生成
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   ├── unit/
│   └── integration/
├── wsgi.py                    # 生产入口
├── requirements/
│   ├── base.txt
│   ├── development.txt
│   └── production.txt
├── Dockerfile
├── docker-compose.yml
└── .env.example
```

## 3. create_app() 工厂

- **MUST** 在 `app/__init__.py` 中实现 `create_app()` 工厂函数。

```python
# app/__init__.py
from flask import Flask
from app.config import config_by_name
from app.extensions import db, migrate, jwt, cors

def create_app(config_name="development") -> Flask:
    app = Flask(__name__)
    app.config.from_object(config_by_name[config_name])

    # 初始化扩展
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    cors.init_app(app)

    # 注册 Blueprints
    from app.api.v1 import api_v1_bp
    app.register_blueprint(api_v1_bp, url_prefix="/api/v1")

    # 注册错误处理器
    from app.errors import register_error_handlers
    register_error_handlers(app)

    # 健康检查
    @app.route("/health")
    def health():
        return {"status": "healthy"}

    return app
```

## 4. 扩展管理

- **MUST** 在 `app/extensions.py` 中集中创建扩展实例（不绑定 app）。

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

## 5. 配置类

- **MUST** 使用类继承管理多环境配置。

```python
# app/config.py
import os

class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY", "dev-key")
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JWT_SECRET_KEY = os.environ.get("JWT_SECRET_KEY", SECRET_KEY)
    CELERY_BROKER_URL = os.environ.get("CELERY_BROKER_URL")

class DevelopmentConfig(Config):
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = os.environ.get("DEV_DATABASE_URL", "sqlite:///dev.db")

class TestingConfig(Config):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = "sqlite:///:memory:"

class ProductionConfig(Config):
    DEBUG = False
    SQLALCHEMY_DATABASE_URI = os.environ["DATABASE_URL"]

config_by_name = {
    "development": DevelopmentConfig,
    "testing": TestingConfig,
    "production": ProductionConfig,
}
```

## 6. wsgi.py 生产入口

- **MUST** 提供 `wsgi.py` 作为生产环境 WSGI 入口。

```python
# wsgi.py
from app import create_app

app = create_app("production")
```

## 7. 数据库初始化

- **MUST** 使用 `Flask-Migrate` 初始化迁移环境。

```bash
flask db init
flask db migrate -m "initial"
flask db upgrade
```

## 8. Dockerfile 模板

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
EXPOSE 8000
CMD ["gunicorn", "wsgi:app", "--bind", "0.0.0.0:8000", "--workers", "4"]
```

## 9. 环境变量

- **MUST** 提供 `.env.example` 作为环境变量模板。
- **禁止** 将 `.env` 提交到版本控制。

```bash
# .env.example
FLASK_APP=app
FLASK_ENV=development
SECRET_KEY=change-me-to-a-random-secret
JWT_SECRET_KEY=change-me-to-a-random-secret
DATABASE_URL=postgresql://user:password@localhost:5432/myapp
CELERY_BROKER_URL=redis://localhost:6379/0
CORS_ORIGINS=http://localhost:3000
```
