# UniApp 组件使用规范

> 本文件描述 UniApp 项目中组件的使用规范。本规则自包含，不依赖其他技术栈目录。

## 组件结构

```vue
<template>
  <view class="user-card">
    <u-avatar :src="avatar" size="80" />
    <view class="info">
      <text class="name">{{ userName }}</text>
      <text class="email">{{ email }}</text>
    </view>
  </view>
</template>

<script setup lang="ts">
import { computed } from 'vue';

interface Props {
  userName: string;
  email: string;
  avatar?: string;
}

const props = withDefaults(defineProps<Props>(), {
  avatar: '/static/default-avatar.png'
});

const emit = defineEmits<{
  tap: [id: string];
}>();

const handleTap = () => {
  emit('tap', props.userName);
};
</script>

<style scoped>
.user-card {
  display: flex;
  align-items: center;
  padding: 20rpx;
  background-color: #fff;
  border-radius: 12rpx;
}
.info {
  margin-left: 20rpx;
}
.name {
  font-size: 32rpx;
  font-weight: bold;
}
.email {
  font-size: 24rpx;
  color: #999;
}
</style>
```

- **MUST** 使用 `<script setup lang="ts">`
- **MUST** Props 完整 TypeScript 类型
- **MUST** 样式使用 `rpx` 单位（响应式像素）
- **MUST** 样式 scoped

## UniApp 内置组件

| 组件 | 说明 |
|---|---|
| `<view>` | 容器（类似 div） |
| `<text>` | 文本（支持选择、长按） |
| `<image>` | 图片（支持懒加载、mode） |
| `<scroll-view>` | 可滚动视图 |
| `<swiper>` | 轮播滑块 |
| `<button>` | 按钮（支持 open-type） |
| `<input>` | 输入框 |
| `<navigator>` | 页面链接 |
| `<web-view>` | 内嵌网页（H5/小程序） |

- **MUST** 文本内容包裹在 `<text>` 中
- **MUST** 图片使用 `<image>` 标签（非 `<img>`）
- **SHOULD** 长列表使用 `<scroll-view>` + `scroll-y`

## uView Plus 组件库

```vue
<template>
  <view>
    <u-button type="primary" @click="handleClick">提交</u-button>
    <u-input v-model="name" placeholder="请输入姓名" />
    <u-form :model="form" :rules="rules">
      <u-form-item label="姓名" prop="name">
        <u-input v-model="form.name" />
      </u-form-item>
    </u-form>
    <u-modal v-model:show="showModal" title="提示" @confirm="confirm" />
    <u-toast ref="toastRef" />
  </view>
</template>
```

- **SHOULD** 优先使用 uView Plus 组件
- **MUST** 使用 `u-` 前缀的组件名

## 平台适配

### 条件编译组件

```vue
<template>
  <view>
    <!-- 微信小程序专用 -->
    <!-- #ifdef MP-WEIXIN -->
    <button open-type="getUserInfo" @getuserinfo="onGetUserInfo">
      微信授权
    </button>
    <!-- #endif -->

    <!-- H5 专用 -->
    <!-- #ifdef H5 -->
    <button @click="h5Login">H5 登录</button>
    <!-- #endif -->
  </view>
</template>
```

### 平台 API 调用

```ts
// 获取系统信息
const systemInfo = uni.getSystemInfoSync();
const isIOS = systemInfo.platform === 'ios';

// 平台判断
// #ifdef MP-WEIXIN
wx.showShareMenu();
// #endif
```

- **MUST** 平台差异代码用条件编译隔离
- **SHOULD** 封装平台适配层，业务代码不直接写条件编译

## 小程序特有组件

```vue
<template>
  <!-- 微信开放能力 -->
  <button open-type="share">分享</button>
  <button open-type="contact">客服</button>

  <!-- 原生组件 -->
  <map :latitude="lat" :longitude="lng" />
  <video src="https://example.com/video.mp4" />
</template>
```

- **MUST** 小程序原生组件在条件编译块中使用
- **禁止** 在 H5 模式使用小程序特有 API

## 自定义组件规范

```vue
<!-- components/user-avatar/index.vue -->
<template>
  <view class="user-avatar" @tap="handleTap">
    <image :src="src" mode="aspectFill" class="avatar-img" />
    <text v-if="name" class="name">{{ name }}</text>
  </view>
</template>

<script setup lang="ts">
interface Props {
  src: string;
  name?: string;
  size?: number;
}

const props = withDefaults(defineProps<Props>(), {
  size: 80
});

const emit = defineEmits<{
  click: [];
}>();

const handleTap = () => emit('click');
</script>

<style scoped>
.avatar-img {
  width: v-bind('props.size + "rpx"');
  height: v-bind('props.size + "rpx"');
  border-radius: 50%;
}
</style>
```

- **MUST** 组件放在 `components/` 目录
- **MUST** 每个组件一个目录（`index.vue`）
- **SHOULD** 支持 easycom 自动导入（`components/` 下组件无需手动 import）
