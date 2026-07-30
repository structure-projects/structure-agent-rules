# Actix-web 核心组件

## 请求提取器 (Extractors)

```rust
async fn handler(
    path: web::Path<(i64, String)>,  // /users/{id}/{name}
    query: web::Query<HashMap<String, String>>, // ?key=value
    body: web::Json<CreateUserRequest>, // JSON body
    form: web::Form<LoginForm>,       // form data
    state: Data<AppState>,            // app data
    headers: HeaderMap,               // headers
) -> impl Responder { }
```

## 中间件

```rust
use actix_web::middleware::{Logger, DefaultHeaders, Compress};
use actix_cors::Cors;

App::new()
    .wrap(Logger::default())
    .wrap(Compress::default())
    .wrap(DefaultHeaders::new().add(("X-Version", "1.0")))
    .wrap(Cors::permissive())
```

## 自定义中间件

```rust
use actix_web::dev::{ServiceRequest, ServiceResponse, Transform};
use actix_web::Error;

pub struct AuthMiddleware;
impl<S, B> Transform<S, ServiceRequest> for AuthMiddleware
where S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Transform = AuthMiddlewareService<S>;
    type InitError = ();
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ready(Ok(AuthMiddlewareService { service }))
    }
}
```

## 数据库: sqlx

```rust
// 连接池
let pool = sqlx::PgPool::connect("postgresql://localhost/mydb").await?;

// 查询
let user = sqlx::query_as::<_, User>("SELECT id, name FROM users WHERE id = $1")
    .bind(id)
    .fetch_optional(&pool)
    .await?;
```

## 数据库: diesel

```rust
// web::block 包装同步操作
async fn get_users(pool: Data<DbPool>) -> impl Responder {
    let users = web::block(move || {
        let mut conn = pool.get()?;
        users::table.load::<User>(&mut conn)
    })
    .await
    .map_err(|e| AppError::Internal(e.to_string()))?;
    HttpResponse::Ok().json(users)
}
```

## HTTP 客户端: awc

```rust
use awc::Client;

let client = Client::default();
let resp = client.get("http://api.example.com/users")
    .send().await?;
let body = resp.json::<Vec<User>>().await?;
```

## 配置管理

```rust
use config::{Config, File, Environment};

let config = Config::builder()
    .add_source(File::with_name("config/default"))
    .add_source(Environment::with_prefix("APP").separator("__"))
    .build()?;
```
