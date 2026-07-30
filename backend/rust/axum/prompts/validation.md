# Axum 参数校验规则（Validation）

## 核心依赖
```toml
[dependencies]
validator = { version = "0.18", features = ["derive"] }
```

## 基本使用

### DTO 校验定义
```rust
use serde::Deserialize;
use validator::Validate;

#[derive(Debug, Deserialize, Validate)]
pub struct CreateUserRequest {
    #[validate(length(min = 2, max = 50, message = "用户名长度必须在 2-50 之间"))]
    pub name: String,

    #[validate(email(message = "邮箱格式不正确"))]
    pub email: String,

    #[validate(length(min = 6, max = 100, message = "密码长度必须在 6-100 之间"))]
    pub password: String,

    #[validate(range(min = 0, max = 150, message = "年龄必须在 0-150 之间"))]
    pub age: Option<i32>,

    #[validate(url(message = "URL 格式不正确"))]
    pub website: Option<String>,

    #[validate(regex(path = *PHONE_REGEX, message = "手机号格式不正确"))]
    pub phone: Option<String>,
}

// 自定义正则
lazy_static::lazy_static! {
    static ref PHONE_REGEX: regex::Regex = regex::Regex::new(r"^1[3-9]\d{9}$").unwrap();
}
```

### 自定义提取器：校验中间件
```rust
use axum::{
    extract::{FromRequest, rejection::JsonRejection},
    async_trait,
};
use validator::Validate;

// 自动校验的 Json 提取器
#[derive(Debug, Clone, Copy, Default)]
pub struct ValidJson<T>(pub T);

#[async_trait]
impl<T, S> FromRequest<S> for ValidJson<T>
where
    T: DeserializeOwned + Validate,
    S: Send + Sync,
    Json<T>: FromRequest<S, Rejection = JsonRejection>,
{
    type Rejection = AppError;

    async fn from_request(req: Request, state: &S) -> Result<Self, Self::Rejection> {
        let Json(value) = Json::<T>::from_request(req, state)
            .await
            .map_err(|e| AppError::ValidationError(e.body_text()))?;

        value.validate().map_err(|e| {
            AppError::ValidationError(
                e.field_errors()
                    .iter()
                    .map(|(field, errors)| {
                        let msgs: Vec<String> = errors.iter()
                            .filter_map(|e| e.message.as_ref().map(|m| m.to_string()))
                            .collect();
                        format!("{}: {}", field, msgs.join(", "))
                    })
                    .collect::<Vec<_>>()
                    .join("; ")
            )
        })?;

        Ok(ValidJson(value))
    }
}

// 在 handler 中使用
async fn create_user(
    State(state): State<AppState>,
    ValidJson(payload): ValidJson<CreateUserRequest>,  // 自动校验
) -> Result<(StatusCode, Json<UserResponse>), AppError> {
    let user = state.user_service.create(payload).await?;
    Ok((StatusCode::CREATED, Json(user.into())))
}
```

### 自定义校验规则
```rust
use validator::{Validate, ValidationError, ValidationErrors};

// 自定义校验函数
fn validate_not_blank(value: &str) -> Result<(), ValidationError> {
    if value.trim().is_empty() {
        let mut error = ValidationError::new("not_blank");
        error.message = Some("不能为空白".into());
        return Err(error);
    }
    Ok(())
}

#[derive(Debug, Deserialize, Validate)]
pub struct UpdateUserRequest {
    #[validate(custom(function = "validate_not_blank"))]
    pub name: String,
}
```

### 嵌套校验
```rust
#[derive(Debug, Deserialize, Validate)]
pub struct Address {
    #[validate(length(min = 1, message = "省份不能为空"))]
    pub province: String,

    #[validate(length(min = 1, message = "城市不能为空"))]
    pub city: String,

    #[validate(length(min = 1, message = "详细地址不能为空"))]
    pub detail: String,
}

#[derive(Debug, Deserialize, Validate)]
pub struct CreateOrderRequest {
    #[validate]
    pub address: Address,  // 嵌套校验

    #[validate(length(min = 1, message = "商品列表不能为空"))]
    pub items: Vec<OrderItem>,
}
```

## 在 Handler 中手动校验
```rust
async fn update_user(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateUserRequest>,
) -> Result<Json<UserResponse>, AppError> {
    // 手动触发校验
    payload.validate().map_err(|e| {
        AppError::ValidationError(format!("参数校验失败: {:?}", e))
    })?;

    let user = state.user_service.update(id, payload).await?;
    Ok(Json(user.into()))
}
```

## 在 Service 层校验
```rust
impl UserService {
    pub async fn create(&self, req: CreateUserRequest) -> Result<User, AppError> {
        // 框架级校验
        req.validate().map_err(|e| {
            AppError::ValidationError(format!("参数校验失败: {:?}", e))
        })?;

        // 业务级校验
        if self.repo.exists_by_email(&req.email).await? {
            return Err(AppError::ValidationError("邮箱已被注册".into()));
        }

        self.repo.insert(&req.into()).await
    }
}
```

## 校验错误响应格式
```json
{
  "code": 400,
  "message": "name: 用户名长度必须在 2-50 之间; email: 邮箱格式不正确"
}
```

## 约束
- **MUST** 所有 DTO（Request）使用 `#[derive(Validate)]` 定义校验规则
- **MUST** 在 Handler 或自定义提取器中触发校验
- **MUST** 校验错误返回 `AppError::ValidationError`
- **SHOULD** 使用 `ValidJson<T>` 自定义提取器自动校验
- **SHOULD** 复杂业务校验放在 Service 层
- **禁止** 在 Handler 中写校验逻辑（应通过 validator 声明式校验）
