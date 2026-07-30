# Micronaut 项目搭建规范

> Micronaut 4.x 项目脚手架创建、初始化与结构搭建指南。

---

## 1. 创建项目

### 1.1 使用 Micronaut CLI

```bash
# 安装 SDKMAN（如未安装）
curl -s "https://get.sdkman.io" | bash
sdk install micronaut

# 创建项目
mn create-app com.example.user-service \
    --features=graalvm,postgres,jpa,hibernate-validator,openapi,security-jwt,reactor \
    --build=gradle_kotlin \
    --lang=java \
    --jdk=17
```

### 1.2 使用 Micronaut Launch（Web）

访问 https://micronaut.io/launch/ 在线生成项目。

### 1.3 手动创建（Gradle）

```kotlin
// build.gradle.kts
plugins {
    id("io.micronaut.application") version "4.4.0"
}

version = "0.1"
group = "com.example"

repositories {
    mavenCentral()
}

micronaut {
    version.set("4.4.0")
    runtime.set(io.micronaut.gradle.MicronautRuntime.NETTY)
}

dependencies {
    annotationProcessor("io.micronaut:micronaut-inject-java")
    annotationProcessor("io.micronaut.data:micronaut-data-processor")
    annotationProcessor("io.micronaut.openapi:micronaut-openapi")
    annotationProcessor("io.micronaut.validation:micronaut-validation-processor")

    implementation("io.micronaut:micronaut-http-server-netty")
    implementation("io.micronaut.data:micronaut-data-hibernate-jpa")
    implementation("io.micronaut.reactor:micronaut-reactor")
    implementation("io.micronaut.security:micronaut-security-jwt")
    implementation("io.micronaut.openapi:micronaut-openapi")
    implementation("jakarta.validation:jakarta.validation-api")

    runtimeOnly("org.postgresql:postgresql")
    runtimeOnly("io.micronaut.sql:micronaut-jdbc-hikari")

    testImplementation("io.micronaut.test:micronaut-test-junit5")
    testImplementation("org.assertj:assertj-core")
    testImplementation("org.testcontainers:testcontainers")
    testImplementation("org.testcontainers:postgresql")
}

application {
    mainClass.set("com.example.Application")
}
```

---

## 2. 项目结构初始化

```bash
# 创建 DDD 四层目录
mkdir -p src/main/java/com/example/{api/{controller,dto},domain/{entity,repository,service},application/service,infrastructure/{repository,client}}
mkdir -p src/main/resources
mkdir -p src/test/java/com/example
mkdir -p src/test/resources
```

最终结构：

```
src/
├── main/
│   ├── java/com/example/
│   │   ├── Application.java
│   │   ├── api/
│   │   │   ├── controller/
│   │   │   └── dto/
│   │   ├── domain/
│   │   │   ├── entity/
│   │   │   ├── repository/
│   │   │   └── service/
│   │   ├── application/
│   │   │   └── service/
│   │   └── infrastructure/
│   │       ├── repository/
│   │       └── client/
│   └── resources/
│       ├── application.yml
│       ├── application-dev.yml
│       └── application-prod.yml
└── test/
    ├── java/com/example/
    └── resources/
        └── application-test.yml
```

---

## 3. 入口类

```java
package com.example;

import io.micronaut.runtime.Micronaut;

public class Application {
    public static void main(String[] args) {
        Micronaut.run(Application.class, args);
    }
}
```

---

## 4. 核心配置文件

### 4.1 application.yml（公共配置）

```yaml
micronaut:
  application:
    name: user-service
  server:
    port: 8080
    cors:
      enabled: true

datasources:
  default:
    driver-class-name: org.postgresql.Driver
    db-type: postgresql

jpa:
  default:
    properties:
      hibernate:
        hbm2ddl:
          auto: validate
        show_sql: false
        format_sql: true

jackson:
  serialization:
    writeDatesAsTimestamps: false
    writeDateKeysAsTimestamps: false
  dateFormat: yyyy-MM-dd HH:mm:ss
```

### 4.2 application-dev.yml

```yaml
datasources:
  default:
    url: jdbc:postgresql://localhost:5432/user_db
    username: postgres
    password: postgres

jpa:
  default:
    properties:
      hibernate:
        hbm2ddl:
          auto: update
        show_sql: true

micronaut:
  server:
    port: 8080
```

### 4.3 application-prod.yml

```yaml
datasources:
  default:
    url: ${DB_URL}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}

micronaut:
  server:
    port: ${SERVER_PORT:8080}
```

### 4.4 application-test.yml

```yaml
datasources:
  default:
    url: jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1
    username: sa
    password: ""
    driver-class-name: org.h2.Driver

jpa:
  default:
    properties:
      hibernate:
        hbm2ddl:
          auto: create-drop
```

---

## 5. 数据库初始化

### 5.1 Flyway 迁移（推荐）

```kotlin
// build.gradle.kts 添加依赖
implementation("io.micronaut.flyway:micronaut-flyway")
```

```sql
-- src/main/resources/db/migration/V1__init_users.sql
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### 5.2 JPA DDL（仅开发环境）

```yaml
# application-dev.yml
jpa:
  default:
    properties:
      hibernate:
        hbm2ddl:
          auto: update  # 仅开发环境使用
```

---

## 6. 日志配置

```yaml
# src/main/resources/logback.xml
<configuration>
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>

    <root level="INFO">
        <appender-ref ref="STDOUT"/>
    </root>

    <logger name="com.example" level="DEBUG"/>
    <logger name="io.micronaut" level="INFO"/>
</configuration>
```

---

## 7. Docker 配置

### 7.1 Dockerfile

```dockerfile
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY build/libs/*-all.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 7.2 docker-compose.yml

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: user_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"

  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      DB_URL: jdbc:postgresql://postgres:5432/user_db
      DB_USERNAME: postgres
      DB_PASSWORD: postgres
    depends_on:
      - postgres
```

---

## 8. Git 初始化

```bash
git init
echo "build/
.gradle/
*.class
*.jar
*.war
.idea/
*.iml
out/
bin/" > .gitignore

git add .
git commit -m "chore: init micronaut project with DDD structure"
```

---

## 9. IDE 配置

### 9.1 IntelliJ IDEA

启用 Annotation Processing：
`Settings → Build → Compiler → Annotation Processors → Enable annotation processing`

### 9.2 VS Code

安装扩展：
- Extension Pack for Java
- Gradle for Java

---

## 10. 验证项目

```bash
# 编译
./gradlew build

# 运行
./gradlew run

# 测试
./gradlew test

# 启动后验证
curl http://localhost:8080/health
```

---

## 11. 搭建检查清单

- [ ] JDK 17+ 已安装
- [ ] Gradle 构建正常（`./gradlew build`）
- [ ] DDD 四层目录已创建
- [ ] application.yml 基本配置完成
- [ ] 数据库连接配置正确
- [ ] Flyway 迁移脚本就绪
- [ ] Dockerfile 和 docker-compose.yml 就绪
- [ ] .gitignore 配置完成
- [ ] 日志配置完成
- [ ] 测试能正常运行（`./gradlew test`）
