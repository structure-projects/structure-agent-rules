# Spring Boot 项目脚手架规范

> 通用 Spring Boot 项目初始化与搭建指南。

---

## 1. 项目初始化

### 1.1 Spring Initializr

推荐使用 [Spring Initializr](https://start.spring.io) 生成项目骨架：

- **Project**：Maven / Gradle
- **Language**：Java
- **Spring Boot**：3.x（最新稳定版）
- **Group**：`com.{company}`
- **Artifact**：`{project-name}`
- **JDK**：17 或 21
- **Packaging**：Jar

### 1.2 常用依赖组合

**最小 Web 项目**：
- Spring Web
- Lombok
- Validation
- Spring Boot Actuator

**标准业务项目**：
- Spring Web
- Lombok
- Validation
- Spring Boot Actuator
- MyBatis-Plus / Spring Data JPA
- MySQL Driver
- Spring Security
- Spring Data Redis

---

## 2. 项目结构

### 2.1 单模块项目

```
{project}/
├── src/
│   ├── main/
│   │   ├── java/com/{company}/{project}/
│   │   │   ├── controller/       # 控制器
│   │   │   ├── service/          # 业务接口
│   │   │   │   └── impl/         # 业务实现
│   │   │   ├── repository/       # 数据访问（JPA）
│   │   │   │   └── mapper/       # Mapper（MyBatis）
│   │   │   ├── entity/           # 实体类
│   │   │   ├── dto/              # 数据传输对象
│   │   │   ├── vo/               # 视图对象
│   │   │   ├── config/           # 配置类
│   │   │   ├── common/           # 公共类
│   │   │   │   ├── exception/    # 异常定义
│   │   │   │   ├── result/       # 统一响应
│   │   │   │   └── util/         # 工具类
│   │   │   └── Application.java  # 启动类
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-dev.yml
│   │       ├── application-prod.yml
│   │       └── mapper/           # MyBatis XML
│   └── test/
│       └── java/com/{company}/{project}/
├── pom.xml
├── Dockerfile
└── README.md
```

### 2.2 多模块项目

```
{project}/
├── {project}-api/              # 接口定义 + DTO
├── {project}-biz/              # 业务实现
├── {project}-core/             # 领域模型 + 仓储接口
├── {project}-infra/            # 基础设施
├── {project}-boot/             # 启动 + 配置
├── {project}-client/           # Feign 客户端（可选）
└── pom.xml                     # 父 POM
```

### 2.3 启动类

```java
package com.company.project;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

---

## 3. Maven 配置

### 3.1 父 POM（多模块）

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.0</version>
        <relativePath/>
    </parent>

    <groupId>com.company</groupId>
    <artifactId>project-parent</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>pom</packaging>

    <modules>
        <module>project-api</module>
        <module>project-core</module>
        <module>project-infra</module>
        <module>project-biz</module>
        <module>project-boot</module>
    </modules>

    <properties>
        <java.version>17</java.version>
        <mybatis-plus.version>3.5.16</mybatis-plus.version>
    </properties>

    <dependencyManagement>
        <dependencies>
            <!-- 统一管理子模块版本 -->
        </dependencies>
    </dependencyManagement>
</project>
```

### 3.2 子模块 POM 示例

```xml
<!-- project-biz/pom.xml -->
<parent>
    <groupId>com.company</groupId>
    <artifactId>project-parent</artifactId>
    <version>1.0.0-SNAPSHOT</version>
</parent>

<artifactId>project-biz</artifactId>

<dependencies>
    <dependency>
        <groupId>com.company</groupId>
        <artifactId>project-core</artifactId>
    </dependency>
    <dependency>
        <groupId>com.company</groupId>
        <artifactId>project-infra</artifactId>
    </dependency>
</dependencies>
```

---

## 4. application.yml 配置

### 4.1 基础配置

```yaml
# application.yml
spring:
  application:
    name: project-name
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:dev}

server:
  port: 8080

logging:
  level:
    root: INFO
    com.company: DEBUG
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"
```

### 4.2 开发环境

```yaml
# application-dev.yml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/db_dev?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai
    username: root
    password: ${DB_PASSWORD:root}
    driver-class-name: com.mysql.cj.jdbc.Driver

  data:
    redis:
      host: localhost
      port: 6379
```

### 4.3 生产环境

```yaml
# application-prod.yml
spring:
  datasource:
    url: ${DB_URL}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}

  data:
    redis:
      host: ${REDIS_HOST}
      port: ${REDIS_PORT:6379}
      password: ${REDIS_PASSWORD}

logging:
  level:
    root: WARN
    com.company: INFO
```

---

## 5. 统一响应体

```java
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Result<T> {
    private Integer code;
    private String message;
    private T data;

    public static <T> Result<T> success(T data) {
        return new Result<>(200, "success", data);
    }

    public static <T> Result<T> fail(Integer code, String message) {
        return new Result<>(code, message, null);
    }

    public static <T> Result<T> fail(String message) {
        return new Result<>(500, message, null);
    }
}
```

---

## 6. 全局异常处理

```java
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public Result<Void> handleBusinessException(BusinessException e) {
        log.warn("业务异常: code={}, message={}", e.getCode(), e.getMessage());
        return Result.fail(e.getCode(), e.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public Result<Void> handleValidationException(MethodArgumentNotValidException e) {
        String message = e.getBindingResult().getFieldErrors().stream()
            .map(FieldError::getDefaultMessage)
            .collect(Collectors.joining(", "));
        return Result.fail(400, message);
    }

    @ExceptionHandler(Exception.class)
    public Result<Void> handleException(Exception e) {
        log.error("系统异常", e);
        return Result.fail(500, "系统内部错误");
    }
}
```

---

## 7. 分页工具

```java
@Data
public class PageQuery {
    @Min(1)
    private Integer pageNum = 1;

    @Min(1)
    @Max(100)
    private Integer pageSize = 20;
}

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PageResult<T> {
    private Long total;
    private Integer pageNum;
    private Integer pageSize;
    private List<T> records;

    public static <T> PageResult<T> of(Long total, Integer pageNum, Integer pageSize, List<T> records) {
        return new PageResult<>(total, pageNum, pageSize, records);
    }
}
```

---

## 8. Dockerfile 模板

```dockerfile
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-Xms512m", "-Xmx1024m", "-jar", "app.jar"]
```

---

## 9. 检查清单

初始化项目后 MUST 确认：

- [ ] 包名与 groupId 一致
- [ ] `Application.java` 在根包下
- [ ] `application.yml` 多环境配置就绪
- [ ] 统一响应体 `Result<T>` 已定义
- [ ] 全局异常处理器已配置
- [ ] 数据库连接配置正确
- [ ] 日志配置合理
- [ ] `.gitignore` 包含 `target/`、`*.log`、`application-local.yml`
- [ ] Dockerfile 可用
