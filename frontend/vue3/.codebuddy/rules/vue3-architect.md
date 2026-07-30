---
description: Vue 3 前端架构规则。涉及选型、组件分层时由 Agent 引用。
paths:
  - "**/vite.config.ts"
  - "**/router/**"
  - "**/stores/**"
  - "**/main.ts"
---

# Vue 3 前端架构

> 完整见 `prompts/architect.md`

- **微前端**：wujie，`structure-portal` 基座
- **组件分层**：L1 npm / L2 本地 file: / L3 页面内
- **状态管理**：Pinia Setup Store，按领域拆分
- **CSS**：UnoCSS 原子类 + `<style scoped>` 补充
- **构建**：Vite + TS strict
