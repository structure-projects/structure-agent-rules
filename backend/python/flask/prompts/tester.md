# Flask Testing Rules

> 本规则适用于 Flask 项目的测试编写。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. 测试框架与工具

- **MUST** 使用 `pytest` 作为测试框架。
- **MUST** 使用 `pytest-flask` 或 `Flask.test_client()` 进行 API 测试。
- **MUST** 使用 `pytest-cov` 生成覆盖率报告，目标覆盖率 ≥ 80%。
- **MAY** 使用 `factory_boy` 或 `mixer` 生成测试数据。

```python
import pytest
from app import create_app
from app.extensions import db

@pytest.fixture
def app():
    app = create_app("testing")
    with app.app_context():
        db.create_all()
        yield app
        db.session.remove()
        db.drop_all()

@pytest.fixture
def client(app):
    return app.test_client()

@pytest.fixture
def runner(app):
    return app.test_cli_runner()
```

## 2. 测试分层

- **MUST** 单元测试（`tests/unit/`）：测试 Service 层和工具函数，mock 外部依赖。
- **MUST** 集成测试（`tests/integration/`）：测试完整 API 流程，使用测试数据库。
- **SHOULD** E2E 测试：测试关键业务流程的完整链路。

## 3. API 测试

- **MUST** 使用 `app.test_client()` 测试 HTTP 端点。
- **MUST** 测试覆盖 HTTP 状态码：200、201、400、401、403、404、422、500。
- **MUST** 验证响应体结构（字段名、类型、值）。
- **SHOULD** 测试认证：有效 Token、无效 Token、过期 Token、无 Token。
- **MUST** 测试分页：验证 `items`、`total`、`page` 字段。

```python
def test_create_user_success(client, auth_headers):
    response = client.post(
        "/api/v1/users/",
        json={"username": "newuser", "email": "new@test.com", "password": "Str0ng!Pass"},
        headers=auth_headers,
    )
    assert response.status_code == 201
    data = response.get_json()
    assert data["username"] == "newuser"
    assert "password" not in data

def test_get_user_unauthorized(client):
    response = client.get("/api/v1/users/1")
    assert response.status_code == 401
```

## 4. 数据库测试

- **MUST** 使用独立的测试数据库（如 SQLite 内存数据库或测试 PostgreSQL）。
- **MUST** 使用 `create_all()` 和 `drop_all()` 管理测试 schema。
- **MUST** 每个测试函数结束后清理数据，保证测试隔离。
- **禁止** 连接生产/开发数据库进行测试。

```python
@pytest.fixture
def db_session(app):
    with app.app_context():
        yield db.session
        db.session.rollback()
```

## 5. Mock 策略

- **MUST** 单元测试中 mock 外部服务（Redis、第三方 API、Celery 任务）。
- **禁止** mock 自己项目的 Model、Service 或数据库操作。
- **SHOULD** 使用 `unittest.mock.patch` 或 `pytest-mock` 进行 mock。

## 6. 参数化测试

- **SHOULD** 使用 `@pytest.mark.parametrize` 覆盖多种输入场景。
- **MUST** 边界值测试：空字符串、超长字符串、负数、零、SQL 注入字符。

```python
@pytest.mark.parametrize("username,expected_status", [
    ("ab", 400),          # 太短
    ("a" * 51, 400),      # 太长
    ("admin", 400),       # 保留字
    ("", 400),            # 空
])
def test_username_validation(client, username, expected_status):
    response = client.post("/api/v1/users/", json={
        "username": username, "email": "test@test.com", "password": "Str0ng!Pass"
    })
    assert response.status_code == expected_status
```

## 7. JWT 认证测试

- **MUST** 测试 JWT 认证端点：登录成功、登录失败、Token 刷新。
- **SHOULD** 创建 `auth_headers` fixture 复用认证 Header。

```python
@pytest.fixture
def auth_headers(client):
    response = client.post("/api/v1/auth/login", json={
        "username": "testuser", "password": "testpass"
    })
    token = response.get_json()["access_token"]
    return {"Authorization": f"Bearer {token}"}
```

## 8. Marshmallow Schema 测试

- **SHOULD** 单独测试 Schema 的验证逻辑。
- **MUST** 测试有效输入和无效输入。

```python
def test_user_schema_valid():
    data = {"username": "john", "email": "john@test.com", "password": "Str0ng!Pass"}
    result = UserSchema().load(data)
    assert result["username"] == "john"

def test_user_schema_invalid_short_username():
    data = {"username": "ab", "email": "john@test.com", "password": "Str0ng!Pass"}
    with pytest.raises(ValidationError):
        UserSchema().load(data)
```

## 9. 测试组织

- **MUST** 测试文件命名为 `test_{module_name}.py`。
- **MUST** 测试函数命名为 `test_{function_name}_{scenario}`。
- **SHOULD** 使用 `conftest.py` 管理 fixtures。
- **MUST** 在 `pytest.ini` 或 `pyproject.toml` 中配置测试选项。

```toml
[tool.pytest.ini_options]
FLASK_APP = "app"
addopts = "-v --tb=short"
markers = [
    "slow: marks tests as slow",
    "integration: marks tests as integration tests",
]
```

## 10. CI 集成

- **MUST** 在 CI 中运行 `pytest --cov --cov-report=xml`。
- **MUST** 测试失败时 CI 中断，**禁止**跳过测试合入代码。
- **SHOULD** 配置覆盖率阈值：低于 80% 警告，低于 70% 失败。
