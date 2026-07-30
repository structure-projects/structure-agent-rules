# structure-projects 评审规则

> 完整规则见 `prompts/reviewer.md`。本文件为通义灵码项目规则（评审场景，建议设为"手动引入"，通过 `@reviewer` 调用）。

## 评审顺序

1. 包名与坐标 → 2. 模块依赖方向 → 3. 工具类优先级 → 4. Bean 注入 → 5. 持久化路径 → 6. POJO 规范 → 7. 统一性 → 8. API 出入参 → 9. 用户上下文 → 10. 数据权限 → 11. 多租户 → 12. 安全 → 13. 版本兼容 → 14. 测试 → 15. 文档

## 硬性驳回项

- 包名混淆 `cn.structure` ↔ `cn.structured`（注意 `structure-security` 是 `cn.structured.security`）
- DDD `application`/`domain` 直接注入 `Mapper`/`PO`
- `MybatisPlusDelegate` **未显式重写** `toEntity`/`toPo`
- 业务层抛非 `CommonException` 异常（含 `throw new RuntimeException(...)`）
- 控制层用 `throw` 抛业务异常（应用 `ResultUtilSimpleImpl.fail(...)`）
- 业务异常缺 `{X}ExceptionEnum` 枚举，用字符串字面量
- POJO 缺无参构造
- 非控制层用 `SecurityUtils`/`SecurityContextHolder`（应用 `UserContext` 静态方法）
- 缓存/事件未用框架的数据权限包装工具（跨服务消息未走 `DataScopeStreamBridge`）
- **事件**：未实现 `Event` 接口；跨服务未声明 `MESSAGE_EVENT`；绕过 `EventManager` 直连 publisher/MQ
- **Binding 消费**：`Consumer` Bean 名 ≠ `@StreamEventListener.bindingName`；`Consumer` 内直接写业务
- **Router 消费**：`@StreamRouteHandler` 签名非 `(T payload, StreamEvent<T> event)` 双参
- 自定义工具类放在非 infra 层
- 业务 SQL 手写 `WHERE tenant_id = ?`
- 从请求参数/Header 读租户 ID
- Controller 返回非 `ResResultVO<T>`
- 绕过 Starter 自行装配且无说明
- 集成测试 Mock 数据库/Redis/MQ
- 无 issue 关联的 `@Disabled` 测试

## 建议性反馈（不驳回）

- 使用 `@Autowired` 字段注入（应优先构造器或 `@Resource`）
- 函数参数 > 3 未用包装类
- 命名不统一（`list`/`page`/`queryPage` 混用）
- Hutool 已实现却手写工具
- 业务用 `UserContext.get()` + `Long.parseLong(...)` 而非 `getLongUserId()`

## 已知历史遗留（不驳回）

- `cn.structured.{X}.repository.repository.*`（双 "repository"）
- 旧 Controller javadoc 含 `@since JDK1.8`
- `UserContext.getLoneDeptIds()` 拼写错误（框架源码问题）

## 反馈格式

每条反馈含：位置（`file:line`）、级别（MUST-FIX / SHOULD-FIX / NIT / QUESTION）、依据（引用规则条目）、建议（可落地）。

详细规则读 `prompts/reviewer.md`。
