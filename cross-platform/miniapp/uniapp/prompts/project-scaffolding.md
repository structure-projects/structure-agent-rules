# UniApp 前端项目脚手架规则

> 面向创建 UniApp 前端项目的 AI Agent。

## 创建步骤

### 1. 使用 CLI 初始化

**HBuilderX**（推荐）:
- 文件 → 新建 → 项目 → uni-app → Vue 3 版本

**CLI**:
```bash
npx degit dcloudio/uni-preset-vue#vite-ts my-app
cd my-app
npm install
```

### 2. 安装依赖

```bash
# UI 组件库
npm install uview-plus

# 状态管理
npm install pinia

# 工具库
npm install dayjs
```

### 3. 目录结构

```bash
mkdir -p src/{pages,components,api,stores,utils,static/images}
```

```
my-app/
├── src/
│   ├── pages/              # 页面目录
│   │   ├── index/
│   │   │   └── index.vue
│   │   └── user/
│   │       └── index.vue
│   ├── components/         # 公共组件（easycom 自动导入）
│   ├── api/                # API 封装
│   │   ├── request.ts      # 统一请求
│   │   └── user.ts         # 用户 API
│   ├── stores/             # Pinia
│   │   └── user.ts
│   ├── utils/              # 工具函数
│   ├── static/             # 静态资源
│   │   └── images/
│   ├── App.vue
│   ├── main.ts
│   ├── pages.json          # 页面配置（核心）
│   ├── manifest.json       # 应用配置
│   └── uni.scss            # 全局 SCSS 变量
├── index.html
├── vite.config.ts
├── tsconfig.json
└── package.json
```

### 4. pages.json 模板

```json
{
  "easycom": {
    "autoscan": true,
    "custom": {
      "^u-(.*)": "uview-plus/components/u-$1/u-$1.vue"
    }
  },
  "pages": [
    {
      "path": "pages/index/index",
      "style": {
        "navigationBarTitleText": "首页"
      }
    },
    {
      "path": "pages/user/index",
      "style": {
        "navigationBarTitleText": "我的"
      }
    }
  ],
  "tabBar": {
    "color": "#999999",
    "selectedColor": "#007AFF",
    "backgroundColor": "#FFFFFF",
    "list": [
      {
        "pagePath": "pages/index/index",
        "text": "首页",
        "iconPath": "static/tab/home.png",
        "selectedIconPath": "static/tab/home-active.png"
      },
      {
        "pagePath": "pages/user/index",
        "text": "我的",
        "iconPath": "static/tab/user.png",
        "selectedIconPath": "static/tab/user-active.png"
      }
    ]
  },
  "globalStyle": {
    "navigationBarTextStyle": "black",
    "navigationBarTitleText": "My App",
    "navigationBarBackgroundColor": "#F8F8F8",
    "backgroundColor": "#F5F5F5"
  },
  "subPackages": []
}
```

### 5. manifest.json 模板

```json
{
  "name": "my-app",
  "appid": "__UNI__XXXXXX",
  "description": "",
  "versionName": "1.0.0",
  "versionCode": "100",
  "transformPx": false,
  "mp-weixin": {
    "appid": "wxXXXXXXXXXXXXXXXX",
    "setting": {
      "urlCheck": false,
      "es6": true,
      "postcss": true,
      "minified": true
    }
  },
  "h5": {
    "router": {
      "mode": "hash"
    }
  }
}
```

### 6. main.ts 入口

```ts
import { createSSRApp } from 'vue';
import { createPinia } from 'pinia';
import uviewPlus from 'uview-plus';
import App from './App.vue';

export function createApp() {
  const app = createSSRApp(App);
  const pinia = createPinia();

  app.use(pinia);
  app.use(uviewPlus);

  return { app };
}
```

- **MUST** 使用 `createSSRApp`（非 `createApp`）
- **MUST** 导出 `createApp` 函数
- **MUST** `uview-plus` 注册为插件

## 检查清单

- [ ] Vue 3 + UniApp CLI 创建
- [ ] `pages.json` 配置所有页面、tabBar、globalStyle
- [ ] `manifest.json` 配置各平台 appid
- [ ] `main.ts` 使用 `createSSRApp` + Pinia + uView Plus
- [ ] `easycom` 自动导入配置
- [ ] `uni.scss` 全局 SCSS 变量
- [ ] `api/request.ts` 统一请求封装
- [ ] `stores/` Pinia Setup Store
- [ ] `static/` 目录放置 tabBar 图标和静态资源

## 禁止事项

- **禁止** 使用 `createApp` 替代 `createSSRApp`
- **禁止** 使用 Vue Router（路由由 `pages.json` 管理）
- **禁止** 使用 `px` 单位（应使用 `rpx`）
- **禁止** 在 H5 代码中调用小程序特有 API
- **禁止** 在 `onLaunch` 中使用 async/await（需同步初始化）
