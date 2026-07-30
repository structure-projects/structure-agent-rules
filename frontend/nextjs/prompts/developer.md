# Next.js 前端开发规则

> 角色：developer（前端）。面向 Next.js 14+ 前端开发的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。

## 硬约束

- **MUST** Next.js 14+ App Router（`app/` 目录）
- **MUST** TypeScript strict mode
- **MUST** React Server Components 为默认，按需 `'use client'`
- **MUST** Tailwind CSS 为样式方案
- **MUST** Zod 用于数据校验（客户端 + 服务端共享）
- **MUST** ESLint + Prettier

## 关键优先级

- **渲染策略**：SSG > ISR > SSR > CSR
- **数据获取**：Server Components 中直接 async/await 获取数据
- **认证**：next-auth (Auth.js) + Middleware 保护路由
- **数据库**：Prisma 或 Drizzle ORM

## 组件规范

### Server Component（默认）

```tsx
// app/posts/page.tsx
import { db } from '@/lib/db'

export default async function PostsPage() {
  const posts = await db.post.findMany({
    include: { author: true },
    orderBy: { createdAt: 'desc' }
  })

  return (
    <main className="container mx-auto p-4">
      <h1 className="text-3xl font-bold mb-6">文章列表</h1>
      <PostList posts={posts} />
    </main>
  )
}
```

- **MUST** 默认使用 Server Component
- **MUST** 数据获取在组件顶层直接 await
- **MUST** 禁止在 Server Component 中使用 `useState`/`useEffect`/`useContext`

### Client Component

```tsx
'use client'

import { useState, useTransition } from 'react'
import { createPost } from '@/app/actions/post'

export function CreatePostForm() {
  const [isPending, startTransition] = useTransition()

  return (
    <form action={(formData) => startTransition(() => createPost(formData))}>
      <input name="title" required />
      <textarea name="content" required />
      <button type="submit" disabled={isPending}>
        {isPending ? '创建中...' : '创建文章'}
      </button>
    </form>
  )
}
```

- **MUST** 仅在需要事件处理、状态、Effect、浏览器 API 时使用 `'use client'`
- **MUST** 使用 `next/navigation` 的 hooks（`useRouter`、`usePathname`、`useSearchParams`）
- **SHOULD** 使用 `useTransition` 包裹 Server Action 调用

## 路由与页面

### 文件约定

```
app/
├── layout.tsx           # 根布局（必需）
├── page.tsx             # 首页
├── loading.tsx          # 加载态（Suspense 边界）
├── error.tsx            # 错误边界
├── not-found.tsx        # 404
├── (auth)/              # 路由组（不影响 URL）
│   ├── login/page.tsx
│   └── register/page.tsx
├── dashboard/
│   ├── layout.tsx       # 仪表盘布局
│   ├── page.tsx         # /dashboard
│   └── users/[id]/page.tsx  # /dashboard/users/:id
└── api/users/route.ts   # Route Handler
```

### 动态路由

```tsx
// app/blog/[slug]/page.tsx
export async function generateStaticParams() {
  const posts = await getPosts()
  return posts.map((post) => ({ slug: post.slug }))
}

export default async function BlogPost({ params }: { params: { slug: string } }) {
  const post = await getPost(params.slug)
  return <article>{post.content}</article>
}
```

- **MUST** 动态路由用 `[param]` 目录命名
- **SHOULD** 静态页面用 `generateStaticParams` 预生成

## 数据获取

### Server Component 中获取

```tsx
// 直接 await — 最简单的模式
const users = await db.user.findMany()

// 并行获取
const [users, posts] = await Promise.all([
  db.user.findMany(),
  db.post.findMany()
])
```

### TanStack Query（客户端数据）

```tsx
'use client'
import { useQuery } from '@tanstack/react-query'

export function UserList() {
  const { data, isLoading } = useQuery({
    queryKey: ['users'],
    queryFn: () => fetch('/api/users').then(r => r.json())
  })
  // ...
}
```

- **SHOULD** 服务端数据在 Server Component 中获取
- **MAY** 客户端实时数据用 TanStack Query

## 认证（next-auth）

```ts
// auth.ts
import NextAuth from 'next-auth'
import Credentials from 'next-auth/providers/credentials'
import { PrismaAdapter } from '@auth/prisma-adapter'
import { db } from '@/lib/db'

export const { handlers, auth, signIn, signOut } = NextAuth({
  adapter: PrismaAdapter(db),
  providers: [
    Credentials({
      credentials: { email: {}, password: {} },
      authorize: async (credentials) => {
        // 验证逻辑
      }
    })
  ],
  callbacks: {
    session: ({ session, token }) => ({
      ...session,
      user: { ...session.user, id: token.sub! }
    })
  }
})
```

- **MUST** 使用 next-auth v5 (Auth.js)
- **MUST** Middleware 保护需要认证的路由
- **SHOULD** 用 PrismaAdapter 持久化会话

## 数据库

```ts
// lib/db.ts — Prisma 单例
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient }
export const db = globalForPrisma.prisma ?? new PrismaClient()
if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = db
```

- **MUST** Prisma Client 使用单例模式（开发时热重载复用）
- **MUST** 数据库迁移用 `prisma migrate dev/deploy`

## 环境变量

```env
# .env.local（不提交）
DATABASE_URL=postgresql://localhost:5432/mydb
AUTH_SECRET=your-secret-key

# 客户端暴露
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

- **MUST** 服务端密钥不加前缀（仅服务端可访问）
- **MUST** 客户端变量用 `NEXT_PUBLIC_` 前缀

## 测试工作流

- 每开发一个功能 **立即** 写单元测试，**单测通过才能做下一个功能**
- 功能有修改时 **同步修改测试** 并通过
- 业务完成后写 **E2E 测试**（Playwright），通过才算交付
- **提交前**：`npm run test` 全部通过 + `npm run lint` 无报错 + `npm run build` 编译通过
- **禁止** 测试/编译失败仍提交
