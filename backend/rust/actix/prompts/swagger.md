# Actix-web API 文档 (OpenAPI)

## utoipa 集成

```toml
[dependencies]
utoipa = { version = "4", features = ["actix_extras"] }
utoipa-swagger-ui = { version = "4", features = ["actix-web"] }
```

## 结构体标注

```rust
use utoipa::ToSchema;

#[derive(Serialize, Deserialize, ToSchema)]
pub struct User {
    pub id: i64,
    #[schema(example = "zhangsan")]
    pub name: String,
    #[schema(example = "zhangsan@example.com")]
    pub email: String,
}

#[derive(Deserialize, ToSchema)]
pub struct CreateUserRequest {
    #[schema(example = "zhangsan")]
    pub name: String,
    #[schema(example = "zhangsan@example.com")]
    pub email: String,
}
```

## API 文档配置

```rust
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

#[derive(OpenApi)]
#[openapi(
    paths(
        handlers::users::list_users,
        handlers::users::create_user,
    ),
    components(schemas(User, CreateUserRequest)),
    tags(
        (name = "users", description = "用户管理")
    ),
    info(
        title = "User Service API",
        version = "1.0.0",
        description = "用户管理服务"
    )
)]
struct ApiDoc;

// main.rs 注册
App::new()
    .service(SwaggerUi::new("/swagger-ui/{_:.*}")
        .url("/api-docs/openapi.json", ApiDoc::openapi()))
```

## 访问

- Swagger UI: `http://localhost:8080/swagger-ui/`
- OpenAPI JSON: `http://localhost:8080/api-docs/openapi.json`
