#!/usr/bin/env bash
# commit-msg hook — 强制 Conventional Commits 规范
# 由 structure-agent-rules 的 install.sh 安装到目标项目 .git/hooks/commit-msg
# 规则源：_common/prompts/git.md「动作前自检」段
set -euo pipefail

msg_file="$1"
msg=$(head -n1 "$msg_file")

# Conventional Commits 正则：<type>(<scope>): <description>
pattern='^(feat|fix|docs|style|refactor|test|chore|perf)(\([a-z0-9_-]+\))?: .{1,100}'

if ! [[ "$msg" =~ $pattern ]]; then
  echo "❌ Commit message 不符合 Conventional Commits 规范:" >&2
  echo "   $msg" >&2
  echo "" >&2
  echo "期望格式: <type>(<scope>): <description>" >&2
  echo "合法 type: feat|fix|docs|style|refactor|test|chore|perf" >&2
  echo "示例:     feat(user): 新增用户登录接口" >&2
  echo "" >&2
  echo "修改后重试: git commit --amend -m \"<type>(<scope>): <描述>\"" >&2
  exit 1
fi

# 禁止在 master/develop 直接提交（放 pre-commit 更合适，此处兜底）
branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
if [[ "$branch" == "master" || "$branch" == "develop" ]]; then
  echo "❌ 禁止直接在 $branch 分支提交，请切到 feat-*/fix-* 分支:" >&2
  echo "   git checkout -b feat-<feature-name>" >&2
  exit 1
fi
