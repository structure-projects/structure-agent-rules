# Developer — structure-projects 开发约束

> 角色：在 structure-projects 生态内 **写代码** 的 AI。
> 本文件是工具无关的单一内容源；`.claude/agents/developer.md` 与 `.cursor/rules/developer.mdc` 均为其包装。

## 生态硬约束（不可违反）

- Maven `groupId` = `cn.structured`；npm scope = `@structure-projects`。
- 包名：`cn.structure.*`（无 d）只用于 **底层基础库**（`structure-common` / `structure-infra`），其余（含 `structure-security` / `structure-tenant` / `structure-datascope` / 所有业务代码）一律 `cn.structured.*`（有 d）。⚠️ `structure-security` 是 `cn.structured.security`，**不是** `cn.structure.security`。
- 版本（以 structure-org-dependencies 2026-07 为准）：Spring Boot `4.0.6` + JDK 17 + `jakarta.*`；MyBatis-Plus `3.5.16`；Spring Cloud `2025.1.0`；`structure-infra 1.3.1`；`structure-security 1.1.5`；`structure-tenant 1.4.3`。
- 项目 parent 是 `cn.structured:structure-dependencies:1.4.4`，业务 pom 放在 `*-dependencies/` 子目录（**仓库根目录无 pom.xml**），版本号用 `${revision}`。

## Starter 优先

`structure-boot` 已提供 Web / MyBatis-Plus / Redis / Redisson / MinIO / 日志 AOP / 多租户 / RPC / OAuth2 客户端等 Starter。

- **MUST** 引入对应 Starter 完成功能，**禁止**绕过 Starter 自行装配 Bean（除非现有 Starter 明确缺失该能力）。
- **MUST** 依赖版本统一在 `structure-{X}-dependencies` 与 `structure-boot` 中配置，业务 pom **不写死** 版本号。
- 🚫 **structure-cloud 已停止维护**（"比较鸡肋"）。**禁止**再引入 `structure-cloud-dependencies` 或 `structure-ribbon-starter`。

## 工具类使用优先级（规则 1）

按以下顺序选择，**越靠前越优先**：

1. **Hutool** —— 通用工具（`StrUtil` / `CollUtil` / `BeanUtil` / `JSONUtil` 等）首选。
2. **框架 `structure-common` 已提供的工具** —— 直接用，**禁止重复造轮子**（如 `ResultUtilSimpleImpl`、上下文管理器等）。
3. **框架其他模块提供的工具类与上下文管理器** —— 如 `structure-infra`、`structure-security`、`structure-tenant` 提供的能力。
4. **自定义工具类** —— 仅当上述都没有时。**必须放在 `infra` 层**，**禁止**放在 `application` / `domain` / `interfaces` 层。

## Bean 注入优先级（规则 8）

按以下顺序选择，**越靠前越优先**：

1. **构造器注入**（首选）—— 推荐 Lombok `@RequiredArgsConstructor` + `private final` 字段。
2. **`@Resource`**（`jakarta.annotation.Resource`）—— 次选，真实代码中广泛使用。
3. **`@Autowired`** —— **谨慎使用**。框架内部代码可用，业务代码应避免；如使用需在评审中说明理由。

```java
// 推荐写法
@Service
@RequiredArgsConstructor
public class UserServiceImpl implements IUserService {
    private final UserRepository userRepository;
    private final IUserTagService userTagService;
}
```

## 持久化（DDD 项目，已在 structure-user / structure-org 验证）

- **MUST** 业务代码只依赖 `domain/repository/{X}Repository` 接口。
- **MUST** 业务仓储接口继承 **`cn.structure.common.repository.ICrudRepository<T, ID>`**（或 `IQueryRepository` 只读场景），**优先使用框架已定义函数**（规则 5）：
  - 读：`queryById` / `queryByIdOptional` / `queryOne` / `queryOneOptional` / `queryList` / `queryPage(ReqPage)`
  - 写：`save` / `saveBatch` / `removeById` / `removeBatchByIds`
  - 其他：`findById` / `listByIds` / `count` / `exists`
  - **禁止**在业务接口中重复定义上述方法 —— 基类已实现。
- **MUST** `infra/repository/{X}RepositoryImpl` 继承 `cn.structure.infra.repository.RepositoryFacade<{X}Entity, Long, {X}RepositoryDelegate>`，方法体内 `return getDelegate().xxx(...)`。
- **MUST** `infra/repository/delegate/{X}RepositoryDelegate` 定义业务侧 Delegate 接口（仅声明框架未覆盖的自定义方法）。
- **MUST** `repository-mybatis/repository/{X}MybatisPlusDelegate` 继承 `cn.structure.infra.mybatis.plus.repository.MybatisPlusRepositoryDelegate<{X}Entity, {X}PO, Long>`。
- **MUST 重写 `toEntity(PO)` 与 `toPo(Entity)`**（规则 3）。**不重写会产生隐藏问题**（字段丢失、默认值错乱、ID 未回填等），即使当前看似能跑也必须显式实现。
- **MUST** 复杂查询直接在 Delegate 内使用 `baseMapper` + `Wrappers.<{X}PO>lambdaQuery()`。简单等值查询交给基类（非空字段自动组装 `QueryWrapper`），`save` 由基类按 ID 是否为空自动区分 insert/update。
- **禁止** 在 `Service` / `Controller` 中直接注入 `Mapper` 或 `PO`。
- **SHOULD** 写操作走 `@WriteDelegate`、读操作走 `@ReadDelegate`（来自 `cn.structure.infra.annotations`）。
- ⚠️ **包路径异常**：`repository-mybatis` 模块下的包当前是 `cn.structured.{X}.repository.repository.*`（双 "repository"）。新代码前 **应向用户确认** 沿用还是修正为 `cn.structured.{X}.repository.mybatis.*`。

## 领域实体与 POJO（规则 4、10）

- **MUST** 领域实体提供 **builder** 能力，**优先 Lombok `@Builder`**（配合 `@Getter` / `@NoArgsConstructor` / `@AllArgsConstructor`）。
- **MUST** 所有 POJO（Entity / PO / DTO / VO / Query）**必须有无参构造方法**（规则 10）。无论使用哪种模式（Lombok / 手写 / 混合）都不能省略 —— MyBatis、Jackson、MapStruct 等反射场景依赖它。
- **MUST** 函数参数数量 **≤ 3**。超过时（规则 4）：
  - 优先用 **值对象 / 包装类** 聚合相关参数；
  - 写操作可用 **命令对象**（`{X}Command`）；
  - 查询场景用 `{X}Query`（见下文"API 出入参"）。

## 异常与响应（规则 2）

- **MUST** 每类业务异常都有对应的 **枚举定义**（`{X}ExceptionEnum`，错误码形如 `ORG_001`）。**禁止**用字符串字面量直接抛异常。
- **MUST** 业务层（application / domain / infra）抛出的异常 **必须是 `cn.structure.common.exception.CommonException` 类型**（可直接，也可间接继承）。
- **MUST** 控制层（interfaces）**不抛异常**，使用 `cn.structure.common.utils.ResultUtilSimpleImpl.fail(code, message)` 返回失败；成功用 `ResultUtilSimpleImpl.success(data)`。
- **MUST** Controller 返回 `cn.structure.common.entity.ResResultVO<T>`；分页响应 `cn.structure.common.vo.ResPage<T>`，请求 `cn.structure.common.vo.ReqPage`。
- **禁止** `throw new RuntimeException(...)` 或返回裸 `Map` / `String`。

## API 出入参（规则 6、7）

- **MUST** API 出入参使用 **DTO / VO / Query** 三族对象，遵循 **CQRS** 方法论与 POJO 定义规则：
  - 写操作入参：`{X}DTO`（或 `{X}Command`）。
  - 读操作入参：`{X}Query`。
  - 出参：`{X}VO`。
- **MUST** **分页接口签名统一为两个参数**（规则 7）：
  ```java
  ResPage<XxxVO> page(XxxQuery query, ReqPage reqPage);
  ```
  - `ReqPage`：框架自带，含页码 / 页大小 / 排序等基础分页参数。
  - `{X}Query`：业务查询参数。
  - **调用方仅关心业务 Query，不需要关心框架底层分页实现**。
- **MUST** 函数命名 **见名知意**，相同功能 **命名必须统一**（规则 7）：
  - 分页一律 `page(...)`，**不要**一处 `list`、一处 `page`、一处 `queryPage`。
  - 基础 CRUD 接口使用一套 **固定标准**（支持 REST 风格）：`create` / `update` / `delete` / `findById` / `page`。

## 命名约定（真实代码已验证）

| 类型 | 模式 |
|---|---|
| 领域实体 | `{X}Entity`（如 `DeptEntity`，**非** `{X}`） |
| 持久化对象 | `{X}PO` |
| 仓储接口 | `{X}Repository` |
| 仓储实现 | `{X}RepositoryImpl` |
| Delegate 接口 | `{X}RepositoryDelegate` |
| MyBatis Delegate | `{X}MybatisPlusDelegate` |
| Service 接口 | `I{X}Service`（含 I 前缀） |
| Service 实现 | `{X}ServiceImpl` |
| Controller | `{X}Controller`（管理 API `/api/{资源}`） / `Open{X}Controller`（开放接口，位于 `controller/open/`） |
| Assembler | `{X}Assembler`（私有构造 + 静态 `assembler()` 方法） |
| 错误码枚举 | `{X}ExceptionEnum`（码如 `ORG_001`） |
| 自定义工具类 | `{X}Util` 或 `{X}Utils`，**放 `infra` 层** |

## 多租户

- **MUST** 租户标识从 **上下文** 取（由 `structure-gateway` / `structure-tenant` 写入），**禁止** 从请求参数 / Header 中读取后直接使用。
- **禁止** 在业务 SQL 中显式追加 `tenant_id` 条件 —— 由数据权限组件（`structure-datascope`）或框架自动处理。

## 数据权限包裹的缓存与事件（规则 12）

- **MUST** 跨服务消息事件 MUST 通过 **`cn.structured.datascope.message.wrapper.DataScopeStreamBridge`** 发送（而非原生 `StreamBridge`），否则数据权限参数无法跨服务传递。
  - 实际开发中 **不直接注入 `DataScopeStreamBridge`**，而是通过 `EventManager.publish(event)` + 事件声明 `EventChannel.MESSAGE_EVENT` 自动路由（见下文"事件发布与监听"）。
- **MUST** 缓存操作使用 **`cn.structured.datascope.cache.manager.DataScopeCacheManager`**（替代 Spring `CacheManager`）。
- **MUST** Redis 操作使用 **`cn.structured.datascope.redis.template.DataScopeRedisTemplate`**（替代 `RedisTemplate` / `StringRedisTemplate`）。
- **禁止** 跳过上述包装类直接注入 `StreamBridge` / `CacheManager` / `RedisTemplate` —— 数据权限参数将无法跨层/跨服务传递。

## 事件发布与监听（规则 11，已读源码验证）

### 发布（业务 MUST 走这里）

生态事件通过 `cn.structure.infra.event.EventChannel` 枚举区分渠道：

| 渠道 | 适用 | 底层实现 |
|---|---|---|
| `SPRING_EVENT` | 仅本 JVM | `ApplicationEventPublisher.publishEvent(event)` |
| `MESSAGE_EVENT` | 跨服务 | `DataScopeStreamBridge.send(eventId, event)`（**经数据权限包装**） |
| `DEFAULT`（默认） | 由配置决定 | `structure.infra.default-event-channel` 配置项 |

**发布约束**：

- **MUST** 业务事件实现 `cn.structure.infra.event.Event` 接口，声明 `getEventId()`，按需重写 `getEventChannel()`。
- **MUST** 通过注入 `cn.structure.infra.event.EventManager` 调用 `publish(event)`。**禁止**直接 `@Autowired ApplicationEventPublisher` 或直连 `StreamBridge` / `DataScopeStreamBridge` / MQ client。
- **MUST** 跨服务事件 MUST 显式 `getEventChannel() = EventChannel.MESSAGE_EVENT`（确保走 `DataScopeStreamBridge` —— 规则 12）。

### 消费（三种模式按场景选）

**模式 1 — Spring 事件（本 JVM）**：标准 `@EventListener` / `@TransactionalEventListener`，无框架特殊要求。

**模式 2 — 消息事件 Binding 监听模型**（跨服务，**推荐**，sample 工程使用）：

由 **两段组成**：

```java
// 第 1 段：Consumer Bean 接收消息（Bean 名 = bindingName，MUST 一致）
@Configuration(proxyBeanMethods = false)
public class StreamMessageConsumer {
    private final StreamEventManager streamEventManager;
    public StreamMessageConsumer(StreamEventManager m) { this.streamEventManager = m; }

    @Bean
    public Consumer<Message<OrderEvent>> orderEvent() {  // Bean 名 = bindingName
        return message -> streamEventManager.dispatch("orderEvent", message.getPayload());
    }
}

// 第 2 段：业务处理器（@StreamEventListener 注解方法，可多个共享 bindingName）
@Component
public class OrderEventListener {
    @StreamEventListener(bindingName = "orderEvent", destination = "order-exchange", group = "order-group")
    public void handleAll(OrderEvent event) { ... }

    @StreamEventListener(bindingName = "orderEvent", destination = "order-exchange", group = "order-group",
                         condition = "#event.status == 'PAID'")
    public void handlePaid(OrderEvent event) { ... }
}
```

**Binding 模型铁律**：

- **MUST** `Consumer<Message<T>>` Bean 名与 `@StreamEventListener.bindingName` **完全一致**。
- **MUST** `Consumer` 内部只调用 `streamEventManager.dispatch(bindingName, payload)`，**不直接处理业务**。
- **SHOULD** 多状态/多场景拆分用 `condition` SpEL（`#event.xxx`），不用 `if-else`。
- **SHOULD** 事件 POJO 用 `@Data @Builder @NoArgsConstructor @AllArgsConstructor`，**MUST 无参构造**（规则 10）。

**模式 3 — 消息事件 Router 路由模型**（一个 exchange 承载多种 eventType，复杂场景）：

- 负载用 `StreamEvent<T>` 信封：`StreamEvent.of(eventType, [businessType,] payload)`。
- 处理器用 `@StreamRouteHandler(eventType, businessType, condition)`，**方法签名 `(T payload, StreamEvent<T> event)` 双参**。
- 4 步匹配：eventType 精确 → businessType 通配（`*`）→ payloadType 类型 → SpEL（`#payload.xxx`）。
- **SHOULD** 仅在需要按 eventType/businessType 多路复用时使用；简单场景用 Binding 模型。

详细 API 与配置见 [`components.md`](components.md) 第 4 节。

## 安全与用户上下文（规则 13）

- **控制层**：使用 `cn.structured.security.util.SecurityUtils` 或 **`cn.structured.starter.context.manager.IContextManager`** 均可。
- **非控制层（Service / Domain / Infra / Assembler / 异步任务）**：**MUST 通过注入 `IContextManager` 调用 `getUser()` 获取当前用户**，返回 `cn.structured.security.entity.UserContextEntity`。
  **原因**：Service 可能被非 HTTP 入口（消息消费、定时任务、内部 RPC、其他 Service）调用，此时无 `HttpServletRequest` / `SecurityContextHolder` 可用，直接依赖安全框架工具会拿不到用户。
- ⚠️ **包名陷阱**：用户上下文模块包名是 `cn.structured.starter.context.*`（注意是 `starter`），**不是** `cn.structured.security.context.*`。
- `IContextManager` 主要方法：`getUser()` / `getUserByUserId(userId)` / `login(user)` / `updateUser(user)` / `logout()`。详见 [`components.md`](components.md) 第 2 节。

## 日志

- **MUST** 使用 SLF4J 或 Lombok `@Slf4j`（真实代码中 `@Slf4j` 普遍）。
- **SHOULD** 关键操作使用 `structure-boot` 的 AOP 日志能力。

## 前端（每个业务服务 monorepo 内含 `*-ui` 与 `*-ui-components`）

- **MUST** `*-ui` 是 wujie 微前端子应用：Vue 3 + Vite + TypeScript + Pinia + Vue Router + Element Plus + UnoCSS + wujie-vue3。
- **MUST** `*-ui-components` 在 **开发时** 通过 `file:../../structure-{X}/structure-{X}-ui-components` 本地引用；**正式发布时发布到 npm**（`@structure-projects/{领域}-ui-components`），便于其他场景复用。
- **MUST** 公开 npm 包发布到 scope `@structure-projects`；私有包不要使用该 scope。
- **SHOULD** 复用 `@structure-projects/components`、`@structure-projects/gateway-client`、`@structure-projects/wujie-subapp`。

## 提交前自检

- [ ] 包名是否区分 `cn.structure.*`（仅 common/infra）vs `cn.structured.*`（其余全部）？
- [ ] 工具类是否按 Hutool → 框架 common → 框架其他 → 自定义（限 infra 层）的优先级选择？
- [ ] Bean 注入是否按 构造器 → `@Resource` → `@Autowired`（谨慎）的优先级？
- [ ] 是否继承了正确的 `RepositoryFacade` / `MybatisPlusRepositoryDelegate` 并 **重写了** `toEntity`/`toPo`？
- [ ] 仓储接口是否优先使用框架已定义的函数，而非全部自定义？
- [ ] 领域实体是否有 `@Builder`？所有 POJO 是否有无参构造？
- [ ] 函数参数是否 ≤ 3？超过是否用了包装类 / 值对象 / 命令对象？
- [ ] 业务异常是否用 `{X}ExceptionEnum` 抛 `CommonException`？控制层是否用 `ResultUtilSimpleImpl.fail`？
- [ ] 分页签名是否为 `page(XxxQuery query, ReqPage reqPage)`？CRUD 命名是否统一？
- [ ] 非控制层是否通过 **用户上下文** 而非 `SecurityUtils` 获取当前用户？
- [ ] 缓存 / 事件是否走了框架的数据权限包装工具？
- [ ] 租户上下文是否来自框架而非请求参数？