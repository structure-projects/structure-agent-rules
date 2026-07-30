# UniApp 前端架构规则

> 角色：uniapp-architect（前端架构）。面向需要做 UniApp 前端架构选型与技术决策的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。

## UniApp 版本与模式

- **MUST** 使用 Vue 3 + UniApp（`@dcloudio/uni-app`）。
- **SHOULD** 使用 Vue 3 Composition API（`<script setup>`）。
- **MUST** 在 `pages.json` 中配置所有页面、tabBar、导航栏。

## 项目结构

```
my-app/
├── src/
│   ├── pages/              # 页面（每个页面一个目录）
│   │   ├── index/
│   │   │   └── index.vue
│   │   └── user/
│   │       └── index.vue
│   ├── components/         # 公共组件
│   ├── api/                # API 请求封装
│   ├── stores/             # Pinia 状态管理
│   ├── utils/              # 工具函数
│   ├── static/             # 静态资源
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

## pages.json 配置

```json
{
  "pages": [
    {
      "path": "pages/index/index",
      "style": {
        "navigationBarTitleText": "首页"
      }
    }
  ],
  "tabBar": {
    "color": "#999",
    "selectedColor": "#007AFF",
    "list": [
      {
        "pagePath": "pages/index/index",
        "text": "首页",
        "iconPath": "static/tab/home.png",
        "selectedIconPath": "static/tab/home-active.png"
      }
    ]
  },
  "globalStyle": {
    "navigationBarTextStyle": "black",
    "navigationBarTitleText": "My App",
    "navigationBarBackgroundColor": "#F8F8F8"
  }
}
```

- **MUST** `pages` 数组的第一项为首页
- **MUST** tabBar 图标使用本地静态资源
- **MUST** `globalStyle` 定义全局导航栏样式

## 路由

- **MUST** 路由由 `pages.json` 的 `pages` 和 `subPackages` 定义
- **MUST** 页面跳转使用 UniApp API：

```ts
// 普通跳转
uni.navigateTo({ url: '/pages/user/index?id=1' });

// Tab 页跳转
uni.switchTab({ url: '/pages/index/index' });

// 重定向
uni.redirectTo({ url: '/pages/login/index' });

// 返回
uni.navigateBack({ delta: 1 });
```

- **SHOULD** 参数通过 URL query 传递（`?id=1&name=test`）
- **MAY** 复杂参数通过 `uni.$emit` / `uni.$on` 事件总线传递

## 状态管理

- **MUST** 使用 Pinia（Setup Store 语法）
- **SHOULD** 按领域拆分 store

```ts
// stores/user.ts
import { defineStore } from 'pinia';

export const useUserStore = defineStore('user', () => {
  const userInfo = ref<UniApp.UserInfo | null>(null);
  const token = ref('');

  const login = async () => {
    // uni.login() + 后端接口
  };

  return { userInfo, token, login };
});
```

## 条件编译

```vue
<template>
  <view>
    <!-- #ifdef H5 -->
    <web-view src="https://example.com" />
    <!-- #endif -->

    <!-- #ifdef MP-WEIXIN -->
    <button open-type="getUserInfo">微信登录</button>
    <!-- #endif -->
  </view>
</template>

<script setup lang="ts">
// #ifdef H5
console.log('H5 platform');
// #endif

// #ifdef MP-WEIXIN
console.log('WeChat Mini Program');
// #endif
</script>

<style>
/* #ifdef H5 */
.page { max-width: 750px; margin: 0 auto; }
/* #endif */
</style>
```

- **MUST** 平台差异代码使用条件编译（`#ifdef` / `#ifndef` / `#endif`）
- **SHOULD** 条件编译尽量封装在工具函数中，减少模板中散布
- 支持平台：`H5`、`MP-WEIXIN`、`MP-ALIPAY`、`MP-BAIDU`、`MP-TOUTIAO`、`APP-PLUS`

## UI 组件库

- **SHOULD** 使用 uView Plus（`uview-plus`）作为主要 UI 库
- **MAY** 使用 Uni UI（`@dcloudio/uni-ui`）作为补充
- **禁止** 同时引入多个功能重叠的 UI 库

## 后端通信

- **SHOULD** 使用 `uni.request` 封装统一的 HTTP 客户端
- **MAY** 使用 uniCloud 作为 BaaS 后端
- **MUST** 请求拦截器中统一处理 Token 刷新和错误提示

## manifest.json 配置

```json
{
  "name": "my-app",
  "appid": "__UNI__XXXXXX",
  "versionName": "1.0.0",
  "mp-weixin": {
    "appid": "wxXXXXXXXXXXXXXXXX",
    "setting": {
      "urlCheck": false
    }
  }
}
```

- **MUST** 各平台 appid 在 `manifest.json` 中配置
- **MUST** 微信小程序 `urlCheck` 开发期设为 `false`
