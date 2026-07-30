# Echo CI/CD 规则

> 适用场景：Echo 项目的持续集成、持续部署、流水线配置。

## CI 流水线阶段（MUST 顺序执行）

1. **Lint** → 2. **Test** → 3. **Build** → 4. **Image** → 5. **Deploy**

## Lint 阶段

- **MUST** 使用 `golangci-lint` 进行静态分析。
- **MUST** 配置 `.golangci.yml`，至少启用：`govet`、`staticcheck`、`errcheck`、`gosimple`、`ineffassign`、`gofmt`。
- **SHOULD** 启用 `goimports`、`misspell`。

## Test 阶段

- **MUST** 运行 `go test -race -coverprofile=coverage.out ./...`。
- **MUST** 覆盖率门槛 >= 70%。
- **MUST** 集成测试使用 Testcontainers 提供真实数据库依赖。
- **SHOULD** 使用 `gotestsum` 输出 JUnit 格式报告。

```makefile
test:
	go test -race -coverprofile=coverage.out -covermode=atomic ./...
	go tool cover -func=coverage.out | grep total | awk '{print $$3}'

test-integration:
	go test -tags=integration -count=1 ./internal/...
```

## Build 阶段

- **MUST** 使用 `CGO_ENABLED=0 GOOS=linux GOARCH=amd64` 编译静态二进制。
- **MUST** 通过 `-ldflags="-s -w"` 去除调试信息。
- **SHOULD** 注入版本信息：`-ldflags="-X main.Version=$(VERSION) -X main.BuildTime=$(BUILD_TIME)"`。

```makefile
build:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
		-ldflags="-s -w -X main.Version=$(VERSION) -X main.BuildTime=$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		-o bin/server ./cmd/server
```

## Docker 镜像阶段

- **MUST** 使用多阶段构建，编译阶段用 `golang:1.23-alpine`，运行阶段用 `alpine:3.20`。
- **MUST** 运行阶段添加 `ca-certificates` 和 `tzdata`。
- **SHOULD** 使用非 root 用户运行。

```dockerfile
FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o server ./cmd/server

FROM alpine:3.20
RUN apk --no-cache add ca-certificates tzdata
COPY --from=builder /app/server /app/server
COPY --from=builder /app/configs /app/configs
USER 1000
EXPOSE 8080
CMD ["/app/server"]
```

## GitHub Actions 示例

```yaml
name: CI
on: [push, pull_request]
jobs:
  ci:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: testdb
        ports: ["5432:5432"]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with: { go-version: "1.23" }
      - run: go mod download
      - run: go test -race -coverprofile=coverage.out ./...
      - run: make build
```

## 部署阶段

- **MUST** 部署前执行健康检查：`curl -f http://localhost:8080/health`。
- **SHOULD** 使用优雅关闭：监听 `SIGTERM`/`SIGINT`，`e.Shutdown(ctx)` 等待进行中请求完成。
- **SHOULD** 使用 Kubernetes Deployment + Service 或 Docker Compose。

## 禁止事项

- **禁止** 跳过 lint 直接构建。
- **禁止** 测试覆盖率低于 70% 时合并 PR。
- **禁止** 在 CI 中使用 `latest` 标签的 Docker 基础镜像。
- **禁止** 在镜像中保留构建工具和源代码。
