# AGENTS.md — structure-projects 通用规范

> 本文件是 **Codex / 通用 AI Agent** 在 structure-projects 业务项目中的通用工作规则。
> 由 [structure-agent-rules](https://github.com/structure-projects/structure-agent-rules) 仓库的 `_common/codex/AGENTS.md` 模板复制而来。
>
> **使用方式**：安装时自动合并到项目 `AGENTS.md`。
> **详细规则**：`prompts/git.md` / `prompts/version-management.md` / `prompts/documentation.md` / `prompts/naming.md` / `prompts/project-structure.md` 等。

---

## 1. Git 分支管理（MUST）

### 分支模型

```
master ──────────────────────── ●(hotfix merge) ──────
  ↑                 ↑          ↑
develop ────●←feat-A─●←feat-B──●←release-1.2.0──●←fix-C──
            ↑        ↑         ↑                 ↑
          feat-A   feat-B   release-1.2.0      fix-C
```

### 分支命名

| 分支 | 用途 | 来源 | 合并目标 | 生命周期 |
|------|------|------|----------|----------|
| `master` | 生产环境稳定代码 | — | — | 永久 |
| `develop` | 开发主分支 | master | — | 永久 |
| `feat-{描述/版本}` | 功能开发 | develop | develop | 合并后删除 |
| `fix-{描述/版本}` | Bug 修复（开发环境） | develop | develop | 合并后删除 |
| `release-{版本号}` | 发布准备 | develop | master + develop | 合并后删除 |
| `hotfix-{版本号}` | 生产热修复 | master | master + develop | 合并后删除 |

### 核心约束

- **禁止** 直接在 `master` 或 `develop` 上推送代码。
- **禁止** 将 `feat-*` 分支直接合并到 `master`（必须经过 `develop`）。
- **禁止** 在生产热修复分支中夹带新功能。
- **禁止** 在未关联版本号的情况下提交代码。
- **MUST** 已发布的 commit 不可变，不 force push 公共分支。
- **MUST** 所有代码合并到 `develop` 前通过 CI 测试。

## 2. 版本管理（MUST）

### 版本格式

`X.Y.Z` 3 段式语义化版本：

| 段位 | 名称 | 自增时机 | 示例 |
|------|------|----------|------|
| **X** | 架构版本 | 架构级别调整（模块拆分/合并、框架大版本升级） | 1 → 2 |
| **Y** | 功能版本 | 新增功能 | 1.0 → 1.1 |
| **Z** | 修复版本 | Bug 修复（每次修复必增） | 1.1.0 → 1.1.1 |

### 核心约束

- **MUST** 版本号不可重复，不可回退。
- **MUST** 每次开发前确认目标版本号（X/Y/Z 哪段自增）。
- **MUST** Y 自增时 Z 归 0；X 自增时 Y 和 Z 归 0。
- **MUST** 开发阶段使用 `{X}.{Y}.{Z}-SNAPSHOT`，发布时去掉 `-SNAPSHOT`。
- **MUST** 分支命名与版本号对应：`feat-1.2.0` 对应功能版本 `1.2.0`。
- **MUST** 发布前检查 `README.md` 是否与当前版本代码一致。
- **禁止** 在 README 过期的情况下发布版本。

## 3. 文档管理（MUST）

### 文档目录结构

```
docs/
├── overview.md                 # 概要设计
├── features/                   # 详细设计
├── {version}/                  # 版本快照
│   └── changelog/
│       ├── 001.md
│       └── ...
└── README.md
```

### AI 开发前置验证（编码前 MUST 执行）

1. **确认目标版本号**：X/Y/Z 哪段自增？
2. **验证设计文档存在**：`docs/features/` 下是否有对应的详细设计文档？
3. **确认预期交付**：从设计文档提取交付物清单并确认。
4. **禁止**在设计文档不存在或版本号不明确的情况下开始编码。

### Changelog 格式（每次变更 MUST 写入）

`docs/{version}/changelog/{序号}.md`：

```markdown
# 变更 #{序号}
- **类型**: feat / fix
- **日期**: YYYY-MM-DD
- **涉及文件**: xxx.java, xxx.sql, ...
- **原始设计**: [引用详细设计文档]
- **变更内容**: 本次修改的具体内容
- **测试结果**: 通过 / 失败 + 影响范围
- **修改人**: xxx
```

### 红线

- **设计文档缺失** → 禁止编码
- **版本号不明** → 禁止编码
- **changelog 未更新** → 禁止提交

## 4. 命名规范

### 通用命名（MUST）

| 元素 | 规范 | 示例 |
|------|------|------|
| 类名/接口名 | `UpperCamelCase` | `UserService`, `OrderRepository` |
| 方法名/变量名 | `lowerCamelCase` | `findById`, `userName` |
| 常量 | `UPPER_SNAKE_CASE` | `MAX_RETRY_COUNT` |
| 包名 | 全小写无分隔符 | `cn.structured.admin.biz.service` |
| 数据库表/字段 | `lower_snake_case` | `user_role`, `created_at` |
| REST API URL | `kebab-case` | `/api/user-roles` |

### Java 注释规范（MUST）

**类头注释**：

```java
/**
 * 用户管理服务实现
 *
 * @author zhangsan
 * @version 1.2.0
 * @since JDK 17 2025-07-31
 */
```

- **MUST** `@version` 与项目版本号同步更新。
- **SHOULD** `@since` 记录首次创建的 JDK 版本与日期。

**方法注释**：每个 public/protected 方法 MUST 包含 `@param` 和 `@return`。

## 5. 项目结构（MUST）

### 文档目录

```
docs/
├── overview.md                 # 概要设计
├── features/                   # 详细设计
├── {version}/                  # 版本快照
└── README.md                   # 文档索引
```

### 禁止事项

- **禁止** 将生成代码与手写代码混放在同一目录。
- **禁止** 在 commit 中包含临时文件、IDE 配置、构建产物。
- **禁止** 在 `README.md` 中写入超前于代码的内容。

---

**详细规则**（如能访问 structure-agent-rules 仓库）：`prompts/git.md` / `prompts/version-management.md` / `prompts/documentation.md` / `prompts/naming.md` / `prompts/project-structure.md`。
