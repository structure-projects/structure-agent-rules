# Actix-web CI/CD

## GitHub Actions

```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: test
        ports: ["5432:5432"]
    steps:
      - uses: actions/checkout@v4
      - name: Setup Rust
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
          components: clippy, rustfmt
      - name: Cache
        uses: Swatinem/rust-cache@v2
      - name: Check formatting
        run: cargo fmt -- --check
      - name: Clippy
        run: cargo clippy -- -D warnings
      - name: Test
        run: cargo test
        env:
          DATABASE_URL: postgresql://postgres:test@localhost:5432/test
```

## Dockerfile (多阶段)

```dockerfile
# Build
FROM rust:1.75 AS builder
WORKDIR /app
COPY . .
RUN cargo build --release

# Runtime
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y libpq5 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/my-service /usr/local/bin/
CMD ["/usr/local/bin/my-service"]
```

## 检查清单

- [ ] `cargo fmt --check` 通过
- [ ] `cargo clippy -- -D warnings` 通过
- [ ] `cargo test` 全部通过
- [ ] Rust cache 使用 `Swatinem/rust-cache`
- [ ] Docker 镜像使用多阶段构建减小体积
- [ ] 数据库服务在 CI 中 bootstrap
