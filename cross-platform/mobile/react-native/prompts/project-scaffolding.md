# React Native 项目脚手架规则

> 面向创建 React Native 项目的 AI Agent。

## 创建步骤

### Expo 项目（推荐）

1. **MUST** 使用 Expo 托管工作流创建项目
2. **MUST** TypeScript 模板

```bash
npx create-expo-app@latest MyApp --template blank-typescript
```

### React Native CLI 项目（备选）

```bash
npx @react-native-community/cli init MyApp --template react-native-template-typescript
```

## 项目配置

### app.json / app.config.ts（Expo）

```json
{
  "expo": {
    "name": "MyApp",
    "slug": "my-app",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "userInterfaceStyle": "light",
    "splash": {
      "image": "./assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#ffffff"
    },
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.example.myapp"
    },
    "android": {
      "adaptiveIcon": {
        "foregroundImage": "./assets/adaptive-icon.png",
        "backgroundColor": "#ffffff"
      },
      "package": "com.example.myapp"
    },
    "plugins": [
      "expo-secure-store"
    ]
  }
}
```

- **MUST** 配置 `ios.bundleIdentifier` 和 `android.package`
- **MUST** 声明需要的 Expo 插件（如 `expo-secure-store`）
- **SHOULD** 使用 `app.config.ts` 动态配置

### tsconfig.json

```json
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "strict": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@shared/*": ["src/shared/*"],
      "@features/*": ["src/features/*"]
    }
  }
}
```

- **MUST** `strict: true`
- **MUST** 配置路径别名 `@/` 映射到 `src/`

### package.json 关键依赖

```json
{
  "dependencies": {
    "expo": "~51.0.0",
    "react": "18.2.0",
    "react-native": "0.74.0",
    "@react-navigation/native": "^6.1.0",
    "@react-navigation/native-stack": "^6.9.0",
    "@react-navigation/bottom-tabs": "^6.5.0",
    "@tanstack/react-query": "^5.0.0",
    "zustand": "^4.5.0",
    "react-native-reanimated": "~3.10.0",
    "react-native-gesture-handler": "~2.16.0",
    "react-native-fast-image": "^8.6.0",
    "react-native-mmkv": "^3.0.0",
    "react-native-safe-area-context": "4.10.0",
    "react-native-screens": "3.31.0",
    "axios": "^1.7.0",
    "expo-secure-store": "~13.0.0"
  },
  "devDependencies": {
    "@types/react": "~18.2.0",
    "typescript": "~5.4.0",
    "jest": "^29.0.0",
    "@testing-library/react-native": "^12.0.0",
    "eslint": "^8.0.0",
    "prettier": "^3.0.0"
  },
  "scripts": {
    "start": "expo start",
    "android": "expo start --android",
    "ios": "expo start --ios",
    "web": "expo start --web",
    "test": "jest",
    "lint": "eslint . --ext .ts,.tsx",
    "typecheck": "tsc --noEmit"
  }
}
```

## 目录结构

```
MyApp/
├── assets/                     # 静态资源（图标、图片）
├── src/
│   ├── app/
│   │   ├── App.tsx
│   │   └── navigation/
│   ├── features/               # 功能模块
│   ├── shared/                 # 共享代码
│   └── theme/
├── app.json                    # Expo 配置
├── tsconfig.json
├── package.json
├── babel.config.js
├── eas.json                    # EAS Build 配置
├── .eslintrc.js
├── .prettierrc.js
└── .gitignore
```

## 检查清单

- [ ] TypeScript `strict: true`
- [ ] Hermes 引擎启用（`android/app/build.gradle` 中 `hermesEnabled = true`）
- [ ] `react-native-reanimated` 在 `babel.config.js` 中配置 plugin
- [ ] `react-native-gesture-handler` 在 `App.tsx` 根节点包裹 `GestureHandlerRootView`
- [ ] `NavigationContainer` 包裹导航器
- [ ] 路径别名配置（`tsconfig.json` + `babel.config.js`）
- [ ] `.gitignore` 排除 `node_modules/`、`.expo/`、`dist/`
- [ ] EAS Build 配置 `eas.json`
- [ ] `eslint` + `prettier` 配置

## 禁止事项

- **禁止** 使用 JavaScript 模板（必须 TypeScript）
- **禁止** 使用旧版导航（`createStackNavigator`）
- **禁止** 未配置 `GestureHandlerRootView` 包裹根组件
- **禁止** `babel.config.js` 中缺少 `react-native-reanimated/plugin`
- **禁止** 将签名密钥和 Firebase 配置文件提交到 Git
