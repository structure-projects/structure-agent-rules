# AGENTS.md — structure-projects 生态 AI 规则索引

> 本仓库是 [structure-projects](https://github.com/structure-projects) 开源生态的 **AI 规则与提示词工程** 仓库，不写业务代码。
> 本文件汇总所有可用规则、各自适用场景与维护约定。

## 规则总览

### 角色规则

| 角色 | 单一内容源（canonical） | Claude Code | Cursor | Trae | CodeBuddy | 通义灵码 |
|---|---|---|---|---|---|---|
| 架构/设计 | [`prompts/architect.md`](prompts/architect.md) | [`.claude/agents/architect.md`](.claude/agents/architect.md) | [`.cursor/rules/architect.mdc`](.cursor/rules/architect.mdc) | [`.trae/rules/architect.md`](.trae/rules/architect.md) | [`.codebuddy/rules/architect.md`](.codebuddy/rules/architect.md) | [`.lingma/rules/architect.md`](.lingma/rules/architect.md) |
| 开发 | [`prompts/developer.md`](prompts/developer.md) | [`.claude/agents/developer.md`](.claude/agents/developer.md) | [`.cursor/rules/developer.mdc`](.cursor/rules/developer.mdc) | [`.trae/rules/developer.md`](.trae/rules/developer.md) | [`.codebuddy/rules/developer.md`](.codebuddy/rules/developer.md) | [`.lingma/rules/developer.md`](.lingma/rules/developer.md) |
| 测试 | [`prompts/tester.md`](prompts/tester.md) | [`.claude/agents/tester.md`](.claude/agents/tester.md) | [`.cursor/rules/tester.mdc`](.cursor/rules/tester.mdc) | [`.trae/rules/tester.md`](.trae/rules/tester.md) | [`.codebuddy/rules/tester.md`](.codebuddy/rules/tester.md) | [`.lingma/rules/tester.md`](.lingma/rules/tester.md) |
| 评审 | [`prompts/reviewer.md`](prompts/reviewer.md) | [`.claude/agents/reviewer.md`](.claude/agents/reviewer.md) | [`.cursor/rules/reviewer.mdc`](.cursor/rules/reviewer.mdc) | [`.trae/rules/reviewer.md`](.trae/rules/reviewer.md) | [`.codebuddy/rules/reviewer.md`](.codebuddy/rules/reviewer.md) | [`.lingma/rules/reviewer.md`](.lingma/rules/reviewer.md) |

**Trae 入口文件**：`.trae/rules/project_rules.md` 是 Trae 自动识别的项目规则入口，包含使用前必读指引与生态硬约束速查。

### 专题规则（跨角色共享）

| 主题 | 文件 | 适用阶段 |
|---|---|---|
| **项目创建约束** | [`prompts/project-scaffolding.md`](prompts/project-scaffolding.md) | 创建新项目/新模块时的选型、坐标、模块布局、初始提交物 |
| **组件使用与配置** | [`prompts/components.md`](prompts/components.md) | 各组件（structure-common / infra / security / tenant / datascope / gateway / boot / cloud）的 API、配置项、典型用法 |

### 自包含模板（独立使用，不依赖 prompts/）

| 文件 | 用途 |
|---|---|
| [`codex/AGENTS.md`](codex/AGENTS.md) | **业务项目 Codex / 通用 AI Agent 规则模板**。包含全部 MUST 级规则，拷到业务项目根目录即可被 Codex 自动加载。⚠️ 修改 `prompts/developer.md` 中 MUST 级规则时需同步此文件 |

## 使用方式

### Claude Code
- 通过 Agent 工具显式调用，如 `Agent(subagent_type="structure-architect", ...)`。
- 或在对话中说明"用 structure-developer 角色实现 X"。

### Cursor
- 将 `.cursor/rules/*.mdc` 拷到目标项目的 `.cursor/rules/` 即可自动加载。
- `developer.mdc` 设置了 `alwaysApply: true`，其他角色按 `globs` 触发。

### Trae
- 将 `.trae/rules/*.md` 拷到目标项目的 `.trae/rules/`；`project_rules.md` 是 Trae 自动识别的入口。
- 可选：在 Trae 设置 → Rules 中粘贴 `prompts/<role>.md` 作为个人规则（不推荐，无法按项目区分）。

### CodeBuddy
- 将 `.codebuddy/rules/*.md` 拷到目标项目的 `.codebuddy/rules/`。
- `developer.md` 设置 `alwaysApply: true`；`architect.md` / `tester.md` 按 `paths` 触发；`reviewer.md` 通过 `@reviewer` 手动调用。
- 项目级规则覆盖用户级同名规则。

### 通义灵码
- 将 `.lingma/rules/*.md` 拷到目标项目的 `.lingma/rules/`。
- 在 Lingma IDE 设置 → 规则 中配置各文件的生效方式：`developer.md` 设为"始终生效"，`architect.md` / `tester.md` 设为"模型决策"或"指定文件生效"，`reviewer.md` 设为"手动引入"。
- 单文件 ≤10000 字符，超出自动截断。

### Codex / 通用 AI Agent
- 将 `codex/AGENTS.md` 拷到业务项目根目录（文件名必须为 `AGENTS.md`）。
- Codex 自动加载：项目级 `./AGENTS.md` > 用户级 `~/.codex/AGENTS.md`；子目录嵌套 `AGENTS.md` 可覆盖。
- 本模板 **自包含**，无需拷贝 `prompts/`。

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