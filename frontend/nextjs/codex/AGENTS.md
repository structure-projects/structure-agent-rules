# AGENTS.md — Next.js 前端规则（Codex 自包含模板）

> 本文件自包含，可直接拷贝到 Next.js 项目根目录，供 Codex / 通用 AI Agent 自动加载。
> 修改规则时，请同步更新 `prompts/` 目录下的对应角色文件。

## 1. 硬约束

- **MUST** Next.js 14+ App Router（`app/` 目录），**禁止** Pages Router
- **MUST** TypeScript strict mode + Tailwind CSS
- **MUST** React Server Components 为默认，按需 `'use client'`
- **MUST** Zod 用于客户端/服务端数据校验
- **MUST** next-auth (Auth.js) 处理认证
- **MUST** ESLint + Prettier

## 2. Server Components vs Client Components

- Server Components（默认）：
  - 可直接 async/await 获取数据
  - 可访问数据库、文件系统
  - 禁止 `useState`、`useEffect`、`useContext`
- Client Components（`'use client'`）：
  - 仅在需要交互时使用
  - 尽可能为叶子节点
  - 使用 `next/navigation`（非 `next/router`）

## 3. Server Actions

- `'use server'` 声明
- Zod 校验输入
- 操作后 `revalidatePath` / `revalidateTag`
- 返回结构化结果 `{ error?, success? }`

## 4. 路由

```
app/
├── layout.tsx       # 根布局（必需）
├── page.tsx         # 首页
├── loading.tsx      # 全局加载态
├── error.tsx        # 全局错误边界
├── not-found.tsx    # 404
├── (auth)/          # 路由组（不影响 URL）
├── (dashboard)/     # 需认证路由组
└── api/             # Route Handlers
```

## 5. 渲染策略

| 策略 | 场景 | 实现 |
|---|---|---|
| SSR | 动态页面 | 默认 |
| SSG | 静态内容 | `generateStaticParams` |
| ISR | 不频繁变化 | `revalidate` 选项 |
| CSR | 强交互 | `'use client'` + 客户端获取 |

## 6. 数据获取

- Server Component 中直接 await 获取数据
- 并行请求用 `Promise.all`
- 客户端数据用 TanStack Query（可选）

## 7. 认证（next-auth）

- Middleware 保护需要认证的路由
- `config.matcher` 精确限定
- API Route Handler 中检查 session

## 8. 数据库

```ts
// lib/db.ts — Prisma 单例（MUST）
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient }
export const db = globalForPrisma.prisma ?? new PrismaClient()
if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = db
```

## 9. 优化

- **MUST** 图片用 `next/image`（自动优化、懒加载）
- **MUST** 字体用 `next/font`（自动子集化、无闪烁）
- **MUST** 关键图片设置 `priority`
- **SHOULD** 静态页面用 `generateStaticParams`

## 10. 环境变量

- 服务端密钥不加前缀（`DATABASE_URL`、`AUTH_SECRET`）
- 客户端变量加 `NEXT_PUBLIC_` 前缀
- `.env.local` 不提交

## 11. 测试

| 层级 | 工具 |
|---|---|
| 单元测试 | Vitest |
| 组件测试 | Vitest + React Testing Library |
| E2E | Playwright |

- Mock `next/navigation` hooks
- Server Action 测试：传入 FormData，断言返回值
- 组件测试优先 `getByRole`
- E2E 用 `data-testid` 选择器，覆盖认证 + CRUD
- 每功能开发后立即写单测，通过才能做下一个
- 业务完成后写 E2E
- 提交前 `npm run test` 全通过 + `npm run build` 编译通过

## 12. CI/CD

- GitHub Actions
- `test.yml`：npm ci + lint + tsc + vitest + build（含 PostgreSQL service）
- `e2e.yml`：Playwright E2E 测试
- `deploy.yml`：Vercel 自动部署
- `migrate.yml`：Prisma 数据库迁移（`prisma migrate deploy`）
- Secrets：`DATABASE_URL`、`VERCEL_TOKEN`、`AUTH_SECRET`

## 13. 项目结构

```
src/
├── app/             # App Router 页面与 API
│   ├── (auth)/
│   ├── (dashboard)/
│   ├── api/
│   └── actions/     # Server Actions
├── components/
│   ├── ui/          # 通用 UI 组件
│   └── forms/       # 表单组件
├── lib/
│   ├── db.ts        # Prisma 单例
│   ├── auth.ts      # next-auth 配置
│   └── utils.ts
├── test/
│   └── setup.ts
├── middleware.ts
└── prisma/
    └── schema.prisma
```
