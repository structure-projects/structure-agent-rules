# Django CI/CD Rules

> 本规则适用于 Django 项目的 CI/CD 流水线配置。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. CI 工具选择

- **MUST** 使用 GitHub Actions 作为 CI/CD 平台。
- **SHOULD** CI 配置文件放在 `.github/workflows/ci.yml`。

## 2. CI 流水线阶段

### 阶段一：代码检查

- **MUST** 运行 `ruff check .` 进行代码风格和静态分析。
- **MUST** 运行 `ruff format --check .` 检查代码格式。
- **SHOULD** 运行 `python manage.py check --deploy` 检查生产部署配置。

### 阶段二：单元测试

- **MUST** 运行 `pytest --cov --cov-report=xml`。
- **MUST** 上传覆盖率报告。

### 阶段三：集成测试

- **MUST** 使用 Docker Compose 启动 PostgreSQL 和 Redis。
- **MUST** 运行迁移：`python manage.py migrate`。
- **MUST** 运行 `pytest -m "integration" -v`。

### 阶段四：构建与推送

- **MUST** 使用 Docker 多阶段构建。
- **MUST** 镜像标签使用 `git tag` 版本号 + `latest`。

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: "pip"
      - run: pip install ruff
      - run: ruff check .
      - run: ruff format --check .

  test:
    needs: lint
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
    env:
      DJANGO_SETTINGS_MODULE: config.settings.test
      DJANGO_SECRET_KEY: ci-test-key
      DB_NAME: test_db
      DB_USER: test
      DB_PASSWORD: test
      DB_HOST: localhost
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: "pip"
      - run: pip install -r requirements/development.txt
      - run: python manage.py migrate
      - run: pytest --cov --cov-report=xml
      - uses: codecov/codecov-action@v4

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

- **MUST** 使用 `requirements/` 目录分层管理依赖：`base.txt`、`development.txt`、`production.txt`。
- **MUST** `requirements/*.txt` 锁定精确版本（使用 `pip freeze` 或 `pip-compile`）。
- **SHOULD** CI 中运行 `pip-audit` 或 `safety check` 扫描已知漏洞。
- **禁止** 使用 `latest` 标签的 Docker 基础镜像。

## 4. 环境管理

- **MUST** 区分至少三个环境：`development`、`staging`、`production`。
- **MUST** 各环境通过 `DJANGO_SETTINGS_MODULE` 切换配置。
- **SHOULD** 使用 GitHub Environments 管理部署审批。

## 5. CD 部署

- **MUST** 部署前运行迁移：`python manage.py migrate --noinput`。
- **MUST** 部署前收集静态文件：`python manage.py collectstatic --noinput`。
- **MUST** 实现健康检查端点（`/health/`），部署后验证服务可用性。
- **SHOULD** 支持蓝绿部署或滚动更新。

## 6. 静态文件管理

- **SHOULD** 生产环境使用 `django-storages` + S3/MinIO 管理静态文件和媒体文件。
- **MUST** CD 中运行 `collectstatic` 将静态文件上传到 CDN 或对象存储。

## 7. 监控与告警

- **SHOULD** 使用 Sentry 捕获 Django 运行时异常。
- **SHOULD** 配置 Django `LOGGING` 输出到 stdout（容器化标准做法）。
- **MUST** 配置健康检查端点：数据库连接 + Redis 连接 + 基本响应。
