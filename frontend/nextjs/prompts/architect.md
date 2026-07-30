# Next.js 前端架构规则

> 角色：architect（前端架构）。面向需要做 Next.js 前端架构选型与技术决策的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。

## 技术栈基线

- **MUST** Next.js 14+ App Router（`app/` 目录）
- **MUST** TypeScript strict mode
- **MUST** Node.js 20 LTS
- **MUST** React Server Components 为默认，按需 `'use client'`

## 渲染策略

| 策略 | 适用场景 | 实现方式 |
|---|---|---|
| **SSR** (Server-Side) | 动态页面、个性化内容 | 默认行为（无显式声明） |
| **SSG** (Static Site) | 博客、文档、营销页 | `generateStaticParams` + 无动态函数 |
| **ISR** (Incremental) | 数据变化不频繁 | `revalidate` 选项 |
| **CSR** (Client-Side) | 强交互后台管理 | `'use client'` + 客户端数据获取 |

```tsx
// SSG 示例
export const revalidate = 3600 // ISR: 每小时重新生成

export async function generateStaticParams() {
  const posts = await getPosts()
  return posts.map((post) => ({ slug: post.slug }))
}
```

- **MUST** 优先使用 Server Components，仅在需要交互性时添加 `'use client'`
- **SHOULD** 静态内容用 SSG/ISR，减少服务端负载

## App Router 架构

```
app/
├── layout.tsx              # 根布局（全局）
├── page.tsx                # 首页
├── loading.tsx             # 全局加载态
├── error.tsx               # 全局错误边界
├── not-found.tsx           # 404 页面
├── (marketing)/            # 路由组（不影响 URL）
│   ├── layout.tsx
│   ├── about/page.tsx
│   └── blog/[slug]/page.tsx
├── (dashboard)/            # 需要认证的路由组
│   ├── layout.tsx          # 仪表盘布局
│   ├── dashboard/page.tsx
│   └── settings/page.tsx
└── api/                    # API Routes / Route Handlers
    ├── auth/[...nextauth]/route.ts
    └── users/route.ts
```

- **MUST** 使用路由组 `(groupName)` 组织页面，不影响 URL
- **MUST** 每个路由组有独立 `layout.tsx`
- **MUST** 关键路由提供 `loading.tsx` 和 `error.tsx`

## Server Components vs Client Components

```tsx
// Server Component（默认）
// 可直接 async，可访问 DB/文件系统
export default async function UserList() {
  const users = await db.user.findMany()
  return (
    <ul>
      {users.map(u => <li key={u.id}>{u.name}</li>)}
    </ul>
  )
}

// Client Component
'use client'
import { useState } from 'react'

export function UserSearch() {
  const [query, setQuery] = useState('')
  // ...
}
```

- **MUST** 将 Client Component 尽可能推向叶子节点
- **SHOULD** Server Component 作为容器，传递数据给 Client Component

## API 层

### Route Handlers（替代 API Routes）

```ts
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url)
  const page = searchParams.get('page') ?? '1'
  const users = await db.user.findMany({ skip: +page * 10, take: 10 })
  return NextResponse.json(users)
}

export async function POST(request: NextRequest) {
  const body = await request.json()
  const user = await db.user.create({ data: body })
  return NextResponse.json(user, { status: 201 })
}
```

### tRPC（类型安全 API）

```ts
// server/api/routers/user.ts
export const userRouter = router({
  list: publicProcedure
    .input(z.object({ page: z.number().default(1) }))
    .query(({ input }) => db.user.findMany({ skip: input.page * 10, take: 10 })),

  create: protectedProcedure
    .input(z.object({ name: z.string(), email: z.string().email() }))
    .mutation(({ input }) => db.user.create({ data: input }))
})
```

- **SHOULD** 使用 tRPC 实现端到端类型安全
- **MAY** REST Route Handlers 用于外部 API 或简单场景

### Server Actions

```tsx
// app/actions/user.ts
'use server'
import { revalidatePath } from 'next/cache'

export async function createUser(formData: FormData) {
  const name = formData.get('name') as string
  await db.user.create({ data: { name } })
  revalidatePath('/users')
}
```

- **SHOULD** Server Actions 用于表单提交，简化前后端交互
- **MUST** Server Action 中做服务端校验（Zod）

## 数据库

- **SHOULD** Prisma 或 Drizzle ORM 作为数据库层
- **SHOULD** 数据库连接复用（Prisma 单例模式）
- **MAY** Vercel Postgres / PlanetScale 作为托管数据库

```ts
// lib/db.ts — Prisma 单例
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient }
export const db = globalForPrisma.prisma ?? new PrismaClient()
if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = db
```

## 认证

- **MUST** next-auth (Auth.js) 作为认证方案
- **MUST** Middleware 保护需要认证的路由

```ts
// middleware.ts
export { auth as middleware } from '@/auth'

export const config = {
  matcher: ['/dashboard/:path*', '/settings/:path*']
}
```

## CSS 与优化

- **MUST** Tailwind CSS 为默认样式方案
- **MUST** `next/image` 用于图片优化
- **MUST** `next/font` 用于字体优化

## 环境变量

```
# .env.local（本地开发，不提交）
DATABASE_URL=postgresql://...
AUTH_SECRET=xxx

# .env.production（生产环境）
NEXT_PUBLIC_API_URL=https://api.example.com
```

- **MUST** 服务端密钥不暴露给客户端
- **MUST** 客户端暴露的变量用 `NEXT_PUBLIC_` 前缀
