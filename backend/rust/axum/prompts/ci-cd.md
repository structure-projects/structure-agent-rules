# Axum CI/CD 规则

## GitHub Actions 工作流

### 基础 CI（格式检查 + 编译 + 测试）
```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  CARGO_TERM_COLOR: always
  RUSTFLAGS: "-D warnings"

jobs:
  check:
    name: 代码检查
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
          components: rustfmt, clippy
      - uses: Swatinem/rust-cache@v2
      - name: 格式检查
        run: cargo fmt --all --check
      - name: Clippy 检查
        run: cargo clippy --all-targets --all-features -- -D warnings

  test:
    name: 测试
    runs-on: ubuntu-latest
    needs: check
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready --health-interval 10s
          --health-timeout 5s --health-retries 5
      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379
        options: >-
          --health-cmd "redis-cli ping" --health-interval 10s
          --health-timeout 5s --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - uses: Swatinem/rust-cache@v2
      - name: 安装 sqlx-cli
        run: cargo install sqlx-cli --no-default-features --features postgres
      - name: 运行迁移
        run: sqlx migrate run
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
          SQLX_OFFLINE: true
      - name: 运行测试
        run: cargo test --all-features
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
          REDIS_URL: redis://localhost:6379
          JWT_SECRET: test-secret-for-ci
          APP_ENV: test

  build:
    name: 编译检查（Release）
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - uses: Swatinem/rust-cache@v2
      - name: Release 编译
        run: cargo build --release

  security:
    name: 安全审计
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - name: cargo-audit
        uses: actions-rs/audit-check@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
```

### Docker 构建流水线
```yaml
# .github/workflows/docker.yml
name: Docker Build & Push

on:
  push:
    tags: ['v*']

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - name: 登录容器注册表
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: 提取元数据
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha
      - name: 构建并推送
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### Dockerfile（多阶段构建）
```dockerfile
# Dockerfile
FROM rust:1.80-slim-bookworm AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*

# 缓存依赖
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release && rm -rf src

# 编译项目
COPY . .
RUN cargo build --release

# 运行时镜像
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/my-axum-app /usr/local/bin/app
COPY --from=builder /app/config /app/config
COPY --from=builder /app/migrations /app/migrations

WORKDIR /app
EXPOSE 3000

CMD ["/usr/local/bin/app"]
```

## 提交前本地检查（Pre-commit）
```bash
# 在提交前必须运行
cargo fmt --all --check        # 格式检查
cargo clippy -- -D warnings     # Lint 检查
cargo test                      # 单元测试
cargo build --release           # Release 编译
```

## sqlx 离线模式
对于 CI 环境，使用 `SQLX_OFFLINE=true` 和预生成的 `sqlx-data.json`：
```bash
# 本地生成离线数据
cargo sqlx prepare -- --all-targets

# 提交 sqlx-data.json 到仓库
git add sqlx-data.json
```

## 约束
- **MUST** 在 CI 中运行 `cargo fmt --check` 和 `cargo clippy`
- **MUST** 测试阶段使用真实 PostgreSQL/Redis 服务
- **MUST** 使用多阶段 Docker 构建减小镜像体积
- **SHOULD** 提交 `sqlx-data.json` 以支持离线编译检查
- **SHOULD** 使用 `rust-cache` 加速 CI 构建
- **SHOULD** 在 tag push 时自动构建 Docker 镜像
- **禁止** CI 测试使用 Mock 数据库
- **禁止** 跳过 `cargo fmt` 和 `cargo clippy` 检查
