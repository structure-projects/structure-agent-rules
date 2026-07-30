# React Native 架构规则

> 角色：structure-architect（移动端架构）。面向需要做 React Native 架构选型与技术决策的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。IDE 包装文件使用 `react-native-` 前缀。

## 架构模式

### 分层架构

- **MUST** 采用 Feature-based 或 Layer-based 分层架构
- **MUST** 业务逻辑与 UI 分离，使用 Custom Hooks 封装
- **MUST** API 层独立封装，通过 Service 层提供给 Hooks/Store
- **MUST** 全局状态与局部状态明确分离

```
src/
├── app/                      # App 入口、导航配置
│   ├── App.tsx
│   └── navigation/
├── features/                 # 功能模块（Feature-based）
│   ├── auth/
│   │   ├── screens/
│   │   ├── components/
│   │   ├── hooks/
│   │   └── api.ts
│   └── home/
├── shared/                   # 共享层
│   ├── components/           # 通用 UI 组件
│   ├── hooks/                # 通用 Hooks
│   ├── services/             # API 客户端、存储
│   ├── stores/               # 全局状态（Zustand）
│   ├── types/                # TypeScript 类型
│   └── utils/                # 工具函数
└── theme/                    # 主题配置
```

### New Architecture 适配

- **MUST** React Native 0.73+ 开启 New Architecture（Fabric + TurboModules）
- **MUST** 使用 `RCT_NEW_ARCH_ENABLED=1` 编译
- **SHOULD** 优先使用 Turbo Native Module（替代旧 Bridge 模式）
- **MAY** 逐步迁移旧原生模块到 TurboModule

## 状态管理

- **MUST** 全局状态使用 Zustand（轻量）或 Redux Toolkit（复杂场景）
- **MUST** 服务端状态使用 TanStack Query（React Query）
- **MUST** 组件内部状态使用 `useState` / `useReducer`
- **SHOULD** 表单状态使用 React Hook Form + zod 校验

```ts
// Zustand Store
import { create } from 'zustand'

interface AuthStore {
  token: string | null
  user: User | null
  login: (credentials: Credentials) => Promise<void>
  logout: () => void
}

export const useAuthStore = create<AuthStore>((set) => ({
  token: null,
  user: null,
  login: async (credentials) => {
    const user = await authService.login(credentials)
    set({ user, token: user.token })
  },
  logout: () => set({ token: null, user: null })
}))
```

## 导航架构

- **MUST** 使用 React Navigation 6.x
- **MUST** 使用 `NavigationContainer` + 类型安全导航（`NativeStackNavigator`）
- **MUST** Stack Navigator 用于页面栈，Tab Navigator 用于底部标签
- **SHOULD** 深层链接使用 `linking` 配置
- **MUST** 类型安全的导航参数

```ts
// 类型安全导航
type RootStackParamList = {
  Home: undefined
  Detail: { id: string }
  Profile: { userId?: number }
}

const Stack = createNativeStackNavigator<RootStackParamList>()
```

## 平台适配

- **MUST** 使用 `.ios.tsx` / `.android.tsx` 文件后缀分离平台代码
- **MUST** 使用 `Platform.OS` / `Platform.select()` 处理运行时差异
- **SHOULD** 共享尽可能多的代码，仅分离平台特定部分

## 构建配置

- **MUST** TypeScript `strict: true`
- **MUST** Hermes 引擎（生产构建）
- **SHOULD** Expo 托管工作流（推荐）或 React Native CLI
- **MUST** EAS Build 用于生产构建

## 安全

- **MUST** 敏感数据使用 react-native-keychain 或 expo-secure-store
- **MUST** API 密钥通过环境变量注入，**禁止** 硬编码
- **MUST** HTTPS 强制开启
- **SHOULD** 使用 SSL Pinning 防止中间人攻击
