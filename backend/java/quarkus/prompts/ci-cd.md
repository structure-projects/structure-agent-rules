# Quarkus CI/CD 规范

> Quarkus 3.x 项目持续集成与持续部署规范。

---

## 1. CI/CD 流水线总览

```
代码提交 → 编译 → 单元测试 → 代码扫描 → 集成测试 → Native编译 → 构建镜像 → 推送仓库 → 部署
```

---

## 2. 持续集成（CI）

### 2.1 GitHub Actions 流水线（Maven）

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
          cache: maven

      - name: Build with Maven
        run: ./mvnw compile

      - name: Unit Tests
        run: ./mvnw test

      - name: Integration Tests
        run: ./mvnw verify

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: '**/target/surefire-reports/*.xml'
```

### 2.2 流水线阶段

| 阶段 | 命令（Maven） | 说明 |
|---|---|---|
| 编译 | `./mvnw compile` | 编译源码 |
| 单元测试 | `./mvnw test` | 运行单元测试 |
| 代码扫描 | SonarQube | 静态代码分析 |
| 打包 | `./mvnw package -DskipTests` | 构建制品 |
| 集成测试 | `./mvnw verify` | 运行集成测试 |
| Native 编译 | `./mvnw package -Pnative -DskipTests` | GraalVM Native Image |

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

### 3.1 JVM Docker 镜像

```yaml
- name: Build JVM Docker Image
  run: |
    ./mvnw package -DskipTests
    docker build -f src/main/docker/Dockerfile.jvm \
      -t ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:${{ github.sha }} .
    docker tag ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:${{ github.sha }} \
               ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:latest

- name: Push Docker Image
  run: |
    docker push ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:${{ github.sha }}
    docker push ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:latest
```

### 3.2 Native Docker 镜像

```yaml
- name: Build Native Image
  run: ./mvnw package -Pnative -Dquarkus.native.container-build=true

- name: Build Native Docker Image
  run: |
    docker build -f src/main/docker/Dockerfile.native \
      -t ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:native .
    docker push ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:native
```

---

## 4. Dockerfile 规范

### 4.1 JVM 多阶段构建

```dockerfile
# 构建阶段
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn package -DskipTests

# 运行阶段
FROM registry.access.redhat.com/ubi9/openjdk-17-runtime:latest
ENV LANGUAGE='en_US:en'
COPY --from=builder --chown=185 /app/target/quarkus-app/lib/ /deployments/lib/
COPY --from=builder --chown=185 /app/target/quarkus-app/*.jar /deployments/
COPY --from=builder --chown=185 /app/target/quarkus-app/app/ /deployments/app/
COPY --from=builder --chown=185 /app/target/quarkus-app/quarkus/ /deployments/quarkus/
EXPOSE 8080
USER 185
ENV JAVA_OPTS_APPEND="-Dquarkus.http.host=0.0.0.0 -Djava.util.logging.manager=org.jboss.logmanager.LogManager"
ENTRYPOINT ["java", "-jar", "/deployments/quarkus-run.jar"]
```

### 4.2 Native Dockerfile

```dockerfile
FROM quay.io/quarkus/quarkus-micro-image:2.0
WORKDIR /work/
COPY target/*-runner /work/application
RUN chmod 775 /work
EXPOSE 8080
CMD ["./application", "-Dquarkus.http.host=0.0.0.0"]
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

### 5.2 健康检查

```yaml
livenessProbe:
  httpGet:
    path: /q/health/live
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /q/health/ready
    port: 8080
  initialDelaySeconds: 3
  periodSeconds: 5
```

**注意**：Quarkus 健康检查路径为 `/q/health`、`/q/health/live`、`/q/health/ready`。

---

## 6. 环境管理

| 环境 | 触发条件 | 说明 |
|---|---|---|
| dev | push 到 develop 分支 | 开发环境，自动部署 |
| staging | push 到 release/* 分支 | 预发布环境，需审批 |
| production | push tag（如 v1.0.0） | 生产环境，需审批 |

---

## 7. 通知与告警

```yaml
- name: Notify on Failure
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {"text": "CI 流水线失败: ${{ github.repository }} - ${{ github.ref_name }}"}
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

---

## 8. 缓存优化

```yaml
# Maven 依赖缓存
- uses: actions/cache@v4
  with:
    path: ~/.m2/repository
    key: ${{ runner.os }}-maven-${{ hashFiles('**/pom.xml') }}
    restore-keys: ${{ runner.os }}-maven-

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
  run: ./mvnw org.owasp:dependency-check-maven:check

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

## 10. Native Image CI

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
        run: ./mvnw package -Pnative

      - name: Run Native Tests
        run: ./mvnw verify -Pnative

      - name: Build Native Docker Image
        run: |
          docker build -f src/main/docker/Dockerfile.native \
            -t ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:native .
```

---

## 11. 检查清单

- [ ] 每次 push 触发 CI 流水线
- [ ] 单元测试和集成测试在流水线中运行
- [ ] 代码质量扫描配置完成
- [ ] Docker 镜像自动构建（JVM + Native）
- [ ] 敏感信息使用 Secrets 管理
- [ ] 部署前有人工审批（生产环境）
- [ ] 健康检查路径正确（`/q/health` 而非 `/actuator/health`）
- [ ] Native Image 编译在 CI 中验证
- [ ] 回滚方案可用
- [ ] 流水线失败有通知
