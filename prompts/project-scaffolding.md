# Project Scaffolding — structure-projects 项目创建约束

> 角色：在 structure-projects 生态内 **创建新项目 / 新模块** 的 AI。
> 目标：让 AI 在选型、命名、模块布局、坐标、初始提交物上一次到位，避免后续返工。

## 1. 选型决策（先选模板再动手）

| 诉求 | 模板 | 适用 |
|---|---|---|
| 单体 + 单模块 | `structure-mono-template` | 小型工具 / 内部服务 |
| 单体 + 扁平多模块 | `structure-multi-module-template` | 中型业务，不需要 DDD 分层 |
| **DDD 7+1 模块**（**默认推荐**） | `structure-ddd-template` | 业务中心、长期演进的服务 |
| 云原生微服务 | `structure-pro` | 需要服务网格、完整可观测性 |
| 前端微前端子应用 | `structure-wujie-template` | 管理后台子应用 |

**默认推荐**：业务中心一律使用 **DDD 7+1 模板**（已被 `structure-user` / `structure-org` 验证）。

## 2. 仓库与坐标硬约束

- **MUST** 仓库放在 GitHub org `structure-projects` 下，命名 `structure-{领域}`（小写、kebab-case）。
- **MUST** Maven `groupId` = `cn.structured`；`artifactId` = `structure-{领域}` 或 `structure-{领域}-{模块}`。
- **MUST** parent 为 `cn.structured:structure-dependencies:1.4.4`（或当时最新稳定版）。
- **MUST** 版本号使用 `${revision}` CI-friendly 方式，初始版本 `1.0.0-SNAPSHOT`。
- **MUST** npm scope = `@structure-projects`；前端包名 `@structure-projects/{领域}-ui` / `@structure-projects/{领域}-ui-components`。
- **MUST** 业务 pom 放在 `structure-{领域}-dependencies/` 子目录，**仓库根目录不放 pom.xml**；通过 `<modules>` + 相对路径聚合。

## 3. 模块布局（DDD 7+1 + 前端 monorepo）

**MUST** 按以下结构创建：

```
structure-{X}/
├── structure-{X}-dependencies/        # 父 POM
├── structure-{X}-common/              # DTO / VO / Query / enums / exception / constant
├── structure-{X}-domain/              # {X}Entity / {X}Repository 接口 / DomainService
├── structure-{X}-infra/               # {X}RepositoryImpl / {X}RepositoryDelegate 接口
├── structure-{X}-repository-mybatis/  # {X}PO / {X}Mapper / {X}MybatisPlusDelegate / Flyway 迁移
├── structure-{X}-application/         # I{X}Service / {X}ServiceImpl / {X}Assembler / {X}Async
├── structure-{X}-interfaces/          # controller/api/{X}Controller + controller/open/Open{X}Controller
├── structure-{X}-boot/                # 启动类 + application.yaml + Dockerfile
├── structure-{X}-ui/                  # wujie 微前端子应用（可选）
├── structure-{X}-ui-components/       # 前端本地组件库（可选）
├── scripts/                           # dockerbuild.sh / mavenbuild.sh / install.sh
├── .github/workflows/                 # CI
├── README.md                          # 项目说明（MUST 与代码同步）
└── PROJECT_RULES.md                   # 本项目的特殊规范（可选）
```

## 4. 包名（MUST）

- **MUST** 根包：`cn.structured.{领域}`（**有 d**）。
- **MUST** 子包按层划分：`.common` / `.domain` / `.infra` / `.repository` / `.application` / `.interfaces` / `.boot`。
- ⚠️ **已知历史遗留**：`repository-mybatis` 模块在 `structure-user` / `structure-org` 中是 `cn.structured.{X}.repository.repository.*`（双 "repository"）。**新项目应使用 `cn.structured.{X}.repository.mybatis.*`**，除非用户明确要求沿用旧约定。**创建项目前 MUST 与用户确认**。

## 5. 初始提交物（MUST）

新项目首次提交 MUST 包含：

- [ ] 完整模块骨架（即使部分模块为空）
- [ ] `README.md`：项目定位、技术栈、模块说明、快速开始、配置说明（**与代码同步**，不写超前于代码的内容）
- [ ] 父 POM + 各模块 POM
- [ ] 至少一个端到端示例（Entity → Repository → Service → Controller → 单测），作为后续开发参考
- [ ] Flyway 迁移脚本目录与初始 `V1.0.0__CREATE_TABLE.sql`
- [ ] `.gitignore`（Java / Node / IDE）
- [ ] `application.yaml` + `application-dev.yml` 模板

## 6. 前端子项目（如创建）

- **MUST** 技术栈：Vue 3 + Vite + TypeScript + Pinia + Vue Router + Element Plus + UnoCSS + wujie-vue3。
- **MUST** `*-ui` 的 `package.json` 中 `name` 为 `@structure-projects/{领域}-ui`，`private: true`。
- **MUST** `*-ui-components` 在 **开发时** 通过 `file:../../structure-{X}/structure-{X}-ui-components` 本地引用；**正式发布时发布到 npm**（`@structure-projects/{领域}-ui-components`），便于其他场景复用。
- **SHOULD** 复用 `@structure-projects/components` / `@structure-projects/gateway-client` / `@structure-projects/wujie-subapp`。

## 7. 数据库与迁移

- **MUST** 使用 Flyway 管理迁移；脚本位于 `structure-{X}-repository-mybatis/src/main/resources/db/migration/`。
- **MUST** 命名 `V{版本}__{描述}.sql`（如 `V1.0.0__CREATE_TABLE.sql`、`V1.0.1__INIT_DATA.sql`）。
- **SHOULD** 所有表含基础字段：`id`（主键）/ `deleted`（逻辑删除）/ `create_time` / `update_time` / `create_by` / `update_by`。

## 8. 禁止事项

- **禁止** 使用 `structure-ruoyi` / `ruoyi-framework` / `structure-yudao` 作为新项目基底（**多数 2024-09 停更，疑似弃用**）。
- **禁止** 在新项目中引入 `structure-pro-infra`（已被 `structure-infra` 取代，见 [`components.md`](components.md)）。
- **禁止** 写 README 超前于代码（描述不存在的目录或文件）。

## 9. 创建后接入

新项目骨架完成后，AI 应引导用户：

1. 是否需要接入 `structure-gateway`（对外服务 MUST）？
2. 是否需要接入 `structure-security`（涉及认证授权 MUST）？
3. 是否需要接入 `structure-tenant`（多租户场景 MUST）？
4. 是否需要 `structure-datascope`（有行级权限需求 MUST）？
5. CI/CD 使用 `structure-multi-module-template` 中的 `build-and-push.yml` / `release.yml` 作为参考。

## 10. 与其他规则的关系

- 模块内代码风格：见 [`developer.md`](developer.md)。
- 分层与依赖方向：见 [`architect.md`](architect.md)。
- 各组件具体使用：见 [`components.md`](components.md)。
- 提交前自检与评审：见 [`reviewer.md`](reviewer.md)。