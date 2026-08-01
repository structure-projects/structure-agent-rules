# structure-agent-rules

[structure-projects](https://github.com/structure-projects) 开源生态的 **多技术栈 AI 规则集合**。

不写业务代码，产出物是 AI Agent（Cursor / Claude Code / CodeBuddy / Trae / 通义灵码 / Codex）可加载的 **规则 + 技能 + 校验** 三层产物。

## 速览

```bash
# 全栈安装（后端 + 前端 + 通用规则，默认含 skills + hooks）
./install.sh -t ../my-erp -s structure-boot,vue3 -w cursor,codebuddy -c

# 仅后端 + 全部 AI 工具
./install.sh -t ../my-service -s structure-boot -w all -c

# 交互模式
./install.sh -i

# 列出所有可用技术栈
./install.sh --list

# 只要规则，不要 skills/hooks
./install.sh -t ../my-project -s structure-boot -w trae -c --no-skills --no-hooks
```

## 三层架构

安装产物按「声明 → 操作 → 物理拦截」分三层，任意一层失守下一层兜底：

| 层 | 产物 | 作用 | 装载位置 |
|---|---|---|---|
| **L0 规则** | `rules/*.mdc` | 声明式约束（红线/规范），按 globs 自动触发或常驻 | `.cursor/rules/`、`.trae/rules/`、`.claude/agents/` 等 |
| **L1 技能** | `skills/*/SKILL.md` | 接管动作（如 commit/CR/发布），AI 按需调用 | `.trae/skills/`、`.claude/skills/`（cursor/codebuddy/lingma 降级为 Agent Requested） |
| **L2 校验** | `checks/*.sh` | 物理拦截（commit-msg hook），绕过 AI 也拦得住 | `.git/hooks/` |

### commit 三道闸示例

提交代码时三层协同：
1. **L1 `git-commit` skill**：用户说"提交" → AI 调用 skill 按规范生成 message（而非裸 commit）
2. **L0 `git.md` 动作前自检**：规则常驻，AI 执行 git 动作前自检（禁推主干/分支命名/commit 格式）
3. **L2 `commit-msg` hook**：物理兜底，即便绕过 skill 裸 `git commit -m "乱写"` 也被 git 拒绝

## 目录结构

```
structure-agent-rules/
├── AGENTS.md                 # 总索引（技术栈表 + 全栈方案 + 安装说明）
├── README.md                 # 本文件
├── install.sh                # 安装脚本（rules + skills + checks 统一安装）
├── _common/                  # 通用层
│   ├── prompts/              # 12 个详细参考文档（git/命名/安全/架构/测试/文档/版本...）
│   ├── rules/                # 通用规则 mdc（naming 红线常驻 + git 动作类 + 文档/版本按 globs 触发）
│   ├── skills/               # 通用技能（git-commit：接管提交动作）
│   └── checks/               # 物理校验（commit-msg.sh：Conventional Commits 拦截）
├── backend/                  # 后端 → 按语言 → 按框架
├── frontend/                 # 前端 → 按框架
└── cross-platform/           # 跨平台 → 按平台
```

## 安装后目录结构

```
my-project/
├── prompts/                  # 详细参考文档（rules 里引用，AI 按需 Read）
│   ├── _common/              # 通用 12 项（git/naming/security...）
│   └── structure-boot/       # 栈专属（developer/architect/components/tester...）
├── .cursor/rules/            # Cursor: .mdc（globs + alwaysApply + description）
├── .claude/
│   ├── agents/               # Claude: subagents（name + description + tools）
│   └── skills/               # Claude: 原生 SKILL.md
├── .trae/
│   └── rules/                # Trae: .md（保留 frontmatter，globs 触发）
├── .codebuddy/rules/         # CodeBuddy: .md（alwaysApply + globs + description）
├── .lingma/rules/            # 通义灵码: .md（同 CodeBuddy）
├── .git/hooks/               # L2 物理拦截（commit-msg，可执行）
└── AGENTS.md                 # Codex: 合并文件（栈规则 + _common + 技能规程）
```

## 安装参数

| 参数 | 说明 |
|---|---|
| `-t <dir>` | 目标项目目录（必填） |
| `-s <stacks>` | 技术栈，逗号分隔（如 `structure-boot,vue3`） |
| `-w <tools>` | AI 工具，逗号分隔；`all` = cursor,claude,codebuddy,trae,lingma |
| `-c` | 安装 `_common` 通用规则 + prompts + skills |
| `-i` | 交互模式 |
| `--list` | 列出所有可用技术栈 |
| `--no-skills` | 跳过 L1 技能层 |
| `--no-hooks` | 跳过 L2 校验层（目标非 git 仓库时自动跳过） |

## 各 AI 工具触发机制

工具机制差异已由 `install.sh` 自动适配，各工具规则均保留 frontmatter 触发信息：

| 工具 | rule 触发 | skill 触发 | codex |
|---|---|---|---|
| Cursor | globs Auto Attached（编辑对应文件自动加载） | Agent Requested（@ 调用） | — |
| Claude Code | description 匹配（/agent 调用或自动选择） | 原生 SKILL.md | — |
| Trae | globs 触发（需手动开 AGENTS.md/CLAUDE.md 开关） | 原生 SKILL.md | — |
| CodeBuddy | globs 触发 | description + alwaysApply:false | — |
| 通义灵码 | globs 触发 | description + alwaysApply:false | — |
| Codex | — | — | AGENTS.md 常驻（栈规则 + _common + 技能规程章节） |

> ⚠️ **Trae 用户必读**：AGENTS.md / CLAUDE.md 默认不进上下文，安装后需到「设置 > 规则 > 导入设置」打开开关，否则规则不生效。

## 已完成的规则

> 全部 27 个技术栈目录已建立（见 [AGENTS.md](AGENTS.md) 技术栈表）。下表为内容完整的旗舰栈；其余栈为轻量/补充中，深度不均。

| 技术栈 | 说明 |
|---|---|
| `backend/java/structure-boot/` | structure-projects Spring Boot 开发约束（旗舰，最完整） |
| `frontend/vue3/` | Vue 3 + Element Plus + wujie 前端规范 |

## 设计原则

1. **三层分离**：规则（声明）+ 技能（动作）+ 校验（拦截），各司其职、互相兜底
2. **自包含**：每个技术栈目录独立可用，不依赖 `_shared/`
3. **前缀命名**：IDE 包装文件名带技术栈前缀；技能安装时 `_common` 保持原名，栈技能拼 `<stack>-<skill>`
4. **项目级安装**：规则安装到目标项目各 AI 工具目录，不全局污染
5. **单一模板源**：`rules/*.mdc` 为唯一模板，`install.sh` 按工具格式自动派生（保留 frontmatter 触发信息）
6. **可扩展**：占位目录按需补充，`install.sh` 自动发现

## 贡献

占位技术栈（标记 📋）欢迎补充。参考已有完整目录的结构创建。

- 新增技能：在 `_common/skills/` 或 `<stack>/skills/` 下建 `SKILL.md`（frontmatter: name/description/allowed-tools）
- 新增校验：在 `_common/checks/` 下建 `<hook-name>.sh`（commit-msg/pre-push/pre-commit）
- `install.sh` 会自动发现并安装
