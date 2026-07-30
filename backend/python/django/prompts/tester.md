# Django Testing Rules

> 本规则适用于 Django 项目的测试编写。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. 测试框架与工具

- **MUST** 使用 `pytest-django` 作为测试框架（替代 Django 默认的 `unittest`）。
- **MUST** 使用 `pytest` 编写测试，配置 `DJANGO_SETTINGS_MODULE` 指向测试 settings。
- **SHOULD** 使用 `pytest-cov` 生成覆盖率报告，目标覆盖率 ≥ 80%。
- **MAY** 使用 `factory_boy` 或 `model_bakery` 生成测试数据。
- **MAY** 使用 `pytest-xdist` 并行运行测试。

```python
import pytest
from django.test import Client
from model_bakery import baker

@pytest.fixture
def api_client():
    return Client()

@pytest.fixture
def authenticated_client(api_client, django_user_model):
    user = django_user_model.objects.create_user(username="testuser", password="testpass")
    api_client.login(username="testuser", password="testpass")
    return api_client
```

## 2. 测试分层

- **MUST** 单元测试（`tests/unit/`）：测试 Service 层和工具函数，mock 外部依赖。
- **MUST** 集成测试（`tests/integration/`）：测试完整 API 流程，使用测试数据库。
- **SHOULD** E2E 测试：测试关键业务流程的完整链路。

## 3. DRF API 测试

- **MUST** 使用 DRF `APIClient` 或 Django `Client` 测试 API。
- **MUST** 测试覆盖 HTTP 状态码：200、201、400、401、403、404、405。
- **MUST** 验证响应体结构（字段名、类型、值）。
- **SHOULD** 测试认证：有效 Token、无效 Token、过期 Token、无 Token。
- **MUST** 测试分页：验证 `count`、`next`、`previous`、`results` 字段。

```python
def test_create_user_success(api_client):
    response = api_client.post(
        "/api/v1/users/",
        {"username": "newuser", "email": "new@test.com", "password": "Str0ng!Pass"},
        content_type="application/json",
    )
    assert response.status_code == 201
    data = response.json()
    assert data["username"] == "newuser"
    assert "password" not in data

def test_create_user_unauthorized(client):
    response = client.post("/api/v1/users/", {"username": "test"}, content_type="application/json")
    assert response.status_code == 401
```

## 4. 数据库测试

- **MUST** 使用 Django 测试数据库（自动创建和销毁），**禁止**连接生产/开发数据库。
- **MUST** 使用 `pytest.mark.django_db` 标记需要数据库的测试。
- **SHOULD** 使用 `transaction=True` 在事务中运行测试以加速（注意数据库支持）。
- **MUST** 使用 `model_bakery` 或 fixtures 创建测试数据。

```python
@pytest.mark.django_db
def test_order_creation():
    user = baker.make(User, username="buyer")
    product = baker.make(Product, price=100.00)
    order = OrderService.create_order(user_id=user.id, items=[{"product_id": product.id, "quantity": 2}])
    assert order.total_amount == 200.00
```

## 5. Mock 策略

- **MUST** 单元测试中 mock 外部服务（Celery、Redis、第三方 API）。
- **禁止** mock 自己项目的 Model、Service 或 Serializer。
- **SHOULD** 使用 `unittest.mock.patch` 或 `pytest-mock` 进行 mock。

## 6. 参数化测试

- **SHOULD** 使用 `@pytest.mark.parametrize` 覆盖多种输入场景。
- **MUST** 边界值测试：空字符串、超长字符串、负数、零、SQL 注入字符。

```python
@pytest.mark.django_db
@pytest.mark.parametrize("username,expected_status", [
    ("ab", 400),          # 太短
    ("a" * 151, 400),     # 太长
    ("admin", 400),       # 保留字
    ("", 400),            # 空
])
def test_username_validation(api_client, username, expected_status):
    response = api_client.post("/api/v1/users/", {
        "username": username, "email": "test@test.com", "password": "Str0ng!Pass"
    }, content_type="application/json")
    assert response.status_code == expected_status
```

## 7. Celery 任务测试

- **SHOULD** 使用 `CELERY_TASK_ALWAYS_EAGER = True` 在测试中同步执行任务。
- **SHOULD** 单独测试 Celery 任务的业务逻辑（调用任务函数直接测试）。

## 8. 测试组织

- **MUST** 测试文件命名为 `test_{module_name}.py`。
- **MUST** 测试函数命名为 `test_{function_name}_{scenario}`。
- **SHOULD** 使用 `conftest.py` 管理 fixtures。
- **MUST** 在 `pytest.ini` 或 `pyproject.toml` 中配置 Django 测试选项。

```toml
[tool.pytest.ini_options]
DJANGO_SETTINGS_MODULE = "config.settings.test"
addopts = "-v --tb=short --strict-markers"
markers = [
    "slow: marks tests as slow",
    "integration: marks tests as integration tests",
]
```

## 9. CI 集成

- **MUST** 在 CI 中运行 `pytest --cov --cov-report=xml`。
- **MUST** 测试失败时 CI 中断，**禁止**跳过测试合入代码。
- **SHOULD** 配置覆盖率阈值：低于 80% 警告，低于 70% 失败。
