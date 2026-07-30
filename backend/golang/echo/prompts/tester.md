# Echo 测试规则

> 适用场景：编写 Echo 项目的单元测试和集成测试。

## 测试工作流（MUST）

- 每开发一个功能 **立即** 写单元测试，**单测通过才能做下一个功能**。
- 功能有修改时 **同步修改测试** 并通过。
- 业务完成后写 **业务流程集成测试**，通过才算交付。
- 覆盖正常 + 异常 + 边界；断言验证行为与数据（**禁止** 僵尸断言）。
- **提交前**：`go test -race ./...` 全部通过 + `go build ./cmd/server` 编译通过。

## 测试分层与命名

| 类型 | 命名 | 说明 |
|---|---|---|
| 单元测试 | `xxx_test.go`（同包） | 不启动外部依赖 |
| 集成测试 | `xxx_integration_test.go` + `//go:build integration` | Testcontainers 真实中间件 |
| HTTP 测试 | 使用 `httptest` + Echo test utils | 测试 handler |

## 单元测试

```go
package service

import (
    "context"
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
)

type mockUserRepo struct {
    mock.Mock
}

func (m *mockUserRepo) FindByID(ctx context.Context, id int64) (*model.User, error) {
    args := m.Called(ctx, id)
    if args.Get(0) == nil {
        return nil, args.Error(1)
    }
    return args.Get(0).(*model.User), args.Error(1)
}

func TestUserService_GetByID(t *testing.T) {
    t.Run("success", func(t *testing.T) {
        mockRepo := new(mockUserRepo)
        svc := NewUserService(mockRepo)
        expected := &model.User{ID: 1, Username: "test"}
        mockRepo.On("FindByID", mock.Anything, int64(1)).Return(expected, nil)

        user, err := svc.GetByID(context.Background(), 1)

        assert.NoError(t, err)
        assert.Equal(t, "test", user.Username)
        mockRepo.AssertExpectations(t)
    })

    t.Run("not found", func(t *testing.T) {
        mockRepo := new(mockUserRepo)
        svc := NewUserService(mockRepo)
        mockRepo.On("FindByID", mock.Anything, int64(999)).Return(nil, ErrNotFound)

        user, err := svc.GetByID(context.Background(), 999)

        assert.Nil(t, user)
        assert.ErrorIs(t, err, ErrNotFound)
    })
}
```

## Handler 测试（Echo test utils）

```go
func TestUserHandler_GetByID(t *testing.T) {
    e := echo.New()
    mockSvc := new(mockUserService)
    handler := NewUserHandler(mockSvc)

    t.Run("success", func(t *testing.T) {
        mockSvc.On("GetByID", mock.Anything, int64(1)).
            Return(&model.User{ID: 1, Username: "test"}, nil).Once()

        req := httptest.NewRequest(http.MethodGet, "/", nil)
        rec := httptest.NewRecorder()
        c := e.NewContext(req, rec)
        c.SetPath("/users/:id")
        c.SetParamNames("id")
        c.SetParamValues("1")

        err := handler.GetByID(c)
        assert.NoError(t, err)
        assert.Equal(t, 200, rec.Code)
    })

    t.Run("invalid id", func(t *testing.T) {
        req := httptest.NewRequest(http.MethodGet, "/", nil)
        rec := httptest.NewRecorder()
        c := e.NewContext(req, rec)
        c.SetPath("/users/:id")
        c.SetParamNames("id")
        c.SetParamValues("abc")

        err := handler.GetByID(c)
        assert.NoError(t, err)
        assert.Equal(t, 400, rec.Code)
    })
}
```

## 集成测试

```go
//go:build integration

package repository_test

func TestUserRepo_Integration(t *testing.T) {
    if testing.Short() { t.Skip("skipping integration test") }

    ctx := context.Background()
    // 使用 Testcontainers 启动 PostgreSQL
    container, _ := testcontainers.GenericContainer(ctx, ...)
    defer container.Terminate(ctx)

    // 获取 DSN 并创建连接
    client, _ := ent.Open("postgres", dsn)
    defer client.Close()
    client.Schema.Create(ctx)  // 集成测试中可用

    repo := entrepo.NewUserRepoEnt(client)

    t.Run("create and find", func(t *testing.T) {
        user := &model.User{Username: "test", Email: "test@example.com"}
        err := repo.Save(ctx, user)
        assert.NoError(t, err)
        assert.NotZero(t, user.ID)

        found, _ := repo.FindByID(ctx, user.ID)
        assert.Equal(t, "test", found.Username)
    })
}
```

## Mock 边界

- **只允许** Mock 进程边界（外部 HTTP API、第三方 SDK）。
- **允许** Mock 自己项目的 Repository/Service 接口。
- **禁止** Mock 标准库或框架核心类型。

## 必须覆盖的场景

- 正常路径、异常路径、边界条件。
- 数据一致性：事务回滚、重复创建。
- 并发安全：`-race` 标志检测。

## 禁止事项

- **禁止** 僵尸断言。
- **禁止** `time.Sleep` 等待异步。
- **禁止** 测试函数间相互依赖。
- **禁止** 集成测试 Mock 数据库/Redis。
- **禁止** `t.Skip` 无注释说明原因。
