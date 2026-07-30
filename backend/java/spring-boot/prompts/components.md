# Spring Boot 组件规范

> 通用 Spring Boot Starter 组件使用指南。

---

## 1. 核心 Starters

### 1.1 spring-boot-starter-web

RESTful Web 应用核心依赖，包含 Spring MVC、嵌入式 Tomcat、Jackson。

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```

**关键配置**：

```yaml
server:
  port: 8080
  servlet:
    context-path: /api

spring:
  jackson:
    date-format: yyyy-MM-dd HH:mm:ss
    time-zone: GMT+8
    default-property-inclusion: non_null
```

### 1.2 spring-boot-starter-data-jpa

JPA + Hibernate 持久化方案。

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
```

**关键配置**：

```yaml
spring:
  jpa:
    hibernate:
      ddl-auto: validate  # none | validate | update | create-drop
    show-sql: false
    open-in-view: false   # 生产环境 MUST 关闭
    properties:
      hibernate:
        format_sql: true
```

### 1.3 spring-boot-starter-security

认证与授权框架。

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

**基础配置**（Spring Security 5.7+）：

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/public/**").permitAll()
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()));
        return http.build();
    }
}
```

### 1.4 spring-boot-starter-validation

Bean Validation 参数校验。

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
</dependency>
```

详见 `prompts/validation.md`。

### 1.5 spring-boot-starter-actuator

应用监控与健康检查。

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

**关键配置**：

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      show-details: when_authorized
```

---

## 2. 数据访问

### 2.1 MyBatis-Plus

```xml
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-plus-spring-boot3-starter</artifactId>
    <version>3.5.16</version>
</dependency>
```

**关键配置**：

```yaml
mybatis-plus:
  mapper-locations: classpath*:/mapper/**/*.xml
  global-config:
    db-config:
      logic-delete-field: isDeleted
      logic-delete-value: 1
      logic-not-delete-value: 0
  configuration:
    log-impl: org.apache.ibatis.logging.slf4j.Slf4jImpl
```

**分页插件**：

```java
@Configuration
public class MybatisPlusConfig {
    @Bean
    public MybatisPlusInterceptor mybatisPlusInterceptor() {
        MybatisPlusInterceptor interceptor = new MybatisPlusInterceptor();
        interceptor.addInnerInterceptor(new PaginationInnerInterceptor(DbType.MYSQL));
        return interceptor;
    }
}
```

### 2.2 Spring Data Redis

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
```

**关键配置**：

```yaml
spring:
  data:
    redis:
      host: localhost
      port: 6379
      password: ${REDIS_PASSWORD:}
      timeout: 3000ms
      lettuce:
        pool:
          max-active: 8
          max-idle: 8
          min-idle: 0
```

**RedisTemplate 配置**：

```java
@Configuration
public class RedisConfig {
    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory factory) {
        RedisTemplate<String, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(factory);
        template.setKeySerializer(new StringRedisSerializer());
        template.setValueSerializer(new GenericJackson2JsonRedisSerializer());
        return template;
    }
}
```

---

## 3. 消息队列

### 3.1 RocketMQ

```xml
<dependency>
    <groupId>org.apache.rocketmq</groupId>
    <artifactId>rocketmq-spring-boot-starter</artifactId>
    <version>2.3.0</version>
</dependency>
```

### 3.2 Kafka

```xml
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
</dependency>
```

---

## 4. 定时任务

```java
@Configuration
@EnableScheduling
public class ScheduleConfig { }

@Component
public class ScheduledTasks {
    @Scheduled(cron = "0 0 2 * * ?")  // 每天凌晨 2 点
    public void cleanExpiredData() {
        // 定时任务逻辑
    }
}
```

**分布式环境**：MUST 使用分布式锁（如 ShedLock），避免多实例重复执行。

---

## 5. 异步处理

```java
@Configuration
@EnableAsync
public class AsyncConfig {
    @Bean
    public Executor taskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(5);
        executor.setMaxPoolSize(10);
        executor.setQueueCapacity(100);
        executor.setThreadNamePrefix("async-");
        executor.initialize();
        return executor;
    }
}

@Service
public class AsyncService {
    @Async
    public CompletableFuture<String> doAsync() {
        // 异步任务
        return CompletableFuture.completedFuture("done");
    }
}
```

---

## 6. 跨域配置

```java
@Configuration
public class CorsConfig implements WebMvcConfigurer {
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
            .allowedOriginPatterns("*")
            .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
            .allowedHeaders("*")
            .allowCredentials(true)
            .maxAge(3600);
    }
}
```

---

## 7. 文件上传

```yaml
spring:
  servlet:
    multipart:
      max-file-size: 10MB
      max-request-size: 50MB
```

```java
@PostMapping("/upload")
public Result<String> upload(@RequestParam("file") MultipartFile file) {
    // 校验文件类型和大小
    if (file.isEmpty()) {
        return Result.fail("文件不能为空");
    }
    // 上传逻辑
    return Result.success(fileUrl);
}
```

---

## 8. 组件选型速查

| 需求 | 推荐组件 | 说明 |
|---|---|---|
| Web 框架 | spring-boot-starter-web | REST API |
| ORM | MyBatis-Plus / Spring Data JPA | 按团队习惯选择 |
| 缓存 | spring-boot-starter-data-redis + Caffeine | 分布式 + 本地 |
| 安全 | spring-boot-starter-security + JWT | 认证鉴权 |
| 参数校验 | spring-boot-starter-validation | Bean Validation |
| 监控 | spring-boot-starter-actuator + Micrometer | 健康检查 + 指标 |
| API 文档 | springdoc-openapi | OpenAPI 3 |
| 消息队列 | RocketMQ / Kafka | 异步解耦 |
| 定时任务 | @Scheduled + ShedLock | 分布式锁 |
| 配置中心 | Nacos / Spring Cloud Config | 动态配置 |
| 熔断降级 | Sentinel / Resilience4j | 高可用 |
| 链路追踪 | SkyWalking / Micrometer Tracing | 可观测性 |
