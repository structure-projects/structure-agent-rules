# Actix-web 架构/设计规则（Architect Rules）

## 硬约束
- Rust 版本 MUST >= 1.75（推荐 1.80+）
- 模块名 MUST 使用 `snake_case`
- 项目 MUST 遵循 Rust 标准项目布局
- 必须使用 `Cargo.toml` 的 `[workspace]` 管理多 crate 项目

## 分层架构（Clean Architecture）
```
┌─────────────────────────────────────┐
│       handlers/ (Handler)           │  ← actix-web handler、提取参数、构建响应
├─────────────────────────────────────┤
│         services/ (Service)         │  ← 纯业务逻辑，不依赖 actix_web 类型
├─────────────────────────────────────┤
│       repositories/ (Repository)    │  ← trait 接口 + 数据库实现
├─────────────────────────────────────┤
│          models/ (Domain)           │  ← 实体、DTO、错误、值对象
└─────────────────────────────────────┘
```

依赖方向：`handlers → services → repositories → models`（models 无外部依赖）

## 模块职责

### handlers/ — Handler 层
- handler 函数：提取参数 → 调用 service → 构建 `HttpResponse`
- 使用 `actix_web::web` 提取器：`web::Data`、`web::Path`、`web::Query`、`web::Json`、`web::Form`
- 路由注册：通过 `configure` 函数组织

### services/ — Service 层
- 纯业务逻辑，`async fn`，返回 `Result<T, AppError>`
- 禁止引用 `actix_web` 类型
- 通过 trait 注入 Repository 依赖

### repositories/ — Repository 层
- trait 定义 + 实现分离
- 将数据库错误映射为 `AppError`
- 同步操作（diesel）用 `web::block` 包装

### models/ — 领域模型
- 实体、DTO、错误定义
- 禁止引用 `actix_web` 类型

### middleware/ — 自定义中间件
- 认证、日志、限流
- 使用 `actix_web::middleware` 或自定义 `Transform`

## 技术选型（推荐）
| 层次 | 推荐 | 替代 | 备注 |
|---|---|---|---|
| Web 框架 | actix-web 4.x | axum | 基于 actix-rt |
| 异步运行时 | actix-rt | — | actix-web 内置 |
| ORM / DB | sqlx | sea-orm / diesel | diesel 需 web::block |
| 配置 | config 0.14+ | envy | 多环境配置 |
| 日志 | tracing-actix-web | env_logger | 结构化日志 |
| 校验 | validator 0.18+ | garde | 派生宏校验 |
| 序列化 | serde 1.x + serde_json | — | 标准序列化 |
| 错误处理 | thiserror + anyhow | snafu | ResponseError trait |
| API 文档 | utoipa 4.x | paperclip | OpenAPI 生成 |
| 测试 | actix_web::test | reqwest | 集成测试 |
| HTTP 客户端 | awc | reqwest | actix actors 客户端 |
| Redis | redis 0.25+ | — | 异步 Redis 客户端 |
| JWT | jsonwebtoken 9.x | — | JWT 签发与验证 |
| 密码 | argon2 | bcrypt | 密码哈希 |
| UUID | uuid 1.x | — | 唯一标识符 |
| 时间 | chrono 0.4 | time | 日期时间处理 |
| CORS | actix-cors | — | CORS 中间件 |
| Session | actix-session | — | 会话管理 |

## 应用构建规范
```rust
use actix_web::{web, App, HttpServer, middleware};

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let state = web::Data::new(AppState::new().await);

    HttpServer::new(move || {
        App::new()
            .app_data(state.clone())
            .wrap(middleware::Logger::default())
            .configure(routes::configure)
    })
    .workers(4)                        // 工作线程数
    .bind("0.0.0.0:8080")?
    .run()
    .await
}
```

## 路由组织
```rust
// src/routes/mod.rs
pub fn configure(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/api")
            .configure(users::configure)
            .configure(orders::configure)
    )
    .route("/health", web::get().to(health::health_check));
}

// src/routes/users.rs
pub fn configure(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/users")
            .route("", web::get().to(list_users))
            .route("", web::post().to(create_user))
            .route("/{id}", web::get().to(get_user))
            .route("/{id}", web::put().to(update_user))
            .route("/{id}", web::delete().to(delete_user))
    );
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

// 成功响应
fn success_response<T: Serialize>(data: T) -> HttpResponse {
    HttpResponse::Ok().json(ApiResponse {
        code: 0,
        message: "success".into(),
        data: Some(data),
    })
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
    pub workers: usize,
}

#[derive(Debug, Deserialize, Clone)]
pub struct DatabaseConfig {
    pub url: String,
    pub max_connections: u32,
    pub min_connections: u32,
}
```

## 安全约束
- **MUST** 使用 `sqlx` 参数化查询，禁止字符串拼接 SQL
- **MUST** 密码使用 `argon2` 哈希存储
- **MUST** JWT token 设置合理过期时间
- **MUST** 生产环境 CORS 不允许 `Any`
- **SHOULD** 生产环境启用 HTTPS
- **SHOULD** 日志中脱敏（手机号、密码、token）

## 数据库规范
- 表名 MUST 使用 `snake_case` 复数形式
- 字段名 MUST 使用 `snake_case`
- MUST 使用 UUID 作为主键
- MUST 有 `created_at`、`updated_at` 时间戳字段
- 同步操作 MUST 用 `web::block` 包装

## 禁止事项
- 禁止在 models 中引用 `actix_web` 类型
- 禁止在 services 中使用 `HttpRequest`、`HttpResponse` 等类型
- 禁止跨层依赖
- 禁止全局 static 持有依赖
- 禁止硬编码配置值
