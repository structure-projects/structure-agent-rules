# Actix-web 评审规则（Reviewer Rules）

## 评审范围
- PR / diff 代码变更
- 设计文档（架构决策、API 设计）
- 配置文件变更

## 评审顺序
1. 模块名与目录结构
2. 分层依赖方向
3. Handler 职责
4. Service 接口定义
5. Repository 数据访问
6. 错误处理
7. 依赖注入
8. 配置管理
9. 中间件
10. 测试
11. 文档

## 硬性驳回项（MUST-FIX）

### 模块与结构
- 模块名使用大写、驼峰命名
- `main` 函数放在非 `src/main.rs` 位置

### 分层违规
- Handler 直接操作数据库
- Handler 包含业务逻辑
- Service 引用 `actix_web` 类型（`HttpRequest`、`HttpResponse`、`web::Data` 等）
- Repository 包含业务逻辑

### 错误处理
- 使用 `unwrap()` / `expect()` 处理请求级业务错误
- 使用 `panic!` 处理业务错误
- 忽略错误（`let _ = fallible_fn()`）
- `AppError` 未实现 `ResponseError` trait

### 依赖注入
- 使用全局 `static` / `lazy_static` 持有依赖
- Handler 中直接创建 Service / Repository 实例

### 配置
- 硬编码数据库连接串、端口号、密钥

### 数据库
- 未设置连接池参数
- SQL 字符串拼接（未使用参数化查询）
- 同步操作未用 `web::block` 包装

### 测试
- 新功能无单测
- 改功能未同步测试
- 缺流程级集成测试
- 僵尸断言
- 测试/编译失败仍提交

### 安全
- `unsafe` 代码无安全性注释
- 生产 CORS 使用 `Any`
- 密码明文存储或使用弱哈希
- JWT secret 硬编码

## 建议性反馈（SHOULD-FIX）
- 函数体超过 50 行
- 函数参数超过 5 个
- 公共 API 缺少文档注释（`///`）
- `clone()` 使用过多
- 在异步上下文中使用阻塞操作
- 使用 `as` 做不安全的类型转换

## NIT
- 变量命名不符合 Rust 惯例
- 注释拼写错误
- `use` 语句未合并
- `match` 可用 `if let` 简化

## 已知常见陷阱

### Actix-web 特定
- `web::block` 闭包中捕获了非 `Send` 类型
- `App::data()` 已废弃，必须用 `App::app_data()`
- `HttpResponse::Ok().json()` 与 `web::Json` 响应类型混淆
- `web::Data` 在 handler 参数中的位置（extractors 顺序）
- actix Actor 模型与 `async/await` 混合时的生命周期问题
- `awc` 客户端仅在 actix 运行时内可用

### sqlx 特定
- `sqlx::query!` 宏离线模式需要 `sqlx-data.json`
- `PgPool` 可直接 `clone()`（内部使用 `Arc`）

## 反馈格式
- **位置**：`file:line`
- **级别**：`MUST-FIX` / `SHOULD-FIX` / `NIT` / `QUESTION`
- **依据**：引用规则条目
- **建议**：可落地的修改方案

## 快速审查清单
- [ ] Cargo.toml 依赖版本合理
- [ ] `src/lib.rs` 正确声明所有公共模块
- [ ] 无 `unwrap()` / `expect()` 在请求处理路径
- [ ] `AppError` 实现了 `ResponseError`
- [ ] 配置通过 `config` crate 加载
- [ ] 数据库连接池参数已配置
- [ ] 同步阻塞操作用 `web::block` 包装
- [ ] `cargo fmt --check` 通过
- [ ] `cargo clippy -- -D warnings` 通过
- [ ] `cargo test` 通过
- [ ] `cargo build --release` 通过
