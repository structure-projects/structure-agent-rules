# NestJS 架构与设计规则

> 适用场景：NestJS 项目架构设计、模块划分、分层决策、技术选型。

## 硬约束

- Node.js 版本 MUST >= 18（推荐 20 LTS）。
- TypeScript MUST 使用严格模式（`strict: true`）。
- 项目 MUST 使用 NestJS 模块系统组织代码。
- 包管理器 SHOULD 使用 pnpm（Monorepo 场景）或 npm。

## 分层架构（NestJS 三层）

```
Controller（路由层） → Service/Provider（业务层） → Repository（数据层）
          ↓                        ↓
    DTO（入参校验）           Entity（领域模型）
```

- **Controller**：路由定义、请求解析、响应格式化。**禁止**写业务逻辑。
- **Service**：业务逻辑，使用 `@Injectable()` 注入。
- **Repository**：数据访问（TypeORM Repository / Prisma Service）。
- **Module**：组织 Controller + Provider 的容器。

## 目录结构（推荐）

```
project/
├── src/
│   ├── main.ts                    # 入口
│   ├── app.module.ts              # 根模块
│   ├── common/                    # 公共模块
│   │   ├── filters/               # 异常过滤器
│   │   ├── guards/                # 守卫
│   │   ├── interceptors/          # 拦截器
│   │   ├── pipes/                 # 管道（校验）
│   │   └── decorators/            # 自定义装饰器
│   ├── config/                    # 配置模块
│   │   ├── config.module.ts
│   │   └── database.config.ts
│   └── modules/                   # 业务模块
│       └── user/
│           ├── user.module.ts
│           ├── user.controller.ts
│           ├── user.service.ts
│           ├── user.repository.ts
│           ├── dto/
│           │   ├── create-user.dto.ts
│           │   └── user-query.dto.ts
│           └── entities/
│               └── user.entity.ts
├── test/
│   └── app.e2e-spec.ts
├── .env
├── nest-cli.json
├── tsconfig.json
└── package.json
```

## 技术选型（推荐组合）

| 层次 | 推荐方案 | 替代方案 |
|---|---|---|
| 框架 | NestJS | — |
| 语言 | TypeScript（strict） | — |
| ORM | TypeORM | Prisma / MikroORM |
| 校验 | class-validator + class-transformer | zod |
| API 文档 | @nestjs/swagger | — |
| 配置 | @nestjs/config | — |
| 认证 | @nestjs/jwt + @nestjs/passport | — |
| 测试 | Jest + @nestjs/testing | — |
| Monorepo | npm workspaces / Turborepo | Nx |
| 日志 | @nestjs/common Logger / pino | winston |

## NestJS 模块设计

- **MUST** 每个业务模块独立：`UserModule`、`OrderModule` 等。
- **MUST** 使用 `@Module()` 装饰器声明 imports、controllers、providers、exports。
- **SHOULD** 公共功能提取到 `common/` 模块（filters、guards、interceptors、pipes）。
- **禁止** 跨模块直接注入 Service（必须通过 Module 的 exports/imports）。

```typescript
@Module({
  imports: [TypeOrmModule.forFeature([User])],
  controllers: [UserController],
  providers: [UserService],
  exports: [UserService],
})
export class UserModule {}
```

## 装饰器驱动

NestJS 核心依赖装饰器，MUST 正确使用：

| 装饰器 | 用途 | 位置 |
|---|---|---|
| `@Module()` | 定义模块 | 模块类 |
| `@Controller('path')` | 定义控制器路由前缀 | 控制器类 |
| `@Get/@Post/@Put/@Delete/@Patch()` | HTTP 方法 | 控制器方法 |
| `@Injectable()` | 标记可注入 Provider | Service/Guard/Pipe 类 |
| `@Body()/@Param()/@Query()` | 提取请求参数 | 控制器方法参数 |
| `@UseGuards()/@UseInterceptors()/@UsePipes()` | 应用中间件 | 类或方法 |
| `@ApiTags()/@ApiOperation()` | Swagger 文档 | 控制器类/方法 |

## 配置管理

- **MUST** 使用 `@nestjs/config` + `.env` 文件管理配置。
- **MUST** 使用 `ConfigModule.forRoot({ isGlobal: true, envFilePath: '.env' })` 全局注册。
- **MUST** 按环境拆分：`.env.development`、`.env.production`。
- **禁止** 硬编码配置值。

## 错误处理

- **MUST** 使用 NestJS 内置异常类（`HttpException`、`BadRequestException`、`NotFoundException` 等）。
- **SHOULD** 使用全局异常过滤器（`ExceptionFilter`）统一响应格式。
- **禁止** 在 Service 层直接使用 HTTP 异常（应抛业务异常，由过滤器转换）。

## 安全

- **MUST** 启用 `helmet` 安全头。
- **MUST** 启用 CORS 配置（白名单模式）。
- **MUST** 使用 `class-validator` 校验所有入参。
- **SHOULD** 启用 Rate Limiting（`@nestjs/throttler`）。

## 构建与部署

- **MUST** 使用 `nest build` 或 `tsc` 编译 TypeScript。
- **MUST** 使用多阶段 Docker 构建（node:20-alpine）。
- **MUST** 生产环境运行编译后的 `dist/main.js`。
