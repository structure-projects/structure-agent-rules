---
alwaysApply: true
description: Vue 3 前端开发规则。每次对话与内联请求都生效。
---

# Vue 3 前端开发规则

> 完整规则见 `prompts/developer.md`；组件用法见 `prompts/components.md`；新建项目见 `prompts/project-scaffolding.md`；流水线见 `prompts/ci-cd.md`。本文件为 CodeBuddy 速查版。

## 硬约束
- npm scope **MUST** `@structure-projects`（公开包）
- **MUST** Vue 3 + Vite + TypeScript + Pinia + Element Plus + UnoCSS + wujie-vue3
- **MUST** `*-ui` private:true；`*-ui-components` `file:` 开发 → npm 发布

## 组件
- `@structure-projects/components` 按需命名导入（非 Vue 插件）；element-plus external
- `<script setup lang="ts">` + Props/Emits TS 类型

## 微前端
- 子应用入口 `createWujieSubapp().init()`
- `structure-portal` 为基座

## 请求
- HTTP 用 `@structure-projects/gateway-client` 的 `request`
- **禁止** 直接用 axios/fetch

## 样式
- UnoCSS 原子类为默认；禁止内联 style

## 测试工作流（MUST）
- 每功能立即写单测，通过才做下一个
- 功能改时同步改测试
- 业务完写 E2E
- 提交前 `npm run test` + `npm run build` 全通过
- **禁止** 测试/编译失败仍提交
