# AGENTS.md — Flask 业务项目规则

> 本文件是 **Codex / 通用 AI Agent** 在 Flask 业务项目中的工作规则。
> 由 [structure-agent-rules](https://github.com/structure-projects/structure-agent-rules) 仓库的 `codex/AGENTS.md` 模板复制而来。
>
> **使用方式**：将本文件放在业务项目根目录，Codex 启动时自动加载。
> **详细规则**（如能访问 structure-agent-rules 仓库）：`prompts/developer.md` / `prompts/architect.md` / `prompts/components.md` / `prompts/tester.md` / `prompts/reviewer.md` / `prompts/validation.md` / `prompts/swagger.md` / `prompts/ci-cd.md`。

---

## 1. 技术栈硬约束

- Python 版本 ≥ 3.10。
- Flask ≥ 3.0 + Werkzeug ≥ 3.0。
- Flask-SQLAlchemy + Flask-Migrate 管理数据库。
- Marshmallow 序列化和验证。
- Flask-JWT-Extended 或 Flask-Login 认证。
- Flask-CORS 跨域管理。
- pytest + pytest-flask 测试。
- Celery + Redis 后台任务。

## 2. 项目结构

```
myapp/
├── app/
│   ├── __init__.py            # create_app() 工厂函数
│   ├── config.py              # 多环境配置类
│   ├── extensions.py          # Flask 扩展实例
│   ├── api/
│   │   └── v1/
│   │       ├── __init__.py    # v1 Blueprint 聚合
│   │       ├── users.py
│   │       ├── orders.py
│   │       └── auth.py
│   ├── models/
│   ├── schemas/               # Marshmallow Schema
│   ├── services/              # 业务逻辑层
│   ├── tasks/                 # Celery 任务
│   ├── errors.py
│   └── utils/
├── migrations/
├── tests/
│   ├── conftest.py
│   ├── unit/
│   └── integration/
├── wsgi.py
├── requirements/
├── Dockerfile
└── .env.example
```

## 3. 关键优先级

- **Application Factory**：`create_app()` 中完成所有初始化。
- **Blueprint 组织**：按业务领域拆分，嵌套 Blueprint 管理 API 版本。
- **扩展管理**：`extensions.py` 集中创建，`create_app()` 中 `init_app()`。

## 4. Application Factory

- **MUST** 使用 `create_app(config_name)` 工厂函数。
- **MUST** 在工厂函数中：加载配置 → 初始化扩展 → 注册 Blueprints → 注册错误处理器。
- **禁止** 在模块级别创建 `app = Flask(__name__)`。

## 5. 数据库

- **MUST** 使用 Flask-SQLAlchemy 进行 ORM 操作。
- **MUST** 使用 Flask-Migrate 管理迁移。
- **MUST** 使用 `joinedload()` / `selectinload()` 避免 N+1 查询。
- **禁止** 在循环中查询数据库。
- **禁止** 使用 `db.create_all()` 替代迁移。

## 6. 序列化与验证

- **MUST** 使用 Marshmallow Schema 进行请求验证（`Schema.load()`）。
- **MUST** 使用 Marshmallow Schema 进行响应序列化（`Schema.dump()`）。
- **MUST** 敏感字段（密码）使用 `load_only=True`。
- **SHOULD** 使用 `@validates` 实现自定义验证逻辑。

## 7. 认证

- **MUST** 使用 Flask-JWT-Extended 实现 JWT 认证。
- **MUST** access_token 有效期 ≤ 30 分钟。
- **MUST** 使用 `@jwt_required()` 保护需要认证的端点。
- **禁止** 明文存储密码，使用 `werkzeug.security.generate_password_hash()`。

## 8. 错误处理

- **MUST** 使用 `@app.errorhandler()` 注册全局错误处理器。
- **MUST** 返回统一的错误响应格式。
- **禁止** 在 Blueprint 路由函数中 `try: except: return {"error": ...}`。

## 9. 上下文

- **MUST** 理解 Application Context 和 Request Context 的区别。
- **禁止** 在请求上下文外访问 `request`、`g`、`session`。
- **禁止** 在 Celery 任务中直接使用 `request` 对象。

## 10. 测试

- **MUST** 使用 pytest + pytest-flask + `app.test_client()`。
- **MUST** 使用独立测试数据库。
- **MUST** 目标覆盖率 ≥ 80%。
- **禁止** mock 自己项目的 Model 或 Service。

## 11. 提交前自检

- [ ] 是否使用 Application Factory 模式（`create_app()`）？
- [ ] 扩展是否在 `extensions.py` 中创建并在 `create_app()` 中 `init_app()`？
- [ ] 是否有 N+1 查询？是否使用了 `joinedload`/`selectinload`？
- [ ] Marshmallow Schema 的 `load_only`/`dump_only` 是否正确？
- [ ] 认证端点是否使用 `@jwt_required()`？
- [ ] `SECRET_KEY` 是否从环境变量读取？
- [ ] CORS 配置是否安全？
- [ ] 是否有对应测试用例？`pytest` 是否全部通过？
- [ ] 是否有数据库迁移文件？

---

**详细规则**：`prompts/developer.md` / `prompts/architect.md` / `prompts/components.md` / `prompts/tester.md` / `prompts/reviewer.md` / `prompts/validation.md` / `prompts/swagger.md` / `prompts/ci-cd.md` / `CLAUDE.md`。
