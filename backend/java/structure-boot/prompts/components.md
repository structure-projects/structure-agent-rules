# Components — structure-projects 各组件使用与配置约束

> 本文是 **各组件"如何使用 / 如何配置"的速查手册**，让 AI 不必读源码就能正确调用生态组件。
> 角色规则文件（`architect.md` / `developer.md` / `reviewer.md`）只写 **通用原则**；**组件级 API、配置项、典型用法** 集中在本文。
>
> ⚠️ **状态图例**：✅ 已读源码验证 / ❓ 待读源码补充 / 🚫 已弃用或不推荐。

## 使用原则（所有组件共通）

- **MUST** 通过生态 artifact 使用组件，**禁止**绕开组件自行实现已有能力。
- **MUST** 引入组件时 **优先使用对应 Starter / AutoConfiguration**，不手动 `@Bean` 装配。
- **MUST** 组件版本由项目 pom（`structure-{X}-dependencies`）与 `structure-boot` 统一管理，业务 pom **不写死** 版本号。
- 🚫 **禁止**再引入 `structure-cloud-dependencies`（`structure-cloud` 已停止维护）。

## 常用组件（优先深入维护本文）

按用户使用频率排序，本文的详写章节：

1. [structure-boot](#1-structure-bootstarter-集合) — Starter 集合
2. [structure-security](#2-structure-security认证与授权) — 安全框架
3. [structure-datascope](#3-structure-datascope数据权限--行级权限) — 数据权限
4. [structure-infra / structure-pro-infra](#4-structure-infra--structure-pro-infra基础设施) — 基础设施（**同一项目**）
5. [structure-gateway / structure-gateway-client](#5-structure-gateway--structure-gateway-client网关--客户端) — 网关
6. [wujie 微前端组件](#6-wujie-微前端组件) — structure-wujie-subapp / structure-wujie-template
7. [公共组件与公共 UI](#7-公共组件与公共-ui) — structure-components / structure-ui

## 非常用组件（暂未详写）

以下组件当前使用频率低，**使用前从对应 git 仓库 README 获取信息**，本文不维护详情：

- `structure-sso`（统一登录）
- `structure-job`（调度中心）
- `structure-message`（消息中心）
- `structure-monitor` / `structure-ops` / `structure-alert` / `structure-audit`（监控/运维/告警/审计）
- `structure-netty` / `structure-peer-to-peer`（网络层）
- `structure-uniapp-ui` / `structure-react-native`（移动端）
- `structure-agent`（AI 智能体）
- `structure-admin` / `structure-admin-ui`（管理后台）
- `structure-web-ui`（基础前端框架）

注：`structure-tenant`（多租户）已在下文补充。

---

## 1. structure-boot（Starter 集合）

**包**：`cn.structured.*`（**有 d**，各 Starter 子包不同）

### 项目目录

```
structure-boot/
├── structure-boot-parent/              # 父 POM，版本管理
├── structure-dependencies/             # BOM
├── structure-common/                   # 基础工具（见 "structure-common" 章）
├── structure-example/                  # 示例工程
├── structure-restful-web-starter/      # Web 统一响应
├── structure-mybatis-starter/          # MyBatis 原生
├── structure-mybatis-plus-starter/     # MyBatis-Plus 增强
├── structure-mybatis-plus-generate/    # 代码生成器
├── structure-redis-starter/            # Redis + 分布式锁
├── structure-redisson-starter/         # Redisson
├── structure-minio-starter/            # MinIO 对象存储
├── structure-log-starter/              # AOP 日志
├── structure-rpc-starter/              # 声明式 HTTP RPC
└── structure-tenant-starter/           # 多租户上下文
```

### Starter 清单（artifactId / 能力 / 配置前缀）

| artifactId | 能力 | 配置前缀 |
|---|---|---|
| `structure-restful-web-starter` | 统一 `CommonResult` 响应、FastJson（Long→String）、Swagger、全局异常、CORS | `structure.web.restful` / `structure.web.cors` / `structure.web.swagger` |
| `structure-mybatis-starter` | MyBatis 原生 + ID 生成插件 | `structure.mybatis.plugin.*` |
| `structure-mybatis-plus-starter` | MP 增强：`IBaseMapper`（insertList/selectJoinPageList/logicDeleteById）、关联注解（`@FieldJoin`/`@Join`/`@Keyword`/`@Where`/`@DateTime`）、Snowflake ID | `structure.snowflake.*` |
| `structure-mybatis-plus-generate` | Velocity 代码生成（Controller/Service/Entity 模板可替换） | 编程式 `Configuration` |
| `structure-redis-starter` | RedisTemplate + `@RedisLock` 分布式锁（SpEL key、LockFailAction.GIVEUP/CONTINUE） | `structure.redis.lock.*` |
| `structure-redisson-starter` | Redisson 多模式（single/sentinel/cluster/master-slave） | `structure.redisson.model` + `*-server-config` |
| `structure-minio-starter` | `MinioTemplate`（uploadFile/getPresignedObjectUrl/分片上传） | `structure.minio.*` |
| `structure-log-starter` | `@EnableWebAopLog`、`@AspectParamLog` AOP 日志切面 | `structure.log.aop.*` |
| `structure-rpc-starter` | `@RpcClient` 声明式 HTTP RPC + OAuth2 Token 自动管理（⚠️ 用于 **外部 HTTP 服务 / 第三方 API**；**生态内部微服务间调用 MUST 用 Spring Cloud OpenFeign**，见 developer.md 远程调用章节） | `structure.rpc.serviceList.<name>.*` |
| `structure-tenant-starter` | 多租户上下文支持 | 待查 |

### 典型用法

**MyBatis-Plus 增强**：

```java
@Mapper
public interface UserMapper extends IBaseMapper<User> {
    IPage<UserVO> selectJoinPageList(IPage<UserVO> page, @Param("ew") Wrapper<UserVO> w);
}
```

**`ResPageConvert` —— MyBatis-Plus `Page` → 生态 `ResPage` 转换**：

```java
import cn.structured.mybatis.plus.starter.convert.ResPageConvert;

Page<Example> page = new Page<>(reqPage.getPage(), reqPage.getSize());
Page<Example> result = exampleMapper.selectPage(page, wrapper);
ResPage<ExampleVO> resPage = ResPageConvert.convert(result, ExampleAssembler::assembler);
```

**Redis 分布式锁**：

```java
@RedisLock(value = "#{#order.userId + '_' + #order.productId}",
           keepMills = 10000, retryTimes = 5, action = LockFailAction.GIVEUP)
public CommonResult processOrder(Order order) { ... }
```

**AOP 日志**：

```java
@EnableWebAopLog  // 启动类或配置类
@SpringBootApplication
public class UserApplication { ... }

@AspectParamLog   // 方法级：打印入参
@GetMapping("/{id}")
public ResResultVO<UserVO> findById(@PathVariable Long id) { ... }
```

### 关键 Starter 配置示例

**`structure-log-starter`**：

```yaml
structure:
  log:
    aop:
      enable: true
      expression: execution(public * cn.structured.example.interfaces.controller..*Controller.*(..))
```

**`structure-redis-starter`**（标准 `spring.data.redis` 配置）：

```yaml
spring:
  data:
    redis:
      host: localhost
      port: 6379
      password:
      database: 0
      timeout: 10000ms
```

**`structure-redisson-starter`**：

```yaml
# 单体模式
structure:
  redisson:
    model: single
    password: your-password
    single:
      address: redis://localhost:6379
    cache:
      key-group-name: example

# 集群模式
structure:
  redisson:
    model: cluster
    cluster:
      node-addresses: redis://host1:6379,redis://host2:6379,redis://host3:6379
```

**`structure-minio-starter`**（⚠️ **老项目/单体用法**）：

> **新项目提示**：新项目已迁移到 **`structure-file` 文件服务**（DDD 7+1 结构的统一文件管理中心），**通过其 API 进行文件操作，不直接引入 `structure-minio-starter`**。以下配置仅供维护老项目/单体应用时参考。

```yaml
structure:
  minio:
    url: http://localhost:9010
    access-key: root
    secret-key: your-secret-key
    endpoint-enable: true
```

**`structure-tenant-starter`**：

```yaml
structure:
  tenant:
    enabled: true
    default-tenant-id: "1"
    header:
      enabled: true
      name: "X-Tenant-Id"
    param:
      enabled: true
      name: "tenantId"
    resolver-order:
      - "header"
      - "param"
```

### 业务侧约束

- **MUST** 按能力引入对应 Starter，**禁止**跳过 Starter 自行装配。
- **MUST** 配置项使用各 Starter 的前缀（如 `structure.web.*` / `structure.redis.lock.*`），不散写。
- **SHOULD** 分布式锁优先用 `@RedisLock` 注解而非手写 `RedisTemplate.opsForValue().setIfAbsent()`。

---

## 2. structure-security（认证与授权）

**包**：`cn.structured.security.*`（**有 d**，**不是** `cn.structure.security`）；**用户上下文模块**包名为 `cn.structured.starter.context.*`（注意是 `starter`，不是 `security.context`）

### 项目目录

```
structure-security/
├── structure-security-dependencies/         # BOM
├── structure-security-common/               # 公共（业务对象、接口）
├── structure-security-core/                 # 核心组件
├── structure-security-context-starter/      # ⭐ 用户上下文（规则 13 关键）
├── structure-security-jwt-starter/          # JWT 认证
├── structure-security-basicauth-starter/    # Basic Auth
├── structure-security-permission-starter/   # 权限管理
├── structure-security-oauth-common/         # OAuth2 公共
├── structure-security-oauth-sdk/            # OAuth2 SDK
├── structure-security-oauth-resource-starter/  # OAuth2 资源服务器
└── structure-security-samples/              # 示例
```

### ✅ 用户上下文（规则 13 —— 已读源码验证）

**业务侧主入口**：`cn.structured.security.context.UserContext`（**静态 ThreadLocal 工具类**，位于 `structure-security-core` 模块，**无需注入**）

#### 核心方法

| 方法 | 返回 | 用途 |
|---|---|---|
| `UserContext.get()` | `UserContextEntity`（可空） | 获取完整用户实体 |
| `UserContext.getUserId()` | `String` | 获取用户 ID（String 形式） |
| `UserContext.getLongUserId()` | `Long` | 获取用户 ID（**推荐**，免手写 `Long.parseLong`） |
| `UserContext.getDeptId()` / `getLongDeptId()` | `String` / `Long` | 获取部门 ID |
| `UserContext.getDeptIds()` / `getLoneDeptIds()` | `Set<String>` / `Set<Long>` | 获取部门 ID 集合 |
| `UserContext.getRoles()` / `getLongRoles()` | `Set<String>` / `Set<Long>` | 获取角色集合 |
| `UserContext.getPermissions()` / `getLongPermissions()` | `Set<String>` / `Set<Long>` | 获取权限集合 |
| `UserContext.set(info)` | — | 写入上下文（框架/认证侧用） |
| `UserContext.remove()` | — | 清理上下文（**MUST 在请求/任务结束调用**，防 ThreadLocal 泄漏） |

#### 典型用法

```java
// ✅ 推荐：直接用静态便捷方法
Long userId = UserContext.getLongUserId();
if (userId == null) {
    throw new OrderException(OrderExceptionEnum.NOT_LOGGED_IN);
}

// ❌ 避免：手写判空 + parseLong（框架已提供 getLongUserId）
UserContextEntity userContextEntity = UserContext.get();
if (userContextEntity != null) {
    String userId = userContextEntity.getUserId();
    return Long.parseLong(userId);
}
```

#### ⚠️ 已知拼写 bug

`UserContext.getLoneDeptIds()` 应为 `getLongDeptIds()`（"Lone" vs "Long"）。**新代码使用该方法时需注意拼写**；修复需改框架源码。

#### 底层 SPI（一般业务不需直接用）

- **接口**：`cn.structured.starter.context.manager.IContextManager` —— `login(user)` / `updateUser(user)` / `logout()` / `getUser()` / `getUserByUserId(userId)`
- **存储**：`cn.structured.starter.context.store.IUserStore`（`DefaultUserStore` 内存 / `RedisUserStore` 预留 / `RemoteUserStore` 预留）
- **实体**：`cn.structured.security.entity.UserContextEntity`

**关系**：`IContextManager` 是认证/框架侧使用的 SPI；**业务侧读取当前用户 MUST 使用 `UserContext` 静态方法**，更简洁且无需注入。

### ✅ 安全工具类（控制层可用）

| 类 | 用途 |
|---|---|
| `cn.structured.security.util.SecurityUtils` | 安全工具（**仅控制层可用**；非控制层 MUST 用 `IContextManager`） |

### 业务侧约束（规则 13）

- **MUST** 非控制层（Service / Domain / Infra / Assembler / 异步任务）通过 **`cn.structured.security.context.UserContext` 静态方法** 获取当前用户（`UserContext.getLongUserId()` / `UserContext.get()` 等）。
- **禁止** 非控制层使用 `SecurityUtils` / `SecurityContextHolder` —— 非 HTTP 入口（消息消费、定时任务、内部 RPC）无法获取。
- **SHOULD** 优先使用 `getLongUserId()` / `getLongDeptId()` / `getLongRoles()` 等 **Long 型便捷方法**，避免手写 `Long.parseLong(...)`。
- **控制层**：`SecurityUtils` 或 `UserContext` 均可。

### ✅ 权限模型（已读源码验证）

**注解**：`cn.structured.starter.permission.annotations.@RequiresPermission`（**METHOD 级**）

```java
@RequiresPermission("order:create")
public void createOrder() { ... }

@RequiresPermission("system:user:read")
public User getUser(Long id) { ... }
```

**服务**：`cn.structured.starter.permission.service.IPermissionService`

| 方法 | 用途 |
|---|---|
| `boolean hasPermission(String permission)` | 编程式权限检查 |
| `Set<UserPerm> getUserPermissions()` | 获取当前用户权限集合 |

**权限字符串格式**：冒号分层 `"order:create"` / `"system:user:read"`，支持通配符匹配。

### ✅ JWT 配置（`cn.structure.starter.jwt.properties.JwtConfig`）

```yaml
structure:
  jwt:
    secret: your-secret-key          # 默认 "JWT"（**生产 MUST 改**）
    jwt-token-validity: 32400        # Token 有效期（秒），默认 32400 = 9 小时
```

### ⚠️ 包名不一致警示（新发现）

`structure-security` 内部不同 starter 包名 **不统一**：

| Starter | 实际包名 | 有无 d |
|---|---|---|
| `jwt-starter` | `cn.structure.starter.jwt.*` | **无 d** ⚠️ |
| `permission-starter` | `cn.structured.starter.permission.*` | 有 d |
| `context-starter` | `cn.structured.starter.context.*` | 有 d |

**生成 import 前 MUST 按目标类所在的具体 starter 核对包名**，不要默认所有 starter 都是 `cn.structured.starter.*`。

---

## 3. structure-datascope（数据权限 / 行级权限）

**包**：`cn.structured.datascope.*`（**有 d**）

### 项目目录

```
structure-datascope/
├── structure-datascope-dependencies/  # BOM
├── structure-datascope-core/          # 核心抽象
├── structure-datascope-starter/       # 主 Starter
├── structure-datascope-message/       # ⭐ 消息事件数据权限包装（规则 12）
├── structure-datascope-cache/         # ⭐ 缓存数据权限包装（规则 12）
├── structure-datascope-redis/         # ⭐ Redis 数据权限包装（规则 12）
├── structure-datascope-mybatis-plus/  # MyBatis-Plus 集成
├── structure-datascope-mongodb/       # MongoDB 集成
├── structure-datascope-elasticsearch/ # ES 集成
└── structure-datascope-example/       # 示例
```

### ✅ 数据权限包装工具（规则 12 —— 已读源码验证）

| 类 | 用途 |
|---|---|
| `cn.structured.datascope.message.wrapper.DataScopeStreamBridge` | **StreamBridge 包装器**。发送消息前经 `DataScopeMessageUtils.injectDataScopeIntoMessage()` 注入数据权限参数 |
| `cn.structured.datascope.cache.manager.DataScopeCacheManager` | **缓存管理器包装**。自动按数据权限规则过滤/路由缓存访问 |
| `cn.structured.datascope.cache.engine.CacheDataRuleEngine` | 缓存侧数据规则引擎 |
| `cn.structured.datascope.redis.template.DataScopeRedisTemplate` | **RedisTemplate 包装**。Redis 操作自动携带数据权限参数 |
| `cn.structured.datascope.redis.engine.RedisDataRuleEngine` | Redis 侧数据规则引擎 |

**`DataScopeStreamBridge` 4 个 `send()` 重载**（与 `StreamBridge` 对齐）：

```java
boolean send(String bindingName, Object data);
boolean send(String bindingName, String binderType, Object data);
boolean send(String bindingName, Object data, MimeType outputContentType);
boolean send(String bindingName, String binderType, Object data, MimeType outputContentType);
```

**工作原理**：`StreamBridge` 是 `final` 类无法 CGLIB 代理，故采用 **包装器模式**。若 `data instanceof Message`，调用 `DataScopeMessageUtils.injectDataScopeIntoMessage(message)` 在 Header 注入数据权限参数后委托原生 `StreamBridge` 发送；非 `Message` 类型直接透传。

### 业务侧约束（规则 12）

- **MUST** 跨服务消息事件 MUST 经 `DataScopeStreamBridge`（而非原生 `StreamBridge`）。实际业务 **不直接注入 `DataScopeStreamBridge`**，而是通过 `EventManager.publish(event)` + `EventChannel.MESSAGE_EVENT` 自动路由（见第 4 节）。
- **MUST** 缓存操作使用 `DataScopeCacheManager`（替代 Spring `CacheManager`）。
- **MUST** Redis 操作使用 `DataScopeRedisTemplate`（替代 `RedisTemplate` / `StringRedisTemplate`）。
- **禁止** 跳过上述包装类直接注入 `StreamBridge` / `CacheManager` / `RedisTemplate` —— 数据权限参数将无法跨层/跨服务传递。

### ✅ 消息 Header（`DataScopeMessageUtils` 注入，已读源码验证）

| Header 名 | 内容 | 来源 |
|---|---|---|
| `DATA_SCOPE_INFO` | `DataScopeInfo` 完整 JSON | 总是注入（当上下文非空） |
| `USER_ID` | 用户 ID | `info.getUserId() != null` 时 |
| `ORG_ID` | 组织 ID | `info.getOrgId() != null` 时 |
| `DEPT_IDS` | 部门 ID 列表，逗号分隔 | `info.getDeptIds()` 非空时 |
| `ROLES` | 角色列表，逗号分隔 | `info.getRoles()` 非空时 |
| `PERMISSIONS` | 权限列表，逗号分隔 | `info.getPermissions()` 非空时 |

下游消费时，`DataScopeMessageUtils.extractDataScopeFromMessage(message)` 将 Header 还原到 `DataScopeContext`（通常由框架拦截器/过滤器自动完成）。

### ✅ DataScopeContext API（ThreadLocal）

**`cn.structured.datascope.DataScopeContext`**：

| 类别 | 方法 |
|---|---|
| 读整个 Info | `get()` / `getInfo()` |
| 读单字段 | `getUserId()` / `getOrgId()` / `getDeptIds()` / `getRoles()` / `getPermissions()` |
| 校验 | `hasRole(role)` / `hasPermission(perm)` / `hasAnyRole(...)` / `hasAnyPermission(...)` |
| 写整个 Info | `set(DataScopeInfo)` / `setInfo(DataScopeInfo)` |
| 写单字段 | `setUserId(...)` / `setOrgId(...)` / `setDeptIds(...)` / `setRoles(...)` / `setPermissions(...)` |
| 清理 | `remove()` —— **MUST 在请求/任务结束调用，避免 ThreadLocal 内存泄漏** |

**`DataScopeInfo` 字段**：`userId` / `orgId` / `deptIds` / `roles` / `permissions`

### ✅ MyBatis-Plus 集成

| 类 | 用途 |
|---|---|
| `cn.structured.datascope.mybatis.interceptor.DataScopeInterceptor` | 数据权限拦截器 |
| `cn.structured.datascope.mybatis.interceptor.MultiTableDataScopeHandler` / `DefaultMultiTableDataScopeHandler` | 多表数据权限处理 |
| `cn.structured.datascope.mybatis.plus.handler.StructureTenantLineHandler` | 租户行处理器 |
| `cn.structured.datascope.mybatis.plus.config.MyMetaObjectHandler` | 自动填充（createBy/updateBy 等） |
| `cn.structured.datascope.mybatis.engine.MySqlDataRuleEngine` | MySQL 数据规则引擎 |
| `cn.structured.datascope.mybatis.properties.DataScopeMybatisProperties` | 配置属性 |

### ✅ 规则引擎 SPI

`cn.structured.datascope.engine.DataRuleEngine` + `DataRuleEngineManager`（core 模块）。各存储模块提供具体实现：

| 模块 | 实现 |
|---|---|
| cache | `CacheDataRuleEngine` |
| redis | `RedisDataRuleEngine` |
| mybatis-plus | `MySqlDataRuleEngine` |

### ✅ `DataRuleEngine.filter()` —— 编程式列级权限过滤

```java
@Service
@RequiredArgsConstructor
public class OrderServiceImpl implements IOrderService {

    private final DataRuleEngine dataRuleEngine;

    @Override
    public OrderVO findById(Long id) {
        Order order = orderRepository.findById(id);
        OrderVO vo = OrderAssembler.assembler(order);
        dataRuleEngine.filter(vo, "order");  // 按 @DataScopeField 规则过滤字段
        return vo;
    }
}
```

**约束**：
- **MUST** DTO/VO 出参前调用 `dataRuleEngine.filter(dto, resourceName)`，确保 `@DataScopeField` 标注的字段按当前用户角色/权限正确隐藏。
- **MUST** `resourceName` 与 DTO 类上 `@DataScopeRule(resource = "...")` 的值一致。

### ✅ 数据权限配置项

```yaml
structure:
  data-scope:
    enabled: true
    header-name: X-DataScope-Id
    role-header-name: X-DataScope-Roles
    permission-header-name: X-DataScope-Permissions
```

**约束**：
- **MUST** 引入 `structure-datascope-starter` + 对应存储模块（如 `structure-datascope-mybatis-plus`）。
- **SHOULD** 上游（gateway / Feign 调用方）按上述 Header 名传递数据权限参数，下游经 `DataScopeContext` 自动还原。

### ❓ 待读源码补充
- 行级权限 `@DataScopeRow` 的完整属性与生效机制
- 规则引擎的 YAML 配置方式
- `CacheDataRuleEngine` / `RedisDataRuleEngine` 的规则配置细节

---

## 4. structure-infra / structure-pro-infra（基础设施）

> ⚠️ **重要**：`structure-pro-infra` 与 `structure-infra` 是 **同一项目**（内部维护名 `structure-infra`，仓库名 `structure-pro-infra`）。**不要当作两个组件对待**。

**包**：`cn.structure.infra.*`（**无 d**）

### 子模块（按存储/能力分）

| 模块 | 提供能力 |
|---|---|
| `structure-infra-starter` | 核心：RepositoryFacade / Delegate SPI / 事件抽象 / 低代码仓储 / 配置属性 |
| `structure-infra-mybatis-plus-starter` | MyBatis-Plus Delegate 实现 + MySQL 低代码 |
| `structure-infra-jpa-starter` | JPA Delegate 实现 |
| `structure-infra-mongodb-starter` | MongoDB Delegate 实现 + 低代码 |
| `structure-infra-elasticsearch-starter` | ES Delegate 实现 |
| `structure-infra-stream-starter` | Spring Cloud Stream 事件路由（`@StreamEventListener` / `@StreamRouteHandler`） |
| `structure-infra-schedule-starter` | 任务调度 SPI + 本地线程池实现 |
| `structure-infra-xxljob-starter` | XXL-Job 调度实现 |

### ✅ 持久化（已读源码验证）

**继承关系**（从通用到具体）：

```
cn.structure.common.repository.IQueryRepository<T, ID>     (structure-common)
   ↑
cn.structure.common.repository.ICrudRepository<T, ID>      (structure-common)
   ↑                                              ↑
cn.structure.infra.repository.IQueryDelegate<T, ID>        (structure-infra)
   ↑                                              ↑
cn.structure.infra.repository.RepositoryDelegate<T, ID>  (structure-infra)
   ↑
cn.structure.infra.mybatis.plus.repository.MybatisPlusRepositoryDelegate<E, P, ID>  (mybatis-plus starter)
   ↑
业务侧：{X}MybatisPlusDelegate
```

**框架已定义的函数（规则 5 —— 优先使用，勿重复定义）**：

| 接口 | 方法 |
|---|---|
| `IQueryRepository<T, ID>` | `queryById(ID)` / `queryByIdOptional(ID)` / `queryOne(T)` / `queryOneOptional(T)` / `queryList(T)` / `queryPage(ReqPage)` |
| `ICrudRepository<T, ID>` | 上述全部 + `save(T)` / `removeById(ID)` / `findById(ID)` / `saveBatch(List<T>)` / `removeBatchByIds(List<ID>)` / `listByIds(List<ID>)` / `count(T)` / `exists(T)` |
| `IQueryDelegate<T, ID>` | 上述全部（仅读） + `findById(ID)` / `listByIds(List<ID>)` / `count(T)` / `exists(T)` |
| `RepositoryFacade<T, ID, D>` | 实现 `ICrudRepository<T, ID>`，方法体 `delegate.xxx()`；`queryList`/`listByIds`/`saveBatch` 自动判空返回 `List.of()` |

**业务侧使用约束**：

- **MUST** 业务仓储接口继承 `ICrudRepository<T, ID>`（或 `IQueryRepository` 只读场景）。
- **MUST** 业务自定义方法（非框架已定义）写在业务接口中，由 `{X}RepositoryImpl` 委托给 Delegate 完成。
- **MUST** `{X}MybatisPlusDelegate` 继承 `MybatisPlusRepositoryDelegate<E, P, ID>` 并 **显式重写** `toEntity(P po)` / `toPo(E entity)`（抽象方法，不重写会有隐藏问题 —— 规则 3）。
- **MUST NOT** 在业务 Delegate 中重复定义 `save` / `findById` / `queryPage` 等框架已有方法 —— 基类已实现。
- `MybatisPlusRepositoryDelegate` 自动识别 PO 上的 `@Id` 注解推断主键字段（默认 `"id"`），`save` 根据 ID 是否为空自动 insert/update；查询按"实体非空字段等值匹配"组装 `QueryWrapper`。

### ✅ 事件抽象（规则 11 —— 已读源码验证）

生态存在 **两层事件 API**，业务 MUST 使用高层 `EventManager` 入口；消费端按场景选 Binding 监听或 Router 路由。

#### 两层 API 对比

| 维度 | 高层抽象（推荐业务用） | Stream 层（框架内部 / 复杂场景） |
|---|---|---|
| 模块 | `structure-infra-starter/event/` | `structure-infra-stream-starter/` |
| 发布入口 | `EventManager.publish(Event)` | `StreamEventManager.publish(bindingName, payload)` |
| 负载要求 | MUST 实现 `cn.structure.infra.event.Event` 接口 | 任意 POJO（无需实现接口） |
| 数据权限包装 | ✅ `MESSAGE_EVENT` 自动经 `DataScopeStreamBridge` | ⚠️ 不经过（需自行包装或放弃数据权限传递） |
| 路由方式 | 按 `EventChannel` 路由 | 按 `bindingName`（监听）或 `eventType/businessType`（路由） |

#### 发布侧（业务 MUST 走这里）

| 类 | 用途 |
|---|---|
| `cn.structure.infra.event.Event` | 事件接口。`getEventId()` + `getEventChannel()`（默认 `DEFAULT`） |
| `cn.structure.infra.event.EventChannel` | `DEFAULT` / `SPRING_EVENT` / `MESSAGE_EVENT` |
| `cn.structure.infra.event.EventManager` | 唯一发布入口：`void publish(Event event)` |
| `cn.structure.infra.properties.InfraProperties` | 配置 `structure.infra.default-event-channel` |

**事件路由规则**（`DefaultEventManagerImpl.publish` 实际逻辑）：

| 事件声明 channel | 实际行为 |
|---|---|
| `SPRING_EVENT` | `ApplicationEventPublisher.publishEvent(event)` —— 仅本 JVM |
| `MESSAGE_EVENT` | **`DataScopeStreamBridge.send(eventId, event)`** —— 跨服务，**经数据权限包装** |
| `DEFAULT` | 读 `structure.infra.default-event-channel` 决定 |

**发布侧约束**：

- **MUST** 业务事件实现 `cn.structure.infra.event.Event` 接口。
- **MUST** 通过注入 `EventManager` 调用 `publish(event)`。**禁止**直接 `@Autowired ApplicationEventPublisher` 或直连 `StreamBridge` / `DataScopeStreamBridge` / MQ client。
- **MUST** 跨服务事件 MUST 显式 `getEventChannel() = EventChannel.MESSAGE_EVENT`（确保走 `DataScopeStreamBridge`，数据权限才能传递 —— 规则 12）。
- **SHOULD** 同 JVM 内事件声明 `SPRING_EVENT` 或保持 `DEFAULT` 由全局配置决定。

#### 消费侧 —— 三种模式（按场景选）

**模式 1：Spring 事件消费（本 JVM）**

- 发布：`EventManager.publish(event)`，事件 channel = `SPRING_EVENT`。
- 消费：标准 Spring 注解，**无框架特殊要求**。
  ```java
  @Component
  public class OrderEventHandler {
      @EventListener  // 或 @TransactionalEventListener
      public void on(OrderCreatedEvent event) { ... }
  }
  ```

**模式 2：消息事件 — Binding 监听模型（跨服务，推荐，sample 工程使用此模式）**

由两段组成：**`Consumer<Message<T>>` Bean 接收 + `@StreamEventListener` 方法处理**。

**第 1 步**：声明 `Consumer` Bean，**Bean 名 = bindingName**（Spring Cloud Stream 据此路由消息）：

```java
@Configuration(proxyBeanMethods = false)
public class StreamMessageConsumer {

    private final StreamEventManager streamEventManager;
    public StreamMessageConsumer(StreamEventManager m) { this.streamEventManager = m; }

    @Bean
    public Consumer<Message<OrderEvent>> orderEvent() {  // Bean 名 = bindingName
        return message -> streamEventManager.dispatch("orderEvent", message.getPayload());
    }
}
```

**第 2 步**：业务处理器用 `@StreamEventListener` 注解方法，可多个方法共享同一 bindingName：

```java
@Component
public class OrderEventListener {

    @StreamEventListener(bindingName = "orderEvent", destination = "order-exchange", group = "order-group")
    public void handleAll(OrderEvent event) { ... }

    @StreamEventListener(bindingName = "orderEvent", destination = "order-exchange", group = "order-group",
                         condition = "#event.status == 'CREATED'")
    public void handleCreated(OrderEvent event) { ... }

    @StreamEventListener(bindingName = "orderEvent", destination = "order-exchange", group = "order-group",
                         condition = "#event.status == 'PAID'")
    public void handlePaid(OrderEvent event) { ... }
}
```

**`@StreamEventListener` 关键属性**：

| 属性 | 作用 |
|---|---|
| `value` / `bindingName` | 绑定名（互为别名），与 `Consumer` Bean 名一致 |
| `destination` | 目标 exchange/topic，缺省派生为 `{name}-exchange` |
| `group` | 消费组（同组负载、跨组广播） |
| `eventType` | 事件负载类型，dispatch 时按类型过滤；缺省回退到方法首个参数类型 |
| `condition` | **SpEL 表达式**，通过 `#event` 引用负载，如 `#event.status == 'PAID'` |
| `contentType` | 默认 `application/json` |

**Binding 模型约束**：

- **MUST** `Consumer<Message<T>>` Bean 名与 `@StreamEventListener.bindingName` **完全一致**，否则消息无法路由到处理器。
- **MUST** `Consumer` 内部调用 `streamEventManager.dispatch(bindingName, payload)`，**不直接处理业务逻辑**。
- **SHOULD** 多状态/多场景拆分用 `condition` SpEL 而非 `if-else`（参考 sample 中 `OrderEventListener`）。
- **SHOULD** 事件 POJO 使用 `@Data @Builder @NoArgsConstructor @AllArgsConstructor`（Lombok），**MUST 有无参构造**（规则 10）。

**模式 3：消息事件 — Router 路由模型（按 eventType/businessType 多路复用）**

负载用 `StreamEvent<T>` **信封**包装，含 `eventType` / `businessType` / `payload` / `traceId` / `headers`。

**发布**：构造信封后经 `StreamEventManager` 或自定义 `Consumer` 发出：

```java
StreamEvent<OrderPayload> envelope = StreamEvent.of("order", "create", payload);
// 或 StreamEvent.<OrderPayload>builder().eventType("order").businessType("create").payload(payload).build()
```

**消费**：用 `@StreamRouteHandler` 注解方法：

```java
@Component
public class OrderRouteHandler {

    @StreamRouteHandler(eventType = "order", businessType = "create")
    public void onCreate(OrderPayload payload, StreamEvent<OrderPayload> event) {
        // payload 已按类型匹配；event 含 eventId/traceId/headers
    }

    @StreamRouteHandler(eventType = "order", businessType = "*",
                        condition = "#payload.amount > 100")
    public void onLargeOrder(OrderPayload payload, StreamEvent<OrderPayload> event) { ... }
}
```

**4 步路由匹配**（按顺序）：`eventType` 精确 → `businessType` 通配（`*`）→ `payloadType` 类型 → `condition` SpEL（用 `#payload` 引用）。

**Router 模型约束**：

- **MUST** 处理器签名 `(T payload, StreamEvent<T> event)` 双参（不是单参）。
- **MUST** `eventType` 必填；`businessType` 可选，支持 `*` 通配。
- **SHOULD** 需要一个统一入口 `Consumer<Message<StreamEvent<?>>>` 调用 `streamEventRouter.route(event)` 分发。
- **SHOULD** 仅在需要"一个 exchange 承载多种 eventType/businessType"时使用 Router 模型；简单场景用 Binding 模型。

### ✅ 数据权限包装（规则 12 —— 部分已验证）

| 类 | 用途 |
|---|---|
| `cn.structured.datascope.message.wrapper.DataScopeStreamBridge` | **数据权限包装的消息桥**。`send(String bindingName, Object payload)`。所有跨服务消息事件必须经由此类，而非原生 `StreamBridge` |

⚠️ 缓存侧的数据权限包装工具类名待读 `structure-datascope` 源码补全（见第 3 节）。

### ✅ CQRS 读写分离（已读源码验证）

**核心类**：`cn.structure.infra.repository.CqrsRepositoryFacade<T, ID, D extends RepositoryDelegate<T, ID>, RD extends IQueryDelegate<T, ID>>` 继承 `RepositoryFacade<T, ID, D>`

**工作机制**：

- 维护两个代理：`baseDelegate`（写 + 默认读） + `readDelegate`（CQRS 读）
- **所有读操作**（`queryById` / `queryOne` / `queryList` / `queryPage` / `listByIds` / `count` / `exists`）：
  1. 优先走 `readDelegate`
  2. `readDelegate` 抛异常 → 自动回退到 `baseDelegate`
  3. `baseDelegate` 是最终兜底
- **所有写操作**：始终走 `baseDelegate`

**典型用法**：

```java
@Component("deptRepository")
public class DeptRepositoryImpl
        extends CqrsRepositoryFacade<DeptEntity, Long, DeptRepositoryDelegate, DeptReadDelegate>
        implements DeptRepository {
    // 读操作自动走 readDelegate，失败回退 baseDelegate
}
```

**注入**：`RepositoryBeanPostProcessor` 根据泛型与 `@WriteDelegate` / `@ReadDelegate` 注解自动注入。

### ✅ 低代码仓储（已读源码验证）

**核心接口**：`cn.structure.infra.lowcode.repository.LowCodeRepository`

**与传统泛型仓储的区别**：

| 维度 | 传统仓储 | 低代码仓储 |
|---|---|---|
| 实体类 | MUST 定义 Entity + PO | **无需定义**，通过 **资源名 + `Map<String, Object>`** 操作 |
| 资源结构 | 编译期固定 | DSL（配置文件 / API）动态定义，**运行时可注册新资源** |
| 存储引擎 | 由 Delegate 决定 | 框架根据配置自动路由 |
| 方法签名 | `save(T entity)` | `save(String resourceName, Map<String, Object> data)` |

**主要方法**（与 `ICrudRepository` 对齐，仅首参为 `resourceName`）：

`save(resourceName, Map)` / `removeById(resourceName, id)` / `findById(resourceName, id)` / `queryById` / `queryByIdOptional` / `queryOne` / `queryList` / `queryPage` 等。

**典型用法**：

```java
Map<String, Object> user = new HashMap<>();
user.put("username", "zhangsan");
user.put("email", "zhangsan@example.com");
lowCodeRepository.save("user", user);

Map<String, Object> found = lowCodeRepository.findById("user", 1L);

ReqPage reqPage = new ReqPage();
reqPage.setPage(1); reqPage.setSize(10);
ResPage<Map<String, Object>> page = lowCodeRepository.queryPage("user", reqPage);
```

**配套类**：

| 类 | 用途 |
|---|---|
| `ResourceSchema` / `FieldSchema` | 资源 / 字段元数据模型 |
| `RepositoryConfig` / `CqrsConfig` / `CacheConfig` | 资源配置 |
| `ResourceSchemaBuilder` | 资源 DSL 注册 |
| `LowCodeStorage` / `LowCodeRepoFactory` / `LowCodeRepositoryRouter` | 存储 SPI / 工厂 / 路由 |

### ✅ 任务调度 SPI（已读源码验证）

**`cn.structure.infra.schedule.TaskScheduler`** —— 调度器 SPI，屏蔽不同调度实现差异：

| 方法 | 用途 |
|---|---|
| `schedule(ScheduleTask)` | 调度任务（幂等：taskId 已存在则先移除再建） |
| `update(ScheduleTask)` | 更新调度配置 |
| `remove(taskId)` | 移除并停止 |
| `pause(taskId)` | 暂停 |
| `resume(taskId)` | 恢复 |
| `getTaskInfo(taskId)` | 查询任务 |
| `getAllTasks()` | 所有任务快照（不可变副本） |

**`cn.structure.infra.schedule.TaskHandler`** —— 任务处理器（`@FunctionalInterface`）：

```java
void execute(String param);  // param 来自 ScheduleTask.getHandlerParam()
```

**实现选择**：

| 实现 | 场景 | 启用方式 |
|---|---|---|
| `LocalThreadTaskScheduler` | 单机 / 本地默认 | 引入 `structure-infra-schedule-starter` |
| `XxlJobTaskScheduler` | 集群 / 分布式 | 引入 `structure-infra-xxljob-starter`（经 `@AutoConfigureBefore` 覆盖本地实现） |

**业务侧约束**：

- **MUST** 通过 `TaskScheduler` 接口注入使用，**禁止**直接依赖 `LocalThreadTaskScheduler` / `XxlJobTaskScheduler` 具体类 —— 切换引擎时业务代码不变。
- **MUST** `TaskHandler` 实现类经 `TaskHandlerRegistry` 按 `handlerName` 注册，调度器触发时按名查找。
- **SHOULD** `execute(String param)` 内妥善处理异常；调度器内部有兜底捕获，但业务侧应自行记录关键日志。

---

## 5. structure-gateway / structure-gateway-client（网关 / 客户端）

**包**：服务端 `cn.structured.cloud.gateway.*`（有 d）；客户端 TS 包 `@structure-projects/gateway-client`

### structure-gateway（服务端）

#### 项目目录

```
structure-gateway/
└── src/main/java/cn/structured/cloud/gateway/
    ├── config/          # 属性/路由/RabbitMQ/Redis 配置
    ├── constant/        # Header 与 Redis Key 常量（GatewayConstants）
    ├── dto/             # TenantPackageMessage 等
    ├── exception/       # GlobalExceptionHandler
    ├── filter/          # 8 个全局 Filter（见下表）
    ├── listener/        # Nacos + RabbitMQ 监听
    ├── service/         # 动态路由刷新
    └── util/
```

#### ✅ 全局 Filter 执行顺序（`Ordered.HIGHEST_PRECEDENCE + N`）

| Order | Filter | 职责 |
|---|---|---|
| +0 | `GlobalGatewayFilter` | 预留，处理 `excluded-paths` |
| +3 | `DeviceIdentificationFilter` | 校验/写入 `X-Device-Id` |
| +4 | `TenantRateLimitFilter` | 基于 Redis 租户套餐做 QPS/日/月限流 |
| +10 | `TokenVerificationFilter` | 校验 `Authorization: Bearer xxx` **存在性**（**不验真伪**） |
| +20 | `TenantIdentificationFilter` | 提取/兜底写入 `X-Tenant-Id` |
| +40 | `ReplayAttackPreventionFilter` | 校验 `X-Timestamp` + `X-Nonce`（Redis 防重放）+ `X-Signature`（HMAC-SHA256） |
| +50 | `TraceHeaderFilter` | 校验/生成 `X-Request-Id` |

#### ✅ 下游服务可读的 Header（`GatewayConstants`）

| Header | 来源 Filter | 下游使用 |
|---|---|---|
| `Authorization` | 客户端 | 透传 |
| `X-Tenant-Id` | `TenantIdentificationFilter` | `@RequestHeader("X-Tenant-Id") String tenantId` |
| `X-Device-Id` | `DeviceIdentificationFilter` | 设备识别 |
| `X-Request-Id` | `TraceHeaderFilter` | 链路追踪 |
| `X-Timestamp` / `X-Nonce` / `X-Signature` | `ReplayAttackPreventionFilter` | 重放防护校验 |

#### ⚠️ 重要警示

- **gateway 不解析 Token、不下发 `X-User-Id`**。`TokenVerificationFilter` 仅做存在性校验。
- 下游服务若需用户身份，**MUST** 自行解析 JWT 或调用 auth-center；**禁止**假设 `X-User-Id` 存在。

#### ✅ 动态路由刷新

- `NacosConfigRefreshListener` 监听 `dataId={appName}-{profile}.yaml`
- 变更触发 `DynamicRouteRefreshService.refreshRoutes()`，经 `RouteDefinitionWriter` 全量替换后发布 `RefreshRoutesEvent`
- 配置由 `DynamicRouteProperties` 承载（`routes[].id/uri/order/predicates[]/filters[]`）

#### ✅ 限流配置

```yaml
structure:
  gateway:
    rate-limit:
      enabled: true
      whitelist-tenants: ["1","2"]
    replay-check:
      enabled: true
      timestamp-tolerance-ms: 300000
      nonce-expire-minutes: 10
      secret-key: your-secret-key
```

租户套餐规则放 Redis：`gateway:tenant:package:{tenantId}` = `{"rateLimitEnabled":true,"rateLimitRules":{"qps":100,"dailyLimit":100000,"monthlyLimit":1000000}}`

---

### structure-gateway-client（TS SDK）

#### 项目目录

```
structure-gateway-client/
├── sdk/                # TS SDK（axios 封装，5 个源文件）
│   ├── src/client.ts   # createGatewayClient / configureGatewayClient
│   ├── src/config.ts   # GatewayClientConfig 类型
│   ├── src/types.ts
│   ├── src/utils.ts    # generateRequestId / generateNonce / hmacSha256 / getDeviceId
│   └── src/index.ts    # 全量导出
└── client-example/     # Vue3 示例工程
```

#### ✅ 关键 API

| API | 用途 |
|---|---|
| `createGatewayClient(config?)` | 创建独立 axios 实例 |
| `configureGatewayClient(config)` | 配置全局默认 client |
| `client` / `defaultClient` | 默认导出实例 |
| `setRequestHeadersConfig` / `getRequestHeadersConfig` / `getGatewayConfig` | 配置读写 |
| `generateRequestId()` / `generateNonce()` / `hmacSha256(data, secret)` / `getDeviceId()` | 工具函数 |

**`GatewayClientConfig` 关键配置**：

```ts
{
  baseURL: '/web-api',               // 默认
  timeout: 50000,
  signatureSecret: 'your-secret',    // 提供则自动 HMAC-SHA256 签名
  defaultTenantId: '1',
  enableDeviceId: true,
  getAccessToken: () => string,      // 取 Token
  getTenantId: () => string,
  getDeviceId: () => string,
  refreshToken: async () => string,  // Token 刷新
  onTokenExpired: async (err) => {}, // 过期回调（跳登录）
  onBeforeRequest / onResponse / onError
}
```

#### ✅ 自动化能力

- **7 个网关 Header 自动注入**：`Authorization` / `X-Tenant-Id` / `X-Device-Id` / `X-Request-Id` / `X-Timestamp` / `X-Nonce` / `X-Signature`
- **HMAC-SHA256 签名**：`signatureSecret` 提供时自动计算 `HMAC(method + url + timestamp + nonce)`
- **Token 自动刷新**：响应 `code === 'INVALID_AUTHENTICATION' / 'NOT_LOGGED_IN'` 时调 `refreshToken()`；并发请求经 `failedQueue` 排队等新 Token 后重放原请求（`_retry` 防循环）

#### 典型用法

```ts
import { createGatewayClient, configureGatewayClient, client } from '@structure-projects/gateway-client';

configureGatewayClient({
  baseURL: 'https://api.example.com',
  signatureSecret: 'your-secret-key',
  defaultTenantId: '1',
});

export const customClient = createGatewayClient({
  baseURL: 'https://custom-api.example.com',
  getAccessToken: () => localStorage.getItem('custom_token'),
  getTenantId: () => 'custom-tenant-id',
  refreshToken: async () => (await (await fetch('/api/refresh-token')).json()).accessToken,
  onTokenExpired: async () => { /* 跳登录 */ },
});

// 业务侧直接 client.get/post(...)，7 个 Header 全部自动注入
```

### 业务侧约束

- **MUST** 前端调用后端 API 统一经 `@structure-projects/gateway-client`，**禁止**裸用 `axios`（会丢失 7 个必需 Header 导致 gateway 拒绝）。
- **MUST** 下游服务读取租户用 `@RequestHeader("X-Tenant-Id")`，**禁止**从 body/query 读 `tenantId`。
- **MUST** 下游服务用户身份 MUST 自行解析 JWT 或调 auth-center，**禁止**假设 `X-User-Id` 存在。

---

## 6. wujie 微前端组件

**npm 包**：`@structure-projects/wujie-subapp` / `structure-wujie-template`

### 项目目录（structure-wujie-subapp/src）

```
src/
├── index.ts          # 主入口（导出 WujieSubapp 类与工厂函数）
├── global.d.ts
├── core/
│   ├── env.ts        # isWujieSubApp / initWujieEnv / getWujieProps / getWujieBus
│   ├── storage.ts    # StorageManager（localStorage 封装，可自定义 key 前缀）
│   └── sync.ts       # DataSyncManager（父子应用数据同步）
├── router/
│   ├── generator.ts  # RouteGenerator（按角色/父应用 routes 动态生成路由）
│   └── guard.ts      # setupRouterGuard（白名单、token 校验、动态注册）
├── pinia/
│   ├── user.ts       # createUserStore(options)
│   └── permission.ts # createPermissionStore(options)
└── types/index.ts    # WujieData / WujieSubappConfig / StorageConfig
```

### ✅ 关键 API

| API | 用途 |
|---|---|
| `createWujieSubapp(config?)` | 工厂函数，返回 `WujieSubapp` 实例 |
| `WujieSubapp.init()` | 初始化（从父应用 props + localStorage 恢复数据） |
| `WujieSubapp.destroy()` | 销毁 |
| `WujieSubapp.emitData(partial)` | 向父应用推数据（默认事件 `'wujie-data'`） |
| `isWujieSubApp()` | 判断当前是否在 wujie 环境 |
| `getWujieProps()` | 读父应用 props |
| `getWujieBus()` | 获取 wujie bus |
| `StorageManager` | localStorage 封装（key 前缀可配） |
| `DataSyncManager` | 父子数据同步 |
| `RouteGenerator` | 动态路由生成 |
| `setupRouterGuard(options)` | 路由守卫（白名单、token、动态注册） |
| `createUserStore(options)` / `createPermissionStore(options)` | Pinia store 工厂 |

**peerDependencies**：`vue@^3` / `vue-router@^4` / `pinia@^2` / `wujie-vue3@^1`

### ⚠️ 重要警示

- **本库不导出 `mount` / `unmount` / `bootstrap` 生命周期**。子应用入口与普通 Vue 应用一致，只是多了 `createWujieSubapp().init()`。
- **子应用无需引入 `wujie-vue3` 组件**，主应用使用 `<WujieVue>` 加载子应用即可。
- 与父应用通信走 `emitData()` + `localStorage` + bus 的 `'wujie-data'` 事件。

### 典型用法

```ts
// src/main.ts (子应用)
import { createApp } from 'vue';
import { createPinia } from 'pinia';
import { createWujieSubapp, setupRouterGuard, createUserStore } from '@structure-projects/wujie-subapp';
import App from './App.vue';
import router from './router';

const wujie = createWujieSubapp();
const data = wujie.init();        // 从父应用 + localStorage 恢复数据

const app = createApp(App);
const pinia = createPinia();
app.use(pinia);

const useUserStore = createUserStore({ getUserInfoApi, loginApi, logoutApi });
setupRouterGuard({
  router,
  getUserStore: () => useUserStore(),
  getPermissionStore: () => usePermissionStore(),
  generateRoutes: async (roles) => buildRoutes(roles),
});

app.use(router).mount('#app');
// 通知父应用就绪：wujie.emitData({ ready: true });
```

### 业务侧约束

- **MUST** 子应用入口调用 `createWujieSubapp().init()` 恢复上下文，**禁止**跳过 init 直接 mount。
- **MUST** 通过 `emitData()` 与父应用通信，**禁止**直接 `window.parent.postMessage`（脱离 wujie 沙箱）。
- **SHOULD** 使用 `createUserStore` / `createPermissionStore` 工厂而非手写 Pinia store，保持跨子应用一致。
- **SHOULD** 路由动态注册走 `setupRouterGuard` + `RouteGenerator`，不手写 `router.addRoute`。

---

## 7. 公共组件与公共 UI

**npm 包**：`@structure-projects/components`（通用 Vue 组件库） / `@structure-projects/{X}-ui-components`（各业务本地组件库）

### 项目目录（structure-components/src）

```
src/
├── index.ts            # 主入口（不含 WangEditor）
├── wang-editor.ts      # 独立子入口（避免未装 wangeditor 的消费者报错）
├── api/base.ts         # 默认导出 request（axios 封装，基于 gateway-client）
├── components/
│   ├── PageContainer/  # 子应用页面容器
│   ├── TagsView/       # 多标签页
│   └── common/         # 16 个通用组件
├── composables/
│   └── useSubApp.ts    # useTagsView / useThemeFromWujie
└── types/common.ts     # PaginationParams / TableColumn / FormItemProps / DialogFormProps
```

### ✅ 组件清单（17 个）

`Pagination` / `SearchBar` / `DialogForm` / `DataTable` / `EmptyState` / `TreeView` / `Breadcrumb` / `TableAction` / `MultiUpload` / `SingleUpload` / `SvgIcon` / `IconSelect` / `LangSelect` / `ErrorPage401` / `ErrorPage404` / `PageContainer` / `TagsView`（+ `WangEditor` 走独立入口）

### ✅ Composables

| 函数 | 用途 |
|---|---|
| `useTagsView(router, cacheViews?)` | 多标签页管理：`visitedViews` / `addView` / `removeView` / `closeOthers` / `closeRight` / `closeAll` / `handleClick` / `handleRefresh` |
| `useThemeFromWujie()` | 自动同步父应用主题色到 Element Plus CSS 变量 |

### ✅ request（default 导出）

```ts
import request from '@structure-projects/components';
// 基于 @structure-projects/gateway-client 的 axios 实例，自动带 7 个网关 Header
```

### ⚠️ 两条铁律

1. **本库不是 Vue 插件**，无 `install` 函数。**所有组件/composable 都按需命名导入**：
   ```ts
   import { DataTable, Pagination, useTagsView } from '@structure-projects/components';
   import type { TableColumn, FormItemProps } from '@structure-projects/components';
   ```
2. **element-plus 是 external**。消费项目 **MUST** 自行：
   ```ts
   import ElementPlus from 'element-plus';
   import 'element-plus/dist/index.css';
   app.use(ElementPlus);
   ```
   否则组件无样式。

### 典型用法（DataTable + TableAction）

```vue
<script setup lang="ts">
import { ref } from 'vue';
import { DataTable, TableAction, DialogForm, Pagination } from '@structure-projects/components';
import type { TableColumn, FormItemProps } from '@structure-projects/components';

const columns: TableColumn[] = [
  { prop: 'name', label: '姓名', width: 120 },
  { prop: 'status', label: '状态' },
];
const rows = ref([{ id: 1, name: '张三', status: '在职' }]);
const actions = [
  { key: 'edit', label: '编辑', type: 'primary' as const },
  { key: 'delete', label: '删除', type: 'danger' as const },
];
</script>

<template>
  <DataTable :data="rows" :columns="columns" border>
    <template #actions="{ row }">
      <TableAction :row="row" :actions="actions" @action="(k, r) => console.log(k, r)" />
    </template>
  </DataTable>
</template>
```

### 各业务 `*-ui-components`

- **开发时**：通过 `file:../../structure-{X}/structure-{X}-ui-components` 本地引用。
- **正式发布时**：发布到 npm（`@structure-projects/{领域}-ui-components`），便于其他场景复用。

### 业务侧约束

- **MUST** 按需命名导入，**禁止** `import * as Components`（破坏 tree-shaking）。
- **MUST** 消费项目自行 `app.use(ElementPlus)` 并引入 CSS。
- **MUST** 使用 `import type` 导入类型（`TableColumn` / `FormItemProps` 等）。
- **SHOULD** 子应用布局用 `PageContainer` + `TagsView` + `useTagsView(router)`；主题同步在 `App.vue` 调一次 `useThemeFromWujie()`。
- **SHOULD** HTTP 请求用 default 导出的 `request`（已接 gateway-client），不再单独封装 axios。

---

## 已弃用 / 不推荐（🚫）

- 🚫 **structure-cloud** —— 已 **停止维护**（"比较鸡肋"）。**依赖版本统一改在 `structure-{X}-dependencies` 与 `structure-boot` 中配置**。新代码 MUST NOT 再引入 `structure-cloud-dependencies` 或 `structure-ribbon-starter`。
- 🚫 **structure-ruoyi / ruoyi-framework / ruoyi-pro / ruoyi-ui / structure-yudao** —— 多数 2024-09 停更，新项目禁止使用。

---

## structure-tenant（多租户）

**包**：`cn.structured.tenant.*`（**有 d**，推断 —— 待验证）

### ✅ 租户上下文

**核心类**：`TenantContextHolder`（全限定名待读源码确认，疑似 `cn.structured.tenant.context.TenantContextHolder`）

| 方法 | 用途 |
|---|---|
| `TenantContextHolder.getTenantId()` | 获取当前租户 ID（业务侧主要使用） |
| `TenantContextHolder.setTenantId(tenantId)` | 设置当前租户 ID（框架/上游写入） |
| `TenantContextHolder.clear()` | 清理当前租户上下文（**MUST 在请求结束调用**） |

**典型用法**：

```java
@Service
public class TenantService {

    public String getCurrentTenantId() {
        return TenantContextHolder.getTenantId();
    }

    /**
     * 在指定租户上下文中执行任务（跨租户批处理、内部 RPC 场景）
     */
    public void executeInTenant(String tenantId, Runnable task) {
        TenantContextHolder.setTenantId(tenantId);
        try {
            task.run();
        } finally {
            TenantContextHolder.clear();  // MUST finally 清理
        }
    }
}
```

### ✅ 配置项

```yaml
structure:
  tenant:
    enabled: true
    default-tenant-id: "1"
    header:
      enabled: true
      name: "X-Tenant-Id"
    param:
      enabled: true
      name: "tenantId"
    resolver-order:
      - "header"
      - "param"
```

### 业务侧约束

- **MUST** 业务代码通过 `TenantContextHolder.getTenantId()` 获取租户，**禁止**从 `@RequestHeader` / `@RequestParam` 读取后直接使用（规则 13）。
- **MUST** 在 `executeInTenant` 等手动设置租户的场景中，**MUST 用 try-finally 确保 `TenantContextHolder.clear()` 被调用**，避免 ThreadLocal 泄漏。
- **SHOULD** 租户识别顺序通过 `resolver-order` 显式声明，避免依赖默认值。
- ⚠️ `TenantContextHolder` 的全限定包名待读 `structure-tenant` 源码补全；使用时先 grep 业务项目现有引用。

### ❓ 待读源码补充
- `TenantContextHolder` 的全限定类名与完整方法清单
- 与 `structure-gateway` 的协作：gateway 写入、下游读取的 Filter 链
- 租户级配置隔离方式

---

## structure-common（基础工具与统一模型）

> 虽未列入"常用组件"前 7，但是所有组件的 **底层依赖**，使用频率隐含最高。

**包**：`cn.structure.common.*`（**无 d**）

### ✅ 已验证可用（来自 structure-common 1.4.4 JAR）

**entity 包**（`cn.structure.common.entity`）：

| 类 | 用途 |
|---|---|
| `ResResultVO<T>` | 统一响应体（含 Builder） |
| `ResultVO` | 另一响应体变体（含 Builder） |
| `IResult` | 响应体接口 |
| `BaseEntity` | 实体基类 |
| `BaseLog` / `FunctionLog` / `ControllerLog` | 日志模型（配合 AOP 日志） |
| `ResCountVO` | 计数响应 |
| `ResObjectIdVO` | ID 响应 |
| `VerificationFailedMsg` | 校验失败消息 |

**vo 包**（`cn.structure.common.vo`）：

| 类 | 用途 |
|---|---|
| `ReqPage` | 分页请求（含页码/页大小/排序） |
| `ResPage<T>` | 分页响应 |
| `OptionVO` | 选项 VO（下拉框等） |

**exception 包**（`cn.structure.common.exception`）：

| 类 | 用途 |
|---|---|
| `CommonException` | 业务异常基类（所有业务异常 MUST 为此类型，直接/间接均可） |

**repository 包**（`cn.structure.common.repository`）：

| 接口 | 方法 |
|---|---|
| `IRepository` | 标记接口 |
| `IQueryRepository<T, ID>` | `queryById` / `queryByIdOptional` / `queryOne` / `queryOneOptional` / `queryList` / `queryPage(ReqPage)` |
| `ICrudRepository<T, ID>` | 上述全部 + `save` / `removeById` / `findById` / `saveBatch` / `removeBatchByIds` / `listByIds` / `count` / `exists` |

**utils 包**（`cn.structure.common.utils`）：

| 类 | 用途 |
|---|---|
| `ResultUtilSimpleImpl` | 构造 `ResResultVO`：`success(data)` / `fail(code, message)` |
| `ResultUtilSecondLevelImpl` | 构造 `ResultVO`（二级响应） |
| `IResultUtil` | 响应构造工具接口 |
| `StringUtil` | 字符串工具（**优先用 Hutool `StrUtil`**） |
| `DateUtil` | 日期工具（**优先用 Hutool `DateUtil`**） |
| `HttpClientUtil` | HTTP 客户端 |
| `BasicAuthGenerator` | Basic Auth 头生成 |

### 使用约束

- **MUST** 优先使用 Hutool；`structure-common.utils` 中已有的（如 `ResultUtilSimpleImpl`）不重复造轮子；Hutool 已覆盖的（`StringUtil`/`DateUtil`）**SHOULD** 用 Hutool 版本。
- **MUST** 业务异常继承 `CommonException`。
- **MUST** 业务仓储接口继承 `ICrudRepository` 或 `IQueryRepository`（不要从 0 定义 CRUD）。

---

## 维护约定

1. 本文件与 `developer.md` / `reviewer.md` 中的 **原则性规则不重复**；本文件只写 **组件级 API、配置项、典型用法**。
2. 读完某组件源码后：把对应 `❓ 待读源码补充` 章节填实，并把"已验证可用"表格更新为 ✅。
3. 发现某组件 **实际已废弃** 或 **被新组件替代** 时：在该章节顶部加 🚫 标记，并在 `CLAUDE.md` 的"已知不一致"清单中登记。