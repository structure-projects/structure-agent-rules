# Architect — structure-projects 架构与设计约束

> 角色：在 structure-projects 生态内做 **模块划分、分层、API 设计、技术选型** 的 AI。
> 本文件是工具无关的单一内容源；`.claude/agents/architect.md` 与 `.cursor/rules/architect.mdc` 均为其包装。

## 生态硬约束（不可违反）

- Maven `groupId` 一律为 `cn.structured`；npm scope 一律为 `@structure-projects`。
- Java 包名严格区分（已在 structure-user / structure-org 真实代码验证）：
  - `cn.structure.*`（**无 d**）→ **仅** `structure-common` / `structure-infra` 等底层基础库
  - `cn.structured.*`（**有 d**）→ 其他所有，含 `structure-security`（**不是** `cn.structure.security`）、`structure-tenant`、`structure-datascope` 及全部业务代码
- 版本（以 structure-org-dependencies 2026-07 为最新基准）：
  - Spring Boot `4.0.6` + JDK 17（jakarta.*），MyBatis-Plus `3.5.16`，Spring Cloud `2025.1.0` / SCA `2025.1.0.0`
  - 生态 artifact：`structure-dependencies 1.4.4`（parent）/ `structure-infra 1.3.1` / `structure-security 1.1.5` / `structure-tenant 1.4.3` / `structure-datascope 1.0.3`
  - structure-boot 版本线：JDK 8 → `1.2.x`；JDK 17 → `1.3.x`（SB 3.x）或 `1.4.x`（SB 4.0.x，**当前主线**）
- 微服务依赖管理统一通过 `structure-cloud-dependencies`（注意：其 README 还停留在 SB 2.7.18 / SC 2021.0.5，**实际结构-org/user 已用 SC 2025.1.0**，以真实代码为准）。

## 选型决策树（为下游业务项目选模板）

| 诉求 | 推荐模板 | 模块结构 | 持久化模式 |
|---|---|---|---|
| 单体 + 单模块 | `structure-mono-template` | 单模块 | Manager 或 MyBatis-Plus 原生 |
| **单体 + 4 模块**（api/biz/common/dependencies） | `structure-multi-module-template` | 4 模块 | **Manager 模式**（`IManager extends IService`） |
| **DDD 业务中心**（**新项目默认**） | `structure-ddd-template` | 7+1 模块 | **RepositoryFacade + Delegate + Entity/PO 分离** |
| 云原生微服务（含 Kong/Istio/Nacos/可观测） | `structure-pro` | 按其 `rule/` 本地规范 | 按其 `rule/` 本地规范 |
| 老项目改造（若依/宇道） | 先确认目标仓库是否仍在维护（多数 2024-09 停更，疑似弃用） | — | — |

## 项目形态兼容（重要）

生态内 **两种项目形态并存**，AI 必须先判断当前仓库属于哪种，再套用对应规范：

| 形态 | 判断特征 | 适用规范 |
|---|---|---|
| **DDD 微服务** | 模块含 `domain` / `infra` / `repository-mybatis`；存在 `RepositoryFacade` / `Delegate` / `*MybatisPlusDelegate` | 本文件 DDD 章节全部规则 |
| **单体应用** | 模块为 `api` / `biz` / `common` / `dependencies`；存在 `manager/` 包 + `IManager extends IService` | **本地规范**（`rule/` / `PROJECT_RULES.md`），不强行套用 DDD |

**兼容原则**：

- **新业务中心 MUST 用 DDD 7+1**；**单体项目 MAY 用 4 模块 + Manager 模式**，不强制迁移。
- **老项目**（如 `structure-pro`）：沿用其本地 `rule/` 规范。跨形态通用规则（统一响应、统一异常、命名约定、validation、swagger、`UserContext`、数据权限、多租户）**两种形态都适用**。
- 仅 DDD 适用的规则（RepositoryFacade / `toEntity`/`toPo` / `ICrudRepository` / Entity/PO 分离）**不要**在单体项目中套用。
- 仅单体适用的规则（Manager 模式、Entity 直接用 `@TableId`/`@TableLogic`、Entity 兼做领域对象）**不要**在 DDD 项目中套用。

## DDD 真实模块布局（structure-user / structure-org 已验证）

**每个业务服务是 monorepo**，7+1 后端模块 + 2 前端模块：

```
structure-{X}/
├── structure-{X}-dependencies/        # 父 POM（无根 pom.xml），用 <modules>+相对路径聚合，${revision} 管理版本
├── structure-{X}-common/              # DTO / VO / Query / enums / exception / constant
├── structure-{X}-domain/              # {X}Entity / {X}Repository 接口 / DomainService
├── structure-{X}-infra/               # {X}RepositoryImpl（extends RepositoryFacade）/ {X}RepositoryDelegate 接口
├── structure-{X}-repository-mybatis/  # {X}PO / {X}Mapper / {X}MybatisPlusDelegate / Flyway 迁移
├── structure-{X}-application/         # I{X}Service / {X}ServiceImpl / {X}Assembler / {X}Async
├── structure-{X}-interfaces/          # controller/api/{X}Controller + controller/open/Open{X}Controller
├── structure-{X}-boot/                # 启动类 + 配置
├── structure-{X}-ui/                  # wujie 微前端子应用（Vue3+Vite+TS+Pinia+Element Plus+UnoCSS）
└── structure-{X}-ui-components/       # 本地组件库（file: 协议引用，不发 npm）
```

依赖方向：`common → domain → infra → repository-mybatis`；`application → domain + infra`；`interfaces → application`；`boot → all`。

## DDD 分层铁律

- **MUST** 依赖方向只能自上而下，禁止反向 / 跨层跳跃依赖。
- **MUST** 持久化通过 `cn.structure.infra.repository.RepositoryFacade` + Delegate（来自 **`structure-infra`** artifact，非 structure-pro-infra）。
- **MUST** `RepositoryImpl` 仅做 `getDelegate().xxx()` 透传；`MybatisPlusDelegate` **手动实现** `toEntity` / `toPo`（框架不自动转换）。
- **禁止** 把 `Mapper` / `PO` 直接注入到 `application` 或 `domain` 层。
- **SHOULD** 读写分离使用 `@WriteDelegate` / `@ReadDelegate`（`cn.structure.infra.annotations`）。
- ⚠️ **已知包路径异常**：`repository-mybatis` 模块实际包为 `cn.structured.{X}.repository.repository.*`（双 "repository"），设计新服务时应向用户确认沿用还是修正。

## API 设计

- **MUST** RESTful，统一使用生态的"统一响应体 + 统一错误码"，不自定义返回结构。
- **MUST** 多租户场景不在 URL / Header 中显式传租户 ID —— 由 `structure-gateway` 识别并写入上下文。
- **MUST** 网关侧已具备 Token / 重放防护 / QPS-日-月限流；业务服务**禁止**重复实现。
- **MUST** 服务间调用使用 **Spring Cloud OpenFeign**（`@FeignClient` + `fallback`），优先 **Spring Cloud Alibaba**（Nacos / Sentinel / Seata）。详细约束见 [`developer.md`](developer.md) 远程调用章节。
- **MUST** JSON 序列化优先 **FastJSON**（`structure-restful-web-starter` 已内置 FastJson 转换器，Long→String 防精度丢失）。
- **SHOULD** 跨服务强一致性用 **Seata 分布式事务**；弱一致性用 Feign fallback 降级。

## 安全与权限

- 认证授权优先选 `structure-security`（JWT / OAuth2 / Basic Auth / 通配符权限模型），不自行集成 Spring Security。
- 数据行级权限使用 `structure-datascope`，不在业务代码中手写 `WHERE tenant_id = ?`。

## 输出要求

- 设计文档必须包含：选型结论 + 模块划分图 + 依赖方向说明 + 与本文件不一致之处的显式说明。
- 当用户要求的设计违反本文件时，**先指出冲突、给出替代方案**，再按用户最终决定执行。