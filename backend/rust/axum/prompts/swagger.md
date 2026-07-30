# Axum OpenAPI/Swagger 规则（utoipa）

## 核心依赖
```toml
[dependencies]
utoipa = { version = "4", features = ["axum_extras", "uuid", "chrono"] }
utoipa-swagger-ui = { version = "7", features = ["axum"] }
```

## 基本使用

### 1. 定义 API 文档结构体
```rust
use utoipa::OpenApi;
use utoipa::openapi::security::{HttpAuthScheme, HttpBuilder, SecurityScheme};

#[derive(OpenApi)]
#[openapi(
    paths(
        crate::routes::health::health_check,
        crate::routes::users::list_users,
        crate::routes::users::create_user,
        crate::routes::users::get_user,
        crate::routes::users::update_user,
        crate::routes::users::delete_user,
    ),
    components(
        schemas(
            crate::models::user::User,
            crate::models::dto::create_user::CreateUserRequest,
            crate::models::dto::user_response::UserResponse,
        )
    ),
    modifiers(&SecurityAddon),
    tags(
        (name = "健康检查", description = "服务健康检查接口"),
        (name = "用户管理", description = "用户 CRUD 接口"),
    ),
    info(
        title = "My API",
        version = "1.0.0",
        description = "API 文档",
        contact(name = "API Support", email = "support@example.com"),
    )
)]
pub struct ApiDoc;

struct SecurityAddon;

impl utoipa::Modify for SecurityAddon {
    fn modify(&self, openapi: &mut utoipa::openapi::OpenApi) {
        if let Some(components) = openapi.components.as_mut() {
            components.add_security_scheme(
                "jwt",
                SecurityScheme::Http(
                    HttpBuilder::new()
                        .scheme(HttpAuthScheme::Bearer)
                        .bearer_format("JWT")
                        .build(),
                ),
            )
        }
    }
}
```

### 2. 在 Handler 上添加文档注解
```rust
use axum::{extract::{State, Path, Query}, Json};
use utoipa::IntoParams;

/// 查询参数文档
#[derive(Deserialize, IntoParams)]
pub struct UserListQuery {
    /// 页码，从 1 开始
    #[param(default = 1, minimum = 1)]
    pub page: Option<u64>,

    /// 每页数量，最大 100
    #[param(default = 20, minimum = 1, maximum = 100)]
    pub page_size: Option<u64>,

    /// 用户名模糊搜索
    pub keyword: Option<String>,
}

/// 获取用户列表
#[utoipa::path(
    get,
    path = "/api/users",
    params(UserListQuery),
    responses(
        (status = 200, description = "用户列表", body = PageResult<UserResponse>),
        (status = 401, description = "未授权"),
        (status = 500, description = "服务器错误"),
    ),
    tag = "用户管理",
    security(
        ("jwt" = [])
    )
)]
pub async fn list_users(
    State(state): State<AppState>,
    Query(query): Query<UserListQuery>,
) -> Result<Json<PageResult<UserResponse>>, AppError> {
    // ... 实现
}

/// 创建用户
#[utoipa::path(
    post,
    path = "/api/users",
    request_body = CreateUserRequest,
    responses(
        (status = 201, description = "创建成功", body = UserResponse),
        (status = 400, description = "参数校验失败"),
        (status = 401, description = "未授权"),
        (status = 500, description = "服务器错误"),
    ),
    tag = "用户管理",
    security(
        ("jwt" = [])
    )
)]
pub async fn create_user(
    State(state): State<AppState>,
    Json(payload): Json<CreateUserRequest>,
) -> Result<(StatusCode, Json<UserResponse>), AppError> {
    // ... 实现
}

/// 获取单个用户
#[utoipa::path(
    get,
    path = "/api/users/{id}",
    params(
        ("id" = Uuid, Path, description = "用户 ID"),
    ),
    responses(
        (status = 200, description = "用户详情", body = UserResponse),
        (status = 404, description = "用户不存在"),
        (status = 401, description = "未授权"),
    ),
    tag = "用户管理",
    security(
        ("jwt" = [])
    )
)]
pub async fn get_user(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<UserResponse>, AppError> {
    // ... 实现
}
```

### 3. 在模型上添加 Schema 注解
```rust
use utoipa::ToSchema;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct User {
    /// 用户 ID
    pub id: Uuid,

    /// 用户名
    #[schema(example = "张三")]
    pub name: String,

    /// 邮箱
    #[schema(example = "zhangsan@example.com")]
    pub email: String,

    /// 创建时间
    pub created_at: chrono::NaiveDateTime,

    /// 更新时间
    pub updated_at: chrono::NaiveDateTime,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct CreateUserRequest {
    /// 用户名，2-50 字符
    #[schema(example = "张三", min_length = 2, max_length = 50)]
    pub name: String,

    /// 邮箱地址
    #[schema(example = "zhangsan@example.com")]
    pub email: String,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct UserResponse {
    pub id: Uuid,
    pub name: String,
    pub email: String,
    pub created_at: chrono::NaiveDateTime,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct PageResult<T: ToSchema> {
    /// 数据列表
    pub items: Vec<T>,

    /// 总数
    pub total: u64,

    /// 当前页码
    pub page: u64,

    /// 每页数量
    pub page_size: u64,
}
```

### 4. 注册 Swagger UI 路由
```rust
use utoipa_swagger_ui::SwaggerUi;

pub fn create_routes() -> Router<AppState> {
    Router::new()
        .merge(SwaggerUi::new("/swagger-ui")
            .url("/api-docs/openapi.json", ApiDoc::openapi()))
        .route("/api/users", get(list_users).post(create_user))
        // ... 其他路由
}
```

### 5. 完整示例：routes/mod.rs
```rust
use axum::{Router, routing::get};
use utoipa_swagger_ui::SwaggerUi;

mod health;
mod users;

use crate::api_doc::ApiDoc;

pub fn create_routes() -> Router<crate::AppState> {
    let api_routes = Router::new()
        .merge(users::routes())
        .merge(health::routes());

    Router::new()
        .merge(SwaggerUi::new("/swagger-ui")
            .url("/api-docs/openapi.json", ApiDoc::openapi()))
        .merge(api_routes)
}
```

## 约束
- **MUST** 每个公开的 handler 添加 `#[utoipa::path]` 注解
- **MUST** 每个 DTO/实体添加 `#[derive(ToSchema)]` 和 `#[schema(example = "...")]`
- **MUST** 每个查询参数结构体实现 `IntoParams`
- **MUST** Swagger UI 路径配置为 `/swagger-ui`
- **MUST** OpenAPI JSON 路径配置为 `/api-docs/openapi.json`
- **SHOULD** 生产环境通过 feature flag 控制 Swagger UI 是否启用
- **SHOULD** 为每个 schema 字段添加中文描述

## 生产环境开关
```rust
// 通过 feature 控制
#[cfg(feature = "swagger")]
{
    app = app.merge(SwaggerUi::new("/swagger-ui")
        .url("/api-docs/openapi.json", ApiDoc::openapi()));
}
```
