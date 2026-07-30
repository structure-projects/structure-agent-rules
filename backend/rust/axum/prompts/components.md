# Axum 组件与中间件参考（Components）

## 核心依赖（Cargo.toml）
```toml
[dependencies]
axum = "0.7"
tokio = { version = "1", features = ["full"] }
tower = "0.4"
tower-http = { version = "0.5", features = ["cors", "trace", "compression-gzip", "limit"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
sqlx = { version = "0.8", features = ["runtime-tokio", "tls-rustls", "postgres", "uuid", "chrono"] }
thiserror = "2"
anyhow = "1"
validator = { version = "0.18", features = ["derive"] }
utoipa = { version = "4", features = ["axum_extras"] }
utoipa-swagger-ui = { version = "7", features = ["axum"] }
config = "0.14"
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }
reqwest = { version = "0.12", features = ["json"] }
uuid = { version = "1", features = ["v4", "serde"] }
chrono = { version = "0.4", features = ["serde"] }
jsonwebtoken = "9"
argon2 = "0.5"
redis = { version = "0.25", features = ["tokio-comp", "connection-manager"] }
dotenvy = "0.15"

[dev-dependencies]
mockall = "0.13"
axum-test = "16"
testcontainers = "0.23"
```

## Router（路由）
```rust
use axum::{Router, routing::{get, post, put, delete}};

// 基础路由
Router::new()
    .route("/", get(root))
    .route("/api/users", get(list_users).post(create_user))
    .route("/api/users/{id}", get(get_user).put(update_user).delete(delete_user))

// 嵌套路由
Router::new()
    .nest("/api/users", user_routes())
    .nest("/api/orders", order_routes())

// 路由合并
let app = Router::new()
    .merge(user_routes())
    .merge(order_routes())
    .fallback(handler_404)
    .with_state(state);
```

## Extractors（提取器）
### 内置提取器
```rust
use axum::{
    extract::{State, Path, Query, Json, HeaderMap, Extension},
    http::HeaderMap,
};

// State — 应用状态
async fn handler(State(state): State<AppState>) -> impl IntoResponse { ... }

// Path — 路径参数
async fn get_user(Path(id): Path<Uuid>) -> impl IntoResponse { ... }

// Query — 查询参数
#[derive(Deserialize)]
struct Pagination { page: Option<u64>, page_size: Option<u64> }
async fn list_users(Query(p): Query<Pagination>) -> impl IntoResponse { ... }

// Json — JSON 请求体
async fn create_user(Json(payload): Json<CreateUserRequest>) -> impl IntoResponse { ... }

// HeaderMap — 请求头
async fn handler(HeaderMap(headers): HeaderMap) -> impl IntoResponse { ... }
```

### 自定义提取器 — 当前用户
```rust
pub struct CurrentUser {
    pub id: Uuid,
    pub name: String,
    pub roles: Vec<String>,
}

impl<S> FromRequestParts<S> for CurrentUser
where
    S: Send + Sync,
{
    type Rejection = AppError;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let auth_header = parts.headers
            .get(HeaderName::from_static("authorization"))
            .and_then(|v| v.to_str().ok())
            .ok_or(AppError::Unauthorized("缺少认证头".into()))?;

        let token = auth_header.strip_prefix("Bearer ")
            .ok_or(AppError::Unauthorized("认证格式错误".into()))?;

        // 解析 JWT
        let claims = decode_jwt(token)?;
        Ok(CurrentUser {
            id: claims.sub,
            name: claims.name,
            roles: claims.roles,
        })
    }
}

// 在 handler 中使用
async fn me(current_user: CurrentUser) -> impl IntoResponse {
    Json(current_user)
}
```

### 自定义提取器 — 分页参数
```rust
pub struct PageParams {
    pub page: u64,
    pub page_size: u64,
}

impl Default for PageParams {
    fn default() -> Self {
        Self { page: 1, page_size: 20 }
    }
}

impl<S> FromRequestParts<S> for PageParams
where
    S: Send + Sync,
{
    type Rejection = AppError;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let query = parts.uri.query().unwrap_or("");
        let params: HashMap<String, String> = serde_urlencoded::from_str(query)
            .map_err(|_| AppError::ValidationError("查询参数解析失败".into()))?;

        let page = params.get("page")
            .and_then(|v| v.parse().ok())
            .filter(|&p| p > 0)
            .unwrap_or(1);

        let page_size = params.get("page_size")
            .and_then(|v| v.parse().ok())
            .filter(|&s| s > 0 && s <= 100)
            .unwrap_or(20);

        Ok(PageParams { page, page_size })
    }
}
```

## Middleware（中间件 — tower Layer）
```rust
use tower_http::cors::{CorsLayer, Any};
use tower_http::trace::TraceLayer;
use tower_http::compression::CompressionLayer;
use tower_http::limit::RequestBodyLimitLayer;
use tower::ServiceBuilder;

let app = Router::new()
    .route("/api/users", get(list_users))
    .layer(
        ServiceBuilder::new()
            // 请求追踪（最内层）
            .layer(TraceLayer::new_for_http())
            // 请求体大小限制
            .layer(RequestBodyLimitLayer::new(10 * 1024 * 1024)) // 10MB
            // CORS
            .layer(
                CorsLayer::new()
                    .allow_origin("http://localhost:5173".parse::<HeaderValue>().unwrap())
                    .allow_methods([Method::GET, Method::POST, Method::PUT, Method::DELETE])
                    .allow_headers([CONTENT_TYPE, AUTHORIZATION])
                    .allow_credentials(true)
            )
            // 压缩（最外层）
            .layer(CompressionLayer::new())
    );
```

### 自定义中间件 — 请求日志
```rust
#[derive(Clone)]
pub struct RequestLoggerLayer;

impl<S> Layer<S> for RequestLoggerLayer {
    type Service = RequestLoggerMiddleware<S>;

    fn layer(&self, inner: S) -> Self::Service {
        RequestLoggerMiddleware { inner }
    }
}

#[derive(Clone)]
pub struct RequestLoggerMiddleware<S> {
    inner: S,
}

impl<S, B> Service<Request<B>> for RequestLoggerMiddleware<S>
where
    S: Service<Request<B>, Response = Response> + Clone + Send + 'static,
    S::Future: Send + 'static,
    B: Send + 'static,
{
    type Response = S::Response;
    type Error = S::Error;
    type Future = Pin<Box<dyn Future<Output = Result<Self::Response, Self::Error>> + Send>>;

    fn poll_ready(&mut self, cx: &mut Context<'_>) -> Poll<Result<(), Self::Error>> {
        self.inner.poll_ready(cx)
    }

    fn call(&mut self, req: Request<B>) -> Self::Future {
        let start = Instant::now();
        let method = req.method().clone();
        let uri = req.uri().clone();

        let fut = self.inner.call(req);

        Box::pin(async move {
            let response = fut.await?;
            let duration = start.elapsed();
            tracing::info!(
                method = %method,
                uri = %uri,
                status = %response.status().as_u16(),
                duration_ms = %duration.as_millis(),
                "请求完成"
            );
            Ok(response)
        })
    }
}
```

## Response（响应）
```rust
use axum::response::{IntoResponse, Json, Html};

// JSON 响应
async fn handler() -> Json<Value> {
    Json(json!({ "status": "ok" }))
}

// 自定义响应
async fn handler() -> impl IntoResponse {
    (StatusCode::CREATED, Json(json!({ "id": "xxx" })))
}

// 统一响应包装
pub fn success_response<T: Serialize>(data: T) -> impl IntoResponse {
    (StatusCode::OK, Json(json!({ "code": 0, "message": "success", "data": data })))
}

pub fn created_response<T: Serialize>(data: T) -> impl IntoResponse {
    (StatusCode::CREATED, Json(json!({ "code": 0, "message": "created", "data": data })))
}
```

## 数据库（sqlx）
### 连接池配置
```rust
let pool = PgPoolOptions::new()
    .max_connections(20)
    .min_connections(5)
    .acquire_timeout(Duration::from_secs(10))
    .idle_timeout(Duration::from_secs(300))
    .max_lifetime(Duration::from_secs(1800))
    .connect(&config.database.url)
    .await?;
```

### 迁移
```rust
// 自动运行迁移
sqlx::migrate!("./migrations").run(&pool).await?;
```

### 事务
```rust
async fn transfer(
    pool: &PgPool,
    from: Uuid,
    to: Uuid,
    amount: Decimal,
) -> Result<(), AppError> {
    let mut tx = pool.begin().await?;

    sqlx::query!("UPDATE accounts SET balance = balance - $1 WHERE id = $2", amount, from)
        .execute(&mut *tx).await?;

    sqlx::query!("UPDATE accounts SET balance = balance + $1 WHERE id = $2", amount, to)
        .execute(&mut *tx).await?;

    tx.commit().await?;
    Ok(())
}
```

## 认证（JWT）
```rust
use jsonwebtoken::{encode, decode, Header, Validation, EncodingKey, DecodingKey};
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: Uuid,        // 用户 ID
    pub name: String,     // 用户名
    pub roles: Vec<String>,
    pub exp: usize,       // 过期时间
    pub iat: usize,       // 签发时间
}

pub fn create_token(user_id: Uuid, name: &str, secret: &str) -> Result<String, AppError> {
    let now = chrono::Utc::now();
    let claims = Claims {
        sub: user_id,
        name: name.to_string(),
        roles: vec![],
        exp: (now + chrono::Duration::hours(24)).timestamp() as usize,
        iat: now.timestamp() as usize,
    };

    encode(&Header::default(), &claims, &EncodingKey::from_secret(secret.as_bytes()))
        .map_err(|e| AppError::Internal(e.into()))
}

pub fn verify_token(token: &str, secret: &str) -> Result<Claims, AppError> {
    decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::default(),
    )
    .map(|data| data.claims)
    .map_err(|e| AppError::Unauthorized(format!("Token 验证失败: {}", e)))
}
```

## 日志（tracing）
```rust
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt, EnvFilter};

// 初始化
tracing_subscriber::registry()
    .with(EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| "info,tower_http=debug".into()))
    .with(tracing_subscriber::fmt::layer()
        .json()
        .with_target(true))
    .init();

// 使用
tracing::info!(user_id = %id, "用户登录成功");
tracing::warn!(error = %e, "数据库连接失败，重试中");
tracing::error!(?e, "未捕获的内部错误");
```

## HTTP 客户端（reqwest）
```rust
use reqwest::Client;

let client = Client::builder()
    .timeout(Duration::from_secs(30))
    .build()?;

let response = client
    .get("https://api.example.com/data")
    .header("Authorization", format!("Bearer {}", token))
    .send()
    .await?;

let data: ApiData = response.json().await?;
```

## Redis
```rust
use redis::aio::ConnectionManager;

let client = redis::Client::open(config.redis.url)?;
let manager = ConnectionManager::new(client).await?;

// 设置缓存
let mut conn = manager.clone();
redis::cmd("SETEX")
    .arg(&cache_key)
    .arg(3600)
    .arg(&serde_json::to_string(&value)?)
    .query_async::<()>(&mut conn)
    .await?;

// 获取缓存
let mut conn = manager.clone();
let result: Option<String> = redis::cmd("GET")
    .arg(&cache_key)
    .query_async(&mut conn)
    .await?;
```
