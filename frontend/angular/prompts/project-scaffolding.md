# Angular 前端项目脚手架规则

> 面向创建 Angular 前端项目的 AI Agent。

## 创建步骤

### 1. 使用 Angular CLI 初始化

```bash
ng new my-app --routing --style=scss --ssr=false --standalone
```

- **MUST** 使用 `--standalone` 标志创建 Standalone 项目
- **MUST** 样式选择 SCSS（`--style=scss`）
- **SHOULD** 启用路由（`--routing`）

### 2. 目录结构

创建以下目录结构：

```
src/app/
├── core/
│   ├── guards/
│   ├── interceptors/
│   ├── models/
│   └── services/
├── shared/
│   ├── components/
│   ├── directives/
│   └── pipes/
├── features/
│   └── (lazy-loaded feature modules)
├── layouts/
├── app.component.ts
├── app.config.ts
└── app.routes.ts
```

```bash
mkdir -p src/app/{core/{guards,interceptors,models,services},shared/{components,directives,pipes},features,layouts}
```

### 3. 安装 UI 库（二选一）

**Angular Material**:
```bash
ng add @angular/material
```

**PrimeNG**:
```bash
npm install primeng @primeng/themes primeicons
```

### 4. app.config.ts 配置

```ts
import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { provideAnimations } from '@angular/platform-browser/animations';

import { routes } from './app.routes';
import { authInterceptor } from './core/interceptors/auth.interceptor';
import { errorInterceptor } from './core/interceptors/error.interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
    provideHttpClient(
      withInterceptors([authInterceptor, errorInterceptor])
    ),
    provideAnimations()
  ]
};
```

### 5. angular.json 配置要点

```json
{
  "projects": {
    "my-app": {
      "architect": {
        "build": {
          "configurations": {
            "production": {
              "budgets": [
                { "type": "initial", "maximumWarning": "500kb", "maximumError": "1mb" }
              ],
              "outputHashing": "all"
            }
          }
        },
        "test": {
          "builder": "@angular-devkit/build-angular:karma",
          "options": {
            "polyfills": ["zone.js", "zone.js/testing"],
            "tsConfig": "tsconfig.spec.json",
            "karmaConfig": "karma.conf.js",
            "codeCoverage": true
          }
        }
      }
    }
  }
}
```

### 6. tsconfig.json

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  },
  "angularCompilerOptions": {
    "strictTemplates": true,
    "strictInjectionParameters": true
  }
}
```

- **MUST** `strict: true` + `strictTemplates: true`
- **SHOULD** 启用 `noUnusedLocals` 和 `noUnusedParameters`

## 检查清单

- [ ] Angular CLI 17+，`--standalone` 创建
- [ ] `app.config.ts` 配置 router、httpClient、animations
- [ ] `core/` 包含 guards、interceptors、services
- [ ] `shared/` 包含可复用 components、directives、pipes
- [ ] `features/` 按业务领域划分，支持懒加载
- [ ] `tsconfig.json` strict 模式
- [ ] `angular.json` 配置 budgets 和 codeCoverage
- [ ] SCSS 作为样式预处理器
- [ ] 环境文件 `environment.ts` / `environment.prod.ts`

## 禁止事项

- **禁止** 在 `core/` 中导入 `features/` 的组件
- **禁止** `shared/` 依赖 `features/` 的代码
- **禁止** 在 Standalone 组件中声明 `providers`（使用 `@Injectable({ providedIn: 'root' })`）
- **禁止** 在生产构建中保留 `console.log`
