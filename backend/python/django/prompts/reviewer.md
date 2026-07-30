# Django Code Review Rules

> 本规则适用于对 Django 项目代码进行审查的 AI 审查者角色。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. Django ORM 审查

- **MUST** 检查是否存在 N+1 查询：View/Service 中是否在循环内查询数据库。
- **MUST** 检查外键关联是否使用 `select_related()`，多对多关联是否使用 `prefetch_related()`。
- **MUST** 验证是否使用 `QuerySet` 而非拼接原生 SQL。
- **禁止** 在 `queryset` 属性中使用 `all()` 后额外过滤（应直接在 `get_queryset()` 中过滤）。

```python
# 错误：N+1 查询
for order in orders:
    print(order.user.username)  # 每次循环查询一次 user 表

# 正确
orders = Order.objects.select_related("user").all()
for order in orders:
    print(order.user.username)  # 仅一次查询
```

## 2. 序列化器审查

- **MUST** 检查 DRF Serializer 的 `fields` 是否包含不必要的敏感字段。
- **MUST** 验证 `read_only_fields` 是否正确设置（`id`、`created_at`、`updated_at`）。
- **SHOULD** 检查是否使用 `SerializerMethodField` 替代了可在查询中计算的字段。
- **禁止** 在 Serializer 的 `validate` 方法中执行数据库查询（应放在 Service 层）。

## 3. 视图审查

- **MUST** 检查 View/ViewSet 中是否包含业务逻辑（应放在 Service 层）。
- **MUST** 验证权限类是否与端点匹配。
- **MUST** 检查分页是否在所有列表端点上正确配置。
- **SHOULD** 检查 `@action` 的 `methods` 参数是否与操作语义匹配。

## 4. 安全性审查

- **MUST** 检查 `settings.py` 中 `DEBUG` 是否在生产环境为 `False`。
- **MUST** 验证 `ALLOWED_HOSTS` 是否正确配置。
- **MUST** 检查 CSRF、XSS、SQL 注入防护是否到位。
- **MUST** 检查密码存储是否使用 Django 默认的 PBKDF2/Argon2 哈希。
- **禁止** 在代码中硬编码密钥、密码、Token。
- **禁止** 在模板中使用 `|safe` 过滤器处理用户输入。

## 5. 数据库迁移审查

- **MUST** 检查模型变更是否有对应迁移文件。
- **MUST** 验证迁移是否可逆（`makemigrations` 自动生成的有 `reverse_code`）。
- **禁止** 修改已合并到主分支的迁移文件。

## 6. 中间件与信号审查

- **MUST** 检查中间件顺序是否正确（SecurityMiddleware 应最先）。
- **SHOULD** 验证 Signal handler 中是否包含耗时操作（应异步化）。
- **MUST** 检查 Signal handler 是否处理了异常，避免影响主流程。

## 7. 性能审查

- **MUST** 检查 `list()` 端点是否启用了分页。
- **SHOULD** 检查频繁查询的数据是否使用了缓存。
- **MUST** 验证 `QuerySet` 是否使用了 `.only()` / `.defer()` 优化字段选择。
- **SHOULD** 检查是否存在不必要的 `count()` + 数据查询组合（可用 `.exists()` 替代）。

## 8. 测试审查

- **MUST** 检查新增端点/Service 是否有对应测试用例。
- **SHOULD** 验证测试是否覆盖了认证/权限场景。
- **禁止** 测试中使用生产数据库配置。

## 9. 管理后台审查

- **MUST** 检查 `ModelAdmin` 的 `list_display` 是否包含外键字段（会导致额外查询）。
- **SHOULD** 使用 `raw_id_fields` 替代外键下拉框（大数据量场景）。
