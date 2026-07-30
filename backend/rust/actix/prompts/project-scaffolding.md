# Actix-web 项目搭建

## 创建项目

```bash
cargo new my-service
cd my-service
```

## Cargo.toml

```toml
[package]
name = "my-service"
version = "0.1.0"
edition = "2021"

[dependencies]
actix-web = "4"
actix-rt = "2"
actix-cors = "0.7"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
sqlx = { version = "0.7", features = ["runtime-tokio", "postgres", "uuid", "chrono"] }
tokio = { version = "1", features = ["full"] }
uuid = { version = "1", features = ["v4", "serde"] }
chrono = { version = "0.4", features = ["serde"] }
thiserror = "1"
anyhow = "1"
env_logger = "0.10"
log = "0.4"
dotenvy = "0.15"
config = "0.13"
jsonwebtoken = "9"
argon2 = "0.5"
validator = { version = "0.16", features = ["derive"] }

[dev-dependencies]
actix-rt = "2"
pretty_assertions = "1"
```

## 项目结构

```
src/
├── main.rs              # 入口
├── lib.rs               # 库根
├── config/              # 配置管理
├── routes/              # 路由定义
├── handlers/            # HTTP Handler
├── models/              # Entity + DTO
├── services/            # 业务逻辑
├── repositories/        # 数据访问
├── middleware/           # 自定义中间件
├── errors/              # 错误定义
└── db/                  # 数据库初始化
```

## main.rs 模板

```rust
use actix_web::{web, App, HttpServer, middleware};
use actix_cors::Cors;

mod config;
mod routes;
mod models;
mod errors;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    dotenvy::dotenv().ok();
    env_logger::init();

    let pool = db::create_pool().await;

    HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(pool.clone()))
            .wrap(Logger::default())
            .wrap(Cors::permissive())
            .configure(routes::configure)
    })
    .bind("127.0.0.1:8080")?
    .run()
    .await
}
```

## 运行

```bash
cargo run                     # 开发运行
cargo build --release          # 生产构建
cargo watch -x run             # 热重载 (cargo watch)
```
