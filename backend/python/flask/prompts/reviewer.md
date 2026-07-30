# Flask Code Review Rules

> 本规则适用于对 Flask 项目代码进行审查的 AI 审查者角色。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. 应用工厂审查

- **MUST** 检查是否使用了 Application Factory 模式（`create_app()`）。
- **MUST** 验证扩展是否通过 `init_app()` 初始化，而非在模块级别绑定。
- **MUST** 检查 Blueprints 是否在 `create_app()` 中注册。
- **禁止** 在模块级别创建 Flask 应用实例（`app = Flask(__name__)` 放在全局）。

## 2. SQLAlchemy 审查

- **MUST** 检查 N+1 查询：循环内是否有数据库查询，是否使用 `joinedload()` / `selectinload()`。
- **MUST** 验证 Model 是否正确定义了 `__tablename__` 和索引。
- **MUST** 检查是否使用 `Flask-Migrate` 管理迁移，而非 `db.create_all()`。
- **禁止** 在请求上下文外使用 `db.session`。

```python
# 错误：N+1 查询
for order in Order.query.all():
    print(order.user.username)  # 每次循环查询一次 user

# 正确：使用 joinedload 预加载
from sqlalchemy.orm import joinedload
orders = Order.query.options(joinedload(Order.user)).all()
```

## 3. Blueprint 审查

- **MUST** 检查 Blueprint 是否有合理的 `url_prefix`。
- **MUST** 验证路由函数中是否包含业务逻辑（应放在 Service 层）。
- **SHOULD** 检查 Blueprint 嵌套是否合理（API 版本 Blueprint 下注册资源 Blueprint）。

## 4. Marshmallow 审查

- **MUST** 检查 Schema 的 `load_only` / `dump_only` 是否正确使用。
- **MUST** 验证敏感字段（密码）是否标记为 `load_only=True`。
- **MUST** 检查输入验证是否充分（`validate.Length`、`validate.Email` 等）。
- **SHOULD** 检查是否存在缺少 `@validates` 的自定义验证逻辑。

## 5. 认证审查

- **MUST** 检查需要认证的端点是否使用了 `@jwt_required()` 或 `@login_required`。
- **MUST** 验证 JWT Token 过期时间是否合理（≤ 30 分钟 access_token）。
- **MUST** 检查密码存储是否使用了 `werkzeug.security.generate_password_hash()`。
- **禁止** 明文存储密码。

## 6. 安全性审查

- **MUST** 检查 `SECRET_KEY` 是否从环境变量读取。
- **MUST** 检查 CORS 配置是否明确限制 `origins`。
- **MUST** 验证 SQL 注入风险（即使使用 ORM，原生 SQL 也需参数化）。
- **禁止** 在响应中返回 traceback（生产环境 `DEBUG=False`）。

## 7. 错误处理审查

- **MUST** 检查是否注册了全局错误处理器（`@app.errorhandler`）。
- **MUST** 验证错误响应格式是否统一。
- **禁止** 在 Blueprint 路由函数中 `try: ... except: return {"error": ...}` 而不使用统一错误处理。

## 8. 上下文审查

- **MUST** 检查 `request`、`g`、`session` 是否仅在请求上下文中使用。
- **MUST** 检查 `current_app` 是否仅在应用上下文中使用。
- **禁止** 在 Celery 任务中直接使用 `request` 对象。

## 9. 性能审查

- **MUST** 检查列表端点是否有分页。
- **SHOULD** 检查频繁查询是否使用了缓存。
- **MUST** 验证 Model 查询是否使用了 `with_entities()` 优化字段选择。

## 10. 测试审查

- **MUST** 检查新增端点是否有对应测试用例。
- **MUST** 验证测试是否使用了 `app.test_client()`。
- **禁止** 测试中连接生产数据库。
