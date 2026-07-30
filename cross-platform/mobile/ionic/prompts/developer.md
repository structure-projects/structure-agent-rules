# Ionic 开发规则

> 角色：structure-developer（Ionic 跨平台）。面向开发 Ionic 应用的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。IDE 包装文件使用 `ionic-` 前缀。

## 硬约束

- **MUST** Ionic 7+ + Capacitor 5+（非 Cordova）
- **MUST** TypeScript strict mode
- **MUST** 前端框架：Angular 16+（推荐）/ React 18+ / Vue 3+
- **MUST** 使用 Ionic 组件替代原生 HTML 元素
- **MUST** Capacitor 插件访问原生能力（Camera、Filesystem、Storage 等）
- **MUST** 存储：`@capacitor/preferences`（键值）或 `@ionic/storage`（带 SQLite）
- **MUST** HTTP：Angular HttpClient 或 axios（配合 Capacitor HTTP plugin）
- **MUST** 代码风格：ESLint + Prettier

## 关键优先级

- **框架选择**：Angular（企业级推荐）> React > Vue
- **状态管理**：NgRx（Angular）> Zustand（React）> Pinia（Vue）
- **存储**：`@capacitor/preferences` > `@ionic/storage` > localStorage（禁止）
- **组件**：Ionic 组件 > 原生 HTML 元素
- **插件**：Capacitor 插件 > Cordova 插件

## 命名规范

- **MUST** 文件名 kebab-case（`user-service.ts`、`login-page.ts`）
- **MUST** 类名 PascalCase（`UserService`、`LoginPage`）
- **MUST** 变量/函数名 camelCase（`userName`、`fetchUsers()`）
- **MUST** 常量 UPPER_SNAKE_CASE（`API_BASE_URL`）
- **MUST** 组件选择器 `app-` 前缀（`<app-user-card>`）（Angular）

## 文件组织

```
src/
├── app/
│   ├── app.component.ts          # 根组件（IonApp + IonRouterOutlet）
│   ├── app-routing.module.ts     # 路由配置（Ionic lazy loading）
│   └── app.module.ts
├── core/
│   ├── services/
│   │   ├── api.service.ts        # HTTP 客户端封装
│   │   ├── platform.service.ts   # Capacitor Platform 封装
│   │   └── storage.service.ts    # Capacitor Preferences 封装
│   ├── guards/
│   │   └── auth.guard.ts         # 路由守卫
│   ├── interceptors/
│   │   └── auth.interceptor.ts   # HTTP 拦截器
│   └── models/
│       └── user.model.ts
├── features/
│   ├── auth/
│   │   ├── login/
│   │   │   ├── login.page.ts
│   │   │   ├── login.page.html
│   │   │   └── login.page.scss
│   │   ├── register/
│   │   │   ├── register.page.ts
│   │   │   ├── register.page.html
│   │   │   └── register.page.scss
│   │   ├── auth.service.ts
│   │   └── auth.module.ts
│   ├── home/
│   │   ├── home.page.ts
│   │   ├── home.page.html
│   │   ├── home.page.scss
│   │   └── home.module.ts
│   └── profile/
│       ├── profile.page.ts
│       ├── profile.page.html
│       ├── profile.page.scss
│       └── profile.module.ts
├── shared/
│   ├── components/
│   │   ├── user-avatar/
│   │   └── loading-spinner/
│   ├── directives/
│   └── pipes/
├── theme/
│   ├── variables.scss            # Ionic CSS 变量（--ion-color-*）
│   └── global.scss
├── environments/
│   ├── environment.ts            # 开发环境
│   └── environment.prod.ts       # 生产环境
├── index.html
├── main.ts
└── polyfills.ts
```

> **注意**：React/Vue 项目目录结构类似，页面文件扩展名改为 `.tsx`（React）或 `.vue`（Vue）。

## 编码规范

### Ionic 组件使用

```typescript
// ✅ 正确：使用 Ionic 组件
@Component({
  template: `
    <ion-header>
      <ion-toolbar>
        <ion-title>用户列表</ion-title>
      </ion-toolbar>
    </ion-header>
    <ion-content>
      <ion-list>
        <ion-item *ngFor="let user of users" (click)="selectUser(user)">
          <ion-avatar slot="start">
            <img [src]="user.avatar" />
          </ion-avatar>
          <ion-label>
            <h2>{{ user.name }}</h2>
            <p>{{ user.email }}</p>
          </ion-label>
          <ion-note slot="end">{{ user.role }}</ion-note>
        </ion-item>
      </ion-list>
    </ion-content>
  `
})
export class UserListPage { }

// ❌ 错误：使用原生 HTML 元素
@Component({
  template: `
    <div class="header">
      <div class="title">用户列表</div>
    </div>
    <ul>
      <li *ngFor="let user of users">
        <div class="name">{{ user.name }}</div>
      </li>
    </ul>
  `
})
```

- **MUST** `<ion-header>` + `<ion-toolbar>` 替代原生 header
- **MUST** `<ion-content>` 替代可滚动容器
- **MUST** `<ion-list>` + `<ion-item>` 替代 `<ul>` + `<li>`
- **MUST** `<ion-input>` 替代 `<input>`
- **MUST** `<ion-button>` 替代 `<button>`
- **MUST** `<ion-icon>` 替代字体图标

### 主题定制（SCSS）

```scss
// theme/variables.scss
:root {
  --ion-color-primary: #3880ff;
  --ion-color-primary-contrast: #ffffff;
  --ion-color-secondary: #3dc2ff;
  --ion-color-tertiary: #5260ff;
  --ion-color-success: #2dd36f;
  --ion-color-warning: #ffc409;
  --ion-color-danger: #eb445a;
  --ion-color-dark: #222428;
  --ion-color-medium: #92949c;
  --ion-color-light: #f4f5f8;

  --ion-font-family: 'Inter', -apple-system, sans-serif;
  --ion-background-color: #ffffff;
  --ion-text-color: #1a1a1a;
}
```

- **MUST** 使用 CSS 自定义属性（`--ion-color-*`）定制主题
- **MUST** 在 `variables.scss` 中集中定义主题变量
- **禁止** 在组件样式中硬编码颜色值

### 平台检测

```typescript
import { Platform } from '@ionic/angular';

@Injectable({ providedIn: 'root' })
export class PlatformService {
  constructor(private platform: Platform) {}

  isIOS(): boolean {
    return this.platform.is('ios');
  }

  isAndroid(): boolean {
    return this.platform.is('android');
  }

  isMobile(): boolean {
    return this.platform.is('mobile');
  }

  isDesktop(): boolean {
    return this.platform.is('desktop');
  }
}
```

- **MUST** 使用 `Platform` 服务检测平台（非 `navigator.userAgent`）
- **MUST** 根据平台动态切换 UI 模式（`mode: 'ios'` / `mode: 'md'`）

### Capacitor 插件使用

```typescript
import { Camera, CameraResultType, CameraSource } from '@capacitor/camera';
import { Filesystem, Directory } from '@capacitor/filesystem';
import { Preferences } from '@capacitor/preferences';

@Injectable({ providedIn: 'root' })
export class CameraService {
  async takePhoto(): Promise<string> {
    const photo = await Camera.getPhoto({
      resultType: CameraResultType.Uri,
      source: CameraSource.Camera,
      quality: 90,
    });
    return photo.webPath!;
  }
}

@Injectable({ providedIn: 'root' })
export class StorageService {
  async set(key: string, value: string): Promise<void> {
    await Preferences.set({ key, value });
  }

  async get(key: string): Promise<string | null> {
    const { value } = await Preferences.get({ key });
    return value;
  }

  async remove(key: string): Promise<void> {
    await Preferences.remove({ key });
  }
}
```

- **MUST** 所有原生功能通过 Capacitor 插件封装
- **MUST** 插件调用封装在 Service 中，组件不直接调用插件
- **MUST** 权限请求在插件调用前处理

### HTTP 服务

```typescript
// Angular
@Injectable({ providedIn: 'root' })
export class ApiService {
  constructor(private http: HttpClient) {}

  get<T>(url: string): Observable<T> {
    return this.http.get<T>(`${environment.apiUrl}${url}`);
  }

  post<T>(url: string, body: unknown): Observable<T> {
    return this.http.post<T>(`${environment.apiUrl}${url}`, body);
  }
}

// React/Vue（使用 axios）
import axios from 'axios';
import { CapacitorHttp } from '@capacitor/core';

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  timeout: 15000,
});

// 原生环境使用 Capacitor HTTP 插件（绕过 CORS）
const isNative = Capacitor.isNativePlatform();
if (isNative) {
  apiClient.defaults.adapter = async (config) => {
    const response = await CapacitorHttp.request({
      url: `${config.baseURL}${config.url}`,
      method: config.method?.toUpperCase() as 'GET' | 'POST',
      headers: config.headers as Record<string, string>,
      data: config.data,
    });
    return { ...response, status: response.status, data: response.data };
  };
}
```

- **MUST** HTTP 客户端统一封装在 `ApiService` 中
- **MUST** 原生环境使用 Capacitor HTTP plugin（避免 CORS 问题）
- **MUST** Token 通过 HTTP Interceptor 自动注入

## 导航规范

### Angular 路由

```typescript
// app-routing.module.ts
const routes: Routes = [
  {
    path: '',
    loadChildren: () => import('./features/home/home.module').then(m => m.HomePageModule),
  },
  {
    path: 'login',
    loadChildren: () => import('./features/auth/login/login.module').then(m => m.LoginPageModule),
  },
  {
    path: 'tabs',
    component: TabsPage,
    children: [
      { path: 'dashboard', loadChildren: () => import(...) },
      { path: 'profile', loadChildren: () => import(...) },
    ],
    canActivate: [AuthGuard],
  },
];
```

- **MUST** 使用懒加载（`loadChildren`）
- **MUST** Tab 导航使用 `<ion-tabs>` + `<ion-tab-bar>`
- **MUST** 路由守卫实现认证检查

## 测试工作流

- **MUST** 每开发一个功能立即写单元测试
- **MUST** 功能修改时同步修改测试并通过
- **MUST** 核心页面写组件测试
- **MUST** 核心流程写 E2E（Cypress/Playwright）
- **MUST** 提交前 `npm run test` + `npm run lint` + `npx tsc --noEmit` 全部通过
- **禁止** 测试/Lint/类型检查失败仍提交

## 禁止事项

- **禁止** 使用原生 HTML 元素替代 Ionic 组件
- **禁止** 使用 Cordova 插件（迁移到 Capacitor）
- **禁止** 直接操作 DOM（`document.querySelector`）
- **禁止** 在组件中直接调用 Capacitor 插件（通过 Service 封装）
- **禁止** 硬编码颜色、字号、间距
- **禁止** 使用 `navigator.userAgent` 做平台判断（使用 `Platform` 服务）
- **禁止** 敏感数据存 `localStorage`
- **禁止** API 密钥硬编码
