# 项目结构约定

> 通用规则，适用范围：所有技术栈和项目类型。
> 各技术栈在其 `project-scaffolding.md` 中定义框架特定的模块模板和初始提交物。

## 目录组织原则

### 关注点分离

- **MUST** 按功能或领域划分目录，同一功能的代码聚合在一起。
- **MUST** 区分代码、资源（静态文件、模板）、配置和测试文件。
- **MUST** 通用代码和业务代码分离，通用代码可跨项目复用。

### 命名一致

- **MUST** 目录和文件名使用一致且描述性的命名，反映其用途和内容。
- **MUST** 目录名使用小写（kebab-case 或 snake_case，按语言约定）。
- **SHOULD** 目录名不使用复数（如 `model/` 而非 `models/`），除非语言约定要求。

### 嵌套深度

- **SHOULD** 目录嵌套不超过 4 层。
- **SHOULD** 当目录下文件超过 15 个时，考虑拆分子目录。

## 模块划分

### 通用模块分类

| 模块类型 | 说明 | 包含内容 |
|---------|------|---------|
| **入口模块** | 应用入口、配置、启动 | 启动类、全局配置、生命周期管理 |
| **接口模块** | 对外暴露的 API | Controller/Handler、DTO/VO/Query |
| **业务模块** | 核心业务逻辑 | Service、DomainService、业务规则 |
| **领域模块** | 领域实体和仓储接口 | Entity、ValueObject、Repository 接口 |
| **基础设施模块** | 技术实现 | Repository 实现、DB 访问、缓存、消息、外部 API 客户端 |
| **公共模块** | 跨模块共享 | 工具类、常量、枚举、异常定义 |

### 通用目录结构

```
project-root/
├── {entry}/                  # 入口模块（boot/server/main）
│   ├── src/main/
│   ├── src/test/
│   └── config/
├── {api}/                    # 接口模块（interfaces/api/controllers）
├── {service}/                # 业务模块（application/service/biz）
├── {domain}/                 # 领域模块（domain/core/model）
├── {infra}/                  # 基础设施模块（infra/infrastructure）
├── {common}/                 # 公共模块（common/shared/base）
├── docs/                     # 设计文档（详见 documentation.md）
│   ├── overview.md           #   概要设计（项目定位+架构+技术栈+能力边界）
│   ├── features/             #   详细设计目录（每个功能一个 md）
│   ├── {version}/            #   版本快照（overview + features + changelog）
│   └── README.md             #   文档索引
├── scripts/                  # 构建/部署脚本
├── .github/workflows/        # CI/CD 流水线
├── README.md
└── CHANGELOG.md
```

## 配置文件

- **MUST** 配置文件按环境分离：
  - `application.yml`（或等效）：公共配置
  - `application-dev.yml`：开发环境
  - `application-test.yml`：测试环境
  - `application-prod.yml`：生产环境
- **MUST** 敏感配置（密码、密钥）通过环境变量或配置中心注入，**禁止**写在配置文件中。
- **SHOULD** 配置项使用清晰的命名，具有可读性。

## 资源文件

- **MUST** 资源文件（国际化、SQL 迁移、静态文件）与代码分目录存放。
- **MUST** 数据库迁移脚本按版本号命名（如 `V1.0__init_schema.sql`），放在 `resources/db/migration/` 或等效目录。
- **SHOULD** 国际化文件按语言代码命名（如 `messages_zh_CN.properties`、`messages_en_US.properties`）。

## 测试目录

```
{module}/
├── src/
│   ├── main/    # 源代码
│   └── test/    # 测试代码（镜像 main/ 结构）
│       ├── unit/          # 单元测试
│       └── integration/   # 集成测试
```

- **MUST** 测试目录镜像源代码目录结构。
- **MUST** 每个正式项目必须同时具备单元测试和集成测试。
- **禁止** 在正式项目中保留示例工程（`*-sample` / `*-example`）作为"测试替代品"。

## 文档目录

> 详细规范见 [`documentation.md`](documentation.md)。项目 MUST 在 `docs/` 下维护概要设计、详细设计、版本快照和变更日志。

## 依赖管理

- **MUST** 所有模块的依赖版本在父级或 BOM（Bill of Materials）中统一管理。
- **MUST** 子模块**不写死**依赖版本号。
- **禁止** 同一个依赖在不同模块中声明不同版本。

## 脚本目录

每个正式项目 **SHOULD** 提供以下脚本（位于 `scripts/` 目录）：

| 脚本 | 用途 |
|------|------|
| `build.sh` | 本地构建 |
| `test.sh` | 运行测试 |
| `run.sh` / `start.sh` | 本地启动 |
| `docker-build.sh` | 构建 Docker 镜像 |

- **MUST** 脚本首行 `#!/bin/bash`（或其他 shell），可执行（`chmod +x`）。
- **禁止** 脚本中硬编码密码/密钥 —— 凭据走环境变量。

## Dockerfile 规范

- **MUST** Dockerfile 位于入口模块目录（可运行的模块）。
- **MUST** 提供健康检查端点（`/health` 或 `/actuator/health`）供 K8s liveness/readiness probe 使用。
- **SHOULD** 使用多阶段构建减小镜像体积。
- **SHOULD** 提供 `.dockerignore` 排除无关文件。

## 禁止事项

- **禁止** 项目根目录散落过多配置文件（超过 5 个）。
- **禁止** 在正式项目中保留示例工程（`*-sample` / `*-example`）。
- **禁止** 测试目录和源码目录混在一起。
- **禁止** 密码/密钥/Token 硬编码在配置文件或脚本中。
