# Quarkus 3.x 后端项目

> Quarkus 是 Red Hat 开发的 Kubernetes Native Java 框架，专为 GraalVM 和 HotSpot 优化。
> 适用于构建云原生、Serverless 和容器化 Java/Kotlin 微服务。

## 技术栈

- **Quarkus**: 3.x
- **JDK**: 17+
- **语言**: Java / Kotlin
- **构建工具**: Maven（推荐）/ Gradle
- **响应式**: Mutiny（SmallRye Mutiny）— `Uni<T>` / `Multi<T>`
- **ORM**: Hibernate with Panache
- **REST**: RESTEasy Reactive（JAX-RS）
- **测试**: JUnit 5 + REST Assured + Testcontainers

## AI 规则索引

| 角色 | 规则文件 | 说明 |
|---|---|---|
| 开发者 | `rules/quarkus-developer.mdc` | 日常开发约束（alwaysApply: true） |
| 架构师 | `rules/quarkus-architect.mdc` | DDD 分层与模块设计 |
| 评审者 | `rules/quarkus-reviewer.mdc` | 代码评审清单 |
| 测试者 | `rules/quarkus-tester.mdc` | 测试编写规范 |

## 关键特性

1. **容器优先**：为 Kubernetes/Serverless 设计，极速启动（Native Image 亚秒级）
2. **JAX-RS 标准**：使用 RESTEasy Reactive，**非** Spring MVC
3. **CDI 依赖注入**：标准 Jakarta CDI，**非** Spring DI
4. **Panache ORM**：简化 Hibernate，Active Record 或 Repository 模式
5. **GraalVM Native**：内置 Native Image 编译支持
6. **Dev 模式**：`quarkus dev` 热重载 + Dev UI（`/q/dev`）

## 项目结构

```
src/main/java/com/example/
├── api/               # JAX-RS Resource（HTTP 接入层）
├── domain/            # Panache Entity + DomainService
├── application/       # ApplicationService（编排层）
└── infrastructure/    # REST Client + 外部集成
```

## 核心依赖

```xml
<!-- pom.xml -->
<dependencies>
    <!-- RESTEasy Reactive (JAX-RS) -->
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-resteasy-reactive-jackson</artifactId>
    </dependency>
    <!-- Hibernate + Panache -->
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-hibernate-orm-panache</artifactId>
    </dependency>
    <!-- Validation -->
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-hibernate-validator</artifactId>
    </dependency>
    <!-- REST Client -->
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-rest-client-reactive-jackson</artifactId>
    </dependency>
    <!-- OpenAPI -->
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-smallrye-openapi</artifactId>
    </dependency>
    <!-- Security (JWT) -->
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-smallrye-jwt</artifactId>
    </dependency>
    <!-- Test -->
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-junit5</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>rest-assured</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

## 相关规范

- [开发规范](prompts/developer.md)
- [架构设计](prompts/architect.md)
- [代码评审](prompts/reviewer.md)
- [测试规范](prompts/tester.md)
- [组件用法](prompts/components.md)
- [项目搭建](prompts/project-scaffolding.md)
- [API 文档](prompts/swagger.md)
- [参数校验](prompts/validation.md)
- [CI/CD](prompts/ci-cd.md)
