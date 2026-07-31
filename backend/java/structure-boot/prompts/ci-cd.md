# CI/CD — structure-projects 测试、流水线与发布规范

> 角色：在 structure-projects 生态内做 **测试、GitHub 流水线、发布** 的 AI。
> 本文件基于 `structure-user` / `structure-org` 真实流水线与脚本提炼，是工具无关的单一内容源。

## 1. 测试要求（所有项目 MUST）

- **MUST** 每个项目都有 **单元测试**（`XxxTest`，不启动 Spring 上下文）与 **集成测试**（`XxxIT`，Testcontainers 真实中间件）。
- **MUST** 测试在 CI 中可独立运行：`mvn clean test` 必须通过，不允许"本地能跑、CI 跑不过"。
- **MUST** 集成测试 **禁止** Mock 数据库 / Redis / MQ —— 用 Testcontainers（版本 `1.20.6`）。
- 详细测试规范见 [`tester.md`](tester.md)。

## 2. GitHub 流水线（4 个标准 workflow）

每个正式项目 **MUST** 在 `.github/workflows/` 下配置以下 4 个 workflow。

### 2.1 `test.yml` —— 测试流水线（push / PR 触发）

```yaml
name: Run Tests

on:
  push:
    branches: ['**']
  pull_request:
    branches: ['**']

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Cache Maven packages
        uses: actions/cache@v3
        with:
          path: ~/.m2
          key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
          restore-keys: ${{ runner.os }}-m2

      - name: Run tests
        run: |
          cd structure-{X}-dependencies
          mvn clean test -s ../.mvn/settings.xml

      - name: Publish Test Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: '**/target/surefire-reports/*.xml'
```

**约束**：
- **MUST** 在 `structure-{X}-dependencies` 目录执行 `mvn clean test`（父 POM 聚合所有模块）。
- **MUST** 使用项目自带的 `.mvn/settings.xml`（`-s ../.mvn/settings.xml`）。
- **MUST** 上传 surefire 报告为 artifact，便于失败时下载分析。

### 2.2 `build-and-push.yml` —— Docker 镜像发布到阿里云 ACR（release / 手动触发）

```yaml
name: Build and Push to Aliyun

on:
  release:
    types: [published]
  workflow_dispatch:
    inputs:
      version:
        description: 'Release version (e.g., 1.2.3)'
        required: true
        type: string

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Cache Maven packages
        uses: actions/cache@v3
        with:
          path: ~/.m2
          key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
          restore-keys: ${{ runner.os }}-m2

      - name: Set release version
        run: |
          if [ "${{ github.event_name }}" = "workflow_dispatch" ]; then
            echo "RELEASE_VERSION=${{ github.event.inputs.version }}" >> $GITHUB_ENV
          else
            echo "RELEASE_VERSION=${GITHUB_REF#refs/tags/}" >> $GITHUB_ENV
          fi

      - name: Build project
        run: |
          cd structure-{X}-dependencies
          mvn clean install -DskipTests -Drevision=$RELEASE_VERSION -s ../.mvn/settings.xml

      - name: Run Tests
        run: |
          cd structure-{X}-dependencies
          mvn test -Drevision=$RELEASE_VERSION -s ../.mvn/settings.xml

      - name: Build structure-{X}-boot
        run: |
          cd structure-{X}-boot
          mvn clean package -DskipTests -Drevision=$RELEASE_VERSION

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Aliyun ACR
        uses: docker/login-action@v3
        with:
          registry: registry.cn-hangzhou.aliyuncs.com
          username: ${{ secrets.ALIYUN_ACR_USERNAME }}
          password: ${{ secrets.ALIYUN_ACR_PASSWORD }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: structure-{X}-boot
          file: structure-{X}-boot/Dockerfile
          push: true
          tags: |
            registry.cn-hangzhou.aliyuncs.com/structured/structured-{x}-center:${{ env.RELEASE_VERSION }}
            registry.cn-hangzhou.aliyuncs.com/structured/structured-{x}-center:latest
```

**约束**：
- **MUST** 镜像地址：`registry.cn-hangzhou.aliyuncs.com/structured/structured-{x}-center:{version}`，同时打 `latest` 标签。
- **MUST** 发布前**先跑测试**（`mvn test`），测试失败则不构建镜像。
- **MUST** ACR 凭据走 GitHub Secrets：`ALIYUN_ACR_USERNAME` / `ALIYUN_ACR_PASSWORD`（**禁止**写死在 yml 或代码中）。
- **MUST** Dockerfile 位于 `structure-{X}-boot/` 模块（boot 是唯一可运行模块）。

### 2.3 `release.yml` —— Maven Central 发布（**排除示例与 boot 模块**）

```yaml
name: Release to Maven Central

on:
  release:
    types: [published]
  workflow_dispatch:
    inputs:
      version:
        description: 'Release version (e.g., 1.2.3)'
        required: true
        type: string

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          server-id: oss
          server-username: MAVEN_USERNAME
          server-password: MAVEN_PASSWORD
          gpg-private-key: ${{ secrets.GPG_PRIVATE_KEY }}
          gpg-passphrase: GPG_PASSPHRASE

      - name: Cache Maven packages
        uses: actions/cache@v3
        with:
          path: ~/.m2
          key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
          restore-keys: ${{ runner.os }}-m2

      - name: Set release version
        run: |
          if [ "${{ github.event_name }}" = "workflow_dispatch" ]; then
            echo "RELEASE_VERSION=${{ github.event.inputs.version }}" >> $GITHUB_ENV
          else
            echo "RELEASE_VERSION=${GITHUB_REF#refs/tags/}" >> $GITHUB_ENV
          fi

      - name: Run Tests
        run: |
          cd structure-{X}-dependencies
          mvn test -Drevision=$RELEASE_VERSION -s ../.mvn/settings.xml

      - name: Deploy to Maven Central
        run: |
          cd structure-{X}-dependencies
          mvn clean deploy -P release,oss -DskipTests -Drevision=$RELEASE_VERSION \
            -Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true \
            -s ../.mvn/settings.xml
        env:
          OSSRH_USERNAME: ${{ secrets.OSSRH_USERNAME }}
          OSSRH_PASSWORD: ${{ secrets.OSSRH_PASSWORD }}
          GPG_PASSPHRASE: ${{ secrets.GPG_PASSPHRASE }}
```

**发布排除约束（重要）—— 推荐 pom 声明式排除**

**MUST** 不发布到 Maven Central 的模块，在 **该模块自身的 `pom.xml`** 中声明 `<maven.deploy.skip>true</maven.deploy.skip>`（来自 `structure-security` 验证的方式）：

```xml
<!-- structure-{X}-boot/pom.xml 或 *-sample/pom.xml -->
<properties>
    <maven.deploy.skip>true</maven.deploy.skip>
</properties>
```

**必须排除的模块**：

| 模块 | 原因 |
|---|---|
| `structure-{X}-boot` | 可运行应用，不是库 |
| `*-sample` / `*-sample-*` | 示例工程 |
| `*-example` / `*-example-*` | 示例工程 |

**为什么用 pom 声明式而非 `-pl '!...'` 命令行排除**：

1. **自文档化**：排除规则跟随模块本身，不埋在 CI yaml 里。
2. **处处生效**：本地 `mvn deploy` 同样跳过，不只 CI。
3. **零维护成本**：新增示例模块只需在其 pom 声明一次，不用改 workflow 的 `-pl` 模式。
4. **防遗忘**：新建模块时声明一次即永久生效，不依赖发布时记得加排除参数。

- **MUST** 发布前先跑测试。
- **MUST** Secrets：`OSSRH_USERNAME` / `OSSRH_PASSWORD` / `GPG_PRIVATE_KEY` / `GPG_PASSPHRASE`。

## 3. 脚本规范（`scripts/` 目录）

每个正式项目 **MUST** 提供以下脚本：

| 脚本 | 用途 | 关键逻辑 |
|---|---|---|
| `scripts/mavenbuild.sh` | 本地 Maven 构建 | `cd structure-{X}-dependencies && mvn clean install -DskipTests -s ../.mvn/settings.xml` |
| `scripts/install.sh` | 安装到本地 Maven 仓库 | 同上，含 `-Drevision=<version>` 支持 |
| `scripts/dockerbuild.sh` | 本地构建并推送 Docker 镜像 | `docker build -t registry.cn-hangzhou.aliyuncs.com/structured/structured-{x}-center:$1 . && docker push ...` |
| `scripts/release.sh` | 本地发版（版本号批量替换 + 提交 + 打 tag） | 配合 `${revision}` 与 Maven Versions Plugin |
| `scripts/update-snapshots.sh` | 批量更新 SNAPSHOT 版本 | 框架版本升级后同步各模块 |

**约束**：
- **MUST** 脚本首行 `#!/bin/bash`，可执行（`chmod +x`）。
- **MUST** 脚本内 **不硬编码密码/密钥** —— 凭据一律走环境变量或 GitHub Secrets。
- **SHOULD** 脚本接受版本号参数（`version=$1`，带默认值兜底）。

## 4. Dockerfile 规范（`structure-{X}-boot/`）

- **MUST** Dockerfile 位于 `structure-{X}-boot/`（唯一可运行模块）。
- **MUST** 基础镜像与 JDK 17 对齐（如 `eclipse-temurin:17-jre`）。
- **MUST** 提供 `liveness.sh` 健康检查脚本（K8s liveness/readiness probe 使用）。
- **SHOULD** 使用多阶段构建减小镜像体积。
- **SHOULD** 提供 `.dockerignore` 排除 `target/` 以外无关文件。

## 5. Secrets 清单（GitHub 仓库 / 组织级配置）

| Secret | 用途 | 适用 workflow |
|---|---|---|
| `ALIYUN_ACR_USERNAME` / `ALIYUN_ACR_PASSWORD` | 阿里云 ACR 登录 | `build-and-push.yml` |
| `OSSRH_USERNAME` / `OSSRH_PASSWORD` | Maven Central (OSSRH) 账号 | `release.yml` |
| `GPG_PRIVATE_KEY` / `GPG_PASSPHRASE` | Maven Central 构件签名 | `release.yml` |
| `MAVEN_USERNAME` / `MAVEN_PASSWORD` | 私有 Maven 仓库（如 settings.xml 中的 `oss` server） | 全部（经 setup-java `server-username/password` 注入） |
| `NPM_TOKEN` | npm 发布 | `publish.yml` |

**约束**：
- **MUST** Secrets 配置在 **组织级**（`structure-projects` org），各仓库继承；仓库级仅放该仓库特有 Secret。
- **禁止** 将任何密码/密钥/Token 写入 yml、settings.xml、代码、README。

## 6. 发布前检查清单

- [ ] `test.yml` 全部通过（push / PR 触发）？
- [ ] 发布版本号符合 3 段式语义化版本规范（详见 [`_common/prompts/version-management.md`](../../../../_common/prompts/version-management.md)），与 `${revision}` 一致？
- [ ] **不发布的模块**（`boot` / `sample` / `example`）在其 **自身 pom.xml** 中已声明 `<maven.deploy.skip>true</maven.deploy.skip>`？
- [ ] `build-and-push.yml` 镜像 tag 同时包含 `{version}` 与 `latest`？
- [ ] `publish.yml` 的 npm 版本号从 tag 提取（非手工维护）？
- [ ] 所有 Secrets 已在组织级配置，无硬编码凭据？
- [ ] `scripts/` 各脚本可执行、无硬编码密码？
- [ ] `structure-{X}-boot/Dockerfile` 与 `liveness.sh` 存在？

## 7. 与其他规则的关系

- 测试细则：见 [`tester.md`](tester.md)。
- 项目结构与初始提交物：见 [`project-scaffolding.md`](project-scaffolding.md)。
- 评审时检查流水线配置：见 [`reviewer.md`](reviewer.md)。
