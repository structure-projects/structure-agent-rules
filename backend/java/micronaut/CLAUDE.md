# Micronaut 4.x 后端项目

> Micronaut 是一个基于编译时依赖注入（AOT）的 JVM 微服务框架，由 GraalVM 团队开发。
> 适用于构建高性能、低内存占用的云原生 Java 微服务。

## 技术栈

- **Micronaut**: 4.x
- **JDK**: 17+
- **语言**: Java（不推荐 Kotlin）
- **构建工具**: Gradle（Kotlin DSL）
- **响应式**: Project Reactor 或 RxJava 3
- **ORM**: Micronaut Data（JPA / JDBC）
- **测试**: JUnit 5 + AssertJ + Testcontainers

## AI 规则索引

| 角色 | 规则文件 | 说明 |
|---|---|---|
| 开发者 | `rules/micronaut-developer.mdc` | 日常开发约束（alwaysApply: true） |
| 架构师 | `rules/micronaut-architect.mdc` | DDD 分层与模块设计 |
| 评审者 | `rules/micronaut-reviewer.mdc` | 代码评审清单 |
| 测试者 | `rules/micronaut-tester.mdc` | 测试编写规范 |

## 关键特性

1. **编译时 DI**：所有依赖注入在编译时完成，无反射，启动极快
2. **声明式 HTTP 客户端**：`@Client` 注解，编译时生成实现
3. **原生 AOT 支持**：天然支持 GraalVM Native Image
4. **响应式优先**：内置 Project Reactor 支持
5. **Micronaut Data**：编译时生成 Repository 实现

## 项目结构（DDD 四层）

```
src/main/java/com/example/
├── api/               # Controller + DTO（HTTP 接入层）
├── domain/            # Entity + Repository 接口
├── application/       # ApplicationService（编排层）
└── infrastructure/    # Repository 实现 + 外部 Client
```

## 核心依赖

```kotlin
// build.gradle.kts
dependencies {
    annotationProcessor("io.micronaut:micronaut-inject-java")
    annotationProcessor("io.micronaut.data:micronaut-data-processor")
    implementation("io.micronaut:micronaut-http-server-netty")
    implementation("io.micronaut.data:micronaut-data-hibernate-jpa")
    implementation("io.micronaut.reactor:micronaut-reactor")
    implementation("io.micronaut.security:micronaut-security-jwt")
    runtimeOnly("org.postgresql:postgresql")
    testImplementation("io.micronaut.test:micronaut-test-junit5")
}
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
