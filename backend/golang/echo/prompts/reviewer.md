# Echo 评审规则

> 适用场景：审查 Echo 项目的 PR、diff、设计文档。

## 评审顺序（按优先级）

1. 包名与目录结构 → 2. 分层依赖方向 → 3. Handler 职责 → 4. Service 接口 → 5. Repository 实现 → 6. 错误处理 → 7. 依赖注入 → 8. Echo 配置 → 9. 中间件 → 10. 测试 → 11. 文档

## 硬性驳回项（MUST-FIX）

### 包名与结构
- 包名使用大写、下划线、复数形式。
- `main` 函数放在非 `cmd/` 目录下。
- 业务代码放在 `cmd/` 或 `pkg/` 中。

### 分层破坏
- Handler 直接操作数据库（`ent.Client` 或 `*sqlx.DB`）。
- Handler 包含业务逻辑。
- Service 引用 `echo.Context` 或 HTTP 相关类型。
- Repository 接口放在实现所在的子包中。

### 错误处理
- 使用 `panic` 处理请求级业务错误。
- 忽略错误（`_ = fn()` 无注释说明）。
- 未将 `ent.IsNotFound` 或 `sql.ErrNoRows` 映射为业务错误。
- 未配置自定义 `HTTPErrorHandler`。

### 依赖注入
- 使用全局变量持有依赖。
- 使用 `init()` 函数初始化依赖。

### 配置管理
- 硬编码配置值。
- Echo Server 参数（端口、超时等）硬编码。

### 数据库
- 生产环境使用 `AutoMigrate`。
- 未设置数据库连接池参数。

### Echo 特定
- 未注册 Recover 中间件。
- 未配置 BodyLimit 中间件。
- CORS 使用 `*` 通配符（生产环境）。

### 测试
- 新功能无单元测试。
- 修改功能未同步修改测试。
- Mock 数据库/Redis。
- `time.Sleep` 等待异步。
- 僵尸断言。

## 建议性反馈（SHOULD-FIX）

- 函数体超过 50 行。
- 函数参数超过 5 个。
- 导出符号缺少文档注释。
- `interface{}` 应使用 `any`。
- Echo handler 使用 `c.String()` 返回非 JSON 响应（API 场景）。

## NIT

- 变量命名不符合 Go 惯例。
- 注释拼写错误。
- import 分组不规范。

## 已知常见陷阱

- `echo.Context` 在 goroutine 中使用（应用 `c.Echo()` 获取 Echo 实例）。
- ent 的 `Only()` 在无结果时 panic（应用 `Only(ctx)` + 检查 `NotFoundError`）。
- Viper `AutomaticEnv` 的点号替换规则。

## 反馈格式

每条反馈含：位置（`file:line`）、级别（MUST-FIX / SHOULD-FIX / NIT / QUESTION）、依据（引用规则条目）、建议（可落地）。
