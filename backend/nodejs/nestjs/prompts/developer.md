# NestJS 开发规则

> 适用场景：编写 NestJS/TypeScript 代码时始终生效。

## 硬约束

- TypeScript MUST 使用严格模式（`strict: true`）。
- 所有类 MUST 使用 `@Injectable()` 或对应装饰器。
- 公共方法 MUST 有返回类型注解。
- DTO MUST 使用 `class-validator` 装饰器校验。
- 禁止使用 `any` 类型（除非有充分理由并注释说明）。

## 代码风格

- **MUST** 使用 ESLint + Prettier 统一代码风格。
- **MUST** 文件名：`kebab-case`（如 `user.service.ts`、`create-user.dto.ts`）。
- **MUST** 类名：`PascalCase`（如 `UserService`、`UserController`）。
- **SHOULD** 函数体不超过 50 行。

## Controller 层

```typescript
import { Controller, Get, Post, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

@ApiTags('用户管理')
@Controller('users')
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Post()
  @ApiOperation({ summary: '创建用户' })
  async create(@Body() dto: CreateUserDto): Promise<UserResponseDto> {
    return this.userService.create(dto);
  }

  @Get(':id')
  @ApiOperation({ summary: '获取用户详情' })
  async findOne(@Param('id') id: number): Promise<UserResponseDto> {
    return this.userService.findById(id);
  }

  @Get()
  @ApiOperation({ summary: '分页查询用户' })
  async findAll(@Query() query: UserQueryDto): Promise<PaginatedResponse<UserResponseDto>> {
    return this.userService.findAll(query);
  }
}
```

**Controller 约束**：
- **MUST** 只做路由定义 + 参数提取 + 调用 Service + 返回响应。
- **MUST** 使用 DTO 类（非 interface）作为入参类型。
- **禁止** 在 Controller 中编写业务逻辑。
- **禁止** 直接注入 `DataSource`、`EntityManager`。

## Service 层

```typescript
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  async findById(id: number): Promise<User> {
    const user = await this.userRepo.findOne({ where: { id } });
    if (!user) {
      throw new NotFoundException(`User ${id} not found`);
    }
    return user;
  }

  async create(dto: CreateUserDto): Promise<User> {
    const exists = await this.userRepo.findOne({ where: { email: dto.email } });
    if (exists) {
      throw new ConflictException('邮箱已被注册');
    }
    const user = this.userRepo.create(dto);
    return this.userRepo.save(user);
  }
}
```

**Service 约束**：
- **MUST** 使用 `@Injectable()` 装饰器。
- **MUST** 通过构造器注入依赖。
- **MUST** 使用 NestJS 内置异常类（`NotFoundException`、`BadRequestException` 等）。
- **禁止** 直接操作 `Request`/`Response` 对象。

## Repository 层（TypeORM 模式）

```typescript
// user.repository.ts
@Injectable()
export class UserRepository {
  constructor(
    @InjectRepository(User)
    private readonly repo: Repository<User>,
  ) {}

  async findById(id: number): Promise<User | null> {
    return this.repo.findOne({ where: { id } });
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.repo.findOne({ where: { email } });
  }

  async save(user: User): Promise<User> {
    return this.repo.save(user);
  }
}
```

## Entity 定义

```typescript
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true, length: 32 })
  username: string;

  @Column({ unique: true })
  email: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
```

## DTO 定义

```typescript
import { IsString, IsEmail, MinLength, MaxLength, IsOptional, IsInt, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';

export class CreateUserDto {
  @ApiProperty({ description: '用户名', minLength: 3, maxLength: 32 })
  @IsString()
  @MinLength(3)
  @MaxLength(32)
  username: string;

  @ApiProperty({ description: '邮箱' })
  @IsEmail()
  email: string;
}

export class UserQueryDto {
  @ApiPropertyOptional({ default: 1 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page: number = 1;

  @ApiPropertyOptional({ default: 20 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  pageSize: number = 20;

  @ApiPropertyOptional({ description: '搜索关键词' })
  @IsOptional()
  @IsString()
  keyword?: string;
}
```

## Module 定义

```typescript
@Module({
  imports: [TypeOrmModule.forFeature([User])],
  controllers: [UserController],
  providers: [UserService, UserRepository],
  exports: [UserService],
})
export class UserModule {}
```

## 全局管道注册

```typescript
// main.ts
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,        // 剔除未定义属性
      forbidNonWhitelisted: true,  // 抛出异常
      transform: true,        // 自动类型转换
    }),
  );

  app.enableShutdownHooks();
  await app.listen(3000);
}
```

## 依赖注入

- **MUST** 通过构造器注入（NestJS IOC 容器管理）。
- **禁止** 手动 `new` Service/Repository。
- **禁止** 使用全局变量持有依赖。

## 测试工作流（MUST）

- 每开发一个功能 **立即** 写单元测试，**单测通过才能做下一个功能**。
- 功能有修改时 **同步修改测试** 并通过。
- 业务完成后写 **E2E 测试**，通过才算交付。
- **提交前**：`npm test` 全部通过 + `npm run build` 编译通过。
- **禁止** 测试/编译失败仍提交。

## 提交前自检

- [ ] TypeScript 严格模式开启？
- [ ] 所有 DTO 使用 class-validator 校验？
- [ ] Controller 只做路由定义 + 参数提取 + 调用 Service？
- [ ] Service 使用 NestJS 内置异常类？
- [ ] Module 正确声明 imports/controllers/providers/exports？
- [ ] 全局注册了 ValidationPipe？
- [ ] `npm test` 全部通过？
- [ ] `npm run build` 编译通过？
