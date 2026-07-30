---
alwaysApply: false
paths:
  - "**/*.md"
  - "**/pom.xml"
  - "**/build.gradle*"
description: structure-projects 架构/设计规则。涉及选型、模块划分、API 设计、DDD 分层决策时由 Agent 引用。
---

# structure-projects 架构/设计规则

> 完整规则见 `prompts/architect.md`（single source of truth）。本文件为 CodeBuddy 速查版。

## 硬约束

- Maven `groupId` = `cn.structured`；npm scope = `@structure-projects`
- 包名：`cn.structure.*`（无 d）仅 `structure-common` / `structure-infra`；其余 `cn.structured.*`（含 `structure-security`，**不是** `cn.structure.security`）
- 当前主线：Spring Boot `4.0.6` + JDK 17 + `jakarta.*`；parent `cn.structured:structure-dependencies:1.4.4`
- **禁止** 引入 `structure-cloud-dependencies`（structure-cloud 已停止维护）

## 模板选型

| 诉求 | 模板 |
|---|---|
| 单体单模块 | `structure-mono-template` |
| 单体多模块 | `structure-multi-module-template` |
| DDD 7+1（**默认推荐**） | `structure-ddd-template` |
| 云原生微服务 | `structure-pro` |
| 前端微前端子应用 | `structure-wujie-template` |

## DDD 7+1 模块布局

```
dependencies / common / domain / infra / repository-mybatis / application / interfaces / boot
+ 前端 *-ui + *-ui-components
```

依赖方向：`common → domain → infra → repository-mybatis`；`application → domain+infra`；`interfaces → application`；`boot → all`。

## DDD 分层铁律

- **MUST** 依赖方向只能自上而下，禁止反向 / 跨层
- **MUST** 持久化通过 `cn.structure.infra.repository.RepositoryFacade` + Delegate
- **MUST** `MybatisPlusDelegate` 显式重写 `toEntity` / `toPo`
- **禁止** 把 `Mapper` / `PO` 注入 `application` / `domain`
- ⚠️ 包路径异常：`cn.structured.{X}.repository.repository.*`（双 "repository"）为历史遗留，新设计需与用户确认

## API 设计

- RESTful；统一响应 `cn.structure.common.entity.ResResultVO<T>`；统一错误码 `{X}ExceptionEnum`
- 多租户不在 URL / Header 显式传租户 ID，由 `structure-gateway` 写入上下文
- 分页签名统一 `page({X}Query query, cn.structure.common.vo.ReqPage reqPage)`

## 输出要求

设计产出必须包含：选型结论、模块划分图、依赖方向说明、与规范不一致之处的显式说明。用户要求违反规范时，先指出冲突并给出替代方案，再按其最终决定执行。

详细规则读 `prompts/architect.md`。
