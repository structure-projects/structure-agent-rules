# structure-agent-rules

> [structure-projects](https://github.com/structure-projects) 开源生态的 **AI 规则与提示词工程** 仓库。
> 让 Claude Code / Cursor / Trae / CodeBuddy / 其他 AI 在生态内做 **设计、开发、测试、评审** 时遵循统一规范。

**这不是业务代码仓库**。本仓库的产出物是 Markdown 规则、Agent 提示词、生态说明文档。

## 生态坐标（AI 必须正确使用）

| 维度 | 值 |
|---|---|
| GitHub 组织 | [`structure-projects`](https://github.com/structure-projects) |
| 官网 | [www.structured.cn](https://www.structured.cn) |
| Maven `groupId` | `cn.structured` |
| npm scope | `@structure-projects` |
| 包名约定 | `cn.structure.*`（无 d，仅 `structure-common` / `structure-infra` 等底层库） vs `cn.structured.*`（有 d，其余全部） |

## 仓库结构

```
structure-agent-rules/
├── README.md                        # 本文
├── CLAUDE.md                        # 生态事实库（版本、包名、组件图谱、已知不一致）
├── AGENTS.md                        # 规则索引 + 维护约定
│
├── prompts/                         # ⭐ 规则正文（single source of truth，工具无关）
│   ├── architect.md                 #   架构/设计约束
│   ├── developer.md                 #   开发约束
│   ├── tester.md                    #   测试约束
│   ├── reviewer.md                  #   评审约束
│   ├── project-scaffolding.md       #   项目创建约束
│   └── components.md                #   各组件使用与配置速查
│
├── .claude/agents/                  # Claude Code subagent 包装（含 frontmatter）
│   └── architect / developer / tester / reviewer.md
│
├── .cursor/rules/                   # Cursor 规则包装（.mdc 格式，含 globs / alwaysApply）
│   └── architect / developer / tester / reviewer.mdc
│
├── .trae/rules/                     # Trae IDE 规则（project_rules.md 入口 + 4 个角色速查）
│   ├── project_rules.md             #   ⭐ Trae 项目规则入口（Trae 识别此文件名）
│   └── architect / developer / tester / reviewer.md
│
├── .codebuddy/rules/                # CodeBuddy 规则（含 frontmatter：alwaysApply / paths）
│   └── architect / developer / tester / reviewer.md
│
├── .lingma/rules/                   # 通义灵码规则（每文件 ≤10000 字符）
│   └── architect / developer / tester / reviewer.md
│
└── codex/                           # Codex / 通用 AI Agent 模板
    └── AGENTS.md                    #   ⭐ 自包含业务项目规则（拷到业务项目根目录使用）
```

**核心原则**：`prompts/` 是 **single source of truth**。`.claude/agents/` / `.cursor/rules/` / `.trae/rules/` / `.codebuddy/rules/` / `.lingma/rules/` 是其 **格式包装**，仅含 frontmatter（如适用）+ 关键规则内联摘要 + 指向 `prompts/` 的指针。**修改规则永远先改 `prompts/`**。

**例外**：`codex/AGENTS.md` 是 **自包含业务项目模板**，包含业务项目所需全部 MUST 级规则，可在没有 `prompts/` 的情况下独立使用。修改 `prompts/developer.md` 中 MUST 级规则时需同步此文件。

## 在不同工具中配置规则

### 1. Claude Code

#### 方式 A：作为工作仓库直接使用（推荐用于规则维护者）

```bash
git clone <本仓库>
cd structure-agent-rules
claude
```

Claude Code 会自动加载根目录的 `CLAUDE.md`；通过 `Agent` 工具可调用 `structure-architect` / `structure-developer` / `structure-tester` / `structure-reviewer` 四个 subagent。

#### 方式 B：把 subagent 安装到目标业务项目（推荐用于业务开发）

```bash
# 在业务项目中
mkdir -p .claude/agents
cp /path/to/structure-agent-rules/.claude/agents/*.md .claude/agents/
# 同时复制 canonical 规则（subagent 内部会引用）
cp -r /path/to/structure-agent-rules/prompts ./prompts
cp /path/to/structure-agent-rules/CLAUDE.md ./STRUCTURE_RULES.md  # 改名避免覆盖项目自身 CLAUDE.md
```

⚠️ subagent 文件中有 `Read prompts/<role>.md` 的指令，所以 `prompts/` 目录必须与 `.claude/agents/` 处于同一层级。

#### 方式 C：在项目 `CLAUDE.md` 中引用（轻量）

在业务项目的 `CLAUDE.md` 顶部加入：

```markdown
# 项目规则

本项目遵循 structure-projects 生态规范。
在开始任何任务前，先 Read 以下文件并视为约束：
- /path/to/structure-agent-rules/CLAUDE.md
- /path/to/structure-agent-rules/prompts/developer.md（编码任务）
- /path/to/structure-agent-rules/prompts/reviewer.md（评审任务）
```

### 2. Cursor

#### 方式 A：项目级规则（推荐）

```bash
# 在业务项目中
mkdir -p .cursor/rules
cp /path/to/structure-agent-rules/.cursor/rules/*.mdc .cursor/rules/
cp -r /path/to/structure-agent-rules/prompts ./prompts  # 供 .mdc 内部引用
```

Cursor 启动时自动加载 `.cursor/rules/*.mdc`：
- `developer.mdc` 设置了 `alwaysApply: true`（**每次对话都生效**）
- 其他三个按 `globs` 文件模式触发（如 `tester.mdc` 只在写测试时生效）

#### 方式 B：手动 @ 引用

在 Cursor 对话框中输入 `@`，选择 `prompts/developer.md` 等文件加入上下文。

#### 方式 C：User Rules（全局，跨项目）

Cursor 设置 → General → Rules for AI，把 `prompts/developer.md` 全文粘贴进去。**不推荐** —— 无法按项目区分，且更新滞后。

### 3. Trae（字节跳动）

Trae 项目级规则位于 **`.trae/rules/`**，自动识别 `project_rules.md` 作为入口。

#### 方式 A：项目级规则（推荐）

```bash
# 在业务项目中
mkdir -p .trae/rules
cp /path/to/structure-agent-rules/.trae/rules/*.md .trae/rules/
cp -r /path/to/structure-agent-rules/prompts ./prompts  # 供规则文件内部引用
```

本仓库已提供：
- `.trae/rules/project_rules.md` — **Trae 自动识别的入口**，包含使用前必读指引 + 生态硬约束 + 关键规则速查
- `.trae/rules/{architect,developer,tester,reviewer}.md` — 各角色速查版

#### 方式 B：个人规则（全局）

Trae 侧边栏 → 设置 → Rules，把 `prompts/developer.md` 全文粘贴为个人规则。**不推荐** —— 无法按项目区分。

### 4. CodeBuddy（腾讯）

CodeBuddy 项目级规则位于 **`.codebuddy/rules/`**，支持 frontmatter 控制加载行为，递归加载子目录。

#### 方式 A：项目级规则（推荐）

```bash
# 在业务项目中
mkdir -p .codebuddy/rules
cp /path/to/structure-agent-rules/.codebuddy/rules/*.md .codebuddy/rules/
cp -r /path/to/structure-agent-rules/prompts ./prompts  # 供规则文件内部引用
```

本仓库已提供 4 个角色文件，frontmatter 已配好：
- `developer.md` — `alwaysApply: true`（**每次对话与内联请求都生效**）
- `architect.md` — `alwaysApply: false` + `paths: "**/*.md,**/pom.xml"`（设计场景触发）
- `tester.md` — `alwaysApply: false` + `paths: "**/test/**,**/*Test.java,**/*IT.java"`（写测试时触发）
- `reviewer.md` — `alwaysApply: false` + `paths: "**/*.md"`（评审场景触发，或通过 `@reviewer` 手动调用）

#### CodeBuddy 规则触发类型

| 类型 | 何时生效 | 本仓库哪个文件用了 |
|---|---|---|
| Always | 每次对话与内联请求 | `developer.md` |
| Agent Requested | Agent 根据任务描述决定引用 | `architect.md` / `tester.md` |
| Manual | 通过 `@RuleName` 手动调用 | `reviewer.md` |

#### 加载优先级

项目级 `.codebuddy/rules/*.md` > 用户级 `~/.codebuddy/rules/*.md` > 插件级。**同名时项目级覆盖**。

详细文档：[CodeBuddy .codebuddy 目录结构](https://www.codebuddy.ai/docs/zh/cli/codebuddy-dir)

### 5. 通义灵码（阿里）

通义灵码项目专属规则位于 **`.lingma/rules/`**，**每个规则文件最大 10000 字符**（超出自动截断）。

#### 方式 A：项目级规则（推荐）

```bash
# 在业务项目中
mkdir -p .lingma/rules
cp /path/to/structure-agent-rules/.lingma/rules/*.md .lingma/rules/
cp -r /path/to/structure-agent-rules/prompts ./prompts  # 供规则文件内部引用
```

本仓库已提供 4 个角色文件，均为 ≤10000 字符的精简版。

#### 通义灵码规则类型（在 Lingma IDE 设置中配置）

| 类型 | 生效方式 | 本仓库建议使用 |
|---|---|---|
| **始终生效** | 智能会话与行间会话所有请求 | `developer.md` |
| **模型决策** | 描述期望生效的场景，由模型判断 | `architect.md` / `tester.md` |
| **指定文件生效** | 按文件路径通配符（如 `src/*.java`） | `tester.md`（可配 `**/test/**`） |
| **手动引入** | 通过 `@rule` 手动调用 | `reviewer.md` |

#### 限制与适用场景

- ✅ 智能问答场景、AI 程序员场景
- ❌ 代码行间补全、`/指令`、Commit Message 触发的操作
- 单文件 ≤10000 字符，自然语言描述，不支持图片/链接解析

#### 团队协作

```gitignore
# 个人规则（不提交）
.lingma/rules_local.json
# 临时生成文件（不提交）
.lingma/generated
```

`.lingma/rules/` 目录本身 **建议提交版本库**，实现团队规则统一。

详细文档：[通义灵码项目专属规则配置与使用](https://help.aliyun.com/zh/lingma/qoder-cn/user-guide/rules)

### 6. Codex（OpenAI）/ 通用 AI Agent

OpenAI Codex CLI 与其他遵循 [agents.md](https://agents.md) 开放标准的 AI Agent（Google Jules、Amp、Factory 等），**自动加载项目根目录的 `AGENTS.md`**。

#### 业务项目接入（推荐）

把本仓库的 `codex/AGENTS.md` 模板拷到业务项目根目录：

```bash
# 在业务项目根目录
cp /path/to/structure-agent-rules/codex/AGENTS.md ./AGENTS.md
```

Codex 启动时自动加载 `./AGENTS.md`（项目级），叠加 `~/.codex/AGENTS.md`（用户级），子目录嵌套 `AGENTS.md` 可进一步覆盖。

#### 模板特点

`codex/AGENTS.md` 是 **自包含** 的业务项目规则：
- 包含全部 MUST 级硬规则（生态硬约束 / 模块布局 / 持久化 / POJO / 异常响应 / 命名 / 用户上下文 / 数据权限 / 事件 / 多租户 / 前端 / 测试 / 提交前自检）
- **不依赖 `prompts/`** —— 即使业务项目没有拷贝 `prompts/` 目录也能用
- 末尾保留指向 `prompts/` 的引用（如能访问 structure-agent-rules 仓库，可查更详细规则）

#### 何时更新模板

`codex/AGENTS.md` 与 `prompts/developer.md` 内容有重叠。修改 `prompts/developer.md` 中的 MUST 级规则时，**需同步更新 `codex/AGENTS.md`**（这是唯一需要双写的文件）。

### 7. 其他 AI（GPT / 通义 / 文心 / 自建 Agent）

这些工具没有"项目规则目录"概念，直接使用 `prompts/` 内容：

| 场景 | 用法 |
|---|---|
| ChatGPT / 自定义 GPT | 把 `prompts/developer.md` 全文作为 Instructions / System Prompt |
| Claude.ai Projects | 把 `prompts/` 整个目录加入 Project Knowledge |
| 通义 / 文心 / Gemini | 把 `prompts/<role>.md` 全文粘贴到对话开头，或加入"知识库 / 记忆"功能 |
| 自建 Agent | 把 `prompts/<role>.md` 作为 system prompt；`CLAUDE.md` 作为生态事实库注入 |

## 选择合适的规则文件

| 任务类型 | 使用的规则文件 |
|---|---|
| 选型、模块划分、API 设计 | `prompts/architect.md` |
| 新建项目 / 新模块 | `prompts/project-scaffolding.md` + `prompts/architect.md` |
| 写业务代码 | `prompts/developer.md` |
| 查某组件怎么用（security / datascope / gateway / wujie 等） | `prompts/components.md` |
| 写 DTO 参数校验（分组验证、级联、自定义注解） | `prompts/validation.md` |
| 写 API 文档（springdoc-openapi） | `prompts/swagger.md` |
| 配 GitHub 流水线 / 发布（ACR / Maven Central / npm） | `prompts/ci-cd.md` |
| 写测试 | `prompts/tester.md` |
| PR 评审 / 设计评审 | `prompts/reviewer.md` |
| 查生态事实（版本、包名、组件清单、已知不一致） | `CLAUDE.md` |

## 生成错误时如何修正规则

AI 生成错误代码时，**不要急着改代码，先判断是规则问题还是 AI 没遵守规则**。按以下流程处理：

### 第 1 步：诊断错误类型

| 错误现象 | 可能的根因 | 验证方法 |
|---|---|---|
| 规则中没覆盖 | **规则缺失** | `grep` 关键词在 `prompts/` 中找不到 |
| 规则写了但描述笼统（如"合理使用工具类"） | **规则模糊** | 读规则文本，看是否含具体的类名/方法名/包名 |
| 规则写的与真实代码不一致 | **规则错误** | 打开业务仓库源码核对 |
| 同一件事在两个规则文件说法矛盾 | **规则冲突** | `grep` 同一关键词在多个文件中的表述 |
| 规则存在且正确，但 AI 没读到 | **未加载** | 问 AI "你读过 X 文件吗？" 或检查工具的加载配置 |
| 规则正确且已加载，AI 仍不遵守 | **模型能力 / 上下文溢出** | 简化上下文、把关键规则 inline 到对话中 |

### 第 2 步：定位要修改的文件

| 错误类型 | 修改文件 |
|---|---|
| 包名 / groupId / npm scope / 版本号错 | `CLAUDE.md`（生态事实库） |
| 组件 API 用错（如 `UserContext` / `DataScopeStreamBridge` / `RepositoryFacade` 用法） | `prompts/components.md` |
| 通用编码约束（异常/响应/命名/注入/持久化路径） | `prompts/developer.md` |
| 模板选型 / 模块依赖方向 / DDD 分层 | `prompts/architect.md` |
| 新项目结构 / 初始提交物 | `prompts/project-scaffolding.md` |
| 测试覆盖率 / Mock 策略 / 集成测试 | `prompts/tester.md` |
| 评审漏判 / 误判 | `prompts/reviewer.md` |

### 第 3 步：修改规则（**先改 `prompts/`，再同步包装**）

```bash
# 1. 修改 canonical
vim prompts/developer.md

# 2. 评估是否需要同步包装文件的内联摘要
#    原则：只有"关键规则变化"才需要同步包装
#    细节补充只需留在 prompts/ 即可（包装会指引 AI 去读 prompts/）
vim .claude/agents/developer.md
vim .cursor/rules/developer.mdc

# 3. 如果是新角色或新文档，登记到 AGENTS.md 索引
vim AGENTS.md
```

### 第 4 步：验证规则生效

1. **新开一个对话**（避免旧上下文干扰）。
2. 用 **同样的提示词** 让 AI 重新生成代码。
3. 检查错误是否消失；如果错误变种出现，回到第 1 步。

### 常见错误模式与修正示例

**例 1：AI 写出了 `cn.structure.security.util.SecurityUtils`（错包名）**

- 诊断：规则错误 / 规则未加载
- 修正：检查 `CLAUDE.md` 的"包名硬约定"是否明确 `structure-security` 是 `cn.structured.security`（有 d）。若已写明，则属"未加载"—— 检查工具的配置。

**例 2：AI 在 Service 中注入了 `Mapper`**

- 诊断：规则存在但 AI 未遵守
- 修正：在 `prompts/developer.md` 的"持久化"章节确认"禁止在 Service/Controller 中注入 Mapper/PO"是 **MUST** 级别且位置靠前。如果仍不遵守，考虑在 `.claude/agents/developer.md` 的内联摘要中也加这一条（提高被读到的概率）。

**例 3：AI 用了过时的 `structure-cloud-dependencies`**

- 诊断：规则错误（文档滞后）
- 修正：在 `prompts/components.md` 顶部"已弃用"清单登记；在 `prompts/developer.md` 加 🚫 禁止条款；同步更新 `CLAUDE.md` 的组件图谱。

**例 4：AI 写的代码与某个真实仓库不一致**

- 诊断：规则基于过时 README，而非真实代码
- 修正：**先读真实代码**（不要凭记忆/凭 README），把验证过的模式写进 `components.md`，并在 `CLAUDE.md` 的"已知不一致"清单登记该仓库 README 滞后。

## 维护约定（给规则维护者）

1. **`prompts/` 是 single source of truth**。修改规则永远先改 `prompts/`，再评估包装文件是否需同步。
2. **强制级别统一用 RFC 2119**：`MUST`（违反即打回）/ `SHOULD`（建议但可不遵守）/ `MAY`（可选）。**禁止**用"应该 / 可以 / 最好"等模糊词。
3. **引用生态事实**（版本、包名、类名）时以 `CLAUDE.md` 为准；发现与实际仓库不符时**先更新 CLAUDE.md 再扩散**。
4. **发现"文档与代码不一致"**时，在 `CLAUDE.md` 的"已知不一致"清单登记，并在相关规则中加 ⚠️ 警示。
5. **新规则尽量给出"已验证"依据**：在规则旁标注"已在 structure-user / structure-org 真实代码验证"或"来自 structure-infra 源码 `path/to/File.java`"。
6. **新增角色 / 新文档**：
   - 先在 `prompts/` 建正文
   - 再生成 `.claude/agents/` 与 `.cursor/rules/` 包装
   - 最后回 `AGENTS.md` 登记到索引表

## FAQ

**Q：AI 没遵守规则怎么办？**

按"生成错误时如何修正规则"章节的流程诊断。最常见的原因是 **规则没有被加载到上下文**：Claude Code 检查 `.claude/agents/` 位置；Cursor 检查 `.cursor/rules/*.mdc` 的 `alwaysApply` / `globs`；其他工具检查是否粘贴到了 system prompt。

**Q：规则太多，AI 看不完怎么办？**

- 关键规则 inline 到 `.claude/agents/<role>.md` 和 `.cursor/rules/<role>.mdc` 的摘要区（这些是 AI 必读）。
- 细节放 `prompts/<role>.md` 和 `prompts/components.md`，让 AI 按需 Read。
- 每次任务只加载相关角色的规则，不要一次性加载全部。

**Q：如何验证规则生效了？**

- 问 AI："你读过 `prompts/developer.md` 吗？第 X 节讲了什么？"
- 给 AI 一个**故意违反规则的代码片段**让它评审，看是否能识别出违反点。

**Q：规则与业务项目的既有规范冲突怎么办？**

业务项目的本地规范 **优先于** 本仓库的生态规范。在业务项目的 `CLAUDE.md` / `.cursor/rules/` 中显式声明覆盖关系，例如："本项目因历史原因沿用 Manager 模式，暂不切换到 RepositoryFacade"。

**Q：我可以提交新规则吗？**

欢迎。提交流程：
1. Fork 本仓库，在 `prompts/` 下新增/修改规则
2. 在 PR 描述中说明：规则约束的行为、依据（源码路径或真实仓库验证）、强制级别（MUST/SHOULD/MAY）
3. 如涉及包装文件同步，一并修改 `.claude/agents/` 与 `.cursor/rules/`

## 许可证

Apache License 2.0
