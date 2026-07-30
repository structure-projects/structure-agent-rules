# Git 规范

> 通用规则，适用范围：所有技术栈和项目类型。

## 分支策略

- **MUST** `main` / `master` 为稳定分支，禁止直接推送。
- **MUST** 功能开发在新分支上进行，命名：`feature/{描述}` 或 `feat/{描述}`。
- **MUST** 修复分支命名：`fix/{描述}` 或 `hotfix/{描述}`。

## Commit 规范

- **MUST** 使用 Conventional Commits 格式：
  ```
  <type>(<scope>): <description>
  ```
- **MUST** type 为以下之一：
  - `feat` — 新功能
  - `fix` — 修复
  - `docs` — 文档
  - `style` — 格式（不影响代码运行）
  - `refactor` — 重构
  - `test` — 测试
  - `chore` — 构建/工具
  - `perf` — 性能优化
- **SHOULD** commit message 使用中文或英文，一个项目内保持一致。

## PR / MR 规范

- **MUST** PR 标题使用 Conventional Commits 格式。
- **MUST** PR 描述包含：变更目的 / 变更内容 / 测试说明。
- **SHOULD** 一个 PR 聚焦一个功能或修复，避免大锅饭式 PR。
