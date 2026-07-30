# Next.js 前端项目脚手架规则

> 面向创建 Next.js 前端项目的 AI Agent。

## 创建步骤

1. **MUST** 使用 `create-next-app`：`npx create-next-app@latest my-app --typescript --tailwind --eslint --app --src-dir`
2. **MUST** 技术栈：Next.js 14+ + TypeScript 5 + Tailwind CSS + Prisma + next-auth
3. **MUST** 使用 App Router（`app/` 目录）

### 交互选项

```bash
npx create-next-app@latest my-app
```

推荐选择：
- TypeScript: **Yes**
- ESLint: **Yes**
- Tailwind CSS: **Yes**
- `src/` directory: **Yes**
- App Router: **Yes**
- Import alias (`@/*`): **Yes**

## package.json

```json
{
  "name": "my-next-app",
  "private": true,
  "scripts": {
    "dev": "next dev --port 3000",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "format": "prettier --write .",
    "test": "vitest",
    "test:coverage": "vitest --coverage",
    "test:e2e": "playwright test",
    "db:generate": "prisma generate",
    "db:push": "prisma db push",
    "db:migrate": "prisma migrate dev",
    "db:studio": "prisma studio"
  },
  "dependencies": {
    "next": "^14.2.0",
    "react": "^18.3.0",
    "react-dom": "^18.3.0",
    "next-auth": "^5.0.0-beta",
    "@auth/prisma-adapter": "^1.6.0",
    "@prisma/client": "^5.18.0",
    "zod": "^3.23.0",
    "@tanstack/react-query": "^5.51.0"
  },
  "devDependencies": {
    "typescript": "^5.5.0",
    "@types/node": "^20.14.0",
    "@types/react": "^18.3.0",
    "@types/react-dom": "^18.3.0",
    "prisma": "^5.18.0",
    "vitest": "^2.0.0",
    "@vitejs/plugin-react": "^4.3.0",
    "@testing-library/react": "^16.0.0",
    "@testing-library/jest-dom": "^6.4.0",
    "@playwright/test": "^1.45.0",
    "eslint": "^8.57.0",
    "eslint-config-next": "^14.2.0",
    "prettier": "^3.3.0",
    "prettier-plugin-tailwindcss": "^0.6.0",
    "jsdom": "^24.0.0"
  }
}
```

## 检查清单

- [ ] App Router 模式（`app/` 目录）
- [ ] TypeScript strict mode（`tsconfig.json` `strict: true`）
- [ ] Tailwind CSS 已配置
- [ ] Prisma schema 已创建（`prisma/schema.prisma`）
- [ ] next-auth 配置完成（`auth.ts` + API route + Middleware）
- [ ] `layout.tsx` 根布局包含 HTML/body 结构
- [ ] `loading.tsx` 和 `error.tsx` 全局覆盖
- [ ] `not-found.tsx` 自定义 404 页面
- [ ] Route Handler 或 tRPC API 层已建立
- [ ] Zod schema 定义共享校验
- [ ] 环境变量 `.env.local` 已配置

## 项目结构（推荐）

```
my-next-app/
├── app/
│   ├── (auth)/
│   │   ├── login/page.tsx
│   │   └── register/page.tsx
│   ├── (dashboard)/
│   │   ├── layout.tsx
│   │   ├── dashboard/page.tsx
│   │   └── settings/page.tsx
│   ├── api/
│   │   ├── auth/[...nextauth]/route.ts
│   │   └── users/route.ts
│   ├── actions/           # Server Actions
│   │   └── user.ts
│   ├── layout.tsx
│   ├── page.tsx
│   ├── loading.tsx
│   ├── error.tsx
│   └── not-found.tsx
├── components/
│   ├── ui/                # 通用 UI 组件
│   └── forms/             # 表单组件
├── lib/
│   ├── db.ts              # Prisma 单例
│   ├── auth.ts            # next-auth 配置
│   └── utils.ts
├── prisma/
│   └── schema.prisma
├── public/
├── types/
├── middleware.ts
├── next.config.mjs
├── tailwind.config.ts
├── tsconfig.json
└── package.json
```

## next.config.mjs 参考

```js
/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**'
      }
    ]
  },
  experimental: {
    serverActions: {
      bodySizeLimit: '2mb'
    }
  }
}

export default nextConfig
```

## Prisma Schema 参考

```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(cuid())
  name      String
  email     String   @unique
  password  String
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model Account {
  id                String  @id @default(cuid())
  userId            String
  type              String
  provider          String
  providerAccountId String
  user              User    @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([provider, providerAccountId])
}

model Session {
  id           String   @id @default(cuid())
  sessionToken String   @unique
  userId       String
  expires      DateTime
  user         User     @relation(fields: [userId], references: [id], onDelete: Cascade)
}
```

## 禁止事项

- **禁止** 使用 Pages Router（`pages/` 目录），统一使用 App Router
- **禁止** 在 Server Component 中使用 `useState`/`useEffect`
- **禁止** 服务端密钥使用 `NEXT_PUBLIC_` 前缀
- **禁止** 在客户端组件中直接访问数据库
- **禁止** 忽略 `loading.tsx` 和 `error.tsx`
- **禁止** 使用 `next/router`（Pages Router API），使用 `next/navigation`
