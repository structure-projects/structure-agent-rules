# Vue 3 前端规则索引

> structure-projects Vue 3 前端技术栈规则集合。
> 用于约束 AI Agent 在 Vue 3 前端项目中的行为。

## 可用角色

| 角色 | 文件 | 说明 |
|---|---|---|
| 开发 | `prompts/developer.md` | Vue 3 前端开发约束 |
| 架构 | `prompts/architect.md` | 前端架构与选型 |
| 组件 | `prompts/components.md` | 组件库使用规范 |
| 脚手架 | `prompts/project-scaffolding.md` | 前端项目创建 |
| 测试 | `prompts/tester.md` | 前端测试规范 |
| 评审 | `prompts/reviewer.md` | 前端评审清单 |
| CI/CD | `prompts/ci-cd.md` | 前端流水线 |

## 使用方式

### 独立使用（纯前端项目）
将本目录拷到目标项目的 `.structure-rules/prompts/vue3/`。

### 组合使用（全栈项目）
与 `backend/java/structure-boot/` 组合安装，由 `install.sh` 自动处理文件名前缀避免冲突。

```bash
install.sh -t ../my-project -s structure-boot,vue3 -w cursor,codebuddy
```

### IDE 工具

各工具包装文件位于本目录下 `.claude/`、`.cursor/`、`.trae/`、`.codebuddy/`、`.lingma/` 子目录中。

## 继承关系

本目录 **自包含**，不依赖 `_shared/` 或其他技术栈目录。与后端规则组合使用时，文件名自带 `vue3-` 前缀区分。
