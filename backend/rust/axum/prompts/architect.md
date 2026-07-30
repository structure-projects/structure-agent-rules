# Axum 架构/设计规则（Architect Rules）

## 硬约束
- Rust 版本 MUST >= 1.75（推荐 1.80+）
- 模块名 MUST 使用 `snake_case`
- 项目 MUST 遵循 Rust 标准项目布局
- 必须使用 `Cargo.toml` 的 `[workspace]` 管理多 crate 项目
- 公共 crate 的公共 API MUST 有 `///` 文档注释

## 分层架构（Clean Architecture）
```
┌─────────────────────────────────────┐
│          routes/ (Handler)          │  ← axum 路由定义、提取参数、构建响应
├─────────────────────────────────────┤
│         services/ (Service)         │  ← 纯业务逻辑，不依赖 HTTP 类型
├─────────────────────────────────────┤
│       repositories/ (Repository)    │  ← trait 接口 + 数据库实现
├─────────────────────────────────────┤
│          models/ (Domain)           │  ← 实体、DTO、错误、值对象
└─────────────────────────────────────┘
```

依赖方向：`routes → services → repositories → models`（models 无外部依赖）

## 模块职责

### routes/ — Handler 层
- 定义 axum `Router`，注册路由
- handler 函数：提取参数 → 调用 service → 构建响应
- 路由分组：按领域拆分文件，`mod.rs` 中组合
- 使用 `axum::extract` 提取器：`State`、`Path`、`Query`、`Json`、`HeaderMap`

### services/ — Service 层
- 纯业务逻辑，`async fn`，返回 `Result<T, AppError>`
- 禁止引用 `axum::extract` 类型或 HTTP 相关类型
- 通过 trait 注入 Repository 依赖
- 事务管理：在 service 层使用 `pool.begin()` + `tx.commit()`

### repositories/ — Repository 层
- trait 定义在 `repositories/` 模块
- 实现在 `repositories/impls/` 或独立文件
- 将数据库错误映射为 `AppError`
- 使用 `sqlx::query_as!` 做编译时 SQL 校验

### models/ — 领域模型
- 实体、DTO、错误定义、值对象
- 禁止引用框架类型（`axum`、`actix-web` 等）
- 使用 `serde` 的 `Deserialize` / `Serialize`

### middleware/ — 自定义中间件
- 认证（JWT 验证）
- 请求日志
- 请求限流
- CORS 配置（使用 `tower_http::cors`）

### extractors/ — 自定义提取器
- 分页参数提取
- 当前用户提取（从 JWT token）
- 参数校验提取器

## 技术选型（推荐）
| 层次 | 推荐 | 替代 | 备注 |
|---|---|---|---|
| Web 框架 | axum 0.7+ | actix-web | 基于 tokio + tower |
| 异步运行时 | tokio 1.x | — | axum 的运行时依赖 |
| ORM / DB | sqlx 0.8+ | sea-orm / diesel | 编译时 SQL 校验 |
| 配置 | config 0.14+ | figment | 多环境配置 |
| 日志 | tracing + tracing-subscriber | env_logger | 结构化日志 |
| 校验 | validator 0.18+ | garde | 派生宏校验 |
| 序列化 | serde 1.x + serde_json | — | 标准序列化 |
| 错误处理 | thiserror + anyhow | snafu | thiserror 定义错误，anyhow 用于应用级 |
| API 文档 | utoipa 4.x + utoipa-swagger-ui | aide | OpenAPI 生成 |
| 测试 | tokio::test + reqwest | axum_test | 集成测试 |
| HTTP 客户端 | reqwest 0.12+ | — | 异步 HTTP 客户端 |
| Redis | redis 0.25+ | — | 异步 Redis 客户端 |
| JWT | jsonwebtoken 9.x | — | JWT 签发与验证 |
| 密码 | argon2 | bcrypt | 密码哈希 |
| UUID | uuid 1.x | — | 唯一标识符 |
| 时间 | chrono 0.4 | time | 日期时间处理 |

## 路由设计规范
```rust
// 按领域分组路由
pub fn user_routes() -> Router<AppState> {
    Router::new()
        .route("/api/users", get(list_users).post(create_user))
        .route("/api/users/{id}", get(get_user).put(update_user).delete(delete_user))
}

pub fn create_app(state: AppState) -> Router {
    Router::new()
        .route("/health", get(health_check))
        .nest("/", user_routes())
        .nest("/", order_routes())
        .layer(
            ServiceBuilder::new()
                .layer(TraceLayer::new_for_http())
                .layer(CorsLayer::permissive())
        )
        .with_state(state)
}
```

## RESTful URL 规范
| 方法 | URL | 说明 |
|---|---|---|
| GET | `/api/{resources}` | 列表查询（分页） |
| GET | `/api/{resources}/{id}` | 单个查询 |
| POST | `/api/{resources}` | 创建 |
| PUT | `/api/{resources}/{id}` | 全量更新 |
| PATCH | `/api/{resources}/{id}` | 部分更新 |
| DELETE | `/api/{resources}/{id}` | 删除 |

## 统一响应格式
```rust
#[derive(Serialize)]
pub struct ApiResponse<T: Serialize> {
    pub code: u16,
    pub message: String,
    pub data: Option<T>,
}

#[derive(Serialize)]
pub struct PageResult<T: Serialize> {
    pub items: Vec<T>,
    pub total: u64,
    pub page: u64,
    pub page_size: u64,
}
```

## 错误处理架构
```rust
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
        let (status, code, message) = match &self {
            AppError::NotFound(msg) => (StatusCode::NOT_FOUND, 404, msg.clone()),
            AppError::ValidationError(msg) => (StatusCode::BAD_REQUEST, 400, msg.clone()),
            AppError::DatabaseError(e) => {
                tracing::error!("数据库错误: {:?}", e);
                (StatusCode::INTERNAL_SERVER_ERROR, 500, "内部数据库错误".into())
            }
            AppError::Unauthorized(msg) => (StatusCode::UNAUTHORIZED, 401, msg.clone()),
            AppError::Forbidden(msg) => (StatusCode::FORBIDDEN, 403, msg.clone()),
            AppError::Internal(e) => {
                tracing::error!("内部错误: {:?}", e);
                (StatusCode::INTERNAL_SERVER_ERROR, 500, "内部服务器错误".into())
            }
        };

        let body = Json(json!({ "code": code, "message": message }));
        (status, body).into_response()
    }
}
```

## 配置管理
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

impl AppConfig {
    pub fn from_env() -> Result<Self, config::ConfigError> {
        Config::builder()
            .add_source(File::with_name("config/default"))
            .add_source(File::with_name(&format!("config/{}", std::env::var("APP_ENV").unwrap_or_else(|_| "development".into()))).required(false))
            .add_source(Environment::with_prefix("APP").separator("__"))
            .build()?
            .try_deserialize()
    }
}
```

## 安全约束
- **MUST** 使用 `sqlx` 参数化查询，禁止字符串拼接 SQL
- **MUST** 密码使用 `argon2` 哈希存储
- **MUST** JWT token 设置合理过期时间
- **MUST** 生产环境 CORS 不允许 `Any`
- **SHOULD** 敏感配置使用环境变量或 vault
- **SHOULD** 生产环境启用 HTTPS
- **SHOULD** 实现请求限流（`tower::limit`）
- **SHOULD** 日志中脱敏（手机号、密码、token）

## 数据库规范
- 表名 MUST 使用 `snake_case` 复数形式
- 字段名 MUST 使用 `snake_case`
- MUST 使用 UUID 作为主键（或分布式友好 ID）
- MUST 有 `created_at`、`updated_at` 时间戳字段
- SHOULD 使用软删除（`deleted_at`）
- 索引命名：`idx_{table}_{column}`

## 禁止事项
- 禁止在 models 中引用 `axum`、`tower` 等框架类型
- 禁止在 services 中使用 HTTP 相关类型（`StatusCode`、`HeaderMap` 等）
- 禁止跨层依赖（routes 不能直接调 repository）
- 禁止使用全局 `static` / `lazy_static` 持有依赖
- 禁止硬编码配置值
