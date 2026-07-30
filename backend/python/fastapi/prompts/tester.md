# FastAPI Testing Rules

> 本规则适用于 FastAPI 项目的测试编写。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. 测试框架与工具

- **MUST** 使用 `pytest` 作为测试框架。
- **MUST** 使用 `httpx.AsyncClient` + `TestClient`（来自 `fastapi.testclient`）进行 API 测试。
- **MUST** 使用 `pytest-asyncio` 支持异步测试，配置 `asyncio_mode = "auto"`。
- **SHOULD** 使用 `pytest-cov` 生成覆盖率报告，目标覆盖率 ≥ 80%。
- **MAY** 使用 `factory_boy` 或 `polyfactory` 生成测试数据。

```python
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.fixture
async def async_client():
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        yield client
```

## 2. 测试分层

- **MUST** 单元测试（`test_*.py`）：测试 Service 层和 Repository 层，mock 外部依赖。
- **MUST** 集成测试（`test_*_integration.py` 或 `conftest.py` 中标记 `integration`）：测试完整 API 流程，使用真实测试数据库。
- **SHOULD** 端到端测试（E2E）：测试关键业务流程的完整链路。

## 3. 数据库测试

- **MUST** 集成测试使用独立的测试数据库，**禁止**连接生产/开发数据库。
- **SHOULD** 使用 Docker 启动临时 PostgreSQL 容器进行测试。
- **MUST** 每个测试函数结束后回滚或清理数据，保证测试隔离。
- **SHOULD** 使用 `pytest-alembic` 验证迁移脚本的正确性。

```python
@pytest.fixture
async def db_session():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with async_session_factory() as session:
        yield session
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
```

## 4. Mock 策略

- **MUST** 单元测试中 mock 外部服务调用（Redis、第三方 API、消息队列）。
- **禁止** mock 自己项目的 Repository 或 Service（应在集成测试中验证）。
- **SHOULD** 使用 `unittest.mock.AsyncMock` mock 异步调用。
- **MAY** 使用 `pytest-mock` 插件简化 mock 操作。

## 5. API 测试

- **MUST** 测试覆盖 HTTP 状态码：200、201、400、401、403、404、422、500。
- **MUST** 验证响应体结构（字段名、类型、值范围）。
- **SHOULD** 测试认证：带有效 Token、无效 Token、过期 Token、无 Token 的场景。
- **MUST** 测试分页：验证 `total`、`items`、`page`、`size` 字段。

```python
async def test_create_user_success(async_client, auth_headers):
    response = await async_client.post(
        "/api/v1/users/",
        json={"username": "newuser", "email": "new@test.com", "password": "Str0ng!Pass"},
        headers=auth_headers,
    )
    assert response.status_code == 201
    data = response.json()
    assert data["username"] == "newuser"
    assert "password" not in data
```

## 6. 参数化测试

- **SHOULD** 使用 `@pytest.mark.parametrize` 覆盖多种输入场景。
- **MUST** 边界值测试：空字符串、超长字符串、负数、零、极大值、SQL 注入字符。

```python
@pytest.mark.parametrize("username,expected_status", [
    ("ab", 422),          # 太短
    ("a" * 51, 422),      # 太长
    ("admin", 422),       # 保留字
    ("user@name", 422),   # 非法字符
])
async def test_create_user_validation(async_client, username, expected_status):
    response = await async_client.post("/api/v1/users/", json={"username": username, ...})
    assert response.status_code == expected_status
```

## 7. 测试组织

- **MUST** 测试文件命名为 `test_{module_name}.py`。
- **MUST** 测试函数命名为 `test_{function_name}_{scenario}`。
- **SHOULD** 使用 `conftest.py` 管理 fixtures，按目录层级继承。
- **MUST** 使用 `pytest.ini` 或 `pyproject.toml` 配置测试选项。

## 8. CI 集成

- **MUST** 在 CI 流水线中运行 `pytest --cov --cov-report=xml`。
- **MUST** 测试失败时 CI 流水线中断，**禁止**跳过测试合入代码。
- **SHOULD** 配置覆盖率阈值：低于 80% 时 CI 警告，低于 70% 时 CI 失败。
