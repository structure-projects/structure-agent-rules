# Quarkus 项目搭建规范

> Quarkus 3.x 项目脚手架创建、初始化与结构搭建指南。

---

## 1. 创建项目

### 1.1 使用 Quarkus CLI

```bash
# 安装 Quarkus CLI
curl -Ls https://sh.jbang.dev | bash -s - trust add https://repo1.maven.org/maven2/io/quarkus/quarkus-cli/
curl -Ls https://sh.jbang.dev | bash -s - app install --fresh --force quarkus@quarkusio

# 创建项目
quarkus create app com.example:user-service \
    --extensions=resteasy-reactive-jackson,hibernate-orm-panache,hibernate-validator,smallrye-openapi,smallrye-jwt,rest-client-reactive-jackson,jdbc-postgresql
```

### 1.2 使用 code.quarkus.io（Web）

访问 https://code.quarkus.io/ 在线生成项目。

### 1.3 Maven Archetype

```bash
mvn io.quarkus:quarkus-maven-plugin:3.15.0:create \
    -DprojectGroupId=com.example \
    -DprojectArtifactId=user-service \
    -Dextensions=resteasy-reactive-jackson,hibernate-orm-panache,hibernate-validator
```

---

## 2. 项目结构初始化

```bash
mkdir -p src/main/java/com/example/{api/resource,api/dto,domain/entity,domain/service,application/service,infrastructure/client}
mkdir -p src/main/resources
mkdir -p src/test/java/com/example
mkdir -p src/test/resources
```

最终结构：

```
src/
├── main/
│   ├── java/com/example/
│   │   ├── api/
│   │   │   ├── resource/
│   │   │   └── dto/
│   │   ├── domain/
│   │   │   ├── entity/
│   │   │   └── service/
│   │   ├── application/
│   │   │   └── service/
│   │   └── infrastructure/
│   │       └── client/
│   └── resources/
│       ├── application.properties
│       └── import.sql
└── test/
    ├── java/com/example/
    └── resources/
        └── application.properties
```

---

## 3. 核心配置文件

### 3.1 application.properties（公共配置）

```properties
quarkus.application.name=user-service
quarkus.http.port=8080

# 数据源
quarkus.datasource.db-kind=postgresql
quarkus.datasource.jdbc.url=jdbc:postgresql://localhost:5432/user_db
quarkus.datasource.username=${DB_USERNAME:postgres}
quarkus.datasource.password=${DB_PASSWORD:postgres}
quarkus.datasource.jdbc.max-size=16

# Hibernate
quarkus.hibernate-orm.database.generation=validate
quarkus.hibernate-orm.log.sql=false
quarkus.hibernate-orm.sql-load-script=no-file

# 日志
quarkus.log.level=INFO
quarkus.log.category."com.example".level=DEBUG
```

### 3.2 Profile 配置

```properties
# 开发环境
%dev.quarkus.hibernate-orm.database.generation=drop-and-create
%dev.quarkus.hibernate-orm.log.sql=true
%dev.quarkus.datasource.jdbc.url=jdbc:postgresql://localhost:5432/user_dev

# 生产环境
%prod.quarkus.datasource.jdbc.url=${DB_URL}
%prod.quarkus.datasource.username=${DB_USERNAME}
%prod.quarkus.datasource.password=${DB_PASSWORD}
%prod.quarkus.http.port=${SERVER_PORT:8080}

# 测试环境（src/test/resources/application.properties）
# quarkus.datasource.db-kind=h2
# quarkus.datasource.jdbc.url=jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1
```

---

## 4. 数据库初始化

### 4.1 Flyway 迁移（推荐）

```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-flyway</artifactId>
</dependency>
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

---

## 5. 日志配置

```properties
quarkus.log.console.format=%d{HH:mm:ss} %-5p [%c] (%t) %s%e%n
quarkus.log.category."org.hibernate.SQL".level=DEBUG
%prod.quarkus.log.console.json=true
```

---

## 6. Docker 配置

### 6.1 JVM Dockerfile

```dockerfile
FROM registry.access.redhat.com/ubi9/openjdk-17:latest
COPY --chown=185 target/quarkus-app/lib/ /deployments/lib/
COPY --chown=185 target/quarkus-app/*.jar /deployments/
COPY --chown=185 target/quarkus-app/app/ /deployments/app/
COPY --chown=185 target/quarkus-app/quarkus/ /deployments/quarkus/
EXPOSE 8080
USER 185
ENV JAVA_OPTS_APPEND="-Xms256m -Xmx512m"
ENTRYPOINT ["java", "-jar", "/deployments/quarkus-run.jar"]
```

### 6.2 Native Dockerfile

```dockerfile
FROM quay.io/quarkus/quarkus-micro-image:2.0
WORKDIR /work/
COPY target/*-runner /work/application
RUN chmod 775 /work
EXPOSE 8080
CMD ["./application", "-Dquarkus.http.host=0.0.0.0"]
```

### 6.3 docker-compose.yml

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

## 7. Git 初始化

```bash
git init
echo "target/
*.class
*.jar
*.war
.idea/
*.iml
.mvn/
" > .gitignore

git add .
git commit -m "chore: init quarkus project"
```

---

## 8. Dev 模式

```bash
# 启动 Dev 模式（热重载）
./mvnw quarkus:dev

# Dev UI 地址
# http://localhost:8080/q/dev
```

---

## 9. Native Image 构建

```bash
# 安装 GraalVM
sdk install java 21.0.1-graal

# Native 编译
./mvnw package -Pnative

# Native + Docker
./mvnw package -Pnative -Dquarkus.native.container-build=true
```

---

## 10. 验证项目

```bash
# 编译
./mvnw compile

# 测试
./mvnw test

# 启动
./mvnw quarkus:dev

# 验证
curl http://localhost:8080/q/health
```

---

## 11. 搭建检查清单

- [ ] JDK 17+ 已安装
- [ ] Maven 构建正常（`./mvnw compile`）
- [ ] DDD 四层目录已创建
- [ ] application.properties 基本配置完成
- [ ] 数据库连接配置正确
- [ ] Flyway 迁移脚本就绪
- [ ] Dockerfile 就绪
- [ ] .gitignore 配置完成
- [ ] Dev 模式可正常启动（`./mvnw quarkus:dev`）
- [ ] 测试能正常运行（`./mvnw test`）
