# UniApp 前端开发规则

> 角色：uniapp-developer（前端）。面向开发 UniApp 跨平台应用的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。

## 硬约束

- **MUST** Vue 3 + UniApp（`@dcloudio/uni-app`）。
- **MUST** 使用 `<script setup lang="ts">`。
- **MUST** `pages.json` 配置所有页面路由和 tabBar。
- **MUST** `manifest.json` 配置各平台 appid 和权限。
- **SHOULD** uView Plus（`uview-plus`）作为 UI 组件库。
- **SHOULD** Pinia 作为状态管理方案。

## 关键优先级

- **路由**：`pages.json` 配置（非 Vue Router）
- **状态管理**：Pinia Setup Store
- **样式**：`rpx` 单位 + scoped + uni.scss 变量
- **平台差异**：条件编译（`#ifdef` / `#ifndef`）

## 应用生命周期

```ts
// App.vue
<script setup lang="ts">
import { onLaunch, onShow, onHide } from '@dcloudio/uni-app';

onLaunch((options) => {
  console.log('App Launch', options);
  // 初始化全局数据
});

onShow((options) => {
  console.log('App Show', options);
});

onHide(() => {
  console.log('App Hide');
});
</script>
```

- **MUST** `onLaunch` 中初始化全局状态（Token、用户信息）
- **SHOULD** `onShow` 中刷新需要的数据

## 页面生命周期

```ts
// pages/user/index.vue
<script setup lang="ts">
import { onLoad, onShow, onReady, onHide, onUnload } from '@dcloudio/uni-app';

onLoad((options) => {
  // 页面加载，接收 URL 参数
  console.log('Page Load', options.id);
});

onShow(() => {
  // 页面显示（每次进入）
});

onReady(() => {
  // 页面初次渲染完成
});

onHide(() => {
  // 页面隐藏
});

onUnload(() => {
  // 页面卸载
});
</script>
```

- **MUST** `onLoad` 接收页面参数
- **SHOULD** 数据请求在 `onLoad` 或 `onShow` 中发起
- **MUST** 在 `onUnload` 中清理定时器、事件监听

## API 调用规范

```ts
// api/request.ts
import { useUserStore } from '@/stores/user';

const BASE_URL = 'https://api.example.com';

interface RequestOptions {
  url: string;
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE';
  data?: Record<string, any>;
  header?: Record<string, string>;
}

export const request = <T = any>(options: RequestOptions): Promise<T> => {
  const userStore = useUserStore();

  return new Promise((resolve, reject) => {
    uni.request({
      url: BASE_URL + options.url,
      method: options.method || 'GET',
      data: options.data,
      header: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${userStore.token}`,
        ...options.header
      },
      success: (res) => {
        if (res.statusCode === 200) {
          resolve(res.data as T);
        } else if (res.statusCode === 401) {
          uni.reLaunch({ url: '/pages/login/index' });
          reject(new Error('Unauthorized'));
        } else {
          uni.showToast({ title: '请求失败', icon: 'none' });
          reject(new Error(`HTTP ${res.statusCode}`));
        }
      },
      fail: (err) => {
        uni.showToast({ title: '网络异常', icon: 'none' });
        reject(err);
      }
    });
  });
};
```

- **MUST** 封装 `uni.request` 为统一的 request 函数
- **MUST** 拦截器中处理 401 Token 过期跳转登录页
- **MUST** 错误统一 `uni.showToast` 提示
- **禁止** 直接在业务代码中调用 `uni.request`

## 路由跳转

```ts
// 普通页面跳转
uni.navigateTo({ url: '/pages/detail/index?id=1' });

// Tab 页跳转
uni.switchTab({ url: '/pages/index/index' });

// 重定向（不可返回）
uni.redirectTo({ url: '/pages/login/index' });

// 关闭所有页面，打开新页面
uni.reLaunch({ url: '/pages/index/index' });

// 返回上一页
uni.navigateBack({ delta: 1 });

// 带参数传递
uni.navigateTo({
  url: `/pages/detail/index?id=${item.id}&name=${encodeURIComponent(item.name)}`
});
```

- **MUST** 简单参数通过 URL query 传递
- **SHOULD** 复杂数据通过 `uni.$emit` / Pinia store 传递
- **MUST** Tab 页跳转用 `switchTab`

## 样式规范

```scss
/* uni.scss - 全局 SCSS 变量 */
$primary-color: #007AFF;
$bg-color: #F5F5F5;
$text-color: #333;
$border-radius: 12rpx;
```

```vue
<style scoped>
.page {
  padding: 20rpx;
  background-color: $bg-color; /* uni.scss 变量全局可用 */
}

.title {
  font-size: 36rpx;
  font-weight: bold;
  color: $text-color;
}
</style>
```

- **MUST** 尺寸使用 `rpx` 单位（750rpx = 屏幕宽度）
- **MUST** 全局变量在 `uni.scss` 中定义
- **MUST** 组件样式使用 scoped
- **禁止** 使用 `px` 单位（除非明确需要固定像素）

## 状态管理（Pinia）

```ts
// stores/user.ts
import { defineStore } from 'pinia';
import { request } from '@/api/request';

export const useUserStore = defineStore('user', () => {
  const userInfo = ref<UserInfo | null>(null);
  const token = ref('');

  const isLogin = computed(() => !!token.value);

  const login = async (code: string) => {
    const res = await request<{ token: string; user: UserInfo }>({
      url: '/auth/login',
      method: 'POST',
      data: { code }
    });
    token.value = res.token;
    userInfo.value = res.user;
    uni.setStorageSync('token', res.token);
  };

  const logout = () => {
    token.value = '';
    userInfo.value = null;
    uni.removeStorageSync('token');
    uni.reLaunch({ url: '/pages/login/index' });
  };

  return { userInfo, token, isLogin, login, logout };
});
```

- **MUST** 使用 Setup Store 语法
- **MUST** Token 持久化到 `uni.setStorageSync`
- **SHOULD** 按领域拆分 store

## 条件编译

| 编译指令 | 说明 |
|---|---|
| `#ifdef PLATFORM` | 仅在指定平台编译 |
| `#ifndef PLATFORM` | 除指定平台外编译 |
| `#endif` | 结束条件块 |

常见平台标识：`H5`、`MP-WEIXIN`、`MP-ALIPAY`、`MP-BAIDU`、`MP-TOUTIAO`、`APP-PLUS`、`APP-PLUS-NVUE`

## 测试工作流

- 每开发一个功能**立即**在至少一个目标平台验证
- 功能修改时**同步修改测试**并通过
- **提交前**：`npm run test` 全部通过 + 所有目标平台 `npm run build` 成功
- **禁止** 测试/编译失败仍提交
