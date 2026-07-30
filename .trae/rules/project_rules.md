# structure-projects 生态项目规则

> 本文件是 Trae IDE 的项目级规则入口。
> 完整规则体系见仓库根目录的 `prompts/`（**single source of truth**）与 `CLAUDE.md`（生态事实库）。

## 使用前必读

在处理任何任务前，**先 Read 以下文件** 并视为约束：

- `CLAUDE.md` — 生态事实（版本、包名、组件清单、已知不一致）
- `prompts/developer.md` — 编码任务
- `prompts/architect.md` — 选型/设计任务
- `prompts/tester.md` — 测试任务
- `prompts/reviewer.md` — 评审任务
- `prompts/components.md` — 查具体组件用法
- `prompts/project-scaffolding.md` — 新建项目/模块
- `prompts/validation.md` — DTO 参数校验（分组验证、级联、自定义注解）
- `prompts/swagger.md` — API 文档（springdoc-openapi 注解与配置）
- `prompts/ci-cd.md` — 测试要求、GitHub 流水线、发布（ACR / Maven Central / npm）

按任务角色选择 `prompts/<role>.md`，也可参考 `.trae/rules/<role>.md` 的速查版。

## 生态硬约束（任何任务都必须遵守）

- Maven `groupId` = `cn.structured`；npm scope = `@structure-projects`。
- 包名：`cn.structure.*`（无 d）**仅**用于 `structure-common` / `structure-infra`；其余全部 `cn.structured.*`（含 `structure-security`，**不是** `cn.structure.security`）。
- 当前主线：Spring Boot `4.0.6` + JDK 17 + `jakarta.*`；parent 为 `cn.structured:structure-dependencies:1.4.4`。
- **禁止** 引入 `structure-cloud-dependencies`（structure-cloud 已停止维护）。

## 关键优先级（顺序不可乱）

- **工具类**：Hutool → 框架 `structure-common` → 框架其他模块 → 自定义（**限 infra 层**）。
- **Bean 注入**：构造器（推荐 Lombok `@RequiredArgsConstructor`）→ `@Resource` → `@Autowired`（谨慎）。

## 持久化（DDD 项目）

- `RepositoryImpl extends RepositoryFacade<Entity, ID, Delegate>`，方法体 `getDelegate().xxx()`。
- `MybatisPlusDelegate extends MybatisPlusRepositoryDelegate<Entity, PO, ID>`，**MUST 显式重写 `toEntity`/`toPo`**。
- 仓储接口继承 `cn.structure.common.repository.ICrudRepository<T, ID>`，**优先使用框架已定义函数**。
- **禁止** 在 `Service`/`Controller` 注入 `Mapper`/`PO`。

## POJO 规范

- 实体 MUST 有 `@Builder`；所有 POJO MUST 有无参构造。
- 函数参数 ≤ 3，超过用 包装类 / 值对象 / 命令对象。

## 异常与响应

- 业务异常 MUST 有 `{X}ExceptionEnum` 枚举 + 抛 `CommonException`。
- 控制层 MUST 用 `ResultUtilSimpleImpl.fail(...)`，**不抛异常**；成功用 `success(data)`。
- Controller 返回 `cn.structure.common.entity.ResResultVO<T>`；分页 `cn.structure.common.vo.ReqPage` + `cn.structure.common.vo.ResPage<T>`。

## 用户上下文与数据权限

- **非控制层 MUST 用 `cn.structured.security.context.UserContext` 静态方法**（`UserContext.getLongUserId()` 等），**无需注入**。
- 消息事件 MUST 经 `DataScopeStreamBridge`（经 `EventManager` + `MESSAGE_EVENT` 自动路由）。
- 缓存 MUST 用 `DataScopeCacheManager`；Redis MUST 用 `DataScopeRedisTemplate`；**禁止**直接用原生 `CacheManager` / `RedisTemplate`。

## 多租户

- 租户标识从上下文取；**禁止** 从请求参数/Header 读；**禁止** SQL 手写 `WHERE tenant_id = ?`。

---

**详细规则以 `prompts/` 为准。** 发现 AI 生成错误代码时，按仓库 `README.md` 的"生成错误时如何修正规则"章节处理。
