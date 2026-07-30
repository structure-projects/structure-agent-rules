# NestJS 测试规则

> 适用场景：编写 NestJS 项目的单元测试和 E2E 测试。

## 测试工作流（MUST）

- 每开发一个功能 **立即** 写单元测试，**单测通过才能做下一个功能**。
- 功能有修改时 **同步修改测试** 并通过。
- 业务完成后写 **E2E 测试**，通过才算交付。
- 覆盖正常 + 异常 + 边界；断言验证行为与数据（**禁止** 僵尸断言）。
- **提交前**：`npm test` 全部通过 + `npm run test:e2e` 通过 + `npm run build` 编译通过。

## 测试分层与命名

| 类型 | 文件 | 说明 |
|---|---|---|
| 单元测试 | `*.spec.ts`（与源文件同目录） | 不启动 NestJS 容器 |
| E2E 测试 | `test/*.e2e-spec.ts` | 启动完整 NestJS 容器 + 真实数据库 |

## 单元测试

```typescript
// user.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserService } from './user.service';
import { User } from './entities/user.entity';
import { NotFoundException, ConflictException } from '@nestjs/common';

describe('UserService', () => {
  let service: UserService;
  let repo: Repository<User>;

  const mockRepo = {
    findOne: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UserService,
        { provide: getRepositoryToken(User), useValue: mockRepo },
      ],
    }).compile();

    service = module.get<UserService>(UserService);
    repo = module.get<Repository<User>>(getRepositoryToken(User));
  });

  afterEach(() => jest.clearAllMocks());

  describe('findById', () => {
    it('should return user when found', async () => {
      const user = { id: 1, username: 'test', email: 'test@example.com' } as User;
      mockRepo.findOne.mockResolvedValue(user);

      const result = await service.findById(1);
      expect(result).toEqual(user);
      expect(mockRepo.findOne).toHaveBeenCalledWith({ where: { id: 1 } });
    });

    it('should throw NotFoundException when not found', async () => {
      mockRepo.findOne.mockResolvedValue(null);

      await expect(service.findById(999)).rejects.toThrow(NotFoundException);
    });
  });

  describe('create', () => {
    it('should create user successfully', async () => {
      const dto = { username: 'new', email: 'new@example.com' };
      mockRepo.findOne.mockResolvedValue(null); // email not exists
      mockRepo.create.mockReturnValue(dto);
      mockRepo.save.mockResolvedValue({ id: 1, ...dto });

      const result = await service.create(dto);
      expect(result.id).toBe(1);
      expect(result.username).toBe('new');
    });

    it('should throw ConflictException when email exists', async () => {
      const dto = { username: 'new', email: 'exist@example.com' };
      mockRepo.findOne.mockResolvedValue({ id: 1 });

      await expect(service.create(dto)).rejects.toThrow(ConflictException);
    });
  });
});
```

## Controller 单元测试

```typescript
// user.controller.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { UserController } from './user.controller';
import { UserService } from './user.service';

describe('UserController', () => {
  let controller: UserController;
  let service: UserService;

  const mockService = {
    findById: jest.fn(),
    create: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [UserController],
      providers: [{ provide: UserService, useValue: mockService }],
    }).compile();

    controller = module.get<UserController>(UserController);
    service = module.get<UserService>(UserService);
  });

  it('should return user by id', async () => {
    const user = { id: 1, username: 'test' };
    mockService.findById.mockResolvedValue(user);

    const result = await controller.findOne(1);
    expect(result).toEqual(user);
  });
});
```

## E2E 测试

```typescript
// test/app.e2e-spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';

describe('Users (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('POST /users - create user', async () => {
    const res = await request(app.getHttpServer())
      .post('/users')
      .send({ username: 'test', email: 'test@example.com' })
      .expect(201);

    expect(res.body.username).toBe('test');
    expect(res.body.id).toBeDefined();
  });

  it('GET /users/:id - get user', async () => {
    const res = await request(app.getHttpServer())
      .get('/users/1')
      .expect(200);

    expect(res.body.id).toBe(1);
  });

  it('GET /users/999 - not found', async () => {
    await request(app.getHttpServer())
      .get('/users/999')
      .expect(404);
  });
});
```

## Mock 边界

- **只允许** Mock 外部 HTTP API、第三方 SDK。
- **允许** Mock Repository/Service（在单测中）。
- **禁止** Mock 数据库连接（E2E 测试用真实数据库）。

## 必须覆盖

- 正常路径、异常路径、边界条件。
- 异常过滤器、守卫、拦截器、管道的行为。

## 禁止事项

- **禁止** 僵尸断言（只 `expect(result).toBeDefined()`）。
- **禁止** `setTimeout` 等待异步（用 `await` 或 `fakeAsync`）。
- **禁止** E2E 测试 Mock 数据库。
- **禁止** 跳过测试无注释说明。
