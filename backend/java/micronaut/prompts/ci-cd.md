# Micronaut CI/CD 规范

> Micronaut 4.x 项目持续集成与持续部署规范。

---

## 1. CI/CD 流水线总览

```
代码提交 → 编译 → 单元测试 → 代码扫描 → 集成测试 → 构建镜像 → 推送仓库 → 部署
```

---

## 2. 持续集成（CI）

### 2.1 GitHub Actions 流水线

#### Gradle 项目（推荐）

```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Setup Gradle
        uses: gradle/actions/setup-gradle@v3

      - name: Build and Test
        run: ./gradlew build

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: '**/build/test-results/**/*.xml'
```

### 2.2 流水线阶段

每个阶段失败时 MUST 阻断后续阶段：

| 阶段 | 命令（Gradle） | 说明 |
|---|---|---|
| 编译 | `./gradlew classes` | 编译源码 |
| 单元测试 | `./gradlew test` | 运行单元测试 |
| 代码扫描 | SonarQube / Checkstyle | 静态代码分析 |
| 打包 | `./gradlew assemble` | 构建制品 |
| 集成测试 | `./gradlew integrationTest` | 运行集成测试 |

### 2.3 代码质量扫描

```yaml
- name: SonarQube Scan
  uses: sonarsource/sonarqube-scan-action@master
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
    SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
```

---

## 3. 制品管理

### 3.1 Docker 镜像构建

```yaml
- name: Build Docker Image
  run: |
    ./gradlew dockerBuild
    docker tag ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:${{ github.sha }} \
               ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:latest

- name: Push Docker Image
  run: |
    docker push ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:${{ github.sha }}
    docker push ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:latest
```

### 3.2 GraalVM Native Image 构建（可选）

```yaml
- name: Build Native Image
  run: ./gradlew nativeCompile

- name: Build Native Docker Image
  run: |
    docker build -f Dockerfile.native -t ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:native .
```

---

## 4. Dockerfile 规范

### 4.1 多阶段构建（JVM）

```dockerfile
# 构建阶段
FROM eclipse-temurin:17-jdk-alpine AS builder
WORKDIR /app
COPY gradlew build.gradle.kts settings.gradle.kts ./
COPY gradle gradle
RUN ./gradlew dependencies --no-daemon
COPY src src
RUN ./gradlew assemble --no-daemon

# 运行阶段
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/build/libs/*-all.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 4.2 Native Image Dockerfile

```dockerfile
FROM ghcr.io/graalvm/native-image-community:17 AS builder
WORKDIR /app
COPY . .
RUN ./gradlew nativeCompile

FROM alpine:3.19
WORKDIR /app
COPY --from=builder /app/build/native/nativeCompile/app app
EXPOSE 8080
ENTRYPOINT ["./app"]
```

### 4.3 JVM 参数

```dockerfile
ENTRYPOINT ["java", \
    "-Xms256m", "-Xmx512m", \
    "-XX:+UseG1GC", \
    "-XX:MaxGCPauseMillis=200", \
    "-Djava.security.egd=file:/dev/./urandom", \
    "-jar", "app.jar"]
```

---

## 5. 持续部署（CD）

### 5.1 Kubernetes 部署

```yaml
- name: Deploy to Kubernetes
  uses: azure/k8s-deploy@v4
  with:
    manifests: k8s/deployment.yaml
    images: ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:${{ github.sha }}
```

### 5.2 部署策略

| 策略 | 说明 | 适用场景 |
|---|---|---|
| Rolling Update | 滚动更新，逐步替换 Pod | 常规部署 |
| Blue-Green | 蓝绿部署，切换流量 | 需要快速回滚 |
| Canary | 金丝雀发布，小流量验证 | 高风险变更 |

### 5.3 健康检查

```yaml
livenessProbe:
  httpGet:
    path: /health/liveness
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health/readiness
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

**注意**：Micronaut 内置健康端点路径为 `/health`（不同于 Spring Boot 的 `/actuator/health`）。

---

## 6. 环境管理

### 6.1 环境划分

| 环境 | 触发条件 | 说明 |
|---|---|---|
| dev | push 到 develop 分支 | 开发环境，自动部署 |
| staging | push 到 release/* 分支 | 预发布环境，需审批 |
| production | push tag（如 v1.0.0） | 生产环境，需审批 |

### 6.2 配置管理

- 各环境配置分离：`application-{env}.yml`
- 敏感信息通过 CI/CD Secrets 注入环境变量
- 配置变更 MUST 走流水线，禁止手动修改

---

## 7. 通知与告警

```yaml
- name: Notify on Failure
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "CI 流水线失败: ${{ github.repository }} - ${{ github.ref_name }}"
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

---

## 8. 缓存优化

```yaml
# Gradle 依赖缓存
- uses: actions/cache@v4
  with:
    path: |
      ~/.gradle/caches
      ~/.gradle/wrapper
    key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
    restore-keys: ${{ runner.os }}-gradle-

# Docker 层缓存
- uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

---

## 9. 安全扫描

```yaml
# 依赖漏洞扫描
- name: Dependency Check
  run: ./gradlew dependencyCheckAnalyze

# 镜像漏洞扫描
- name: Trivy Scan
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:${{ github.sha }}
    format: 'table'
    exit-code: '1'
    severity: 'CRITICAL,HIGH'
```

---

## 10. GraalVM Native Image CI

```yaml
jobs:
  native-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up GraalVM JDK 17
        uses: graalvm/setup-graalvm@v1
        with:
          java-version: '17'
          distribution: 'graalvm-community'
          github-token: ${{ secrets.GITHUB_TOKEN }}

      - name: Build Native Image
        run: ./gradlew nativeCompile

      - name: Run Native Tests
        run: ./gradlew nativeTest

      - name: Build Native Docker Image
        run: docker build -f Dockerfile.native -t app:native .
```

---

## 11. 检查清单

- [ ] 每次 push 触发 CI 流水线
- [ ] 单元测试和集成测试在流水线中运行
- [ ] 代码质量扫描配置完成
- [ ] Docker 镜像自动构建
- [ ] 敏感信息使用 Secrets 管理
- [ ] 部署前有人工审批（生产环境）
- [ ] 健康检查路径正确（`/health` 而非 `/actuator/health`）
- [ ] 回滚方案可用
- [ ] 流水线失败有通知
