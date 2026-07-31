# AGENTS.md — structure-projects AI 规则总索引

> 本仓库是 [structure-projects](https://github.com/structure-projects) 开源生态的 **多技术栈 AI 规则集合**。

## 快速开始

```bash
# 全栈项目（后端 + 前端）
./install.sh -t ../my-erp -s structure-boot,vue3 -w cursor,codebuddy

# 仅后端
./install.sh -t ../my-service -s structure-boot -w all

# 交互模式
./install.sh -i

# 列出所有可用技术栈
./install.sh --list
```

## 技术栈目录

### 后端（按语言）

| 语言 | 技术栈 | 状态 |
|---|---|---|
| **Java** | [structure-boot](backend/java/structure-boot/) | ✅ 内容完整 |
| Java | [spring-boot](backend/java/spring-boot/) | ✅ 内容完整 |
| Java | [micronaut](backend/java/micronaut/) | ✅ 内容完整 |
| Java | [quarkus](backend/java/quarkus/) | ✅ 内容完整 |
| Python | [django](backend/python/django/) | ✅ 内容完整 |
| Python | [fastapi](backend/python/fastapi/) | ✅ 内容完整 |
| Python | [flask](backend/python/flask/) | ✅ 内容完整 |
| Go | [gin](backend/golang/gin/) | ✅ 内容完整 |
| Go | [echo](backend/golang/echo/) | ✅ 内容完整 |
| Rust | [axum](backend/rust/axum/) | ✅ 内容完整 |
| Rust | [actix](backend/rust/actix/) | ✅ 内容完整 |
| Node.js | [nestjs](backend/nodejs/nestjs/) | ✅ 内容完整 |
| Node.js | [koa](backend/nodejs/koa/) | ✅ 内容完整 |
| Node.js | [express](backend/nodejs/express/) | ✅ 内容完整 |

### 前端

| 框架 | 技术栈 | 状态 |
|---|---|---|
| **Vue** | [vue3](frontend/vue3/) | ✅ 内容完整 |
| React | [react](frontend/react/) | ✅ 内容完整 |
| React | [nextjs](frontend/nextjs/) | ✅ 内容完整 |
| Angular | [angular](frontend/angular/) | ✅ 内容完整 |
| Svelte | [svelte](frontend/svelte/) | ✅ 内容完整 |

### 跨平台

| 平台 | 技术栈 | 状态 |
|---|---|---|
| 移动 | [flutter](cross-platform/mobile/flutter/) | ✅ 内容完整 |
| 移动 | [react-native](cross-platform/mobile/react-native/) | ✅ 内容完整 |
| 移动 | [ionic](cross-platform/mobile/ionic/) | ✅ 内容完整 |
| 桌面 | [tauri](cross-platform/desktop/tauri/) | ✅ 内容完整 |
| 桌面 | [electron](cross-platform/desktop/electron/) | ✅ 内容完整 |
| 小程序 | [uniapp](cross-platform/miniapp/uniapp/) | ✅ 内容完整 |
| 原生 | [android](cross-platform/native/android/) | ✅ 内容完整 |
| 原生 | [ios](cross-platform/native/ios/) | ✅ 内容完整 |

### 通用规则

| 文件 | 说明 |
|---|---|
| [_common/prompts/git.md](_common/prompts/git.md) | Git 分支策略与 Commit 规范 |
| [_common/prompts/version-management.md](_common/prompts/version-management.md) | 3 段式语义化版本管理 |
| [_common/prompts/documentation.md](_common/prompts/documentation.md) | 文档管理规范（概要/详细设计+版本快照+变更日志+AI 开发前置验证） |
| [_common/prompts/code-review.md](_common/prompts/code-review.md) | Code Review 通用原则 |
| [_common/prompts/naming.md](_common/prompts/naming.md) | 通用命名规范（跨语言） |
| [_common/prompts/api-design.md](_common/prompts/api-design.md) | RESTful API 设计原则 |
| [_common/prompts/security.md](_common/prompts/security.md) | OWASP 安全基线 |
| [_common/prompts/error-handling.md](_common/prompts/error-handling.md) | 错误处理公约 |
| [_common/prompts/logging.md](_common/prompts/logging.md) | 日志规范 |
| [_common/prompts/testing.md](_common/prompts/testing.md) | 测试策略 |
| [_common/prompts/architecture.md](_common/prompts/architecture.md) | 分层架构通用原则 |
| [_common/prompts/project-structure.md](_common/prompts/project-structure.md) | 项目结构约定 |

## 全栈方案速查

推荐的全栈组合：

| 方案 | 后端规则 | 前端规则 | 说明 |
|---|---|---|---|
| **Vue 3 + structure-boot** | structure-boot | vue3 | structure-projects 标准全栈 |
| Vue 3 + Spring Boot | spring-boot | vue3 | 通用 Spring Boot 全栈 |
| React + structure-boot | structure-boot | react | 待补充 |
| React + Spring Boot | spring-boot | react | 通用 Spring Boot + React |
| React + NestJS | nestjs | react | 全 TypeScript 全栈 |
| React + FastAPI | fastapi | react | Python 后端 + React 前端 |
| React + Gin | gin | react | Go 后端 + React 前端 |
| Vue 3 + Django | django | vue3 | Python Django + Vue 3 |
| Next.js + FastAPI | fastapi | nextjs | 全栈 SSR + Python API |
| Next.js + NestJS | nestjs | nextjs | 全 TypeScript SSR 全栈 |
| UniApp + structure-boot | structure-boot | uniapp | 小程序全栈 |
| UniApp + Spring Boot | spring-boot | uniapp | 通用小程序全栈 |
| Flutter + structure-boot | structure-boot | flutter | 移动端全栈 |
| Flutter + FastAPI | fastapi | flutter | Python 后端 + Flutter |
| React Native + FastAPI | fastapi | react-native | Python 后端 + RN |

## 安装说明

### 项目级安装（推荐）

规则安装到目标项目的 `prompts/` 和各 AI 工具的对应目录：

```bash
./install.sh -t ../my-project -s structure-boot,vue3 -w cursor,codebuddy,claude
```

安装后目标项目结构：
```
my-project/
├── prompts/                    # 完整规则文件
│   ├── structure-boot/         # 后端规则
│   ├── vue3/                   # 前端规则
│   └── _common/prompts/         # 通用规则（-c 选项）
├── .cursor/rules/              # Cursor 自动加载
├── .codebuddy/rules/           # CodeBuddy 自动加载
├── .claude/agents/             # Claude Code Agents
├── .trae/rules/                # Trae
├── .lingma/rules/              # 通义灵码
└── AGENTS.md                   # Codex 合并规则（-w codex）
```

### 冲突避免

- 各技术栈文件名自带前缀（如 `structure-boot-developer.mdc`、`vue3-developer.mdc`），组合使用时天然不冲突。
- AI 工具是扁平加载，多技术栈规则并行生效。
- 规则内容互补不重复：后端规则管 Java/Spring，前端规则管 Vue/TS。

### 维护规则

- 每个技术栈目录 **自包含**，不依赖 `_shared/` 或其他技术栈。
- 修改规则时先改对应 `prompts/<role>.md`，再评估是否需要同步 IDE 包装文件。
- 占位目录按需补充，补充时参考现有完整目录的结构。

## 贡献

欢迎补充占位技术栈或改进已有规则。

- 目录结构：每个技术栈目录包含 `prompts/` + IDE 包装文件 + `codex/AGENTS.md`
- 规则使用 RFC 2119 风格标注强制级别（MUST / SHOULD / MAY）
- `install.sh` 会自动发现新目录
