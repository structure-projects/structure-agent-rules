# Next.js 前端评审规则

> 角色：reviewer（前端评审）。面向审查 Next.js 前端 PR / diff 的 AI Agent。

## 审查清单

### App Router 规范
- [ ] 是否使用 App Router（`app/` 目录），非 Pages Router
- [ ] 路由组 `(groupName)` 使用是否正确
- [ ] 是否提供了 `loading.tsx` 和 `error.tsx`
- [ ] 是否自定义了 `not-found.tsx`
- [ ] 动态路由 `[param]` 命名是否正确

### Server Components vs Client Components
- [ ] 默认是否为 Server Component
- [ ] `'use client'` 是否仅在必要时添加
- [ ] Client Component 是否尽可能为叶子节点
- [ ] Server Component 中是否有 `useState`/`useEffect`（**禁止**）
- [ ] 是否使用 `next/navigation`（非 `next/router`）

### 数据获取
- [ ] Server Component 中数据获取是否在顶层 await
- [ ] 是否有不必要的客户端数据获取
- [ ] 并行请求是否用 `Promise.all`

### Server Actions
- [ ] Server Actions 是否有 `'use server'` 声明
- [ ] 输入是否用 Zod 校验
- [ ] 操作成功后是否调用 `revalidatePath`/`revalidateTag`
- [ ] 是否返回结构化结果（`{ error, success }`）

### 认证
- [ ] next-auth Middleware 是否正确保护路由
- [ ] `config.matcher` 是否精确（非 `/:path*` 全局匹配）
- [ ] API Route 是否有认证检查

### 数据库
- [ ] Prisma Client 是否为单例模式
- [ ] 数据库查询是否有 N+1 问题（缺少 `include`）
- [ ] 迁移文件是否正确生成

### 优化
- [ ] 图片是否使用 `next/image`
- [ ] 字体是否使用 `next/font`
- [ ] 关键图片是否设置 `priority`
- [ ] 是否合理使用 ISR（`revalidate`）
- [ ] 静态页面是否用 `generateStaticParams`

### 安全
- [ ] 用户输入是否用 Zod 校验
- [ ] 服务端密钥是否不加 `NEXT_PUBLIC_` 前缀
- [ ] Server Action 是否有权限检查
- [ ] 是否防止 CSRF（next-auth 内置）

### 环境变量
- [ ] 服务端密钥是否在 `.env.local`（不加前缀）
- [ ] 客户端变量是否有 `NEXT_PUBLIC_` 前缀
- [ ] `.env.local` 是否在 `.gitignore` 中

### 样式
- [ ] 是否使用 Tailwind CSS
- [ ] 无内联 `style={{}}`

### 测试
- [ ] 新增功能是否包含单元测试
- [ ] E2E 测试是否覆盖核心流程
- [ ] 测试用例是否有有意义的断言

## 常见驳回原因

1. **使用 Pages Router**：项目统一使用 App Router
2. **Server Component 中使用 Hook**：`useState`/`useEffect` 只能在 Client Component
3. **使用 `next/router`**：App Router 使用 `next/navigation`
4. **Server Action 无校验**：必须用 Zod 校验输入
5. **Server Action 不刷新缓存**：操作后缺少 `revalidatePath`
6. **服务端密钥暴露**：使用了 `NEXT_PUBLIC_` 前缀
7. **Prisma Client 非单例**：开发热重载会导致连接泄漏
8. **图片未优化**：使用 `<img>` 而非 `next/image`
9. **缺少 loading.tsx / error.tsx**：影响用户体验
10. **中间件 matcher 过于宽泛**：应用 `config.matcher` 精确限定
