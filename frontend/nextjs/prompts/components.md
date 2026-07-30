# Next.js 组件使用规范

> 本文件描述 Next.js 项目中 Server Components 与 Client Components 的开发规范。
> 本规则自包含，不依赖其他技术栈目录。

## Server Components（默认）

Server Components 运行在服务端，可直接访问数据库、文件系统。

```tsx
// app/users/page.tsx — Server Component（默认，无需 'use client'）
import { db } from '@/lib/db'
import { UserTable } from './UserTable' // Client Component

export default async function UsersPage() {
  const users = await db.user.findMany({
    orderBy: { createdAt: 'desc' }
  })

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-4">用户管理</h1>
      <UserTable users={users} />
    </div>
  )
}
```

- **MUST** 默认使用 Server Components，仅在需要交互时添加 `'use client'`
- **MUST** Server Component 的数据获取在组件顶层 await
- **MUST** Server Component 中禁止使用 `useState`、`useEffect` 等客户端 Hook
- **SHOULD** 将数据获取逻辑放在 Server Component，数据展示放在 Client Component

## Client Components（`'use client'`）

```tsx
'use client'

import { useState, useCallback } from 'react'
import { useRouter } from 'next/navigation'

interface UserTableProps {
  users: User[]
}

export function UserTable({ users: initialUsers }: UserTableProps) {
  const [users, setUsers] = useState(initialUsers)
  const router = useRouter()

  const handleDelete = useCallback(async (id: string) => {
    await fetch('/api/users/' + id, { method: 'DELETE' })
    setUsers(prev => prev.filter(u => u.id !== id))
    router.refresh()
  }, [router])

  return (
    <table>
      {users.map(u => (
        <tr key={u.id}>
          <td>{u.name}</td>
          <td>
            <button onClick={() => handleDelete(u.id)}>删除</button>
          </tr>
        </tr>
      ))}
    </table>
  )
}
```

- **MUST** 仅在需要交互（事件处理、状态、Effect）时使用 `'use client'`
- **MUST** 使用 `next/navigation` 的 `useRouter`、`usePathname`（非 `next/router`）
- **MUST** Client Component 尽量作为叶子节点

## 特殊文件约定

| 文件 | 类型 | 说明 |
|---|---|---|
| `layout.tsx` | 均可 | 根布局建议 Server Component |
| `page.tsx` | 均可 | 默认 Server Component |
| `loading.tsx` | Client | 加载骨架屏 |
| `error.tsx` | Client | 错误边界 |
| `not-found.tsx` | 均可 | 404 页面 |
| `route.ts` | Server | API Route Handler |

## Server Actions

```tsx
// app/actions/user.ts
'use server'

import { z } from 'zod'
import { revalidatePath } from 'next/cache'
import { db } from '@/lib/db'

const CreateUserSchema = z.object({
  name: z.string().min(2, '名称至少 2 个字符'),
  email: z.string().email('邮箱格式不正确')
})

export async function createUser(formData: FormData) {
  const parsed = CreateUserSchema.safeParse({
    name: formData.get('name'),
    email: formData.get('email')
  })

  if (!parsed.success) {
    return { error: parsed.error.flatten().fieldErrors }
  }

  await db.user.create({ data: parsed.data })
  revalidatePath('/users')
  return { success: true }
}
```

```tsx
// 客户端表单中使用
'use client'
import { createUser } from '@/app/actions/user'

export function CreateUserForm() {
  return (
    <form action={createUser}>
      <input name="name" required />
      <input name="email" type="email" required />
      <button type="submit">创建</button>
    </form>
  )
}
```

- **MUST** Server Actions 中用 Zod 校验输入
- **MUST** 操作成功后 `revalidatePath` 或 `revalidateTag` 刷新缓存
- **SHOULD** Server Actions 返回结构化结果（`{ error, success }`）

## 中间件

```ts
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const token = request.cookies.get('token')
  const isAuthPage = request.nextUrl.pathname.startsWith('/login')

  if (!token && !isAuthPage) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  if (token && isAuthPage) {
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/dashboard/:path*', '/settings/:path*', '/login']
}
```

- **SHOULD** 中间件用于认证重定向、国际化路由
- **MUST** `config.matcher` 精确限定中间件范围

## next/image 和 next/font

```tsx
import Image from 'next/image'
import { Inter } from 'next/font/google'

const inter = Inter({ subsets: ['latin'] })

export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="zh-CN" className={inter.className}>
      <body>
        <Image
          src="/logo.png"
          alt="Logo"
          width={120}
          height={40}
          priority
        />
        {children}
      </body>
    </html>
  )
}
```

- **MUST** 图片使用 `next/image`（自动优化、懒加载、占位）
- **MUST** 字体使用 `next/font`（自动子集化、无闪烁）
- **MUST** 关键图片（LCP）设置 `priority`
