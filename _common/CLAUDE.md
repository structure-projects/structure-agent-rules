# CLAUDE.md — structure-projects 通用规范

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 通用规范定位

`_common/` 包含所有技术栈共享的**跨切面规范**：Git 分支策略、版本管理、文档管理、命名规范、项目结构等。这些规范在安装时通过 `-c` 选项注入到目标项目，与技术栈规则并行生效。

## 目录结构

```
_common/
├── prompts/                    # 完整规范（单源真实，供人类和 prompts 交叉引用）
│   ├── git.md                  # Git 分支策略与 Commit 规范
│   ├── version-management.md   # 3 段式语义化版本管理
│   ├── documentation.md        # 文档管理规范
│   ├── naming.md               # 通用命名 + Java 注释规范
│   ├── project-structure.md    # 项目结构约定
│   ├── code-review.md          # Code Review 通用原则
│   ├── architecture.md         # 分层架构通用原则
│   ├── api-design.md           # RESTful API 设计原则
│   ├── security.md             # OWASP 安全基线
│   ├── error-handling.md       # 错误处理公约
│   ├── logging.md              # 日志规范
│   └── testing.md              # 测试策略
├── rules/                      # AI 直接加载的紧凑规则（alwaysApply: true）
│   ├── common-git.mdc
│   ├── common-version-management.mdc
│   ├── common-documentation.mdc
│   ├── common-naming.mdc
│   └── common-project-structure.mdc
├── codex/
│   └── AGENTS.md               # Codex 合并规则
└── CLAUDE.md                   # 本文件
```

## 核心通用约束（所有技术栈通用）

### Git 分支策略

- 主分支默认 `master`（替代 `main`）
- 分支模型：`master` → `develop` → `feat-*` / `fix-*` / `release-*` / `hotfix-*`
- **禁止** 直接在 `master` 或 `develop` 上推送代码
- **禁止** `feat-*` 直接合并到 `master`
- **MUST** 已发布的 commit 不可变，不 force push 公共分支

### 版本管理

- `X.Y.Z` 3 段式语义化版本
- X = 架构版本（模块拆分/合并、框架大版本升级）
- Y = 功能版本（新增功能）
- Z = 修复版本（Bug 修复，每次必增）
- 版本号不可重复、不可回退
- 开发阶段使用 `{X}.{Y}.{Z}-SNAPSHOT`

### 文档管理

- `docs/overview.md` + `docs/features/` + `docs/{version}/` + `docs/{version}/changelog/`
- AI 开发前置验证（编码前 MUST 执行）：确认版本号 → 验证设计文档 → 确认交付物
- 设计文档缺失或版本号不明 → 禁止编码
- 每次变更 MUST 写入 changelog

### 命名规范

- 类名 `UpperCamelCase`，方法/变量 `lowerCamelCase`，常量 `UPPER_SNAKE_CASE`
- 数据库 `lower_snake_case`，REST API `kebab-case`
- 禁止拼音、无意义缩写
- Java：每个类 MUST `@author`/`@version`/`@since`，每个 public 方法 MUST JavaDoc

### 项目结构

- `docs/` 目录为强制要求
- 禁止生成代码与手写代码混放
- 禁止提交临时文件、IDE 配置、构建产物
- README 禁止写入超前于代码的内容

## 安装方式

```bash
# 全栈项目（后端 + 前端 + 通用规范）
./install.sh -t ../my-erp -s structure-boot,vue3 -w all -c

# 仅通用规范
./install.sh -t ../my-app -s structure-boot -w cursor -c
```

安装后，通用规范的 `.mdc` 规则会被注入到 `.cursor/rules/`、`.codebuddy/rules/` 等 AI 工具目录，`alwaysApply: true` 确保始终生效。
