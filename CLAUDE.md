# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 本仓库的定位（重要）

`structure-agent-rules` **不是业务代码仓库**，它是 [structure-projects](https://github.com/structure-projects) 开源生态的 **AI 规则与提示词工程仓库**。目标是：

1. 让 AI（Claude Code / Cursor / 其他 Agent）能快速理解 structure-projects 生态并正确选型。
2. 用规则与提示词约束 AI 在生态内的 **设计、开发、测试、评审** 行为，使其符合社区规范。

本仓库的产出物是 **规则文件、Agent 提示词、生态说明文档**，不产出可运行的业务代码。

## 生态坐标（AI 必须正确使用）

| 维度 | 值 | 说明 |
|---|---|---|
| GitHub 组织 | `structure-projects` | https://github.com/structure-projects |
| 官网 | `www.structured.cn` | 文档库见 `structure-docs` 仓库（VitePress） |
| Maven groupId | `cn.structured` | 所有 Java 组件统一使用 |
| npm scope | `@structure-projects` | 所有前端组件统一使用 |
| 组织定位 | "结构化开发为规范而生" | 强调规范优先 |
| 微服务组件偏好 | **Spring Cloud Alibaba** | Nacos（注册发现/配置）/ Sentinel（熔断限流）/ Seata（分布式事务） |
| JSON 序列化偏好 | **FastJSON** | `structure-restful-web-starter` 已内置 FastJson 转换器（Long→String 防精度丢失）；业务禁用 Jackson/Gson |
| 服务间调用 | **Spring Cloud OpenFeign** | 必须声明 `fallback`/`fallbackFactory`；强一致性场景 fallback 抛 `CommonException` 中断业务 |

### 包名硬约定（已在 structure-user / structure-org 真实代码中验证）

- `cn.structure.*`（**无 d**）→ **底层基础库**：`structure-common`、`structure-infra`（含 `RepositoryFacade` / `@WriteDelegate` / `MybatisPlusRepositoryDelegate` / `ResResultVO` / `ResultUtilSimpleImpl` / `ResPage` / `ReqPage` 等）
- `cn.structured.*`（**有 d**）→ **上层组件与业务代码**：`structure-security`、`structure-tenant`、`structure-datascope` 以及所有 `structure-*` 业务中心

⚠️ **注意**：`structure-security` 实际包名是 `cn.structured.security.*`（**有 d**），不是 `cn.structure.security.*`。这与"框架=无 d"的字面理解不同 —— 真正的分界是 **"common/infra 等基础库用无 d，其余全部有 d"**。AI 生成 import 前必须按目标仓库真实包名核对。

## 已验证的真实版本号（来自 structure-org-dependencies/pom.xml，2026-07 时点）

| 依赖 | 版本 | 备注 |
|---|---|---|
| `structure-dependencies`（parent） | `1.4.4` | 所有业务服务继承此 parent |
| Spring Boot | `4.0.6` | JDK 17+，使用 `jakarta.*` |
| Spring Cloud | `2025.1.0` | |
| Spring Cloud Alibaba | `2025.1.0.0` | |
| MyBatis-Plus | `3.5.16` | |
| `structure-infra` | `1.3.1` | **RepositoryFacade / Delegate 所在** |
| `structure-security` | `1.1.5` | |
| `structure-datascope` | `1.0.3` | |
| `structure-tenant` | `1.4.3` | |
| Testcontainers | `1.20.6` | 集成测试采用真实中间件 |
| springdoc-openapi | `3.0.3` | OpenAPI 文档 |

**CVE 修复版本**（**仅框架 < 1.4.4 需显式处理**；1.4.4 起框架已内置，无需再加）：

| 依赖 | 版本 | 修复 |
|---|---|---|
| bouncycastle | `1.84` | CVE-2026-0636 |
| commons-fileupload | `1.6.0` | CVE-2025-48976 |

Maven 使用 `${revision}` CI-friendly 版本（如 `1.1.0-SNAPSHOT`）。

⚠️ Spring Boot 4 项目 **MUST** 使用 `mybatis-plus-spring-boot4-starter`（**不是** `mybatis-plus-boot-starter`）。

## 项目形态与适用规范（重要）

生态内存活 **两类项目形态**，规范需分别适配：

| 形态 | 模块结构 | 持久化模式 | 适用 |
|---|---|---|---|
| **DDD 微服务**（**新项目默认**） | 7+1 模块（common/domain/infra/repository-mybatis/application/interfaces/boot/dependencies）+ 前端 monorepo | RepositoryFacade + Delegate + Entity/PO 分离 | structure-user / structure-org / structure-tenant / structure-resource 等业务中心 |
| **单体应用** | 4 模块（api / biz / common / dependencies） | Manager 模式（`IManager extends IService` / `ManagerImpl extends ServiceImpl`） | structure-mono-template 及历史单体项目 |

**兼容原则**：

1. **新业务中心 MUST 用 DDD 7+1**；**单体项目 MAY 用 4 模块 + Manager 模式**，不强制迁移。
2. **老项目兼容**：`structure-pro` 等历史项目仍基于 4 模块 + Manager 模式，整体用法与现行规范相近。AI 在这类仓库工作时 **沿用其本地规范**（`rule/` 目录），**不强行套用 DDD 规范**。
3. 跨形态通用的规则（统一响应 `ResResultVO`、统一异常 `CommonException`、命名约定、参数验证、Swagger、用户上下文 `UserContext`、数据权限、多租户）**两种形态都适用**。
4. 仅 DDD 形态适用的规则：RepositoryFacade / Delegate / `toEntity`/`toPo` 重写 / `ICrudRepository` 继承 / Entity/PO 分离。
5. 仅单体形态适用的规则：Manager 模式、Entity 直接用 `@TableId`/`@TableLogic`、`manager.count(Wrappers...)` 直查。

**老项目清单**（AI 工作在这些仓库时按本地规范，不按 DDD 新规范）：

- `structure-pro` —— 云原生微服务脚手架（含 `rule/` 本地规范，基于 4 模块 + Manager）
- 其他仍基于 4 模块结构的单体项目（以各仓库 `rule/` / `PROJECT_RULES.md` / README 实际描述为准，用前先验证）

🚫 **不兼容的老项目**（已弃用，新项目禁止）：`structure-ruoyi` / `ruoyi-framework` / `ruoyi-pro` / `ruoyi-ui` / `structure-yudao` / `structure-cloud`。

## 已验证的真实模块布局（structure-user / structure-org 通用）

**每个业务服务是一个 monorepo**，包含 7+1 后端模块 + 2 个前端模块：

```
structure-{X}/
├── structure-{X}-dependencies/        # ⭐ 父 POM 在此（无根 pom.xml），通过 <modules>+相对路径聚合
├── structure-{X}-common/              # DTO / VO / Query / enums / exception / constant
├── structure-{X}-domain/              # {X}Entity、{X}Repository（接口）、DomainService
├── structure-{X}-infra/               # {X}RepositoryImpl（extends RepositoryFacade）、{X}RepositoryDelegate（接口）
├── structure-{X}-repository-mybatis/  # {X}PO、{X}Mapper、{X}MybatisPlusDelegate、Flyway 迁移
├── structure-{X}-application/         # I{X}Service、{X}ServiceImpl、{X}Assembler、{X}Async
├── structure-{X}-interfaces/          # controller/api/{X}Controller、controller/open/Open{X}Controller
├── structure-{X}-boot/                # 启动类 + application.yaml
├── structure-{X}-ui/                  # 前端微前端子应用（Vue3+Vite+TS+Pinia+Element Plus+UnoCSS+wujie-vue3）
└── structure-{X}-ui-components/       # 前端本地组件库（通过 file: 协议引用，不发布 npm）
```

⚠️ **已识别包路径异常**：`repository-mybatis` 模块下的实际包是 `cn.structured.{X}.repository.repository.*`（**双 "repository"**），疑似历史遗留 / 错误。AI 生成新代码前 **应向用户确认** 是沿用还是修正为 `cn.structured.{X}.repository.mybatis.*`。

## 生态组件图谱（按层次分组）

> 数据来自 GitHub org 公开仓库（共 59 个）。⚠️ 用户已声明：**部分仓库已弃用，文档可能滞后于代码**，下方描述以 README 为准、仅作大致参考，选型时需向用户确认活跃状态。

### 核心基座 / Starter
- **structure-boot** — Spring Boot Starter 集合（Web/MyBatis-Plus/Redis/MinIO/多租户/RPC 等）。
  版本线：**1.4.x = Spring Boot 4.0 + JDK 17**；**1.3.x = SB 3.x + JDK 17**；**1.2.x = SB 2.x + JDK 8**。
- **structure-cloud** — 🚫 **已停止维护**（"比较鸡肋"）。依赖版本统一改在 `structure-{X}-dependencies` 与 `structure-boot` 中配置。
- **structure-basic** — 基座（README 为空，待澄清）。
- **structure-plugin** — 扩展插件。
- **structure-pro-infra** — DDD 基础设施抽象层：Repository **Facade + Delegate** 防腐层、低代码仓储、CQRS 读写分离、事件管理、XXL-Job / Spring Cloud Stream 集成。**与 `structure-infra` 是同一项目**（仓库名 `structure-pro-infra`，内部 artifact/包名 `structure-infra` / `cn.structure.infra.*`）。

### 脚手架 / 模板（AI 生成新项目时选型）
- **structure-pro** — 云原生微服务脚手架（Git submodule 组织，含 Kong/Istio/Nacos/Grafana/SkyWalking/Sentinel/Kibana）。
- **structure-ddd-template** — DDD 服务模板，**7+1 模块**（dependencies / common / domain / infra / repository-mybatis / application / interfaces / boot），JDK 21 + SB 3.2 + SC 2025。
- **structure-multi-module-template** — 扁平多模块模板（common / core / biz / boot / cloud），JDK 17 + SB 3.x。
- **structure-mono-template** — 单体模板（README 为空）。

### 网关与安全
- **structure-gateway** — Spring Cloud Gateway 多租户 API 网关（Token / 租户识别 / 重放防护 / QPS-日-月限流 / 链路追踪），JDK 8 + SB 2.7。
- **structure-gateway-adapter** — 网关适配。
- **structure-gateway-client** — 网关客户端（TS，npm `@structure-projects/gateway-client`）。
- **structure-security** — Spring Security 企业级安全框架（JWT / OAuth2 / Basic Auth / 通配符权限模型），SB 4.0.6 + JDK 17。
- **structure-sso** — 统一登录（Vue）。

### 业务中心（微服务）
用户 `structure-user` / 组织 `structure-org` / 租户 `structure-tenant` / 成员 `structure-member` / 账户 `structure-account` / 资源 `structure-resource` / 订单 `structure-order` / 商品 `structure-product` / 买家 `structure-seller` / 支付 `structure-pay` / 内容 `structure-content` / 任务 `structure-task` / 激励 `structure-incentive` / 广告 `structure-advertising` / 风控 `structure-risk` / 文件 `structure-file`（统一文件管理服务，新项目文件操作走此服务 API，不直接用 `structure-minio-starter`）。

### 平台服务
调度 `structure-job` / 消息 `structure-message` / 监控 `structure-monitor` / 运维 `structure-ops` / 告警 `structure-alert` / 审计 `structure-audit` / 数据权限 `structure-datascope`。

### 前端 / 客户端
- **structure-admin / structure-admin-ui** — 管理后台（Vue + Element Plus + Avue + amis）。
- **structure-components** — Vue 组件库（npm `@structure-projects/components`）。
- **structure-ui** — 业务 UI。
- **structure-web-ui** — 基础前端框架。
- **structure-wujie-subapp / structure-wujie-template** — 无界微前端子应用与模板（TS）。
- **structure-uniapp-ui / structure-react-native** — 移动端框架。
- **structure-app** — 应用（README 空）。

### AI / 网络 / 集成
- **structure-agent** — AI 智能体。
- **structure-netty / structure-peer-to-peer** — Netty 与 P2P。
- **structure-ruoyi / ruoyi-framework / ruoyi-pro / ruoyi-ui** — 若依整合（**多数 2024-09 停更，疑似弃用**）。
- **structure-yudao** — 宇道整合（2024-09 停更，疑似弃用）。

### 运维与文档
- **somcli** — Structure Ops CLI（Go，容器生命周期管理）。
- **docker-compose / kubernetes** — 部署清单。
- **structure-docs** — VitePress 文档站（`docs/` 含 products / quickstart / ops-architecture / industry-ai 等）。

## 本仓库文件结构

- **`prompts/<role>.md`** — 各角色规则的 **single source of truth**（工具无关）。当前角色：`architect` / `developer` / `tester` / `reviewer`。
- **`prompts/project-scaffolding.md`** — 项目创建约束（跨角色共享）。
- **`prompts/components.md`** — 各组件使用与配置速查（跨角色共享，⚠️ 部分章节待读源码补全）。
- **`.claude/agents/<role>.md`** — Claude Code subagent 包装，含 frontmatter 与关键规则内联，正文仍指向 `prompts/`。
- **`.cursor/rules/<role>.mdc`** — Cursor 规则包装，含 `globs` 与 `alwaysApply` 配置。
- **`AGENTS.md`** — 规则索引、使用方式、维护约定。**新增/修改角色前先读它**。

## 本仓库工作方式

- **没有构建、lint、测试命令** —— 产出物是 Markdown 规则与提示词。
- 新增规则时：写清 **目标读者（哪类 AI / 哪种角色）**、**适用仓库范围**、**强制级别（MUST / SHOULD / MAY）**。
- 修改规则时 **先改 `prompts/`，再评估是否同步包装文件中的内联摘要**。
- 引用生态事实（如 groupId、版本线、包名约定）时，以本文件为 single source of truth；发现与实际仓库不符时**先更新本文件**再扩散到各角色规则。

## 已识别的"文档与代码不一致"案例（提醒 AI 不要盲信 README）

- `structure-user/README.md` 描述的是旧 4 模块（api/biz/cloud/domain）+ JDK 8 + Spring Boot 2.x，**实际已是 DDD 7+1 模块 + 前端 monorepo**。
- `structure-org/PROJECT_RULES.md` 仍写 Manager 层模式与 4 模块结构，**实际代码已切换到 RepositoryFacade + Delegate**，Manager 模式在代码中已不存在。
- `structure-org/PROJECT_RULES.md` 中实体命名约定为 `{业务}`（如 `Dept`），**实际代码为 `{业务}Entity`**（如 `DeptEntity`）。
- `structure-multi-module-template` README 描述了完整目录与 `PROJECT_RULES.md`，但仓库实际只有 `README.md`。
- `structure-docs` README 引用了 `pd.md`，但根目录无此文件。
- 多个 `structure-*` 业务中心仓库无 README，仅有描述字段。

## 已识别的"老项目兼容形态"（AI 应按本地规范工作）

- 生态内存在仍基于 **4 模块 + Manager 模式 + Entity 直接用 `@TableId`** 的老项目/单体应用。这是 **合法的本地规范**，与 DDD 新规范并存（见前文"项目形态与适用规范"）。AI 在这类仓库工作时 **沿用其本地规范**（各仓库的 `rule/` / `PROJECT_RULES.md` / README，用前先验证），不强行套用 DDD 规则。
- 本规则库已包含老项目兼容所需的全部通用内容（CVE 修复、构建配置、`TenantContextHolder`、`DataRuleEngine.filter`、各 Starter 配置、validation、swagger），**全部自包含在本仓库维护**，不依赖任何外部仓库。

## 已识别的"包名不一致"案例（生成 import 前 MUST 核对目标类所在的具体 starter）

- **`structure-security` 内部 starter 包名不统一**：
  - `jwt-starter` 包名 `cn.structure.starter.jwt.*`（**无 d**）
  - `permission-starter` 包名 `cn.structured.starter.permission.*`（**有 d**）
  - `context-starter` 包名 `cn.structured.starter.context.*`（**有 d**）
  - 业务代码（如 `structure-user`）使用的 `cn.structured.security.util.SecurityUtils` 又是 `cn.structured.security.*`（有 d，但不在 starter 命名空间下）
- **`repository-mybatis` 模块下的业务包**：`cn.structured.{X}.repository.repository.*`（**双 "repository"**）—— 见前文章节。
- **`structure-security` artifact 本身**：包名 `cn.structured.security.*`（**有 d**），**不是** `cn.structure.security.*` —— 与"common/infra 无 d"的规律不同。

→ 生成引用生态细节的文档前，**优先用 GitHub API 验证仓库实际状态**，避免基于过时 README 产出错误规则。

## 已验证的真实代码模式（structure-user / structure-org，2026-07）

### RepositoryFacade + Delegate（持久化）

```java
// domain/repository/XxxRepository.java —— 接口
public interface XxxRepository { /* ... */ }

// infra/repository/XxxRepositoryImpl.java
@Component("xxxRepository")
public class XxxRepositoryImpl
        extends RepositoryFacade<XxxEntity, Long, XxxRepositoryDelegate>
        implements XxxRepository {
    @Override public ReturnType method(...) { return getDelegate().method(...); }
}

// infra/repository/delegate/XxxRepositoryDelegate.java —— 接口（业务侧）
public interface XxxRepositoryDelegate { /* ... */ }

// repository-mybatis/repository/XxxMybatisPlusDelegate.java
@Component
public class XxxMybatisPlusDelegate
        extends MybatisPlusRepositoryDelegate<XxxEntity, XxxPO, Long>
        implements XxxRepositoryDelegate {
    @Override protected XxxEntity toEntity(XxxPO po) { /* 手动转换 */ }
    @Override protected XxxPO toPo(XxxEntity entity) { /* 手动转换 */ }
    // 复杂查询直接用 baseMapper.xxx()
}
```

**关键事实**：
- Entity ↔ PO 转换是 **Delegate 子类手动实现 `toEntity`/`toPo`**，**并非** RepositoryFacade 自动完成（旧文档说法已纠正）。
- 复杂查询可直接访问 `baseMapper`（MyBatis-Plus 提供）。
- 读写分离通过 `@WriteDelegate` / `@ReadDelegate` 注解（来自 `cn.structure.infra.annotations`）。

### 统一响应（Controller 层）

```java
import cn.structure.common.entity.ResResultVO;
import cn.structure.common.utils.ResultUtilSimpleImpl;
import cn.structure.common.vo.ResPage;
import cn.structure.common.vo.ReqPage;

@GetMapping("/{id}")
public ResResultVO<XxxVO> findById(@PathVariable Long id) {
    return ResultUtilSimpleImpl.success(xxxService.findById(id));
}
```

- 响应体：`ResResultVO<T>`
- 构造：`ResultUtilSimpleImpl.success(data)` / `ResultUtilSimpleImpl.fail(code, message)`
- 分页：`ResPage<T>`（响应）、`ReqPage`（请求）

### 命名约定（真实代码）

| 类型 | 模式 | 示例 |
|---|---|---|
| 领域实体 | `{X}Entity` | `DeptEntity` |
| 持久化对象 | `{X}PO` | `DeptPO` |
| 仓储接口 | `{X}Repository` | `DeptRepository` |
| 仓储实现 | `{X}RepositoryImpl` | `DeptRepositoryImpl` |
| Delegate 接口 | `{X}RepositoryDelegate` | `DeptRepositoryDelegate` |
| MyBatis Delegate | `{X}MybatisPlusDelegate` | `DeptMybatisPlusDelegate` |
| Service 接口 | `I{X}Service` | `IUserService` |
| Service 实现 | `{X}ServiceImpl` | `UserServiceImpl` |
| Controller | `{X}Controller` / `Open{X}Controller` | `UserController` / `OpenApiUserController` |
| Assembler | `{X}Assembler`（静态方法） | `UserAssembler` |
| 错误码枚举 | `{X}ExceptionEnum`（码形如 `ORG_001`） | `OrgExceptionEnum` |

### 依赖注入风格

- 字段注入使用 `@Resource`（`jakarta.annotation.Resource`），**非** `@Autowired`。
- Controller 路径前缀 `/api/{资源}`；开放接口位于 `controller/open/Open{X}Controller`。

## 生态内已使用的其他 AI 工具

业务仓库中观察到以下 AI 工具痕迹，规则与提示词应尽量 **工具中立**，不绑定特定厂商：

- `.trae/` — ByteDance Trae，含 `documents/` 存放 AI 生成的设计/迁移计划（如 `ddd_business_design_plan.md`、`org_ddd_upgrade_plan.md`）。
- `.codebuddy/` — 腾讯 CodeBuddy，含 `memory/`。
- `.claude/`、`AGENTS.md`、`CLAUDE.md` — 本仓库规则的目标载体之一。

→ 评估规则普适性时，应让同一份 `prompts/<role>.md` 能喂给以上任一工具。