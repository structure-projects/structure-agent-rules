# NestJS Swagger/OpenAPI 规则

> 适用场景：NestJS 项目的 API 文档生成（@nestjs/swagger）。

## 硬约束

- **MUST** 使用 `@nestjs/swagger` 生成 OpenAPI 文档。
- **MUST** 每个公开 API 有完整的 Swagger 装饰器。
- **MUST** 所有 DTO 使用 `@ApiProperty()` 描述字段。
- **SHOULD** 生产环境可关闭 Swagger UI。

## main.ts 配置

```typescript
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  const config = new DocumentBuilder()
    .setTitle('My Service API')
    .setDescription('用户管理微服务')
    .setVersion('1.0.0')
    .addBearerAuth(
      { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
      'access-token',
    )
    .addTag('用户管理', '用户 CRUD 操作')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api-docs', app, document, {
    swaggerOptions: { persistAuthorization: true },
  });
}
```

## Controller 注解

```typescript
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';

@ApiTags('用户管理')
@Controller('users')
export class UserController {

  @Post()
  @ApiOperation({ summary: '创建用户', description: '创建新用户并返回用户信息' })
  @ApiResponse({ status: 201, description: '创建成功', type: UserResponseDto })
  @ApiResponse({ status: 400, description: '参数校验失败' })
  @ApiResponse({ status: 409, description: '用户已存在' })
  @ApiBearerAuth('access-token')
  async create(@Body() dto: CreateUserDto): Promise<UserResponseDto> {
    return this.userService.create(dto);
  }

  @Get(':id')
  @ApiOperation({ summary: '获取用户详情' })
  @ApiParam({ name: 'id', type: Number, description: '用户ID' })
  @ApiResponse({ status: 200, type: UserResponseDto })
  @ApiResponse({ status: 404, description: '用户不存在' })
  @ApiBearerAuth('access-token')
  async findOne(@Param('id') id: number): Promise<UserResponseDto> {
    return this.userService.findById(id);
  }

  @Get()
  @ApiOperation({ summary: '分页查询用户' })
  @ApiQuery({ name: 'page', required: false, type: Number, example: 1 })
  @ApiQuery({ name: 'pageSize', required: false, type: Number, example: 20 })
  @ApiQuery({ name: 'keyword', required: false, type: String })
  @ApiResponse({ status: 200, type: PaginatedResponseDto })
  @ApiBearerAuth('access-token')
  async findAll(@Query() query: UserQueryDto) {}
}
```

## DTO 注解

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateUserDto {
  @ApiProperty({
    description: '用户名',
    minLength: 3,
    maxLength: 32,
    example: 'zhangsan',
  })
  username: string;

  @ApiProperty({
    description: '邮箱地址',
    example: 'zhangsan@example.com',
  })
  email: string;

  @ApiPropertyOptional({
    description: '手机号',
    example: '13800138000',
  })
  phone?: string;
}

export class UserResponseDto {
  @ApiProperty({ example: 1 })
  id: number;

  @ApiProperty({ example: 'zhangsan' })
  username: string;

  @ApiProperty({ example: 'zhangsan@example.com' })
  email: string;

  @ApiProperty({ example: '2024-01-01T00:00:00.000Z' })
  createdAt: Date;
}
```

## 分页响应 DTO

```typescript
export class PaginatedResponseDto<T> {
  @ApiProperty({ example: 100 })
  total: number;

  @ApiProperty({ example: 1 })
  page: number;

  @ApiProperty({ example: 20 })
  pageSize: number;

  data: T[];
}
```

## 文件上传

```typescript
import { ApiConsumes, ApiBody } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';

@Post('upload')
@ApiOperation({ summary: '上传文件' })
@ApiConsumes('multipart/form-data')
@ApiBody({
  schema: {
    type: 'object',
    properties: {
      file: { type: 'string', format: 'binary' },
    },
  },
})
@UseInterceptors(FileInterceptor('file'))
async upload(@UploadedFile() file: Express.Multer.File) {}
```

## 禁止事项

- **禁止** 在生产环境默认暴露 Swagger UI。
- **禁止** DTO 缺少 `@ApiProperty` 注解。
- **禁止** 公共 API 缺少 `@ApiBearerAuth` 或 `@ApiSecurity`。
- **禁止** `@ApiResponse` 中 `type` 与实际返回类型不一致。
