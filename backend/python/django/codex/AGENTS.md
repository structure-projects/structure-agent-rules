# AGENTS.md — Django 业务项目规则

> 本文件是 **Codex / 通用 AI Agent** 在 Django 业务项目中的工作规则。
> 由 [structure-agent-rules](https://github.com/structure-projects/structure-agent-rules) 仓库的 `codex/AGENTS.md` 模板复制而来。
>
> **使用方式**：将本文件放在业务项目根目录，Codex 启动时自动加载。
> **详细规则**（如能访问 structure-agent-rules 仓库）：`prompts/developer.md` / `prompts/architect.md` / `prompts/components.md` / `prompts/tester.md` / `prompts/reviewer.md` / `prompts/validation.md` / `prompts/swagger.md` / `prompts/ci-cd.md`。

---

## 1. 技术栈硬约束

- Python 版本 ≥ 3.10。
- Django ≥ 4.2 LTS + Django REST Framework ≥ 3.15。
- PostgreSQL 作为主数据库。
- Celery + Redis 处理后台任务。
- pytest-django 测试。
- drf-spectacular 生成 API 文档。

## 2. 项目结构

```
myproject/
├── config/
│   ├── settings/
│   │   ├── base.py
│   │   ├── development.py
│   │   └── production.py
│   ├── urls.py
│   └── wsgi.py
├── apps/
│   ├── users/
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── serializers.py
│   │   ├── services.py
│   │   ├── urls.py
│   │   ├── admin.py
│   │   └── tasks.py
│   └── orders/
├── core/
│   ├── models.py
│   ├── pagination.py
│   ├── permissions.py
│   └── exceptions.py
├── manage.py
├── requirements/
│   ├── base.txt
│   ├── development.txt
│   └── production.txt
└── Dockerfile
```

## 3. 关键优先级

- **安全**：`DEBUG=False`（生产）、CSRF/HTTPS Cookie、环境变量管理密钥。
- **ORM**：`select_related()` / `prefetch_related()` 避免 N+1、QuerySet 链式调用。
- **分层**：View → Service → Model，View 不包含业务逻辑。

## 4. DRF API

- **MUST** 使用 `ModelViewSet` + `Router` 构建 RESTful API。
- **MUST** 使用 `ModelSerializer` 进行序列化。
- **MUST** 使用 `permission_classes` 控制访问权限。
- **MUST** API 版本化使用 URL 前缀：`/api/v1/`。
- **MUST** 所有列表端点启用分页。

## 5. Django ORM

- **MUST** 使用 Django ORM 进行数据库操作，**禁止**拼接原生 SQL 字符串。
- **MUST** 外键关联使用 `select_related()`，多对多使用 `prefetch_related()`。
- **MUST** 每次模型变更生成迁移文件（`makemigrations` + `migrate`）。
- **禁止** 在循环中查询数据库（N+1 问题）。

## 6. 安全配置

- **MUST** 生产环境：`DEBUG=False`、`SECURE_SSL_REDIRECT=True`。
- **MUST** `SESSION_COOKIE_SECURE=True`、`CSRF_COOKIE_SECURE=True`。
- **MUST** `ALLOWED_HOSTS` 限制允许的主机名。
- **MUST** 使用 `django-cors-headers` 管理 CORS。
- **禁止** 在 settings.py 中硬编码密钥。
- **禁止** 在模板中使用 `|safe` 处理用户输入。

## 7. 后台任务

- **MUST** 使用 Celery + Redis 处理异步任务。
- **MUST** 任务函数幂等，支持 `autoretry_for` + `max_retries`。
- **SHOULD** 使用 `django-celery-beat` 管理定时任务。

## 8. 测试

- **MUST** 使用 `pytest-django` + `pytest-cov`。
- **MUST** 使用 Django 测试数据库（自动创建和销毁）。
- **MUST** 使用 `model_bakery` 或 `factory_boy` 生成测试数据。
- **MUST** 目标覆盖率 ≥ 80%。
- **禁止** 连接生产/开发数据库进行测试。

## 9. 提交前自检

- [ ] `settings.py` 中 `DEBUG` 是否为 `False`（生产环境）？
- [ ] 密钥是否从环境变量读取？
- [ ] 是否有 N+1 查询？是否使用了 `select_related`/`prefetch_related`？
- [ ] 是否有对应迁移文件？
- [ ] DRF Serializer 的 `fields` 是否排除了敏感字段？
- [ ] 列表端点是否启用了分页？
- [ ] 是否有对应测试用例？`pytest` 是否全部通过？
- [ ] CORS 配置是否安全？

---

**详细规则**：`prompts/developer.md` / `prompts/architect.md` / `prompts/components.md` / `prompts/tester.md` / `prompts/reviewer.md` / `prompts/validation.md` / `prompts/swagger.md` / `prompts/ci-cd.md` / `CLAUDE.md`。
