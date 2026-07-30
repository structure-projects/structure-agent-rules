# Vue 3 前端项目脚手架规则

> 面向在 structure-projects 生态中创建 Vue 3 前端项目的 AI Agent。

## 子应用项目（`*-ui`）

### 创建步骤

1. **MUST** 在对应领域项目目录内创建，路径：`structure-{X}/structure-{X}-ui/`
2. **MUST** 技术栈：Vue 3 + Vite 5 + TypeScript 5 + Pinia + Vue Router 4 + Element Plus 2 + UnoCSS + wujie-vue3
3. **MUST** `package.json` 配置：

```json
{
  "name": "@structure-projects/{领域}-ui",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite --port {端口}",
    "build": "vue-tsc && vite build",
    "preview": "vite preview",
    "test": "vitest",
    "test:e2e": "playwright test"
  }
}
```

### 检查清单

- [ ] `package.json` name `@structure-projects/{领域}-ui`，`private: true`
- [ ] `vite.config.ts` 配置 base、server.proxy、resolve.alias
- [ ] `vite.config.ts` 配置 wujie 子应用 plugin（`build.lib` 模式）
- [ ] `tsconfig.json` strict 模式
- [ ] `uno.config.ts` presetUno + presetAttributify
- [ ] `src/main.ts` 调用 `createWujieSubapp().init()`
- [ ] `src/api/` 封装 gateway-client request
- [ ] `src/router/` 懒加载路由
- [ ] `src/stores/` Pinia Setup Store 语法

### 端口约定

开发端口按以下规则分配：

| 领域 | 端口 |
|---|---|
| user | 17102 |
| org | 17104 |
| resource | 17106 |
| tenant | 17108 |
| 其他 | 171XX |

### 代理配置

```ts
// vite.config.ts
server: {
  port: 171XX,
  proxy: {
    '/api': { target: 'http://localhost:181XX', changeOrigin: true }
  }
}
```

## 组件库项目（`*-ui-components`）

### 创建步骤

1. **MUST** 路径：`structure-{X}/structure-{X}-ui-components/`
2. **MUST** 技术栈同子应用
3. **MUST** `package.json` 配置：

```json
{
  "name": "@structure-projects/{领域}-ui-components",
  "private": false,
  "main": "./dist/index.js",
  "module": "./dist/index.mjs",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "import": "./dist/index.mjs",
      "require": "./dist/index.js",
      "types": "./dist/index.d.ts"
    }
  },
  "scripts": {
    "dev": "vite build --watch",
    "build": "vue-tsc && vite build",
    "prepublishOnly": "npm run build"
  }
}
```

### 开发时引用方式

在 `structure-{X}-ui/package.json` 中：

```json
{
  "dependencies": {
    "@structure-projects/{领域}-ui-components": "file:../structure-{X}-ui-components"
  }
}
```

配合 Vite alias：

```ts
// vite.config.ts
resolve: {
  alias: {
    '@structure-projects/{领域}-ui-components': 
      path.resolve(__dirname, '../structure-{X}-ui-components/src')
  }
}
```

### 发布前切换

正式发布前从 `file:` 改为版本号：

```json
{
  "dependencies": {
    "@structure-projects/{领域}-ui-components": "^1.0.0"
  }
}
```

## 禁止事项

- **禁止** 将 `*-ui` 发布到 npm（private: true）
- **禁止** 在 `*-ui` 中 `file:` 引用其他子应用（只能引用同领域的 `*-ui-components`）
- **禁止** 跨领域 `file:` 引用组件库（通过 npm 发布后的 `@structure-projects/{领域}-ui-components` 引用）
- **禁止** 在子应用中单独安装 Element Plus 主题包（由 Portal 统一提供）
