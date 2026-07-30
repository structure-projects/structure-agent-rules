# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 本仓库的定位

`structure-agent-rules` 是 [structure-projects](https://github.com/structure-projects) 开源生态的 **AI 规则与提示词工程仓库**。

## Koa 技术栈概览

Koa 是 Express 团队打造的轻量级 Node.js Web 框架，以洋葱模型中间件和 async/await 为核心特点。

### 核心依赖

| 依赖 | 用途 |
|---|---|
| `koa` | Web 框架 |
| `koa-router` | 路由 |
| `koa-body` | 请求体解析 |
| `@koa/cors` | CORS |
| `koa-helmet` | 安全头 |
| `sequelize` | ORM |
| `knex` | Query Builder（替代方案） |
| `joi` / `zod` | 数据校验 |
| `koa-jwt` + `jsonwebtoken` | JWT 认证 |
| `pino` / `winston` | 日志 |
| `jest` + `supertest` | 测试 |

### 项目结构

```
src/
├── index.js             # 入口
├── app.js               # Koa app 创建与中间件注册
├── routes/              # koa-router 路由定义
├── controllers/         # 控制器
├── services/            # 业务逻辑
├── models/              # Sequelize Models
├── middlewares/         # 中间件
├── validators/          # Joi/Zod schema
├── config/              # 配置
└── utils/
```

### 洋葱模型中间件

Koa 中间件的执行顺序是洋葱模型：

```javascript
app.use(async (ctx, next) => {
  console.log('1. 进入中间件 1');
  await next();
  console.log('5. 离开中间件 1');
});

app.use(async (ctx, next) => {
  console.log('2. 进入中间件 2');
  await next();
  console.log('4. 离开中间件 2');
});

// 输出顺序：1 → 2 → (route handler) → 4 → 5
```

### 推荐中间件顺序

1. Error Handler（最外层，`try-catch` 所有下游错误）
2. Logger
3. CORS
4. Body Parser（koa-body）
5. Auth（JWT 验证）
6. Routes（业务路由）

### Context（ctx）关键属性

- `ctx.request.body` — 解析后的请求体
- `ctx.params` — 路由参数
- `ctx.query` — URL 查询参数
- `ctx.state` — 中间件间传递数据（如 `ctx.state.user`）
- `ctx.throw(status, message)` — 抛出 HTTP 错误
- `ctx.assert(condition, status, message)` — 条件断言

### Koa vs Express

| 特性 | Koa | Express |
|---|---|---|
| 中间件模型 | 洋葱模型（async/await） | 线性模型（callback） |
| 错误处理 | `try-catch` + `ctx.throw()` | 4-arg error handler |
| 内置功能 | 无（按需安装） | 路由、静态文件等内置 |
| Context | `ctx`（封装 req + res） | `req` + `res`（分离） |
| Response | `ctx.body = data` | `res.json(data)` |

### 本目录文件结构

- **`prompts/<role>.md`** — 各角色规则 single source of truth
- **`.cursor/rules/<role>.mdc`** — Cursor 规则包装
- **`AGENTS.md`** — 规则索引
- **`CLAUDE.md`** — 本文件
- **`codex/AGENTS.md`** — Codex 合并规则
