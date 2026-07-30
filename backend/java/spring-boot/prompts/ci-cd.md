# Spring Boot CI/CD 规范

> 通用 Spring Boot 项目持续集成与持续部署规范。

---

## 1. CI/CD 流水线总览

```
代码提交 → 编译 → 单元测试 → 代码扫描 → 集成测试 → 构建镜像 → 推送仓库 → 部署
```

---

## 2. 持续集成（CI）

### 2.1 GitHub Actions 流水线

#### Maven 项目

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
        run: mvn clean package -DskipTests

      - name: Unit Tests
        run: mvn test

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: '**/target/surefire-reports/*.xml'
```

#### Gradle 项目

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

      - name: Build and Test
        run: ./gradlew build
```

### 2.2 流水线阶段

每个阶段失败时 MUST 阻断后续阶段：

| 阶段 | 命令（Maven） | 说明 |
|---|---|---|
| 编译 | `mvn clean compile` | 编译源码 |
| 单元测试 | `mvn test` | 运行单元测试 |
| 代码扫描 | SonarQube / Checkstyle | 静态代码分析 |
| 打包 | `mvn clean package -DskipTests` | 构建制品 |
| 集成测试 | `mvn verify` | 运行集成测试 |

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

### 3.1 Maven 发布

```yaml
- name: Publish to Maven Repository
  run: mvn deploy -DskipTests
  env:
    MAVEN_USERNAME: ${{ secrets.MAVEN_USERNAME }}
    MAVEN_PASSWORD: ${{ secrets.MAVEN_PASSWORD }}
```

### 3.2 Docker 镜像构建

```yaml
- name: Build Docker Image
  run: |
    docker build -t ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:${{ github.sha }} .
    docker tag ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:${{ github.sha }} \
               ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:latest

- name: Push Docker Image
  run: |
    docker push ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:${{ github.sha }}
    docker push ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:latest
```

---

## 4. Dockerfile 规范

### 4.1 多阶段构建

```dockerfile
# 构建阶段
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package -DskipTests

# 运行阶段
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 4.2 JVM 参数

```dockerfile
ENTRYPOINT ["java", \
    "-Xms512m", "-Xmx1024m", \
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
    path: /actuator/health/liveness
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
```

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

### 7.1 流水线通知

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
  run: mvn dependency-check:check

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

## 10. 检查清单

- [ ] 每次 push 触发 CI 流水线
- [ ] 单元测试和集成测试在流水线中运行
- [ ] 代码质量扫描配置完成
- [ ] Docker 镜像自动构建
- [ ] 敏感信息使用 Secrets 管理
- [ ] 部署前有人工审批（生产环境）
- [ ] 健康检查配置正确
- [ ] 回滚方案可用
- [ ] 流水线失败有通知
