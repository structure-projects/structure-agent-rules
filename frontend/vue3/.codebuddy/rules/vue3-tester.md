---
description: Vue 3 前端测试规则。编写测试时由 Agent 引用。
paths:
  - "**/*.test.ts"
  - "**/*.spec.ts"
  - "**/e2e/**"
---

# Vue 3 前端测试规则

> 完整见 `prompts/tester.md`

单元测试 Vitest + 组件测试 Vue Test Utils + E2E Playwright。每功能立即写单测，提交前全通过。
