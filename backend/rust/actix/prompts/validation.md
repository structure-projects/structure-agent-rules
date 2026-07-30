# Actix-web 参数校验

## validator crate

```toml
[dependencies]
validator = { version = "0.16", features = ["derive"] }
actix-web-validator = "5"
```

## DTO 校验

```rust
use validator::Validate;
use serde::Deserialize;

#[derive(Deserialize, Validate)]
pub struct CreateUserRequest {
    #[validate(length(min = 2, max = 50))]
    pub name: String,

    #[validate(email)]
    pub email: String,

    #[validate(range(min = 18, max = 120))]
    pub age: i32,
}
```

## Handler 使用

```rust
use actix_web_validator::Json;

async fn create_user(body: Json<CreateUserRequest>) -> impl Responder {
    // Json<CreateUserRequest> 自动校验，失败返回 400
    user_service.create(body.into_inner()).await
}
```

## 自定义校验

```rust
use validator::ValidationError;

fn validate_non_empty(value: &str) -> Result<(), ValidationError> {
    if value.trim().is_empty() {
        return Err(ValidationError::new("must not be empty"));
    }
    Ok(())
}
```

## 常用校验

| 注解 | 说明 |
|---|---|
| `#[validate(length(min = 1, max = 100))]` | 长度 |
| `#[validate(email)]` | 邮箱 |
| `#[validate(range(min = 0, max = 150))]` | 数值范围 |
| `#[validate(url)]` | URL |
| `#[validate(regex)]` | 正则 |
| `#[validate(required)]` | 非 None |
| `#[validate(custom = "fn")]` | 自定义 |
