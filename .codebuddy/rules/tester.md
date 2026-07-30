---
alwaysApply: false
paths:
  - "**/test/**/*.java"
  - "**/*Test.java"
  - "**/*IT.java"
  - "**/*.test.ts"
  - "**/*.spec.ts"
description: structure-projects 测试规则。编写或修改测试代码时由 Agent 引用。
---

# structure-projects 测试规则

> 完整规则见 `prompts/tester.md`。本文件为 CodeBuddy 速查版。

## 测试分层与命名

- `XxxTest` — 单元测试，覆盖 `domain`/`application`，**不启动** Spring 上下文
- `XxxIT` — 集成测试，覆盖 `infra`/`interfaces`，**必须** 用真实中间件（Testcontainers），**禁止** Mock 数据库/Redis/MQ
- Feign 跨服务调用 **必须** 有契约测试

## 生态必须覆盖

- **多租户**：至少覆盖"租户 A 看不到租户 B"与"无租户上下文兜底"
- **数据权限**：使用 `structure-datascope` 时必须验证行级过滤实际生效（不仅看 200）
- **统一异常**：断言业务异常返回统一错误码，而非堆栈或裸 500
- **读写分离**：覆盖 `@ReadDelegate` 失败回退路径
- **用户上下文**：覆盖 `UserContext.getLongUserId()` 返回 null 的兜底

## Mock 边界

- 只允许 Mock **进程边界**（第三方 HTTP / 外部 SaaS / 不可控硬件）
- **禁止** Mock 自己项目的 `Repository` / `Service` / `Mapper`
- Feign 客户端集成测试用 WireMock / MockServer 替身

## 禁止事项

- 僵尸断言（只 `assertNotNull`）
- `Thread.sleep` 等待异步 —— 用 Awaitility / CountDownLatch
- 提交无 issue 关联的 `@Disabled` 测试

## 输出要求

- 新增/修改的公共方法 MUST 有对应测试用例
- 测试失败时 **先修代码再改测试**；如确需改测试，提交说明中显式解释

详细规则读 `prompts/tester.md`。
