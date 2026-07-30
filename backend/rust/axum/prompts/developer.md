# Axum 开发规则（Developer Rules）

## 硬约束
- Rust 版本 MUST >= 1.75（推荐 1.80+），使用 `Cargo.toml` 管理依赖
- 模块名 MUST 使用 `snake_case`，文件名与模块名一致
- 公共 API MUST 有文档注释（`///`），包括函数、trait、结构体
- 错误 MUST 被处理，禁止 `unwrap()` / `expect()` 用于请求级错误
- `unsafe` 代码 MUST 有注释说明安全性，**禁止** 滥用 `unsafe`
- 禁止使用全局 `static` / `lazy_static` 持有运行时依赖

## 项目结构
```
src/
├── main.rs            # 入口，启动服务器
├── lib.rs             # 库根，导出公共模块
├── config.rs          # 配置加载（config crate）
├── error.rs           # 统一错误定义（thiserror）
├── routes/            # Handler 层，按领域拆分
│   ├── mod.rs
│   ├── health.rs      # 健康检查
│   └── users.rs       # 用户相关路由
├── services/          # Service 层
│   ├── mod.rs
│   └── user_service.rs
├── repositories/      # Repository 层
│   ├── mod.rs
│   ├── user_repository.rs  # trait 定义
│   └── impls/
│       └── pg_user_repository.rs  # PostgreSQL 实现
├── models/            # 领域模型、DTO
│   ├── mod.rs
│   ├── user.rs
│   └── dto/
│       ├── mod.rs
│       ├── create_user.rs
│       └── update_user.rs
├── middleware/        # 自定义中间件
│   ├── mod.rs
│   ├── auth.rs
│   └── logging.rs
└── extractors/        # 自定义提取器
    └── mod.rs
```

## 分层约束（MUST 遵守）
### Handler 层（`routes/`）
- **只做三件事**：提取参数 → 调用 service → 构建响应
- 使用 `axum::extract` 提取参数：`State`、`Path`、`Query`、`Json`、`HeaderMap`
- 禁止写业务逻辑、禁止直接操作数据库
- 返回 `Result<impl IntoResponse, AppError>`

```rust
// ✅ 正确：Handler 职责清晰
async fn create_user(
    State(state): State<AppState>,
    Json(payload): Json<CreateUserRequest>,
) -> Result<Json<UserResponse>, AppError> {
    let user = state.user_service.create(payload).await?;
    Ok(Json(user.into()))
}

// ❌ 错误：Handler 包含业务逻辑
async fn create_user(
    State(pool): State<PgPool>,
    Json(payload): Json<CreateUserRequest>,
) -> Result<Json<UserResponse>, AppError> {
    // 直接操作数据库 —— 违反分层
    sqlx::query!("INSERT INTO users ...").execute(&pool).await?;
}
```

### Service 层（`services/`）
- 实现业务逻辑，使用 `async fn`
- 返回 `Result<T, AppError>`
- 禁止引用 `axum::extract` 类型、`HttpResponse`、`StatusCode` 等 HTTP 相关类型
- 通过 trait 注入 Repository 依赖

```rust
// ✅ 正确：Service 纯业务逻辑
pub struct UserService {
    repo: Arc<dyn UserRepository>,
}

impl UserService {
    pub async fn create(&self, req: CreateUserRequest) -> Result<User, AppError> {
        // 业务校验
        if req.name.is_empty() {
            return Err(AppError::ValidationError("名称不能为空".into()));
        }
        self.repo.insert(&req.into()).await
    }
}
```

### Repository 层（`repositories/`）
- trait 定义业务语义接口
- 实现中将数据库错误映射为 `AppError`
- 使用 `sqlx::query_as!` / `sqlx::query!` 做编译时 SQL 校验

```rust
#[async_trait]
pub trait UserRepository: Send + Sync {
    async fn find_by_id(&self, id: Uuid) -> Result<Option<User>, AppError>;
    async fn insert(&self, user: &NewUser) -> Result<User, AppError>;
    async fn list(&self, page: u64, page_size: u64) -> Result<(Vec<User>, u64), AppError>;
}
```

## 错误处理（MUST）
### 统一错误类型
```rust
#[derive(Debug, thiserror::Error)]
pub enum AppError {
    #[error("资源不存在: {0}")]
    NotFound(String),

    #[error("参数校验失败: {0}")]
    ValidationError(String),

    #[error("数据库错误: {0}")]
    DatabaseError(#[from] sqlx::Error),

    #[error("未授权: {0}")]
    Unauthorized(String),

    #[error("内部错误: {0}")]
    Internal(#[from] anyhow::Error),
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, message) = match &self {
            AppError::NotFound(msg) => (StatusCode::NOT_FOUND, msg.clone()),
            AppError::ValidationError(msg) => (StatusCode::BAD_REQUEST, msg.clone()),
            AppError::DatabaseError(_) => (StatusCode::INTERNAL_SERVER_ERROR, "内部数据库错误".into()),
            AppError::Unauthorized(msg) => (StatusCode::UNAUTHORIZED, msg.clone()),
            AppError::Internal(_) => (StatusCode::INTERNAL_SERVER_ERROR, "内部服务器错误".into()),
        };

        let body = Json(json!({
            "error": message,
            "code": status.as_u16()
        }));

        (status, body).into_response()
    }
}
```

## 应用状态（State）
```rust
#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
    pub redis: redis::aio::ConnectionManager,
    pub config: Arc<AppConfig>,
    pub user_service: Arc<UserService>,
}

async fn main() {
    let state = AppState::new().await;

    let app = Router::new()
        .route("/api/users", get(list_users).post(create_user))
        .with_state(state);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
```

## 中间件使用（tower）
```rust
use tower_http::cors::{CorsLayer, Any};
use tower_http::trace::TraceLayer;
use tower::ServiceBuilder;

let app = Router::new()
    .route("/api/users", get(list_users))
    .layer(
        ServiceBuilder::new()
            .layer(TraceLayer::new_for_http())
            .layer(CorsLayer::permissive())
            .layer(CompressionLayer::new())
    )
    .with_state(state);
```

## 数据库操作（sqlx）
```rust
// 编译时校验 SQL
let user = sqlx::query_as!(User, "SELECT id, name, email FROM users WHERE id = $1", id)
    .fetch_optional(&self.pool)
    .await?
    .ok_or(AppError::NotFound("用户不存在".into()))?;

// 插入并返回
let user = sqlx::query_as!(
    User,
    "INSERT INTO users (name, email) VALUES ($1, $2) RETURNING id, name, email, created_at",
    new_user.name,
    new_user.email
)
.fetch_one(&self.pool)
.await?;
```

## 测试工作流（MUST）
- 每开发一个功能 **立即** 写单元测试，**单测通过才能做下一个功能**
- 功能有修改时 **同步修改测试** 并通过
- 业务完成后写 **业务流程集成测试**，通过才算交付
- 提交前 `cargo test` 全部通过 + `cargo build --release` 编译通过
- 禁止测试/编译失败仍提交

## 提交前自检清单
- [ ] `cargo fmt --check` 格式检查通过
- [ ] `cargo clippy -- -D warnings` 无警告
- [ ] `cargo test` 全部通过
- [ ] `cargo build --release` 编译通过
- [ ] `cargo doc --no-deps` 文档无错误
- [ ] 无 `unwrap()` / `expect()` 在请求处理路径
- [ ] 无 `println!` / `dbg!` 残留
- [ ] 新增公共 API 有 `///` 文档注释
- [ ] 连接池参数已配置
- [ ] 敏感配置使用环境变量，无硬编码

## 禁止事项
- 禁止 `unwrap()` / `expect()` 处理业务错误
- 禁止 `panic!` 处理业务错误
- 禁止 `let _ = fallible_fn()` 吞错误
- 禁止 Handler 直接访问数据库
- 禁止 Service 引用 HTTP 相关类型
- 禁止全局静态变量持有依赖
- 禁止硬编码配置（端口、数据库连接串、密钥）
- 禁止 `#[cfg(test)]` 中 Mock 数据库做集成测试
