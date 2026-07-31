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

## 3. 模块布局

### 3.1 形态选择（先选形态再创建）

| 形态 | 模块结构 | 持久化模式 | 适用 |
|---|---|---|---|
| **DDD 业务中心**（**默认推荐**） | 7+1 后端模块 + 2 前端模块 | RepositoryFacade + Delegate + Entity/PO 分离 | 新建业务中心（用户、订单、商品等） |
| **单体应用** | 4 模块（api/biz/common/dependencies） | Manager 模式（`IManager extends IService`） | 小型工具、内部服务、管理后台 |

### 3.2 DDD 7+1 + 前端 monorepo（默认）

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

### 3.3 单体 4 模块（老项目兼容形态）

```
structure-{X}/
├── structure-{X}-api/                 # 控制层（controller/ + 启动类）
├── structure-{X}-biz/                 # 业务层（service/ + manager/ + mapper/ + entity/ + assembler/ + config/）
├── structure-{X}-common/              # 公共层（dto/ + vo/ + query/ + enums/ + exception/ + constant/）
└── structure-{X}-dependencies/        # 父 POM
```

**单体形态约束**：

- **MUST** 使用 Manager 模式：`I{X}Manager extends IService<{X}Entity>` + `{X}ManagerImpl extends ServiceImpl<{X}Mapper, {X}Entity>`。
- **MUST** Entity 直接使用 `@TableId` / `@TableField` / `@TableLogic` 注解（**不分离 Entity/PO**）。
- **禁止** 在单体项目中强行套用 DDD 的 RepositoryFacade / Delegate 模式。
- 跨形态通用规则（统一响应、统一异常、命名、validation、swagger、`UserContext`、数据权限、多租户）**仍 MUST 遵守**。

## 4. 包名（MUST）

- **MUST** 根包：`cn.structured.{领域}`（**有 d**）。
- **MUST** 子包按层划分：`.common` / `.domain` / `.infra` / `.repository` / `.application` / `.interfaces` / `.boot`。
- ⚠️ **已知历史遗留**：`repository-mybatis` 模块在 `structure-user` / `structure-org` 中是 `cn.structured.{X}.repository.repository.*`（双 "repository"）。**新项目应使用 `cn.structured.{X}.repository.mybatis.*`**，除非用户明确要求沿用旧约定。**创建项目前 MUST 与用户确认**。

## 5. 初始提交物（MUST）

新项目首次提交 MUST 包含：

- [ ] 完整模块骨架（即使部分模块为空）
- [ ] `README.md`：项目定位、技术栈、模块说明、快速开始、配置说明（**与代码同步**，不写超前于代码的内容）
- [ ] **`docs/` 文档骨架**（详见 [`_common/prompts/documentation.md`](../../../../_common/prompts/documentation.md)）：
  - [ ] `docs/overview.md` — 项目概要设计
  - [ ] `docs/features/` — 功能详细设计目录（至少包含一个示例功能文档）
  - [ ] `docs/README.md` — 文档索引
  - [ ] `docs/1.0.0/changelog/` — 初始版本变更日志目录（含 `001.md` 初始创建记录）
  - [ ] `docs/1.0.0/overview.md` — 初始版本概要设计快照
- [ ] 父 POM + 各模块 POM
- [ ] 至少一个端到端示例（Entity → Repository → Service → Controller → 单测），作为后续开发参考
- [ ] **单元测试（`XxxTest`）与集成测试（`XxxIT`，Testcontainers）各至少一个**，且 `mvn clean test` 通过
- [ ] Flyway 迁移脚本目录与初始 `V1.0.0__CREATE_TABLE.sql`
- [ ] **4 个 GitHub workflow**：`.github/workflows/test.yml` / `build-and-push.yml` / `release.yml` / `publish.yml`（模板见 [`ci-cd.md`](ci-cd.md)）
- [ ] **`scripts/` 脚本**：`mavenbuild.sh` / `install.sh` / `dockerbuild.sh` / `release.sh` / `update-snapshots.sh`（见 [`ci-cd.md`](ci-cd.md) 第 3 节）
- [ ] **`structure-{X}-boot/Dockerfile` + `liveness.sh` + `.dockerignore`**（见 [`ci-cd.md`](ci-cd.md) 第 4 节）
- [ ] `.gitignore`（Java / Node / IDE）
- [ ] `application.yaml` + `application-dev.yml` 模板

**禁止包含**：

- **示例工程**（`*-sample` / `*-example`）—— 正式项目 **不保留示例工程**；如需示例，放独立的 `structure-{X}-sample` 仓库或在 `structure-infra-sample` 等集中示例仓库维护。
- 硬编码的密码 / 密钥 / Token（凭据一律走 GitHub Secrets，见 [`ci-cd.md`](ci-cd.md) 第 5 节）。

## 6. 数据库与迁移

- **MUST** 使用 Flyway 管理迁移；脚本位于 `structure-{X}-repository-mybatis/src/main/resources/db/migration/`。
- **MUST** 命名 `V{版本}__{描述}.sql`（如 `V1.0.0__CREATE_TABLE.sql`、`V1.0.1__INIT_DATA.sql`）。
- **SHOULD** 所有表含基础字段：`id`（主键）/ `deleted`（逻辑删除）/ `create_time` / `update_time` / `create_by` / `update_by`。

## 6.1 依赖管理（dependencies 模块）

**MUST** `structure-{X}-dependencies/pom.xml` 包含以下版本属性与 CVE 修复：

```xml
<properties>
    <revision>1.0.0-SNAPSHOT</revision>
    <spring-boot.version>4.0.6</spring-boot.version>
    <spring-cloud.version>2025.1.0</spring-cloud.version>
    <spring-alibaba.version>2025.1.0.0</spring-alibaba.version>
    <mybatis-plus.version>3.5.16</mybatis-plus.version>
    <springdoc.version>3.0.3</springdoc.version>
    <structure.version>1.4.4</structure.version>
    <structure-security.version>1.1.5</structure-security.version>
    <structure-infra.version>1.3.1</structure-infra.version>
    <structure-tenant.version>1.4.3</structure-tenant.version>
    <structure-datascope.version>1.0.3</structure-datascope.version>
    <testcontainers.version>1.20.6</testcontainers.version>

    <!-- CVE 修复版本（⚠️ 仅框架 < 1.4.4 需显式声明；1.4.4 起框架已内置处理，无需再加） -->
    <bouncycastle.version>1.84</bouncycastle.version>           <!-- CVE-2026-0636 -->
    <commons-fileupload.version>1.6.0</commons-fileupload.version> <!-- CVE-2025-48976 -->
</properties>

<!-- ⚠️ 以下 CVE 修复依赖仅当 parent 框架版本 < 1.4.4 时才需显式声明 -->
<dependencyManagement>
<dependencies>
    <!-- CVE-2026-0636 修复（框架 < 1.4.4 时） -->
    <dependency>
        <groupId>org.bouncycastle</groupId>
        <artifactId>bcprov-jdk18on</artifactId>
        <version>${bouncycastle.version}</version>
    </dependency>
    <dependency>
        <groupId>org.bouncycastle</groupId>
        <artifactId>bcpkix-jdk18on</artifactId>
        <version>${bouncycastle.version}</version>
    </dependency>

    <!-- CVE-2025-48976 修复（框架 < 1.4.4 时） -->
    <dependency>
        <groupId>commons-fileupload</groupId>
        <artifactId>commons-fileupload</artifactId>
        <version>${commons-fileupload.version}</version>
    </dependency>
</dependencies>
</dependencyManagement>
```

**MUST** Spring Boot 4 项目使用 **`mybatis-plus-spring-boot4-starter`**（**不是** `mybatis-plus-boot-starter`）：

```xml
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-plus-spring-boot4-starter</artifactId>
</dependency>
```

## 6.2 构建配置

**MUST** `maven-compiler-plugin` 加 `-parameters` 编译参数（保留方法参数名，利于 Spring MVC 反射绑定与 Swagger 文档生成）：

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-compiler-plugin</artifactId>
    <configuration>
        <compilerArgs>
            <arg>-parameters</arg>
        </compilerArgs>
    </configuration>
</plugin>
```

**MUST** `boot` 模块配置 `spring-boot-maven-plugin` 的 `repackage` goal：

```xml
<plugin>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-maven-plugin</artifactId>
    <executions>
        <execution>
            <goals>
                <goal>repackage</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

**SHOULD** 开启资源 filtering（让 `application.yml` 可使用 `${project.version}` 等占位符）：

```xml
<build>
    <resources>
        <resource>
            <directory>src/main/resources</directory>
            <filtering>true</filtering>
        </resource>
    </resources>
</build>
```

## 7. 禁止事项

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