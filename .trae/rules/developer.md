# Developer — structure-projects 开发规则速查

> 完整规则见 `prompts/developer.md`；组件用法见 `prompts/components.md`。本文件为 Trae IDE 速查版。

## 硬约束

- `groupId` = `cn.structured`；npm scope = `@structure-projects`
- 包名：`cn.structure.*`（无 d）仅 common/infra；其余 `cn.structured.*`
- Spring Boot `4.0.6` + JDK 17 + `jakarta.*`（**不要写 `javax.*`**）

## 关键优先级

- **工具类**：Hutool → 框架 common → 框架其他 → 自定义（**限 infra 层**）
- **Bean 注入**：构造器（`@RequiredArgsConstructor`）→ `@Resource` → `@Autowired`（谨慎）

## 持久化

- `RepositoryImpl extends RepositoryFacade<Entity, ID, Delegate>`，方法体 `getDelegate().xxx()`
- `MybatisPlusDelegate extends MybatisPlusRepositoryDelegate<Entity, PO, ID>`，**MUST 显式重写 `toEntity`/`toPo`**
- 仓储接口继承 `ICrudRepository<T, ID>`，**优先用框架已定义函数**（`save` / `findById` / `queryPage` 等）
- **禁止** 在 `Service`/`Controller` 注入 `Mapper`/`PO`

## POJO

- 实体 MUST `@Builder`；所有 POJO MUST 无参构造
- 函数参数 ≤ 3，超过用 包装类 / 值对象 / 命令对象

## 异常与响应

- 业务异常 MUST 有 `{X}ExceptionEnum` 枚举 + 抛 `CommonException`
- 控制层 MUST 用 `ResultUtilSimpleImpl.fail(...)`，**不抛异常**
- Controller 返回 `ResResultVO<T>`；分页 `ReqPage` + `ResPage<T>`

## 用户上下文

- **非控制层 MUST 用 `cn.structured.security.context.UserContext` 静态方法**（`getLongUserId()` 等）
- 优先用 `getLongUserId()` 等 Long 型方法，避免手写 `Long.parseLong(...)`

## 数据权限

- 消息事件 MUST 经 `DataScopeStreamBridge`（`EventManager` + `MESSAGE_EVENT`）
- 缓存 MUST 用 `DataScopeCacheManager`；Redis MUST 用 `DataScopeRedisTemplate`

## 多租户

- 租户标识从上下文取；**禁止** 从请求参数/Header 读；**禁止** SQL 手写 `WHERE tenant_id = ?`

## 事件

- **发布**：实现 `cn.structure.infra.event.Event` + `EventManager.publish(event)`；跨服务 MUST `MESSAGE_EVENT`
- **消费 Binding 模型**：`Consumer<Message<T>>` Bean 名 = `@StreamEventListener.bindingName`；`Consumer` 内只 `dispatch(...)`
- **消费 Router 模型**：`StreamEvent<T>` 信封 + `@StreamRouteHandler(eventType, businessType, condition)`，签名 `(T payload, StreamEvent<T> event)` 双参

## 前端

- `*-ui` 为 wujie 微前端子应用：Vue3 + Vite + TS + Pinia + Element Plus + UnoCSS
- `*-ui-components` 开发时 `file:` 本地引用，正式发布时发 npm
- 公开 npm 包发布到 `@structure-projects` scope

详细规则读 `prompts/developer.md`。
