# Axum 评审规则（Reviewer Rules）

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
这些发现必须修复，不得绕过：

### 模块与结构
- 模块名使用大写、驼峰命名
- `main` 函数放在非 `src/main.rs` 位置
- `lib.rs` 未声明公共模块

### 分层违规
- Handler 直接操作数据库（`State(pool): State<PgPool>` 在 handler 中直接执行 SQL）
- Handler 包含业务逻辑
- Service 引用 `axum::extract` 类型或 HTTP 相关类型
- Repository 包含业务逻辑

### 错误处理
- 使用 `unwrap()` / `expect()` 处理请求级业务错误
- 使用 `panic!` 处理业务错误
- 忽略错误（`let _ = fallible_fn()`）
- `AppError` 未实现 `IntoResponse`

### 依赖注入
- 使用全局 `static` / `lazy_static` 持有依赖
- Handler 中直接创建 Service / Repository 实例

### 配置
- 硬编码数据库连接串、端口号、密钥
- 配置结构体未使用 `Deserialize` 派生

### 数据库
- 未设置连接池参数（`max_connections` 等）
- SQL 字符串拼接（未使用 `sqlx::query!` 参数化）
- 事务未正确处理（未使用 `pool.begin()`）

### 测试
- 新功能无单测
- 改功能未同步测试
- 缺流程级集成测试
- 僵尸断言（`assert!(result.is_ok())` 无具体验证）
- 测试/编译失败仍提交

### 安全
- `unsafe` 代码无安全性注释
- 生产 CORS 使用 `Any` 允许所有来源
- 密码明文存储或使用弱哈希（MD5/SHA1）
- JWT secret 硬编码

## 建议性反馈（SHOULD-FIX）

### 代码质量
- 函数体超过 50 行
- 函数参数超过 5 个
- 公共 API 缺少文档注释（`///`）
- `clone()` 使用过多，建议用引用或 `Arc`
- `.await` 调用未处理取消安全性
- `match` 分支过多，建议提取函数

### 类型使用
- 使用 `as` 做不安全的类型转换（应用 `From`/`TryFrom`）
- `Option` / `Result` 解包方式不当
- 滥用 `String` 作为参数（考虑 `&str` 或 `impl AsRef<str>`）

### 异步
- 在异步上下文中使用阻塞操作（`std::thread::sleep` 等）
- `tokio::spawn` 中未处理 `JoinHandle`
- 未设置 `tokio` 运行时工作线程数

## NIT
- 变量命名不符合 Rust 惯例
- 注释拼写错误
- `use` 语句未合并（同一模块多条 `use`）
- `match` 可用 `if let` 简化
- 不必要的 `return` 语句

## 已知常见陷阱

### Axum 特定
- handler 中 `State` 提取器参数位置错误
- `tower::ServiceBuilder` 中间件顺序错误（后添加的在外层，先执行）
- `Router::merge()` 与 `Router::nest()` 行为混淆
- `Json` 提取器对大请求体无大小限制

### sqlx 特定
- `sqlx::query!` 宏在离线模式下需要 `sqlx-data.json`
- `PgPool` 不是 `Clone` 但内部使用 `Arc`，可直接 `clone()`
- `sqlx::FromRow` 派生宏字段名与数据库列名不匹配

### tokio 特定
- `tokio::spawn` 中 `State` 不能直接 move（需 `Arc<AppState>`）
- `tokio::sync::Mutex` 与 `std::sync::Mutex` 混淆
- 忘记 `.await` 导致 Future 未被执行

## 反馈格式
每条反馈含以下字段：
- **位置**：`file:line` 或 `file:line-range`
- **级别**：`MUST-FIX` / `SHOULD-FIX` / `NIT` / `QUESTION`
- **依据**：引用规则条目或最佳实践
- **建议**：可落地的修改方案（含代码示例）

## 快速审查清单
- [ ] Cargo.toml 依赖版本合理，无不必要依赖
- [ ] `src/lib.rs` 正确声明所有公共模块
- [ ] 无 `unwrap()` / `expect()` 在请求处理路径
- [ ] `AppError` 实现了 `IntoResponse`
- [ ] 配置通过 `config` crate 加载
- [ ] 数据库连接池参数已配置
- [ ] `cargo fmt --check` 通过
- [ ] `cargo clippy -- -D warnings` 通过
- [ ] `cargo test` 通过
- [ ] `cargo build --release` 通过
