# CLAUDE.md — Next.js 前端技术栈生态

本文件为 structure-projects 开源生态的 **Next.js 前端规则**，供 AI Agent 理解前端技术栈约定。

## 生态坐标

| 维度 | 值 | 说明 |
|---|---|---|
| 框架 | Next.js 14+ App Router | `app/` 目录，Server Components 默认 |
| 渲染策略 | SSG > ISR > SSR > CSR | 按需选择，优先静态 |
| 样式 | Tailwind CSS | 默认方案 |
| 数据库 | Prisma / Drizzle ORM | 类型安全 ORM |
| 认证 | next-auth (Auth.js) | Middleware + Providers |
| 校验 | Zod | 客户端/服务端共享 |
| 部署 | Vercel / Docker standalone | 首选 Vercel |

## 关键决策

- **App Router only**：禁止使用 Pages Router（`pages/` 目录）
- **Server Components 优先**：默认在服务端渲染，仅在需要交互时添加 `'use client'`
- **Server Actions**：表单提交通道，替代传统 API Route
- **数据校验**：Zod schema 定义在共享位置，客户端和服务端同时使用
- **Prisma 单例**：开发模式下全局复用 Prisma Client 实例，避免连接泄漏

## 核心概念

### Server Components（默认）
- 运行在服务端，可直接访问数据库、文件系统
- 支持 async/await 顶层数据获取
- 禁止使用 `useState`、`useEffect`、`useContext` 等客户端 Hook
- 不可添加事件处理器（`onClick` 等）

### Client Components（`'use client'`）
- 仅在需要交互（事件、状态、Effect、浏览器 API）时使用
- 尽可能作为叶子节点
- 使用 `next/navigation`（非 `next/router`）
- 可用 `useTransition` 包裹 Server Action 调用

### Server Actions（`'use server'`）
- 在服务端执行的异步函数
- 可用于 `<form action={serverAction}>` 
- 必须用 Zod 校验输入
- 操作后调用 `revalidatePath` 或 `revalidateTag` 刷新缓存

## 项目结构

```
app/
├── (auth)/login/page.tsx
├── (dashboard)/layout.tsx
├── api/                    # Route Handlers
├── actions/                # Server Actions
├── layout.tsx
├── loading.tsx
├── error.tsx
└── not-found.tsx
components/
├── ui/                     # 通用 UI
└── forms/                  # 表单组件
lib/
├── db.ts                   # Prisma 单例
├── auth.ts                 # next-auth 配置
└── utils.ts
prisma/schema.prisma
middleware.ts
```

## 版本信息

| 依赖 | 版本 |
|---|---|
| Next.js | 14.x+ |
| React | 18.x+ |
| TypeScript | 5.x+ |
| Prisma | 5.x |
| next-auth | 5.x (beta) |
| Zod | 3.x |
| Tailwind CSS | 3.x |
| Vitest | 2.x |
| Playwright | 1.x |
| Node.js | 20 LTS |

## 关键技术事实

- `next/image` 自动优化图片（尺寸、格式、懒加载），必须使用而非 `<img>`。
- `next/font` 自动优化字体（子集化、无闪烁），必须在根布局中引入。
- Prisma Client 必须使用单例模式（`globalThis`），否则开发热重载导致连接池耗尽。
- 服务端环境变量不加前缀（`DATABASE_URL`），客户端暴露的加 `NEXT_PUBLIC_` 前缀。
- Middleware 的 `config.matcher` 必须精确限定，避免全局匹配影响性能。
- `revalidatePath` / `revalidateTag` 是 Server Action 操作后刷新缓存的标准方式。
