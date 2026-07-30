# Vue 3 前端开发规则

> 本文件为 Trae 项目规则。完整规则见 `prompts/developer.md`。

## 硬约束
- npm scope `@structure-projects`
- Vue 3 + Vite + TS + Pinia + Element Plus + UnoCSS + wujie-vue3
- `*-ui` private:true；`*-ui-components` file: 开发 → npm 发布

## 组件
- `@structure-projects/components` 按需命名导入
- `<script setup lang="ts">` + Props/Emits TS 类型

## 微前端
- 子应用入口 `createWujieSubapp().init()`

## 请求
- `@structure-projects/gateway-client` 的 `request`

## 测试
- 每功能立即写单测，通过才做下一个
- 提交前 `npm run test` + `npm run build` 全通过
