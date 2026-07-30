# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 本仓库的定位

`structure-agent-rules` 是 [structure-projects](https://github.com/structure-projects) 开源生态的 **AI 规则与提示词工程仓库**。

## Express 技术栈概览

Express 是 Node.js 最流行的 Web 框架，以中间件模式和庞大的生态系统著称。

### 核心依赖

| 依赖 | 用途 |
|---|---|
| `express` | Web 框架 |
| `helmet` | 安全头 |
| `cors` | 跨域 |
| `express-rate-limit` | 限流 |
| `sequelize` / `prisma` / `mongoose` | ORM/ODM |
| `express-validator` | 请求校验 |
| `jsonwebtoken` + `express-jwt` | JWT 认证 |
| `winston` / `pino` | 日志 |
| `swagger-jsdoc` + `swagger-ui-express` | API 文档 |
| `jest` + `supertest` | 测试 |

### 项目结构

```
src/
├── index.js             # 入口
├── app.js               # Express app 创建与中间件注册
├── routes/              # express.Router() 路由定义
├── controllers/         # 控制器 (req, res, next)
├── services/            # 业务逻辑
├── models/              # Sequelize/Mongoose Models
├── middlewares/         # 中间件
├── validators/          # express-validator schemas
├── config/              # 配置
└── utils/
```

### 中间件模型

Express 中间件是线性执行模型：

```javascript
// 普通中间件 (req, res, next)
app.use((req, res, next) => {
  console.log('before');
  next();
  // next() 之后的代码也会执行（但 res 已发送则无效）
});

// 错误处理中间件（4 个参数，必须放最后）
app.use((err, req, res, next) => {
  res.status(err.status || 500).json({ error: err.message });
});
```

### Express vs Koa

| 特性 | Express | Koa |
|---|---|---|
| 中间件模型 | 线性（callback） | 洋葱模型（async/await） |
| 错误处理 | 4-arg error handler | try-catch + ctx.throw() |
| 内置功能 | 路由、静态文件内置 | 无内置（按需安装） |
| Context | req + res 分离 | ctx 封装 |
| 异步错误 | 需手动 try-catch | 自动冒泡 |

### 本目录文件结构

- `prompts/<role>.md` — 各角色规则 single source of truth
- `.cursor/rules/<role>.mdc` — Cursor 规则包装
- `AGENTS.md` — 规则索引
- `CLAUDE.md` — 本文件
- `codex/AGENTS.md` — Codex 合并规则
