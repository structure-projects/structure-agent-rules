# Echo 项目脚手架规则

> 适用场景：新建 Echo 项目时的初始化步骤、目录创建、依赖配置。

## 初始化步骤（MUST 按顺序执行）

### 1. 初始化 Go Module

```bash
mkdir my-service && cd my-service
go mod init github.com/myorg/my-service
```

### 2. 创建目录结构

```bash
mkdir -p cmd/server
mkdir -p internal/{handler,middleware,service,repository,model,config,router}
mkdir -p internal/repository/{ent,sqlx}
mkdir -p internal/service/impl
mkdir -p pkg
mkdir -p ent/schema
mkdir -p migrations
mkdir -p configs
mkdir -p scripts
```

### 3. 安装核心依赖

```bash
go get github.com/labstack/echo/v4
go get github.com/spf13/viper
go get github.com/rs/zerolog
go get github.com/go-playground/validator/v10
go get github.com/swaggo/echo-swagger github.com/swaggo/swag
go get github.com/golang-jwt/jwt/v5
go get github.com/stretchr/testify
```

### 4. 选择数据库方案

**ent 方案**：
```bash
go get entgo.io/ent
go get entgo.io/ent/cmd/ent
go run entgo.io/ent/cmd/ent new User
```

**sqlx 方案**：
```bash
go get github.com/jmoiron/sqlx
go get github.com/lib/pq  # PostgreSQL driver
```

### 5. 创建入口文件 `cmd/server/main.go`

```go
package main

import "github.com/labstack/echo/v4"

// @title My Service API
// @version 1.0.0
func main() {
    e := echo.New()
    // ... 初始化配置、依赖、路由
    e.Logger.Fatal(e.Start(":8080"))
}
```

### 6. 创建默认配置文件 `configs/config.dev.yaml`

```yaml
server:
  port: 8080
  read_timeout: 30s
  write_timeout: 30s

database:
  driver: postgres
  dsn: "host=localhost port=5432 user=postgres password=postgres dbname=mydb sslmode=disable"
  max_open_conns: 100
  max_idle_conns: 10
  conn_max_lifetime: 1h

jwt:
  secret: change-me-in-production
  expiration_hours: 24
```

### 7. 创建 Makefile

```makefile
.PHONY: build run test lint swagger ent-gen

APP_NAME = my-service
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")

build:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
		-ldflags="-s -w -X main.Version=$(VERSION)" \
		-o bin/$(APP_NAME) ./cmd/server

run:
	go run ./cmd/server

test:
	go test -race -coverprofile=coverage.out ./...

lint:
	golangci-lint run ./...

swagger:
	swag init -g cmd/server/main.go -o docs

ent-gen:
	go generate ./ent

docker:
	docker build -t $(APP_NAME):$(VERSION) .
```

### 8. 创建 Dockerfile

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

## 禁止事项

- **禁止** 手动创建 vendor 目录。
- **禁止** 在 `cmd/` 下放业务逻辑。
- **禁止** 把接口和实现放在同一个文件中。
