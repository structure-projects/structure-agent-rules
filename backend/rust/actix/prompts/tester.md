# Actix-web 测试规则（Tester Rules）

## 测试工作流（MUST）
- 每开发一个功能 **立即** 写单元测试，**单测通过才能做下一个功能**
- 功能有修改时 **同步修改测试** 并通过
- 业务完成后写 **业务流程集成测试**，通过才算交付
- 覆盖正常+异常+边界；断言验证行为与数据（**禁止** 僵尸断言）
- 提交前 `cargo test` 全部通过 + `cargo build --release` 编译通过

## 测试分层

### 单元测试
- 位置：`#[cfg(test)] mod tests { ... }` 同文件内嵌
- 不启动外部依赖（数据库、Redis、HTTP 服务）
- 使用 Mock 或 stub 替代外部依赖

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use mockall::predicate::*;

    mock! {
        UserRepo {}
        #[async_trait]
        impl UserRepository for UserRepo {
            async fn find_by_id(&self, id: Uuid) -> Result<Option<User>, AppError>;
            async fn insert(&self, user: &NewUser) -> Result<User, AppError>;
        }
    }

    #[actix_rt::test]
    async fn test_create_user_success() {
        let mut mock_repo = MockUserRepo::new();
        mock_repo.expect_insert()
            .returning(|user| Ok(User { id: Uuid::new_v4(), name: user.name.clone(), .. }));
        let service = UserService::new(Arc::new(mock_repo));

        let result = service.create(CreateUserRequest { name: "测试用户".into() }).await;

        assert!(result.is_ok());
        assert_eq!(result.unwrap().name, "测试用户");
    }

    #[actix_rt::test]
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

### 集成测试 — actix_web::test
```rust
#[cfg(test)]
mod tests {
    use actix_web::{test, web, App};
    use super::*;

    #[actix_rt::test]
    async fn test_create_user_api() {
        let pool = setup_test_db().await;
        let state = web::Data::new(AppState::new_for_test(pool).await);

        let app = test::init_service(
            App::new()
                .app_data(state.clone())
                .configure(routes::configure)
        ).await;

        let req = test::TestRequest::post()
            .uri("/api/users")
            .set_json(&json!({ "name": "集成测试用户", "email": "test@example.com" }))
            .to_request();

        let resp = test::call_service(&app, req).await;

        assert!(resp.status().is_success());

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["code"], 0);
        assert!(body["data"]["id"].is_string());
    }

    #[actix_rt::test]
    async fn test_create_user_validation_error() {
        let app = test::init_service(
            App::new()
                .app_data(web::Data::new(AppState::new_for_test(pool).await))
                .configure(routes::configure)
        ).await;

        let req = test::TestRequest::post()
            .uri("/api/users")
            .set_json(&json!({ "name": "" }))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 400);
    }
}
```

### 集成测试 — tests/ 目录
```rust
// tests/user_api_test.rs
use actix_web::{test, web, App};

mod common;

#[actix_rt::test]
async fn test_create_user_full_flow() {
    let test_ctx = common::TestContext::new().await;

    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(test_ctx.state()))
            .configure(my_app::routes::configure)
    ).await;

    let req = test::TestRequest::post()
        .uri("/api/users")
        .set_json(&json!({ "name": "张三", "email": "zhangsan@example.com" }))
        .to_request();

    let resp = test::call_service(&app, req).await;
    assert!(resp.status().is_success());

    let body: serde_json::Value = test::read_body_json(resp).await;
    assert_eq!(body["data"]["name"], "张三");
}
```

## 必须覆盖
- **正常路径**：正确输入返回正确结果
- **异常路径**：参数校验失败、资源不存在、未授权
- **边界条件**：空字符串、最大长度、分页边界
- **数据一致性**：事务回滚、重复创建
- **并发安全**：`actix_rt::test` 测试异步代码

## Mock 边界
- **允许** Mock 进程边界（第三方 HTTP API / 外部 SaaS）
- **允许** 单元测试中 Mock Repository/Service trait
- **禁止** Mock 标准库或框架核心类型
- **禁止** 集成测试中 Mock 数据库/Redis

## 禁止
- 僵尸断言（只 `assert!(result.is_ok())` / 只看 HTTP 200）
- `std::thread::sleep` 等待异步
- 测试函数间相互依赖
- 集成测试 Mock 数据库/Redis
- `#[ignore]` 无注释说明原因

## 断言最佳实践
```rust
// ✅ 正确：验证具体值
let user = result.unwrap();
assert_eq!(user.name, "张三");
assert_eq!(user.email, "zhangsan@example.com");

// ✅ 正确：验证错误类型
match result.unwrap_err() {
    AppError::NotFound(msg) => assert!(msg.contains("用户")),
    other => panic!("期望 NotFound，得到 {:?}", other),
}

// ❌ 错误：僵尸断言
assert!(result.is_ok());
assert_eq!(response.status(), 200);
```

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
```
