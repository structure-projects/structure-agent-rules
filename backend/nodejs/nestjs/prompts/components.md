# NestJS 组件与依赖速查

> 适用场景：NestJS 项目中使用生态组件时的配置参考、最佳实践。

## 核心框架

### @nestjs/common

```typescript
import { Module, Controller, Get, Injectable } from '@nestjs/common';
```

### TypeORM

```typescript
import { TypeOrmModule } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';

// app.module.ts
@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: 'localhost',
      port: 5432,
      username: 'postgres',
      password: 'postgres',
      database: 'mydb',
      entities: [__dirname + '/**/*.entity{.ts,.js}'],
      synchronize: false, // 生产 MUST 为 false
    }),
  ],
})

// 业务模块中使用
@Module({
  imports: [TypeOrmModule.forFeature([User])],
})
export class UserModule {}

// Repository 注入
@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User)
    private userRepo: Repository<User>,
  ) {}
}
```

### Prisma

```typescript
import { PrismaService } from './prisma.service';

// prisma.service.ts
@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  async onModuleInit() { await this.$connect(); }
}

// 使用
@Injectable()
export class UserService {
  constructor(private prisma: PrismaService) {}

  async findById(id: number) {
    return this.prisma.user.findUnique({ where: { id } });
  }
}
```

### class-validator + class-transformer

```typescript
import { IsString, IsEmail, MinLength, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateUserDto {
  @ApiProperty({ description: '用户名' })
  @IsString()
  @MinLength(3)
  username: string;

  @ApiProperty({ description: '邮箱' })
  @IsEmail()
  email: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  phone?: string;
}
```

### @nestjs/swagger

```typescript
// main.ts
const config = new DocumentBuilder()
  .setTitle('My API')
  .setVersion('1.0')
  .addBearerAuth()
  .build();
const document = SwaggerModule.createDocument(app, config);
SwaggerModule.setup('api-docs', app, document);

// Controller
@ApiTags('用户管理')
@Controller('users')
export class UserController {
  @Get(':id')
  @ApiOperation({ summary: '获取用户详情' })
  @ApiResponse({ status: 200, type: UserResponseDto })
  findOne(@Param('id') id: string) {}
}
```

### @nestjs/config

```typescript
import { ConfigModule, ConfigService } from '@nestjs/config';

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true })],
})
export class AppModule {}

// 使用
@Injectable()
export class AppService {
  constructor(private configService: ConfigService) {}

  getPort(): number {
    return this.configService.get<number>('PORT', 3000);
  }
}
```

## NestJS 核心概念

### Guards（守卫 - 认证/授权）

```typescript
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}

@UseGuards(JwtAuthGuard)
@Controller('users')
export class UserController {}
```

### Interceptors（拦截器 - 响应转换）

```typescript
@Injectable()
export class TransformInterceptor<T> implements NestInterceptor<T, Response<T>> {
  intercept(context: ExecutionContext, next: CallHandler): Observable<Response<T>> {
    return next.handle().pipe(map(data => ({ code: 0, data, message: 'success' })));
  }
}
```

### Pipes（管道 - 参数校验/转换）

```typescript
@Injectable()
export class ValidationPipe implements PipeTransform {
  transform(value: any, metadata: ArgumentMetadata) {
    // class-validator 校验
  }
}

// 全局注册
app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
```

### Filters（过滤器 - 异常处理）

```typescript
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    // 统一错误响应
    response.status(status).json({ code: status, message });
  }
}

// 全局注册
app.useGlobalFilters(new AllExceptionsFilter());
```

## 禁止事项

- **禁止** 在 Controller 中直接使用 `DataSource` 或 `EntityManager`。
- **禁止** 绕过 Module 系统直接 new Service。
- **禁止** 生产环境 `synchronize: true`（TypeORM）。
- **禁止** 硬编码配置值。
