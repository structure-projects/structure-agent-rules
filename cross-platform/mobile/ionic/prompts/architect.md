# Ionic 架构规则

> 角色：structure-architect（跨平台架构）。面向需要做 Ionic 架构选型与技术决策的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。IDE 包装文件使用 `ionic-` 前缀。

## 架构模式

### Feature-Module 分层架构

- **MUST** 采用 Feature-module 分层架构（Core / Shared / Feature）
- **MUST** Core 模块：全局单例服务（API、Storage、Platform、Auth）
- **MUST** Shared 模块：可复用组件、指令、管道
- **MUST** Feature 模块：按业务领域划分（auth、home、profile、settings）

```
src/
├── app/                          # 根模块（IonApp + IonRouterOutlet）
├── core/                         # 核心服务（单例、全局）
│   ├── services/                 # API、Storage、Platform、Auth
│   ├── guards/                   # 路由守卫
│   ├── interceptors/             # HTTP 拦截器
│   └── models/                   # 全局数据模型
├── features/                     # 业务模块
│   ├── auth/                     # 认证模块
│   │   ├── login/                # 登录页
│   │   ├── register/             # 注册页
│   │   ├── auth.service.ts       # 认证服务
│   │   └── auth.module.ts
│   ├── home/                     # 首页模块
│   └── settings/                 # 设置模块
├── shared/                       # 共享模块
│   ├── components/               # 通用组件
│   ├── directives/               # 通用指令
│   └── pipes/                    # 通用管道
├── theme/                        # 主题配置
│   ├── variables.scss            # Ionic CSS 变量
│   └── global.scss               # 全局样式
└── environments/                 # 环境配置
```

### 依赖注入

- Angular: Angular DI（`@Injectable({ providedIn: 'root' })`）
- React: Context API 或 DI 容器（`tsyringe`）
- Vue: `provide` / `inject`
- **MUST** Service 统一管理依赖注入，组件不直接实例化服务

## 状态管理

| 框架 | 推荐方案 | 适用场景 |
|---|---|---|
| Angular | NgRx（`@ngrx/store` + `@ngrx/effects`） | 大型企业应用 |
| Angular | `BehaviorSubject` + RxJS | 中小型应用 |
| React | Zustand | 轻量、简洁 |
| React | Redux Toolkit | 复杂状态 |
| Vue | Pinia | Vue 官方推荐 |

```typescript
// Angular NgRx 示例
@Injectable({ providedIn: 'root' })
export class UserFacade {
  users$ = this.store.select(selectAllUsers);
  loading$ = this.store.select(selectUsersLoading);

  constructor(private store: Store) {}

  loadUsers() {
    this.store.dispatch(UserActions.loadUsers());
  }
}

// React Zustand 示例
interface UserStore {
  users: User[];
  loading: boolean;
  fetchUsers: () => Promise<void>;
}

const useUserStore = create<UserStore>((set) => ({
  users: [],
  loading: false,
  fetchUsers: async () => {
    set({ loading: true });
    const users = await userService.getUsers();
    set({ users, loading: false });
  },
}));
```

## 路由

- Angular: Angular Router + `IonRouterOutlet`
- React: React Router 6 + `IonReactRouter`
- Vue: Vue Router 4 + `IonRouterOutlet`

### 路由架构要点

- **MUST** Tab 导航使用 `<ion-tabs>` + `<ion-tab-bar>` + `<ion-tab-button>`
- **MUST** 路由守卫实现认证、权限检查
- **MUST** 懒加载所有页面模块（减少首屏体积）
- **SHOULD** 使用 `ion-split-pane` 实现平板端侧边栏导航

```typescript
// Angular Tab 路由
const routes: Routes = [
  {
    path: 'tabs',
    component: TabsPage,
    children: [
      {
        path: 'dashboard',
        loadChildren: () => import('./dashboard/dashboard.module').then(m => m.DashboardModule),
      },
      {
        path: 'profile',
        loadChildren: () => import('./profile/profile.module').then(m => m.ProfileModule),
      },
    ],
    canActivate: [AuthGuard],
  },
];
```

## Capacitor 插件体系

### 核心插件（MUST）
| 插件 | 用途 |
|---|---|
| `@capacitor/camera` | 拍照、选图 |
| `@capacitor/filesystem` | 文件读写 |
| `@capacitor/preferences` | 键值存储 |
| `@capacitor/device` | 设备信息 |
| `@capacitor/network` | 网络状态 |
| `@capacitor/app` | App 生命周期 |

### 推荐插件（SHOULD）
| 插件 | 用途 |
|---|---|
| `@capacitor/push-notifications` | 推送通知 |
| `@capacitor/geolocation` | 地理位置 |
| `@capacitor/haptics` | 触觉反馈 |
| `@capacitor/share` | 分享 |
| `@capacitor/splash-screen` | 启动屏 |
| `@capacitor-community/sqlite` | SQLite 数据库 |
| `@capacitor-community/secure-storage` | 安全存储 |

### 插件封装模式

```typescript
@Injectable({ providedIn: 'root' })
export class FileService {
  async readFile(path: string): Promise<string> {
    const result = await Filesystem.readFile({
      path,
      directory: Directory.Data,
      encoding: Encoding.UTF8,
    });
    return result.data as string;
  }

  async writeFile(path: string, data: string): Promise<void> {
    await Filesystem.writeFile({
      path,
      data,
      directory: Directory.Data,
      encoding: Encoding.UTF8,
    });
  }
}
```

- **MUST** 每个 Capacitor 插件封装为独立 Service
- **MUST** Web 环境提供 fallback 实现（开发时在浏览器预览）
- **禁止** 组件中直接 import Capacitor 插件

## 数据持久化

- **MUST** 键值对：`@capacitor/preferences`（轻量）或 `@ionic/storage`（带 SQLite 回退）
- **MUST** 结构化数据：`@capacitor-community/sqlite`
- **MUST** 敏感数据：`@capacitor-community/secure-storage`
- **SHOULD** 缓存策略：Service Worker（PWA）或自定义缓存层

## 网络层

- Angular: `HttpClient` + Interceptor（Token 注入、错误处理）
- React/Vue: `axios` + Capacitor HTTP plugin（原生适配）
- **MUST** 配置请求超时、重试、错误统一处理
- **MUST** Token 自动注入通过 Interceptor/中间件实现

## 环境配置

```typescript
// environments/environment.ts
export const environment = {
  production: false,
  apiUrl: 'https://api.dev.example.com',
  enablePWA: false,
};

// environments/environment.prod.ts
export const environment = {
  production: true,
  apiUrl: 'https://api.example.com',
  enablePWA: true,
};
```

- **MUST** 使用 Angular environments 或 Vite env 变量区分环境
- **MUST** dev / staging / production 三套环境配置
- **禁止** 硬编码 API 地址

## 安全

- **MUST** HTTPS 强制
- **MUST** 敏感数据使用 `@capacitor-community/secure-storage` 或 `cordova-plugin-secure-storage`
- **MUST** API 密钥通过环境变量注入
- **SHOULD** CSP 头部配置
- **SHOULD** 证书固定（SSL Pinning）防止中间人攻击

## 多平台考虑

- **MUST** 使用 `Platform` 服务处理 iOS/Android 差异
- **MUST** 使用 `ion-split-pane` 处理平板/桌面布局
- **SHOULD** PWA 支持：Service Worker + manifest.json + workbox
- **SHOULD** 响应式断点：手机（<576px）、平板（<992px）、桌面（>=992px）
