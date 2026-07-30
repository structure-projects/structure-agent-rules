# FastAPI CI/CD Rules

> 本规则适用于 FastAPI 项目的 CI/CD 流水线配置。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. CI 工具选择

- **MUST** 使用 GitHub Actions 作为 CI/CD 平台（如使用 GitLab 则用 GitLab CI）。
- **SHOULD** CI 配置文件放在 `.github/workflows/ci.yml`。

## 2. CI 流水线阶段

### 阶段一：代码检查（Lint & Type Check）

- **MUST** 运行 `ruff check .` 进行代码风格和静态分析。
- **MUST** 运行 `ruff format --check .` 检查代码格式。
- **MUST** 运行 `mypy .` 进行类型检查。

### 阶段二：单元测试

- **MUST** 运行 `pytest tests/unit/ -v --cov=app --cov-report=xml`。
- **MUST** 上传覆盖率报告到 Codecov 或 Coveralls。

### 阶段三：集成测试

- **MUST** 使用 Docker Compose 启动 PostgreSQL 和 Redis 服务。
- **MUST** 运行 `pytest tests/integration/ -v`。
- **SHOULD** 集成测试通过后才允许构建 Docker 镜像。

### 阶段四：构建与推送

- **MUST** 使用 Docker 多阶段构建。
- **MUST** 镜像标签使用 `git tag` 版本号 + `latest`。
- **SHOULD** 推送到私有镜像仓库（如 Harbor、ECR、ACR）。

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint-and-type:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: "pip"
      - run: pip install ruff mypy
      - run: ruff check .
      - run: ruff format --check .
      - run: mypy .

  test:
    needs: lint-and-type
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test_db
        ports: ["5432:5432"]
      redis:
        image: redis:7-alpine
        ports: ["6379:6379"]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: "pip"
      - run: pip install -e ".[dev]"
      - run: pytest -v --cov=app --cov-report=xml
      - uses: codecov/codecov-action@v4
        with:
          file: ./coverage.xml

  build:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build Docker image
        run: docker build -t app:${{ github.sha }} .
```

## 3. 依赖管理

- **MUST** 使用 `pip-tools`（`pip-compile` + `pip-sync`）或 Poetry 锁定依赖版本。
- **MUST** `requirements.txt` 或 `poetry.lock` 文件纳入版本控制。
- **SHOULD** CI 中运行 `pip-audit` 或 `safety check` 扫描已知漏洞。
- **禁止** 使用 `latest` 标签的 Docker 基础镜像，**MUST** 指定精确版本。

## 4. 环境管理

- **MUST** 区分至少三个环境：`development`、`staging`、`production`。
- **MUST** 各环境的配置通过环境变量注入，**禁止**硬编码在代码中。
- **SHOULD** 使用 GitHub Environments 管理部署审批和密钥保护。

## 5. CD 部署

- **SHOULD** 使用 `docker-compose` 或 Kubernetes manifests 定义部署配置。
- **MUST** 部署前运行数据库迁移（`alembic upgrade head`）。
- **MUST** 实现健康检查端点（`/health`），部署后验证服务可用性。
- **SHOULD** 支持蓝绿部署或滚动更新，减少停机时间。

## 6. 数据库迁移

- **MUST** 在 CD 流水线中自动执行 Alembic 迁移。
- **MUST** 迁移前备份数据库（生产环境）。
- **禁止** 在应用启动时自动执行迁移（生产环境），应作为独立部署步骤。

## 7. 监控与告警

- **SHOULD** 部署 Prometheus + Grafana 监控服务指标。
- **SHOULD** 使用 Sentry 捕获运行时异常。
- **MUST** 配置健康检查端点供负载均衡器探测。
