# Ionic 组件使用规范

> 本文件描述 Ionic 开发中的 UI 组件、Capacitor 插件和第三方库使用规范。
> 本规则自包含，不依赖其他技术栈目录。

## Ionic 核心组件

### 布局组件

```html
<!-- 页面结构 -->
<ion-app>
  <ion-split-pane content-id="main-content">
    <ion-menu content-id="main-content">
      <ion-header><ion-toolbar><ion-title>菜单</ion-title></ion-toolbar></ion-header>
      <ion-content>
        <ion-list>
          <ion-menu-toggle>
            <ion-item routerLink="/home">首页</ion-item>
          </ion-menu-toggle>
        </ion-list>
      </ion-content>
    </ion-menu>
    <ion-router-outlet id="main-content"></ion-router-outlet>
  </ion-split-pane>
</ion-app>
```

- **MUST** `<ion-app>` 作为根组件
- **MUST** `<ion-split-pane>` 实现平板端侧边栏布局
- **MUST** `<ion-router-outlet>` 用于页面渲染出口

### 导航组件

```html
<!-- Tab 导航 -->
<ion-tabs>
  <ion-tab-bar slot="bottom">
    <ion-tab-button tab="home">
      <ion-icon name="home"></ion-icon>
      <ion-label>首页</ion-label>
    </ion-tab-button>
    <ion-tab-button tab="profile">
      <ion-icon name="person"></ion-icon>
      <ion-label>我的</ion-label>
    </ion-tab-button>
  </ion-tab-bar>
</ion-tabs>
```

- **MUST** 底部 Tab 使用 `<ion-tabs>` + `<ion-tab-bar>`
- **MUST** `<ion-tab-button>` 必须指定 `tab` 属性

### 列表组件

```html
<ion-list>
  <ion-list-header>
    <ion-label>用户列表</ion-label>
  </ion-list-header>
  
  <ion-item-sliding *ngFor="let user of users">
    <ion-item>
      <ion-avatar slot="start">
        <img [src]="user.avatar" />
      </ion-avatar>
      <ion-label>
        <h2>{{ user.name }}</h2>
        <p>{{ user.email }}</p>
      </ion-label>
      <ion-note slot="end">{{ user.role }}</ion-note>
    </ion-item>
    
    <ion-item-options side="end">
      <ion-item-option color="danger" (click)="deleteUser(user)">
        <ion-icon slot="icon-only" name="trash"></ion-icon>
      </ion-item-option>
    </ion-item-options>
  </ion-item-sliding>
</ion-list>
```

- **MUST** `<ion-list>` 内使用 `<ion-item>` 作为子元素
- **MUST** 使用 `slot="start"` / `slot="end"` 定位图标、头像、备注
- **MUST** 滑动操作使用 `<ion-item-sliding>` + `<ion-item-options>`

### 表单组件

```html
<form (ngSubmit)="onSubmit()" #loginForm="ngForm">
  <ion-item>
    <ion-label position="floating">邮箱</ion-label>
    <ion-input
      type="email"
      [(ngModel)]="email"
      name="email"
      required
      email
      autocomplete="email"
    ></ion-input>
    <ion-note slot="error" *ngIf="loginForm.controls['email']?.invalid">
      请输入有效的邮箱地址
    </ion-note>
  </ion-item>

  <ion-item>
    <ion-label position="floating">密码</ion-label>
    <ion-input
      type="password"
      [(ngModel)]="password"
      name="password"
      required
      minlength="6"
    ></ion-input>
  </ion-item>

  <ion-button expand="block" type="submit" [disabled]="loginForm.invalid">
    登录
  </ion-button>
</form>
```

- **MUST** `<ion-input>` 替代 `<input>`
- **MUST** `<ion-label position="floating">` 实现浮动标签
- **MUST** 表单验证使用框架内置机制（Angular Forms / React Hook Form / VeeValidate）
- **SHOULD** 使用 `<ion-note slot="error">` 显示验证错误

### 反馈组件

```typescript
// Toast
import { ToastController } from '@ionic/angular';

constructor(private toastController: ToastController) {}

async showToast(message: string, color: 'success' | 'danger' = 'success') {
  const toast = await this.toastController.create({
    message,
    duration: 2000,
    color,
    position: 'bottom',
  });
  await toast.present();
}

// Alert
async showConfirm(message: string): Promise<boolean> {
  const alert = await this.alertController.create({
    header: '确认',
    message,
    buttons: [
      { text: '取消', role: 'cancel' },
      { text: '确认', handler: () => true },
    ],
  });
  await alert.present();
  const { role } = await alert.onDidDismiss();
  return role !== 'cancel';
}

// Loading
async showLoading(message = '加载中...') {
  const loading = await this.loadingController.create({ message });
  await loading.present();
  return loading;
}

// Modal
async openModal(component: any, props?: any) {
  const modal = await this.modalController.create({
    component,
    componentProps: props,
    cssClass: 'my-modal',
  });
  await modal.present();
  const { data } = await modal.onDidDismiss();
  return data;
}
```

- **MUST** Toast 用于短暂操作反馈
- **MUST** Alert 用于确认操作
- **MUST** Loading 用于异步操作等待
- **MUST** Modal 用于子页面或表单

## Capacitor 插件封装

### Camera 插件

```typescript
import { Camera, CameraResultType, CameraSource, Photo } from '@capacitor/camera';

@Injectable({ providedIn: 'root' })
export class CameraService {
  async takePhoto(): Promise<Photo> {
    const photo = await Camera.getPhoto({
      resultType: CameraResultType.Uri,
      source: CameraSource.Camera,
      quality: 90,
      allowEditing: true,
    });
    return photo;
  }

  async pickFromGallery(): Promise<Photo> {
    const photo = await Camera.getPhoto({
      resultType: CameraResultType.Uri,
      source: CameraSource.Photos,
      quality: 90,
    });
    return photo;
  }
}
```

### Filesystem 插件

```typescript
import { Filesystem, Directory, Encoding } from '@capacitor/filesystem';

@Injectable({ providedIn: 'root' })
export class FileService {
  async writeFile(path: string, data: string): Promise<void> {
    await Filesystem.writeFile({
      path,
      data,
      directory: Directory.Data,
      encoding: Encoding.UTF8,
    });
  }

  async readFile(path: string): Promise<string> {
    const result = await Filesystem.readFile({
      path,
      directory: Directory.Data,
      encoding: Encoding.UTF8,
    });
    return result.data as string;
  }

  async deleteFile(path: string): Promise<void> {
    await Filesystem.deleteFile({
      path,
      directory: Directory.Data,
    });
  }
}
```

### Preferences 插件

```typescript
import { Preferences } from '@capacitor/preferences';

@Injectable({ providedIn: 'root' })
export class StorageService {
  async set<T>(key: string, value: T): Promise<void> {
    await Preferences.set({
      key,
      value: JSON.stringify(value),
    });
  }

  async get<T>(key: string): Promise<T | null> {
    const { value } = await Preferences.get({ key });
    return value ? JSON.parse(value) : null;
  }

  async remove(key: string): Promise<void> {
    await Preferences.remove({ key });
  }

  async clear(): Promise<void> {
    await Preferences.clear();
  }
}
```

## 平台检测服务

```typescript
import { Platform } from '@ionic/angular';

@Injectable({ providedIn: 'root' })
export class PlatformService {
  constructor(private platform: Platform) {}

  isIOS(): boolean { return this.platform.is('ios'); }
  isAndroid(): boolean { return this.platform.is('android'); }
  isMobile(): boolean { return this.platform.is('mobile'); }
  isDesktop(): boolean { return this.platform.is('desktop'); }
  isHybrid(): boolean { return this.platform.is('hybrid'); }
  isPWA(): boolean { return this.platform.is('pwa'); }
  
  getPlatforms(): string[] { return this.platform.platforms(); }
}
```

- **MUST** 使用 `Platform` 服务（非 `navigator.userAgent`）
- **MUST** 平台相关逻辑封装在 `PlatformService` 中

## 响应式布局

```html
<ion-grid>
  <ion-row>
    <ion-col size="12" size-md="6" size-lg="4" *ngFor="let item of items">
      <ion-card>
        <ion-card-content>
          {{ item.title }}
        </ion-card-content>
      </ion-card>
    </ion-col>
  </ion-row>
</ion-grid>
```

- **MUST** 使用 `<ion-grid>` + `<ion-row>` + `<ion-col>` 栅格系统
- **MUST** `size` / `size-md` / `size-lg` 实现响应式
- **MUST** 断点：xs(<576px)、sm(>=576px)、md(>=768px)、lg(>=992px)、xl(>=1200px)

## 虚拟滚动

```html
<ion-virtual-scroll [items]="users" [approxItemHeight]="60">
  <ion-item *virtualItem="let user">
    <ion-label>{{ user.name }}</ion-label>
  </ion-item>
</ion-virtual-scroll>
```

- **MUST** 长列表（>50 项）使用 `ion-virtual-scroll`
- **MUST** 设置合理的 `approxItemHeight`

## 无限滚动

```html
<ion-content>
  <ion-list>
    <ion-item *ngFor="let user of users">
      <ion-label>{{ user.name }}</ion-label>
    </ion-item>
  </ion-list>
  
  <ion-infinite-scroll (ionInfinite)="loadMore($event)">
    <ion-infinite-scroll-content
      loadingText="加载更多..."
      loadingSpinner="bubbles"
    ></ion-infinite-scroll-content>
  </ion-infinite-scroll>
</ion-content>
```

```typescript
async loadMore(event: InfiniteScrollCustomEvent) {
  const newUsers = await this.userService.getUsers(this.currentPage + 1);
  this.users.push(...newUsers);
  event.target.complete();
  
  if (newUsers.length === 0) {
    event.target.disabled = true;
  }
}
```

- **MUST** 分页加载使用 `ion-infinite-scroll`
- **MUST** 数据加载完成后调用 `event.target.complete()`
- **MUST** 无更多数据时禁用 `event.target.disabled = true`

## 下拉刷新

```html
<ion-content>
  <ion-refresher slot="fixed" (ionRefresh)="doRefresh($event)">
    <ion-refresher-content></ion-refresher-content>
  </ion-refresher>
  <!-- 内容 -->
</ion-content>
```

```typescript
async doRefresh(event: RefresherCustomEvent) {
  await this.loadData();
  event.target.complete();
}
```

- **MUST** 使用 `ion-refresher` 实现下拉刷新
- **MUST** 刷新完成后调用 `event.target.complete()`
