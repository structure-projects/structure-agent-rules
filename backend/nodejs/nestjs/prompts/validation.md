# NestJS 数据校验规则

> 适用场景：NestJS 项目的请求参数校验、DTO 校验、业务校验。

## 硬约束

- **MUST** 使用 `class-validator` + `class-transformer` 进行 DTO 校验。
- **MUST** 全局注册 `ValidationPipe`。
- **MUST** DTO 使用 class（非 interface），因为装饰器需要运行时元数据。
- **禁止** 在 Controller 中手写逐字段校验。

## 全局管道配置

```typescript
// main.ts
app.useGlobalPipes(
  new ValidationPipe({
    whitelist: true,              // 自动剔除未定义的属性
    forbidNonWhitelisted: true,   // 存在未定义属性时抛异常
    transform: true,              // 自动类型转换（Query 参数 String → Number）
    transformOptions: {
      enableImplicitConversion: true,
    },
  }),
);
```

## DTO 校验

```typescript
import {
  IsString, IsEmail, IsInt, Min, Max, MinLength, MaxLength,
  IsOptional, IsEnum, IsNotEmpty, IsBoolean,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';

export enum UserRole {
  ADMIN = 'admin',
  USER = 'user',
  GUEST = 'guest',
}

export class CreateUserDto {
  @ApiProperty({ minLength: 3, maxLength: 32 })
  @IsString()
  @IsNotEmpty()
  @MinLength(3)
  @MaxLength(32)
  username: string;

  @ApiProperty()
  @IsEmail()
  email: string;

  @ApiProperty({ minLength: 8 })
  @IsString()
  @MinLength(8)
  password: string;

  @ApiPropertyOptional({ enum: UserRole })
  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;
}

export class UpdateUserDto {
  @ApiPropertyOptional({ minLength: 3 })
  @IsOptional()
  @IsString()
  @MinLength(3)
  username?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsEmail()
  email?: string;
}

export class UserQueryDto {
  @ApiPropertyOptional({ default: 1 })
  @Type(() => Number)  // Query 参数是 string，需显式转换
  @IsInt()
  @Min(1)
  page: number = 1;

  @ApiPropertyOptional({ default: 20 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  pageSize: number = 20;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  keyword?: string;
}
```

## 常用装饰器速查

| 装饰器 | 用途 |
|---|---|
| `@IsString()` | 字符串类型 |
| `@IsInt()` / `@IsNumber()` | 整数/数字 |
| `@IsBoolean()` | 布尔值 |
| `@IsEmail()` | 邮箱格式 |
| `@IsUrl()` | URL 格式 |
| `@IsEnum(EnumClass)` | 枚举值 |
| `@IsNotEmpty()` | 非空（`''`/`null`/`undefined`） |
| `@IsOptional()` | 可选字段 |
| `@Min(n)` / `@Max(n)` | 最小值/最大值 |
| `@MinLength(n)` / `@MaxLength(n)` | 最小/最大长度 |
| `@Length(min, max)` | 长度范围 |
| `@Matches(/regex/)` | 正则匹配 |
| `@ArrayMinSize(n)` / `@ArrayMaxSize(n)` | 数组最小/最大长度 |
| `@ValidateNested()` | 嵌套对象校验（配合 `@Type()`） |
| `@IsDateString()` | ISO 8601 日期字符串 |
| `@IsUUID()` | UUID 格式 |

## 自定义校验装饰器

```typescript
import { registerDecorator, ValidationOptions, ValidatorConstraint, ValidatorConstraintInterface } from 'class-validator';

@ValidatorConstraint({ async: true })
export class IsEmailUniqueConstraint implements ValidatorConstraintInterface {
  async validate(email: string) {
    // 查询数据库检查邮箱唯一性
    return true;
  }
  defaultMessage() {
    return '邮箱 ($value) 已被注册';
  }
}

export function IsEmailUnique(validationOptions?: ValidationOptions) {
  return function (object: object, propertyName: string) {
    registerDecorator({
      target: object.constructor,
      propertyName,
      options: validationOptions,
      constraints: [],
      validator: IsEmailUniqueConstraint,
    });
  };
}

// 使用
export class CreateUserDto {
  @IsEmail()
  @IsEmailUnique()
  email: string;
}
```

## 校验错误格式化

```typescript
// 自定义异常过滤器
@Catch(BadRequestException)
export class ValidationExceptionFilter implements ExceptionFilter {
  catch(exception: BadRequestException, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse();
    const status = exception.getStatus();
    const exceptionResponse = exception.getResponse() as any;

    const errors = exceptionResponse.message?.map((msg: string) => {
      const [field, ...rest] = msg.split(' ');
      return { field, message: rest.join(' ') };
    }) || [];

    response.status(status).json({
      code: status,
      message: '参数校验失败',
      errors,
    });
  }
}
```

## 业务校验（Service 层）

```typescript
@Injectable()
export class UserService {
  async create(dto: CreateUserDto): Promise<User> {
    const exists = await this.userRepo.findOne({ where: { email: dto.email } });
    if (exists) {
      throw new ConflictException('邮箱已被注册');
    }
    // 创建用户
  }
}
```

## 禁止事项

- **禁止** 仅在前端做校验。
- **禁止** 使用 `interface` 作为 DTO（class-validator 需要运行时元数据）。
- **禁止** `ValidationPipe` 不配置 `whitelist: true`。
- **禁止** 在 Controller 中手写 `if` 逐字段校验。
