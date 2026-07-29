# AGENTS.md — structure-projects 生态 AI 规则索引

> 本仓库是 [structure-projects](https://github.com/structure-projects) 开源生态的 **AI 规则与提示词工程** 仓库，不写业务代码。
> 本文件汇总所有可用规则、各自适用场景与维护约定。

## 规则总览

### 角色规则

| 角色 | 单一内容源（canonical） | Claude Code subagent | Cursor rule | 适用阶段 |
|---|---|---|---|---|
| 架构/设计 | [`prompts/architect.md`](prompts/architect.md) | [`.claude/agents/architect.md`](.claude/agents/architect.md) | [`.cursor/rules/architect.mdc`](.cursor/rules/architect.mdc) | 选型、模块划分、API 设计 |
| 开发 | [`prompts/developer.md`](prompts/developer.md) | [`.claude/agents/developer.md`](.claude/agents/developer.md) | [`.cursor/rules/developer.mdc`](.cursor/rules/developer.mdc) | 编码实现 |
| 测试 | [`prompts/tester.md`](prompts/tester.md) | [`.claude/agents/tester.md`](.claude/agents/tester.md) | [`.cursor/rules/tester.mdc`](.cursor/rules/tester.mdc) | 编写/维护测试 |
| 评审 | [`prompts/reviewer.md`](prompts/reviewer.md) | [`.claude/agents/reviewer.md`](.claude/agents/reviewer.md) | [`.cursor/rules/reviewer.mdc`](.cursor/rules/reviewer.mdc) | PR / 设计评审 |

### 专题规则（跨角色共享）

| 主题 | 文件 | 适用阶段 |
|---|---|---|
| **项目创建约束** | [`prompts/project-scaffolding.md`](prompts/project-scaffolding.md) | 创建新项目/新模块时的选型、坐标、模块布局、初始提交物 |
| **组件使用与配置** | [`prompts/components.md`](prompts/components.md) | 各组件（structure-common / infra / security / tenant / datascope / gateway / boot / cloud）的 API、配置项、典型用法 |

## 使用方式

### Claude Code
- 通过 Agent 工具显式调用，如 `Agent(subagent_type="structure-architect", ...)`。
- 或在对话中说明"用 structure-developer 角色实现 X"。

### Cursor
- 将 `.cursor/rules/*.mdc` 拷到目标项目的 `.cursor/rules/` 即可自动加载。
- `developer.mdc` 设置了 `alwaysApply: true`，其他角色按 `globs` 触发。

### 其他 AI（GPT / 通义 / 文心 / 自建 Agent）
- 直接把 `prompts/<role>.md` 的完整内容作为 system prompt 或上下文喂入。
- 项目创建场景同时使用 `prompts/project-scaffolding.md`；查询组件用法时搭配 `prompts/components.md`。

## 维护约定（重要）

1. **`prompts/<role>.md` 是 single source of truth**。`.claude/agents/` 与 `.cursor/rules/` 是其 **格式包装**，仅做 frontmatter + 关键规则内联，**不重复完整规则**。
2. 修改规则时 **先改 `prompts/`**，再决定是否需要同步调整包装文件中的内联摘要。
3. 所有规则必须使用 **MUST / SHOULD / MAY**（RFC 2119 风格）标注强制级别。
4. 引用生态事实（版本线、groupId、包名约定等）时，以 [`CLAUDE.md`](CLAUDE.md) 为准；发现与实际仓库不符时 **先更新 CLAUDE.md 再扩散**。
5. 新增角色时：先在 `prompts/` 建立正文 → 再生成 `.claude/agents/` 与 `.cursor/rules/` 包装 → 回本文件登记到上方表格。

## 规则适用对象的区分

部分规则只适用于 **生态贡献者**（向 `structure-projects` 组织内仓库提交代码），部分只适用于 **下游业务开发者**（基于 `structure-boot`/`structure-cloud` 搭建业务系统）。各 `prompts/<role>.md` 中若有此区分会显式标注；评审 Agent 在驳回前必须先确认当前 PR 属于哪一类。

## 已知文档/代码不一致

- `structure-multi-module-template` README 描述了完整目录与 `PROJECT_RULES.md`，实际仓库仅含 README。
- `structure-docs` README 引用的 `pd.md` 不存在。
- 多个业务中心仓库（`structure-member` / `structure-account` / `structure-order` 等）仅有描述、无 README。

→ 在生成/评审规则时如需引用这些仓库细节，**先用 GitHub API 验证实际状态**，不要基于过时 README 下结论。