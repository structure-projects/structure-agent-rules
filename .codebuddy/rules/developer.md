---
alwaysApply: true
description: structure-projects 开发规则。每次对话与内联请求都生效。编码、重构、写测试前的强制约束。
---

# structure-projects 开发规则

> 完整规则见 `prompts/developer.md`；组件用法见 `prompts/components.md`；新建项目见 `prompts/project-scaffolding.md`。本文件为 CodeBuddy 速查版（alwaysApply: true）。

## 硬约束

- Maven `groupId` = `cn.structured`；npm scope = `@structure-projects`
- 包名：`cn.structure.*`（无 d）**仅** `structure-common` / `structure-infra`；其余全部 `cn.structured.*`（含 `structure-security`）
- Spring Boot `4.0.6` + JDK 17 + `jakarta.*`（**不要写 `javax.*`**）；parent `cn.structured:structure-dependencies:1.4.4`
- **禁止** 引入 `structure-cloud-dependencies`

## 关键优先级（顺序不可乱）

- **工具类**：Hutool → 框架 `structure-common` → 框架其他 → 自定义（**限 infra 层**）
- **Bean 注入**：构造器（推荐 Lombok `@RequiredArgsConstructor`）→ `@Resource` → `@Autowired`（谨慎）

## 持久化（DDD 项目）

- `RepositoryImpl extends RepositoryFacade<Entity, ID, Delegate>`，方法体 `getDelegate().xxx()`
- `MybatisPlusDelegate extends MybatisPlusRepositoryDelegate<Entity, PO, ID>`，**MUST 显式重写 `toEntity`/`toPo`**
- 仓储接口继承 `cn.structure.common.repository.ICrudRepository<T, ID>`，**优先用框架已定义函数**（`save` / `findById` / `queryPage` 等），**禁止**重复定义
- **禁止** 在 `Service`/`Controller` 注入 `Mapper`/`PO`

## POJO 规范

- 实体 MUST `@Builder`；所有 POJO MUST 有无参构造（MyBatis/Jackson 反射依赖）
- 函数参数 ≤ 3，超过用 包装类 / 值对象 / 命令对象

## 异常与响应

- 业务异常 MUST 有 `{X}ExceptionEnum` 枚举 + 抛 `cn.structure.common.exception.CommonException`
- 控制层 MUST 用 `cn.structure.common.utils.ResultUtilSimpleImpl.fail(...)`，**不抛异常**；成功用 `success(data)`
- Controller 返回 `cn.structure.common.entity.ResResultVO<T>`；分页 `cn.structure.common.vo.ReqPage` + `cn.structure.common.vo.ResPage<T>`

## 用户上下文

- **非控制层 MUST 用 `cn.structured.security.context.UserContext` 静态方法**（`UserContext.getLongUserId()` 等），**无需注入**
- ⚠️ `UserContext` 在 `cn.structured.security.context.*`（security-core），**不是** `cn.structured.starter.context.*`
- 优先用 `getLongUserId()` 等 Long 型方法，避免手写 `Long.parseLong(...)`

## 数据权限

- 消息事件 MUST 经 `cn.structured.datascope.message.wrapper.DataScopeStreamBridge`（经 `EventManager` + `MESSAGE_EVENT` 自动路由）
- 缓存 MUST 用 `cn.structured.datascope.cache.manager.DataScopeCacheManager`
- Redis MUST 用 `cn.structured.datascope.redis.template.DataScopeRedisTemplate`
- **禁止**直接用原生 `CacheManager` / `RedisTemplate` / `StreamBridge`

## 事件

- **发布**：实现 `cn.structure.infra.event.Event` + `EventManager.publish(event)`；跨服务 MUST `getEventChannel() = MESSAGE_EVENT`
- **消费 Binding 模型**：`Consumer<Message<T>>` Bean 名 = `@StreamEventListener.bindingName`；`Consumer` 内只 `streamEventManager.dispatch(...)`
- **消费 Router 模型**：`StreamEvent<T>` 信封 + `@StreamRouteHandler(eventType, businessType, condition)`，签名 `(T payload, StreamEvent<T> event)` 双参

## 多租户

- 租户标识从上下文取；**禁止** 从请求参数/Header 读；**禁止** SQL 手写 `WHERE tenant_id = ?`

## 前端

- `*-ui` 为 wujie 微前端子应用：Vue3 + Vite + TS + Pinia + Element Plus + UnoCSS
- `*-ui-components` 开发时 `file:` 本地引用，正式发布时发 npm
- 公开 npm 包发布到 `@structure-projects` scope
- `@structure-projects/components` **不是 Vue 插件**，按需命名导入；element-plus 是 external，消费项目自己 `app.use()` 并引 CSS

详细规则读 `prompts/developer.md`。
