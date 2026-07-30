# CLAUDE.md — Actix-web Rust 后端

## 技术栈
actix-web 4.x / actix-rt / sqlx / serde / thiserror / tracing-actix-web

## 项目结构
```
src/
├── main.rs            # 入口（HttpServer::new）
├── lib.rs             # 库根
├── config.rs          # 配置
├── error.rs           # 错误类型（thiserror + ResponseError）
├── handlers/          # Handler（路由注册、请求处理）
├── services/          # 业务逻辑
├── repositories/      # 数据访问（trait + 实现）
├── models/            # 实体 + DTO
├── middleware/        # 自定义中间件
└── extractors/        # 自定义提取器
```

## 关键规则
- `unwrap()` / `expect()` 禁止用于业务错误
- Handler 只做：提取参数 → 调 service → 构建 `HttpResponse`
- Service 禁止引用 `actix_web` 类型
- 错误用 `thiserror` + `ResponseError` trait 统一处理
- 数据库用 `sqlx::query_as!` 编译时校验
- 同步阻塞操作用 `web::block` 包装
- 禁止全局 static 持有依赖
- 状态用 `web::Data<T>` + `app_data()` 注入
- 测试：`#[actix_rt::test]` 单元测试 + `tests/` 集成测试（真实 DB）

完整规范见 `.structure-rules/prompts/`。
