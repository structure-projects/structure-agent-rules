# Angular 组件使用规范

> 本文件描述 Angular 项目中组件的使用规范。本规则自包含，不依赖其他技术栈目录。

## Standalone Components（推荐）

```ts
// user-card.component.ts
import { Component, input, output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';

@Component({
  selector: 'app-user-card',
  standalone: true,
  imports: [CommonModule, MatCardModule],
  template: `
    <mat-card>
      <mat-card-header>
        <mat-card-title>{{ user().name }}</mat-card-title>
      </mat-card-header>
      <mat-card-content>{{ user().email }}</mat-card-content>
      <mat-card-actions>
        <button (click)="delete.emit(user().id)">Delete</button>
      </mat-card-actions>
    </mat-card>
  `,
  styles: [`
    mat-card { margin: 8px; }
  `]
})
export class UserCardComponent {
  user = input.required<User>();
  delete = output<string>();
}
```

- **MUST** 新组件使用 `standalone: true`
- **MUST** 明确声明 `imports` 数组（所需的模块/组件/指令/管道）
- **SHOULD** 使用 Signals API（`input()`、`output()`、`model()`）替代 `@Input()` / `@Output()` 装饰器

## 组件生命周期

| 生命周期 | 使用场景 |
|---|---|
| `ngOnInit()` | 组件初始化，获取数据 |
| `ngOnChanges()` | 响应 `@Input()` 变化（Signals 时代减少使用） |
| `ngOnDestroy()` | 取消订阅、清理资源 |
| `ngAfterViewInit()` | 操作 DOM 或子组件视图 |

- **MUST** 在 `ngOnDestroy()` 中取消 RxJS 订阅（或用 `takeUntilDestroyed()` 自动管理）
- **SHOULD** 使用 `effect()` 替代手动生命周期钩子做副作用

## 组件命名

- **MUST** 组件文件使用 kebab-case（`user-card.component.ts`）
- **MUST** 组件类名使用 PascalCase（`UserCardComponent`）
- **MUST** selector 使用 `app-` 前缀（`app-user-card`）

## 组件通信

```ts
// 父→子：使用 input() signal
// 子→父：使用 output()
@Component({...})
export class ParentComponent {
  users = signal<User[]>([]);
}
```

```html
<!-- 模板中 -->
<app-user-card [user]="user" (delete)="handleDelete($event)" />
```

- **SHOULD** 跨层级组件通信使用共享 Service + Signals
- **MAY** 简单父子通信使用 `@Input()` / `@Output()`（遗留代码兼容）

## 指令

```ts
import { Directive, ElementRef, input, effect } from '@angular/core';

@Directive({
  selector: '[appHighlight]',
  standalone: true
})
export class HighlightDirective {
  color = input<string>('yellow');
  
  constructor(private el: ElementRef) {
    effect(() => {
      this.el.nativeElement.style.backgroundColor = this.color();
    });
  }
}
```

- **SHOULD** 可复用的 DOM 操作封装为 Attribute Directive
- **SHOULD** 可复用的模板逻辑封装为 Structural Directive

## 管道

```ts
import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'currencyFormat',
  standalone: true
})
export class CurrencyFormatPipe implements PipeTransform {
  transform(value: number, currency: string = 'CNY'): string {
    return new Intl.NumberFormat('zh-CN', { style: 'currency', currency }).format(value);
  }
}
```

- **MUST** 管道为纯函数，无副作用
- **SHOULD** 管道标记 `standalone: true`
- **禁止** 在管道中发起 HTTP 请求

## Angular Material

- **SHOULD** 优先使用 Angular Material CDK 构建自定义交互
- **MUST** 主题通过 `@angular/material` 的 theming API 统一配置
- **禁止** 覆盖 Material 组件的内部 CSS 类（使用主题变量）
