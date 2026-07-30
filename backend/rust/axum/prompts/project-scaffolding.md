# Axum 项目脚手架（Project Scaffolding）

## Cargo.toml 模板
```toml
[package]
name = "my-axum-app"
version = "0.1.0"
edition = "2021"
rust-version = "1.75"

[dependencies]
# Web 框架
axum = "0.7"
tokio = { version = "1", features = ["full"] }
tower = "0.4"
tower-http = { version = "0.5", features = ["cors", "trace", "compression-gzip", "limit", "request-id"] }

# 序列化
serde = { version = "1", features = ["derive"] }
serde_json = "1"

# 数据库
sqlx = { version = "0.8", features = ["runtime-tokio", "tls-rustls", "postgres", "uuid", "chrono", "migrate"] }

# 错误处理
thiserror = "2"
anyhow = "1"

# 校验
validator = { version = "0.18", features = ["derive"] }

# API 文档
utoipa = { version = "4", features = ["axum_extras"] }
utoipa-swagger-ui = { version = "7", features = ["axum"] }

# 配置
config = "0.14"
dotenvy = "0.15"

# 日志
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }

# HTTP 客户端
reqwest = { version = "0.12", features = ["json"] }

# 工具
uuid = { version = "1", features = ["v4", "serde"] }
chrono = { version = "0.4", features = ["serde"] }
jsonwebtoken = "9"
argon2 = "0.5"
redis = { version = "0.25", features = ["tokio-comp", "connection-manager"] }

[dev-dependencies]
mockall = "0.13"
axum-test = "16"
testcontainers = "0.23"
reqwest = { version = "0.12", features = ["json"] }

[[bin]]
name = "my-axum-app"
path = "src/main.rs"
```

## 标准项目结构
```
my-axum-app/
├── Cargo.toml
├── Cargo.lock
├── .env.example
├── .env
├── .gitignore
├── config/
│   ├── default.toml        # 默认配置
│   ├── development.toml    # 开发环境覆盖
│   ├── production.toml     # 生产环境覆盖
│   └── test.toml           # 测试环境覆盖
├── migrations/             # sqlx 迁移脚本
│   ├── 20240101000001_create_users.sql
│   └── 20240101000002_create_orders.sql
├── src/
│   ├── main.rs             # 入口：启动服务器
│   ├── lib.rs              # 库根：声明公共模块
│   ├── config.rs           # 配置加载
│   ├── error.rs            # 统一错误类型（AppError）
│   ├── routes/             # Handler 层
│   │   ├── mod.rs
│   │   ├── health.rs
│   │   ├── users.rs
│   │   └── orders.rs
│   ├── services/           # Service 层
│   │   ├── mod.rs
│   │   ├── user_service.rs
│   │   └── order_service.rs
│   ├── repositories/       # Repository 层
│   │   ├── mod.rs
│   │   ├── user_repository.rs
│   │   ├── order_repository.rs
│   │   └── impls/
│   │       ├── mod.rs
│   │       ├── pg_user_repository.rs
│   │       └── pg_order_repository.rs
│   ├── models/             # 领域模型 + DTO
│   │   ├── mod.rs
│   │   ├── user.rs
│   │   ├── order.rs
│   │   └── dto/
│   │       ├── mod.rs
│   │       ├── create_user.rs
│   │       ├── update_user.rs
│   │       └── user_response.rs
│   ├── middleware/          # 自定义中间件
│   │   ├── mod.rs
│   │   ├── auth.rs
│   │   └── request_logger.rs
│   └── extractors/         # 自定义提取器
│       ├── mod.rs
│       ├── current_user.rs
│       └── page_params.rs
├── tests/                  # 集成测试
│   ├── common/
│   │   └── mod.rs
│   ├── health_test.rs
│   ├── user_api_test.rs
│   └── order_api_test.rs
└── docs/
    └── api.md
```

## src/main.rs 模板
```rust
use my_axum_app::{config::AppConfig, AppState};
use axum::Router;
use tower_http::cors::CorsLayer;
use tower_http::trace::TraceLayer;
use tower::ServiceBuilder;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt, EnvFilter};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // 初始化日志
    tracing_subscriber::registry()
        .with(EnvFilter::try_from_default_env()
            .unwrap_or_else(|_| "info,tower_http=debug".into()))
        .with(tracing_subscriber::fmt::layer())
        .init();

    // 加载 .env
    dotenvy::dotenv().ok();

    // 加载配置
    let config = AppConfig::from_env()?;

    // 初始化数据库连接池
    let pool = sqlx::postgres::PgPoolOptions::new()
        .max_connections(config.database.max_connections)
        .min_connections(config.database.min_connections)
        .acquire_timeout(std::time::Duration::from_secs(config.database.acquire_timeout_seconds))
        .connect(&config.database.url)
        .await?;

    // 运行迁移
    sqlx::migrate!("./migrations").run(&pool).await?;

    // 构建应用状态
    let state = AppState::new(pool, config).await?;

    // 构建路由
    let app = Router::new()
        .merge(my_axum_app::routes::create_routes())
        .layer(
            ServiceBuilder::new()
                .layer(TraceLayer::new_for_http())
                .layer(CorsLayer::permissive())
        )
        .with_state(state);

    // 启动服务
    let addr = format!("{}:{}", state.config.server.host, state.config.server.port);
    tracing::info!("服务器启动: http://{}", addr);

    let listener = tokio::net::TcpListener::bind(&addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
```

## src/lib.rs 模板
```rust
pub mod config;
pub mod error;
pub mod extractors;
pub mod middleware;
pub mod models;
pub mod repositories;
pub mod routes;
pub mod services;

use axum::Router;
use services::{user_service::UserService, order_service::OrderService};
use std::sync::Arc;

#[derive(Clone)]
pub struct AppState {
    pub db: sqlx::PgPool,
    pub config: Arc<config::AppConfig>,
    pub user_service: Arc<UserService>,
    pub order_service: Arc<OrderService>,
}

impl AppState {
    pub async fn new(
        db: sqlx::PgPool,
        config: config::AppConfig,
    ) -> Result<Self, anyhow::Error> {
        let config = Arc::new(config);
        let user_repo = Arc::new(repositories::impls::PgUserRepository::new(db.clone()));
        let order_repo = Arc::new(repositories::impls::PgOrderRepository::new(db.clone()));

        Ok(Self {
            db,
            config,
            user_service: Arc::new(UserService::new(user_repo)),
            order_service: Arc::new(OrderService::new(order_repo)),
        })
    }
}
```

## src/config.rs 模板
```rust
use config::{Config, Environment, File};
use serde::Deserialize;

#[derive(Debug, Deserialize, Clone)]
pub struct AppConfig {
    pub server: ServerConfig,
    pub database: DatabaseConfig,
    pub redis: RedisConfig,
    pub jwt: JwtConfig,
}

#[derive(Debug, Deserialize, Clone)]
pub struct ServerConfig {
    pub host: String,
    pub port: u16,
}

#[derive(Debug, Deserialize, Clone)]
pub struct DatabaseConfig {
    pub url: String,
    pub max_connections: u32,
    pub min_connections: u32,
    pub acquire_timeout_seconds: u64,
}

#[derive(Debug, Deserialize, Clone)]
pub struct RedisConfig {
    pub url: String,
}

#[derive(Debug, Deserialize, Clone)]
pub struct JwtConfig {
    pub secret: String,
    pub expiration_hours: i64,
}

impl AppConfig {
    pub fn from_env() -> Result<Self, config::ConfigError> {
        let run_env = std::env::var("APP_ENV").unwrap_or_else(|_| "development".into());

        Config::builder()
            .add_source(File::with_name("config/default"))
            .add_source(File::with_name(&format!("config/{}", run_env)).required(false))
            .add_source(Environment::with_prefix("APP").separator("__"))
            .build()?
            .try_deserialize()
    }
}
```

## src/error.rs 模板
```rust
use axum::{
    http::StatusCode,
    response::{IntoResponse, Response, Json},
};
use serde_json::json;

#[derive(Debug, thiserror::Error)]
pub enum AppError {
    #[error("资源不存在: {0}")]
    NotFound(String),

    #[error("参数校验失败: {0}")]
    ValidationError(String),

    #[error("数据库错误")]
    DatabaseError(#[from] sqlx::Error),

    #[error("未授权: {0}")]
    Unauthorized(String),

    #[error("禁止访问: {0}")]
    Forbidden(String),

    #[error("内部错误")]
    Internal(#[from] anyhow::Error),
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, message) = match &self {
            AppError::NotFound(msg) => (StatusCode::NOT_FOUND, msg.clone()),
            AppError::ValidationError(msg) => (StatusCode::BAD_REQUEST, msg.clone()),
            AppError::DatabaseError(e) => {
                tracing::error!("数据库错误: {:?}", e);
                (StatusCode::INTERNAL_SERVER_ERROR, "内部数据库错误".into())
            }
            AppError::Unauthorized(msg) => (StatusCode::UNAUTHORIZED, msg.clone()),
            AppError::Forbidden(msg) => (StatusCode::FORBIDDEN, msg.clone()),
            AppError::Internal(e) => {
                tracing::error!("内部错误: {:?}", e);
                (StatusCode::INTERNAL_SERVER_ERROR, "内部服务器错误".into())
            }
        };

        let body = Json(json!({
            "code": status.as_u16(),
            "message": message,
        }));

        (status, body).into_response()
    }
}
```

## .env.example
```
APP_ENV=development

APP__SERVER__HOST=0.0.0.0
APP__SERVER__PORT=3000

APP__DATABASE__URL=postgres://postgres:postgres@localhost:5432/myapp
APP__DATABASE__MAX_CONNECTIONS=20
APP__DATABASE__MIN_CONNECTIONS=5
APP__DATABASE__ACQUIRE_TIMEOUT_SECONDS=10

APP__REDIS__URL=redis://localhost:6379

APP__JWT__SECRET=change-me-to-a-random-secret
APP__JWT__EXPIRATION_HOURS=24
```

## .gitignore（Rust 相关）
```
/target/
**/*.rs.bk
.env
*.log
Cargo.lock  # 二进制项目提交，库项目忽略
```
