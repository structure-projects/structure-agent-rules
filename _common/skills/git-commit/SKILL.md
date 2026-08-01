---
name: git-commit
description: "按 Conventional Commits 规范生成提交信息并提交。当用户请求 commit/提交代码/总结变更/提交代码时触发。禁止跳过本技能直接执行裸 git commit。"
allowed-tools: Bash, Read
---

# 规范化提交

> 本技能接管 git commit 动作，确保提交信息符合 Conventional Commits 规范。
> 若已安装 `commit-msg` hook，不合规提交会被 git 物理拦截；本技能在 hook 之前完成校验，避免反复试错。

## 步骤

1. **收集变更**：运行 `git status` 与 `git diff --staged`。
   - 若无可提交内容（staged 为空），提示用户先 `git add`，不要自动 add 全部。
2. **归类 type**：分析变更内容，从白名单选定 type：
   - `feat` 新功能 | `fix` 修复 | `docs` 文档 | `style` 格式 | `refactor` 重构 | `test` 测试 | `chore` 杂务 | `perf` 性能
3. **推断 scope**：按受影响模块/包名推断 scope（小写、可省略）。如 `user`、`auth`、`config`。
4. **撰写 description**：祈使句、现在时、≤50 字、首字母小写（中文无大小写约束）、结尾不加句号。
5. **组装 message**：`<type>(<scope>): <description>`
   - 示例：`feat(user): 新增用户登录接口`
6. **校验**：调用 `scripts/validate-msg.sh` 预校验（若存在）；不通过回到第 3 步修正。
7. **分支检查**：若当前在 `master`/`develop`，拒绝提交并提示切到 `feat-*`/`fix-*` 分支。
8. **提交**：执行 `git commit -m "<message>"`，输出提交结果与 hash。

## body 规范（多行，可选）

若变更较多需 body：

```
<type>(<scope>): <description>

<空行>
- 要点 1
- 要点 2
```

body 用于说明「为什么」改，不是「改了什么」（diff 已说明 what）。

## 禁止

- ❌ 禁止跳过校验直接 `git commit -m "..."`。
- ❌ 禁止在 `master`/`develop` 分支提交。
- ❌ 禁止 message 仅写「修改」「更新」「fix bug」等无信息内容。
- ❌ 禁止自动 `git add -A`（应由用户决定 stage 内容，或征得同意）。

## 关联

- 规则源：`_common/prompts/git.md`「动作前自检」段
- 兜底拦截：`_common/checks/commit-msg.sh`（git commit-msg hook）
- L0 红线：`common-git-redline`（禁推主干、分支命名前缀）
