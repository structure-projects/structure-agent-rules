# AGENTS.md — NestJS 项目规则

> 本文件是 **Codex / 通用 AI Agent** 在 NestJS 项目中的工作规则。
> **详细规则**：`prompts/developer.md` / `prompts/architect.md` / `prompts/components.md` / `prompts/tester.md` / `prompts/reviewer.md` / `prompts/validation.md` / `prompts/swagger.md` / `prompts/ci-cd.md`。

---

## 1. 硬约束

- Node.js >= 18（推荐 20 LTS），TypeScript 严格模式。
- 所有 Provider MUST `@Injectable()`。
- DTO MUST 是 class（非 interface），使用 class-validator。
- 禁止 `any` 类型。

## 2. 模块布局

```
src/
├── main.ts              # 入口，全局注册
├── app.module.ts        # 根模块
├── common/              # filters, guards, interceptors, pipes, decorators
├── config/              # 配置模块
└── modules/             # 业务模块
    └── user/
        ├── user.module.ts
        ├── user.controller.ts
        ├── user.service.ts
        ├── dto/ + entities/
```

## 3. 关键优先级

- **DI**：构造器注入（NestJS IOC）→ 禁止手动 new
- **异常**：NestJS 内置异常 → 全局 ExceptionFilter → 统一响应
- **校验**：class-validator DTO → ValidationPipe 全局注册

## 4. Controller 规范

```typescript
@ApiTags('用户管理')
@Controller('users')
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Post()
  @ApiOperation({ summary: '创建用户' })
  async create(@Body() dto: CreateUserDto): Promise<UserResponseDto> {
    return this.userService.create(dto);
  }
}
```

- **MUST** 只做路由 + 参数提取 + 调用 Service + 返回响应
- **MUST** 使用 class DTO 作为入参
- **禁止** 写业务逻辑、直接注入 DataSource

## 5. Service 规范

```typescript
@Injectable()
export class UserService {
  constructor(@InjectRepository(User) private userRepo: Repository<User>) {}

  async findById(id: number): Promise<User> {
    const user = await this.userRepo.findOne({ where: { id } });
    if (!user) throw new NotFoundException(`User ${id} not found`);
    return user;
  }
}
```

- **MUST** `@Injectable()` + 构造器注入
- **MUST** 使用 NestJS 内置异常类
- **禁止** 直接操作 Request/Response

## 6. DTO 校验

```typescript
export class CreateUserDto {
  @ApiProperty({ minLength: 3, maxLength: 32 })
  @IsString() @MinLength(3) @MaxLength(32)
  username: string;

  @ApiProperty()
  @IsEmail()
  email: string;
}
```

- **MUST** 全局注册 `ValidationPipe({ whitelist: true, transform: true })`
- **MUST** Query 参数使用 `@Type(() => Number)` 转换

## 7. Module 规范

```typescript
@Module({
  imports: [TypeOrmModule.forFeature([User])],
  controllers: [UserController],
  providers: [UserService],
  exports: [UserService],
})
export class UserModule {}
```

## 8. 持久化

- **MUST** TypeORM `synchronize: false`（生产）
- **MUST** 使用版本化迁移
- **禁止** Controller 直接注入 DataSource

## 9. 安全

- **MUST** 启用 `helmet()`
- **MUST** CORS 白名单（禁止生产 `*`）
- **SHOULD** 启用 `@nestjs/throttler`

## 10. 测试

- 单测：`*.spec.ts`，`Test.createTestingModule` mock 依赖
- E2E：`test/*.e2e-spec.ts`，supertest + 真实数据库
- **MUST** 覆盖率 >= 70%
- **禁止** 僵尸断言、Mock 数据库（E2E）

## 11. 提交前自检

- [ ] TypeScript 严格模式？
- [ ] DTO 使用 class-validator？
- [ ] Module 正确声明 imports/exports？
- [ ] 全局注册了 ValidationPipe？
- [ ] TypeORM synchronize: false？
- [ ] `npm test` + `npm run build` 通过？

---

**详细规则**：`prompts/developer.md` / `prompts/components.md` / `prompts/tester.md` / `prompts/reviewer.md` / `prompts/architect.md` / `prompts/project-scaffolding.md` / `prompts/validation.md` / `prompts/swagger.md` / `prompts/ci-cd.md` / `CLAUDE.md`。
