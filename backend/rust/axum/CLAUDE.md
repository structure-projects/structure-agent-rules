# CLAUDE.md — Axum Rust 后端

## 技术栈
axum 0.7+ / tokio / tower / sqlx / serde / thiserror / tracing

## 项目结构
```
src/
├── main.rs            # 入口
├── lib.rs             # 库根
├── config.rs          # 配置
├── error.rs           # 错误类型（thiserror）
├── routes/            # Handler
├── services/          # 业务逻辑
├── repositories/      # 数据访问（trait + 实现）
├── models/            # 实体 + DTO
├── middleware/        # 自定义中间件
└── extractors/        # 自定义提取器
```

## 关键规则
- `unwrap()` / `expect()` 禁止用于业务错误
- Handler 只做：提取参数 → 调 service → 构建响应
- Service 禁止引用 HTTP 类型
- 错误用 `thiserror` + `IntoResponse` 统一处理
- 数据库用 `sqlx::query_as!` 编译时校验
- 禁止全局 static 持有依赖
- 测试：单元测试 + 集成测试（真实 DB）

完整规范见 `.structure-rules/prompts/`。
