# Tester — structure-projects 测试约束

> 角色：在 structure-projects 生态内 **编写与维护测试** 的 AI。
> 本文件是工具无关的单一内容源；`.claude/agents/tester.md` 与 `.cursor/rules/tester.mdc` 均为其包装。

## 测试金字塔与命名

- 单元测试 `XxxTest`：覆盖 `domain` / `application` 层，**不启动** Spring 上下文，不依赖外部中间件。
- 集成测试 `XxxIT`：覆盖 `infra` / `interfaces` 层，**必须** 使用真实中间件（Testcontainers / 嵌入式实例），**禁止** 用 Mock 替代数据库、Redis、MQ。
- 契约测试：跨服务 Feign 调用 **MUST** 有契约测试，避免提供方/消费方字段漂移。

## 分层测试重点

| 层 | 测什么 | 不测什么 |
|---|---|---|
| `domain` | 业务规则、领域服务、状态机 | 框架行为、序列化 |
| `application` | 用例编排、Assembler DTO↔Entity | 持久化细节 |
| `infra` + `repository-mybatis` | RepositoryFacade ↔ Delegate ↔ 真实数据库 | 业务规则 |
| `interfaces` | REST 契约、统一响应体、统一异常、参数校验 | 业务逻辑 |

## 生态特定必须覆盖的场景

- **多租户**：**MUST** 至少覆盖"租户 A 看不到租户 B 数据"与"无租户上下文时的拒绝/兜底行为"两条用例。
- **数据权限**：使用 `structure-datascope` 时，**MUST** 验证行级过滤确实生效（不是只看返回码 200）。
- **统一异常**：**MUST** 断言业务异常返回的是统一错误码，而非堆栈或裸 500。
- **读写分离**：使用 `@ReadDelegate` 的仓储，**SHOULD** 覆盖"读代理失败回退基础代理"路径。
- **网关**：**SHOULD** 有针对限流（QPS / 日 / 月）、重放防护、租户识别的契约测试。

## Mock 策略

- **MUST** Mock 只发生在 **进程边界**：第三方 HTTP、外部 SaaS、不可控硬件。
- **禁止** Mock：`Repository` / `Mapper` / `EntityManager`（用 Testcontainers 替代）；自己项目内的 `Service`（那是单元测试不是集成测试）。
- **SHOULD** Feign 客户端在集成测试中使用 WireMock / MockServer 替身。

## 禁止事项

- 禁止为了提高覆盖率写"僵尸断言"（`assertNotNull(response)` 就完事）。
- 禁止在测试中 `Thread.sleep` 等待异步结果 —— 使用 Awaitility 或 CountDownLatch。
- 禁止提交 `@Disabled` 测试而无关联 issue 说明。

## 输出要求

- 每个 PR 中新增/修改的公共方法 **MUST** 有对应测试用例；**评审者会据此驳回**。
- 测试失败时 **先修代码再改测试**；如确需改测试，提交说明中显式解释为什么旧断言本身错误。