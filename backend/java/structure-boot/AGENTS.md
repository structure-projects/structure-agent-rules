# AGENTS.md — structure-boot 规则索引

> structure-projects Spring Boot 后端开发规则集合。
> 面向 AI Agent (Claude Code / Cursor / CodeBuddy / Trae / 通义灵码 / Codex)。

## 可用角色

| 角色 | 单一内容源（canonical） | Claude Code | Cursor | Trae | CodeBuddy | 通义灵码 |
|---|---|---|---|---|---|---|
| 架构/设计 | [`prompts/architect.md`](prompts/architect.md) | [`.claude/agents/structure-boot-architect.md`](.claude/agents/structure-boot-architect.md) | [`.cursor/rules/structure-boot-architect.mdc`](.cursor/rules/structure-boot-architect.mdc) | [`.trae/rules/structure-boot-architect.md`](.trae/rules/structure-boot-architect.md) | [`.codebuddy/rules/structure-boot-architect.md`](.codebuddy/rules/structure-boot-architect.md) | [`.lingma/rules/structure-boot-architect.md`](.lingma/rules/structure-boot-architect.md) |
| 开发 | [`prompts/developer.md`](prompts/developer.md) | [`.claude/agents/structure-boot-developer.md`](.claude/agents/structure-boot-developer.md) | [`.cursor/rules/structure-boot-developer.mdc`](.cursor/rules/structure-boot-developer.mdc) | [`.trae/rules/structure-boot-developer.md`](.trae/rules/structure-boot-developer.md) | [`.codebuddy/rules/structure-boot-developer.md`](.codebuddy/rules/structure-boot-developer.md) | [`.lingma/rules/structure-boot-developer.md`](.lingma/rules/structure-boot-developer.md) |
| 测试 | [`prompts/tester.md`](prompts/tester.md) | [`.claude/agents/structure-boot-tester.md`](.claude/agents/structure-boot-tester.md) | [`.cursor/rules/structure-boot-tester.mdc`](.cursor/rules/structure-boot-tester.mdc) | [`.trae/rules/structure-boot-tester.md`](.trae/rules/structure-boot-tester.md) | [`.codebuddy/rules/structure-boot-tester.md`](.codebuddy/rules/structure-boot-tester.md) | [`.lingma/rules/structure-boot-tester.md`](.lingma/rules/structure-boot-tester.md) |
| 评审 | [`prompts/reviewer.md`](prompts/reviewer.md) | [`.claude/agents/structure-boot-reviewer.md`](.claude/agents/structure-boot-reviewer.md) | [`.cursor/rules/structure-boot-reviewer.mdc`](.cursor/rules/structure-boot-reviewer.mdc) | [`.trae/rules/structure-boot-reviewer.md`](.trae/rules/structure-boot-reviewer.md) | [`.codebuddy/rules/structure-boot-reviewer.md`](.codebuddy/rules/structure-boot-reviewer.md) | [`.lingma/rules/structure-boot-reviewer.md`](.lingma/rules/structure-boot-reviewer.md) |

### 专题规则（跨角色共享）

| 主题 | 文件 | 说明 |
|---|---|---|
| 项目创建约束 | [`prompts/project-scaffolding.md`](prompts/project-scaffolding.md) | DDD 模块布局、Maven 坐标、构建配置 |
| 组件使用 | [`prompts/components.md`](prompts/components.md) | structure-common / infra / security / tenant 等组件 API |
| DTO 校验 | [`prompts/validation.md`](prompts/validation.md) | Jakarta Validation 规范 |
| OpenAPI 文档 | [`prompts/swagger.md`](prompts/swagger.md) | springdoc-openapi 配置 |
| CI/CD | [`prompts/ci-cd.md`](prompts/ci-cd.md) | Maven + GitHub Actions 流水线 |

## 关键版本

- Spring Boot 4.0.6 + JDK 17 + `jakarta.*`
- parent: `cn.structured:structure-dependencies:1.4.4`
- **禁止** 引入 `structure-cloud-dependencies`

## 使用方式

独立使用或与前端规则组合。组合时由 `install.sh` 自动处理文件名前缀。

详见仓库根目录 `AGENTS.md` 了解安装命令。
