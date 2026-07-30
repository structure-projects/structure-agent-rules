# Axum 测试规则（Tester Rules）

## 测试工作流（MUST）
- 每开发一个功能 **立即** 写单元测试，**单测通过才能做下一个功能**
- 功能有修改时 **同步修改测试** 并通过
- 业务完成后写 **业务流程集成测试**，通过才算交付
- 覆盖正常+异常+边界；断言验证行为与数据（**禁止** 僵尸断言）
- 提交前 `cargo test` 全部通过 + `cargo build --release` 编译通过
- 禁止测试/编译失败仍提交

## 测试分层

### 单元测试
- 位置：`#[cfg(test)] mod tests { ... }` 同文件内嵌
- 不启动外部依赖（数据库、Redis、HTTP 服务）
- 使用 Mock 或 stub 替代外部依赖
- 测试对象：Service 函数、工具函数、DTO 转换

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use mockall::predicate::*;
    use mockall::*;

    mock! {
        UserRepo {}
        #[async_trait]
        impl UserRepository for UserRepo {
            async fn find_by_id(&self, id: Uuid) -> Result<Option<User>, AppError>;
            async fn insert(&self, user: &NewUser) -> Result<User, AppError>;
        }
    }

    #[tokio::test]
    async fn test_create_user_success() {
        // Arrange
        let mut mock_repo = MockUserRepo::new();
        mock_repo.expect_insert()
            .returning(|user| Ok(User { id: Uuid::new_v4(), name: user.name.clone(), .. }));
        let service = UserService::new(Arc::new(mock_repo));

        // Act
        let result = service.create(CreateUserRequest { name: "测试用户".into() }).await;

        // Assert
        assert!(result.is_ok());
        let user = result.unwrap();
        assert_eq!(user.name, "测试用户");
    }

    #[tokio::test]
    async fn test_create_user_empty_name() {
        let mock_repo = MockUserRepo::new();
        let service = UserService::new(Arc::new(mock_repo));

        let result = service.create(CreateUserRequest { name: "".into() }).await;

        assert!(result.is_err());
        match result.unwrap_err() {
            AppError::ValidationError(msg) => assert!(msg.contains("不能为空")),
            _ => panic!("期望 ValidationError"),
        }
    }
}
```

### 集成测试
- 位置：`tests/` 目录（项目根目录，与 `src/` 同级）
- **必须** 使用真实中间件（Testcontainers / docker-compose）
- **禁止** Mock 数据库/Redis/MQ
- 测试完整请求链路：HTTP 请求 → Handler → Service → Repository → 数据库

```rust
// tests/user_api_test.rs
use reqwest::StatusCode;
use serde_json::json;

mod common;  // 测试公共模块：启动服务器、准备数据库

#[tokio::test]
async fn test_create_user_api() {
    let app = common::spawn_app().await;

    let client = reqwest::Client::new();
    let response = client
        .post(&format!("{}/api/users", app.address))
        .json(&json!({ "name": "集成测试用户", "email": "test@example.com" }))
        .send()
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::CREATED);

    let body: serde_json::Value = response.json().await.unwrap();
    assert_eq!(body["code"], 0);
    assert!(body["data"]["id"].is_string());
    assert_eq!(body["data"]["name"], "集成测试用户");
}

#[tokio::test]
async fn test_create_user_validation_error() {
    let app = common::spawn_app().await;

    let client = reqwest::Client::new();
    let response = client
        .post(&format!("{}/api/users", app.address))
        .json(&json!({ "name": "" }))
        .send()
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::BAD_REQUEST);
}
```

### 测试辅助模块
```rust
// tests/common/mod.rs
use sqlx::PgPool;
use testcontainers::{clients, images::postgres};
use once_cell::sync::Lazy;

pub struct TestApp {
    pub address: String,
    pub db_pool: PgPool,
}

pub async fn spawn_app() -> TestApp {
    // 启动 PostgreSQL Testcontainer
    let docker = clients::Cli::default();
    let pg = docker.run(postgres::Postgres::default());
    let db_url = format!(
        "postgres://postgres:postgres@{}:{}/postgres",
        pg.get_host().unwrap(),
        pg.get_host_port_ipv4(5432).unwrap()
    );

    // 运行迁移
    let pool = PgPool::connect(&db_url).await.unwrap();
    sqlx::migrate!("./migrations").run(&pool).await.unwrap();

    // 启动应用
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    let app = build_app(pool.clone());
    tokio::spawn(async move { axum::serve(listener, app).await.unwrap() });

    TestApp {
        address: format!("http://{}", addr),
        db_pool: pool,
    }
}
```

## 必须覆盖
- **正常路径**：正确输入返回正确结果
- **异常路径**：参数校验失败、资源不存在、未授权
- **边界条件**：空字符串、最大长度、分页边界
- **数据一致性**：事务回滚、重复创建、并发更新
- **并发安全**：使用 `tokio::test` 测试异步代码，验证并发场景

## Mock 边界
- **允许** Mock 进程边界（第三方 HTTP API / 外部 SaaS）
- **允许** 单元测试中 Mock Repository/Service trait
- **禁止** Mock 标准库或框架核心类型
- **禁止** 集成测试中 Mock 数据库/Redis

## 禁止
- 僵尸断言（只 `assert!(result.is_ok())` / 只看 HTTP 200 / 不检查数据内容）
- `std::thread::sleep` 或 `tokio::time::sleep` 等待异步结果
- 测试函数间相互依赖
- 集成测试 Mock 数据库/Redis
- `#[ignore]` 无注释说明原因
- 测试中硬编码绝对路径

## 断言最佳实践
```rust
// ✅ 正确：验证具体值
let user = result.unwrap();
assert_eq!(user.name, "张三");
assert_eq!(user.email, "zhangsan@example.com");
assert!(!user.id.is_nil());

// ✅ 正确：验证错误类型
match result.unwrap_err() {
    AppError::NotFound(msg) => assert!(msg.contains("用户")),
    other => panic!("期望 NotFound，得到 {:?}", other),
}

// ❌ 错误：僵尸断言
assert!(result.is_ok());  // 不检查返回值内容

// ❌ 错误：只检查 HTTP 状态码
assert_eq!(response.status(), 200);  // 不检查响应体
```

## 测试数据管理
- 每个测试用例使用独立的测试数据
- 使用 `Uuid::new_v4()` 生成唯一标识
- 测试后清理数据（或每个测试使用独立事务回滚）
- 禁止依赖数据库中的预置数据

## CI 集成
```yaml
# .github/workflows/test.yml
test:
  runs-on: ubuntu-latest
  services:
    postgres:
      image: postgres:16
      env:
        POSTGRES_PASSWORD: postgres
      ports:
        - 5432:5432
  steps:
    - uses: actions/checkout@v4
    - uses: actions-rs/toolchain@v1
      with:
        toolchain: stable
    - run: cargo test --all-features
    - run: cargo test --all-features -- --ignored  # 集成测试（可能需要 docker）
```
