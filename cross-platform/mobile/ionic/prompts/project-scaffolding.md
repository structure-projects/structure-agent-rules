# Ionic 项目脚手架规则

> 面向创建 Ionic 项目的 AI Agent。

## 创建步骤

1. **MUST** 使用 Ionic CLI 7+
2. **MUST** 选择 Capacitor 而非 Cordova

```bash
# Angular 项目（推荐）
ionic start my-app tabs --type=angular --capacitor

# React 项目
ionic start my-app tabs --type=react --capacitor

# Vue 项目
ionic start my-app tabs --type=vue --capacitor
```

## 项目配置

### package.json 关键依赖（Angular）

```json
{
  "dependencies": {
    "@angular/core": "^17.0.0",
    "@ionic/angular": "^7.0.0",
    "@capacitor/core": "^5.0.0",
    "@capacitor/camera": "^5.0.0",
    "@capacitor/filesystem": "^5.0.0",
    "@capacitor/preferences": "^5.0.0",
    "@ionic/storage": "^4.0.0",
    "rxjs": "~7.8.0",
    "zone.js": "~0.14.0"
  },
  "devDependencies": {
    "@angular-devkit/build-angular": "^17.0.0",
    "@ionic/angular-toolkit": "^10.0.0",
    "@types/jasmine": "~5.1.0",
    "jasmine-core": "~5.1.0",
    "karma": "~6.4.0",
    "typescript": "~5.2.0"
  }
}
```

### capacitor.config.ts

```typescript
import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.example.myapp',
  appName: 'MyApp',
  webDir: 'www',
  server: {
    androidScheme: 'https',
    // 开发时允许本地热重载
    // url: 'http://192.168.1.100:8100',
    // cleartext: true,
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 2000,
    },
    PushNotifications: {
      presentationOptions: ['badge', 'sound', 'alert'],
    },
  },
};

export default config;
```

- **MUST** `appId` 使用反向域名格式
- **MUST** `webDir` 指向构建输出目录（Angular: `www`）
- **MUST** 生产环境使用 HTTPS

### ionic.config.json

```json
{
  "name": "my-app",
  "integrations": {
    "capacitor": {}
  },
  "type": "angular"
}
```

- **MUST** `integrations` 包含 `capacitor`（非 `cordova`）
- **MUST** `type` 指定前端框架

### tsconfig.json 关键配置

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

- **MUST** 启用 `strict: true`
- **MUST** 启用 `forceConsistentCasingInFileNames`

## 目录结构

```
my-app/
├── src/
│   ├── app/
│   │   ├── app.component.ts
│   │   ├── app.component.html
│   │   ├── app-routing.module.ts
│   │   └── app.module.ts
│   ├── core/
│   │   ├── services/
│   │   │   ├── api.service.ts
│   │   │   ├── platform.service.ts
│   │   │   └── storage.service.ts
│   │   ├── guards/
│   │   │   └── auth.guard.ts
│   │   ├── interceptors/
│   │   │   └── auth.interceptor.ts
│   │   └── models/
│   ├── features/
│   │   ├── auth/
│   │   ├── home/
│   │   └── profile/
│   ├── shared/
│   │   └── components/
│   ├── theme/
│   │   ├── variables.scss
│   │   └── global.scss
│   ├── environments/
│   │   ├── environment.ts
│   │   └── environment.prod.ts
│   ├── index.html
│   ├── main.ts
│   └── polyfills.ts
├── android/                      # 自动生成（ionic cap add android）
├── ios/                          # 自动生成（ionic cap add ios）
├── e2e/
│   └── src/
├── capacitor.config.ts
├── ionic.config.json
├── angular.json
├── tsconfig.json
├── package.json
└── .gitignore
```

## 平台添加

```bash
# 添加原生平台
ionic cap add android
ionic cap add ios

# 同步 Web 代码到原生项目
ionic cap sync

# 打开原生 IDE
ionic cap open android   # Android Studio
ionic cap open ios       # Xcode
```

- **MUST** 使用 `ionic cap sync` 同步代码（非 `ionic cap copy`）
- **MUST** 原生项目文件不提交到 Git（`android/`、`ios/` 在 `.gitignore`）

## PWA 配置

### 添加 PWA 支持

```bash
# Angular
ng add @angular/pwa

# React/Vue
npm install workbox-webpack-plugin
```

### manifest.json

```json
{
  "name": "MyApp",
  "short_name": "MyApp",
  "theme_color": "#3880ff",
  "background_color": "#ffffff",
  "display": "standalone",
  "scope": "/",
  "start_url": "/",
  "icons": [
    {
      "src": "assets/icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "assets/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

## 环境配置

```typescript
// src/environments/environment.ts
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8080/api',
  enablePWA: false,
  logLevel: 'debug',
};

// src/environments/environment.prod.ts
export const environment = {
  production: true,
  apiUrl: 'https://api.example.com',
  enablePWA: true,
  logLevel: 'error',
};
```

- **MUST** 使用 Angular environments 或 Vite env 变量
- **禁止** 硬编码 API 地址

## 构建命令

```bash
# 开发
ionic serve                          # Web 预览
ionic cap run android -l             # Android 热重载
ionic cap run ios -l                 # iOS 热重载（需 Xcode）

# 构建
ionic build --prod                   # Web 构建
ionic cap sync                       # 同步到原生项目
ionic cap build android              # 构建 Android APK
ionic cap build ios                  # 构建 iOS IPA

# 资源生成
ionic cordova resources              # 生成图标和启动屏（已废弃）
npm install -g @capacitor/assets
npx @capacitor/assets generate       # 使用 Capacitor Assets 工具
```

## 检查清单

- [ ] Ionic CLI 7+ 安装
- [ ] Capacitor 5+（非 Cordova）
- [ ] TypeScript strict mode 启用
- [ ] Ionic 组件全面使用（非原生 HTML）
- [ ] `capacitor.config.ts` 正确配置
- [ ] `ionic.config.json` 包含 `capacitor` integration
- [ ] 环境变量配置（`environment.ts`）
- [ ] PWA 支持（manifest.json + Service Worker）
- [ ] `.gitignore` 排除 `android/`、`ios/`、`www/`、`node_modules/`
- [ ] ESLint + Prettier 配置

## 禁止事项

- **禁止** 使用 Cordova 替代 Capacitor
- **禁止** 使用 `ionic cordova` 命令（已废弃）
- **禁止** 将 `android/`、`ios/` 目录提交到 Git
- **禁止** 在 `capacitor.config.ts` 中硬编码服务器地址
- **禁止** 将签名密钥提交到 Git
