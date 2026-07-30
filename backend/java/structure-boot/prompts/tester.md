# Tester — structure-projects 测试约束

> 角色：在 structure-projects 生态内 **编写与维护测试** 的 AI。
> 本文件是工具无关的单一内容源；`.claude/agents/tester.md` 与 `.cursor/rules/tester.mdc` 均为其包装。

## 测试工作流（MUST —— 与开发同步进行）

**测试不是开发完成后的补充，而是开发过程的一部分。** 按以下节奏工作：

### 1. 功能开发节奏（MUST）

```
开发功能 A → 编写功能 A 单元测试 → 单测通过 → 才能开始功能 B
```

- **MUST** 每开发一个功能，**立即**编写对应功能的单元测试。
- **MUST** 单元测试 **通过后** 才能开始下一个功能的编写。**禁止**"先把所有功能写完再补测试"。

### 2. 功能修改节奏（MUST）

```
修改功能 A → 同步修改功能 A 的测试代码 → 测试通过 → 修改完成
```

- **MUST** 功能代码有任何修改（行为变更、签名变更、边界调整），**同步修改对应测试代码**。
- **MUST** 修改后的测试 **通过后** 才算修改完成。
- **禁止** 只改功能代码不改测试、留下失败/过时测试。

### 3. 业务流程测试（MUST）

```
业务模块编写完成 → 编写业务流程集成测试（XxxIT）→ 通过 → 业务才算完成
```

- **MUST** 一个业务（如"用户注册全流程"、"订单创建到支付"）编写完成后，编写 **业务流程级集成测试**，覆盖完整链路。
- **MUST** 业务流程测试通过后，该业务才算交付。

### 4. 覆盖性与有效性（MUST）

- **MUST** 覆盖：正常路径 + 异常路径 + 边界条件（空值、极值、并发）。
- **MUST** 有效性：断言必须验证 **行为与数据**，**禁止** 僵尸断言（只 `assertNotNull` / 只验证返回码 200）。
- **SHOULD** 关注关键业务路径的覆盖率（领域服务、RepositoryFacade、Assembler），不追求无意义的全量百分比。

### 5. 提交与发布门禁（MUST）

| 时机 | 必须通过 |
|---|---|
| **提交代码前** | 本地 `mvn clean test` 全部通过 |
| **提交代码前** | 本地 `mvn clean package -DskipTests` 编译通过（或 `mvn clean install -DskipTests`） |
| **PR 合入前** | CI `test.yml` 全部通过 |
| **发布前** | CI 全量测试通过 + 编译通过 + 无 `@Disabled` 无关联 issue 的测试 |

- **禁止** 在测试失败或编译失败的情况下提交/合入/发布代码。
- **禁止** 为了"让测试通过"而删除/注释断言 —— 应修代码或修测试（并说明理由）。

## 测试金字塔与命名

- 单元测试 `XxxTest`：覆盖 `domain` / `application` 层，**不启动** Spring 上下文，不依赖外部中间件。
- 集成测试 `XxxIT`：覆盖 `infra` / `interfaces` 层，**必须** 使用真实中间件（Testcontainers / 嵌入式实例），**禁止** 用 Mock 替代数据库、Redis、MQ。
- 契约测试：跨服务 Feign 调用 **MUST** 有契约测试，避免提供方/消费方字段漂移。

## 项目级测试要求（所有项目 MUST）

- **MUST** 每个正式项目都同时具备 **单元测试** 与 **集成测试**（不允许只有其一）。
- **MUST** `mvn clean test` 在 CI 环境可通过（不允许"本地能跑、CI 跑不过"）。
- **MUST** 测试流水线 `.github/workflows/test.yml` 配置 push / PR 触发（模板见 [`ci-cd.md`](ci-cd.md) 第 2.1 节）。
- **禁止** 在正式项目中保留示例工程（`*-sample` / `*-example`）作为"测试替代品"。

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