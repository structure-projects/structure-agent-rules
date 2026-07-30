# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 本仓库的定位

`structure-agent-rules` 是 [structure-projects](https://github.com/structure-projects) 开源生态的 **AI 规则与提示词工程仓库**。

## NestJS 技术栈概览

NestJS 是 Node.js 的企业级框架，使用 TypeScript 装饰器模式和模块化架构。本规则适用于 NestJS + TypeORM/Prisma 项目。

### 核心依赖

| 依赖 | 用途 |
|---|---|
| `@nestjs/common`、`@nestjs/core` | 框架核心 |
| `@nestjs/typeorm` + `typeorm` | TypeORM ORM |
| `@prisma/client` | Prisma ORM（替代） |
| `class-validator` + `class-transformer` | DTO 校验 |
| `@nestjs/swagger` | OpenAPI 文档 |
| `@nestjs/config` | 配置管理 |
| `@nestjs/jwt` + `@nestjs/passport` | JWT 认证 |
| `@nestjs/throttler` | 限流 |
| `helmet` | 安全头 |

### 项目结构

```
src/
├── main.ts              # 入口，全局管道/过滤器注册
├── app.module.ts        # 根模块
├── common/              # 公共：filters, guards, interceptors, pipes, decorators
├── config/              # 配置模块
└── modules/             # 业务模块
    └── user/
        ├── user.module.ts
        ├── user.controller.ts
        ├── user.service.ts
        ├── user.repository.ts (可选)
        ├── dto/
        └── entities/
```

### 装饰器驱动的核心模式

NestJS 的一切都围绕装饰器：

- `@Module({ imports, controllers, providers, exports })` — 模块定义
- `@Controller('path')` — 路由前缀
- `@Get()` / `@Post()` / `@Put()` / `@Delete()` — HTTP 方法
- `@Body()` / `@Param()` / `@Query()` — 参数提取
- `@Injectable()` — 标记可注入 Provider
- `@UseGuards()` / `@UseInterceptors()` / `@UsePipes()` — 应用中间件
- `@ApiTags()` / `@ApiOperation()` / `@ApiProperty()` — Swagger 文档

### 关键约束

1. **DTO MUST 是 class**（非 interface），因为装饰器需要运行时元数据
2. **ValidationPipe MUST 全局注册**（`whitelist: true, transform: true`）
3. **Module 系统 MUST 正确使用**：跨模块 Provider 必须 exports/imports
4. **生产环境 TypeORM `synchronize` MUST 为 false**
5. **全局 ExceptionFilter** 统一响应格式

### 依赖注入

NestJS 使用 IOC 容器管理依赖：
- 通过构造器注入
- 使用 `@InjectRepository()` 注入 TypeORM Repository
- 自定义 Provider 使用 `useClass`、`useFactory`、`useValue`

### 本目录文件结构

- **`prompts/<role>.md`** — 各角色规则 single source of truth
- **`.cursor/rules/<role>.mdc`** — Cursor 规则包装
- **`AGENTS.md`** — 规则索引
- **`CLAUDE.md`** — 本文件
- **`codex/AGENTS.md`** — Codex 合并规则
