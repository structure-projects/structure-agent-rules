# Quarkus 参数校验规范

> Quarkus 3.x 项目 Bean Validation 规范（jakarta.validation + Hibernate Validator）。

---

## 1. 依赖与基础

Quarkus 使用 `quarkus-hibernate-validator` 扩展：

```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-hibernate-validator</artifactId>
</dependency>
```

**注意**：Quarkus 3.x 使用 `jakarta.validation` 包，Hibernate Validator 8.x 作为实现。

---

## 2. 常用校验注解

### 2.1 基础校验

| 注解 | 说明 | 示例 |
|---|---|---|
| `@NotNull` | 不能为 null | `@NotNull` |
| `@NotBlank` | 不能为 null 且 trim 后长度 > 0（String） | `@NotBlank` |
| `@NotEmpty` | 不能为 null 且 size > 0 | `@NotEmpty` |
| `@Size(min, max)` | 长度范围（String/Collection） | `@Size(min=2, max=50)` |
| `@Min(value)` | 最小值（数字） | `@Min(0)` |
| `@Max(value)` | 最大值（数字） | `@Max(150)` |
| `@Email` | 邮箱格式 | `@Email` |
| `@Pattern(regexp)` | 正则匹配 | `@Pattern(regexp="^1[3-9]\\d{9}$")` |
| `@Positive` | 正数（> 0） | `@Positive` |
| `@PositiveOrZero` | 非负数 | `@PositiveOrZero` |
| `@Negative` | 负数 | `@Negative` |
| `@DecimalMin(value)` | 最小值（BigDecimal） | `@DecimalMin("0.01")` |
| `@DecimalMax(value)` | 最大值（BigDecimal） | `@DecimalMax("999999.99")` |
| `@Digits(integer, fraction)` | 整数和小数位数 | `@Digits(integer=10, fraction=2)` |
| `@Past` | 过去日期 | `@Past` |
| `@Future` | 未来日期 | `@Future` |
| `@AssertTrue` / `@AssertFalse` | 布尔断言 | `@AssertTrue` |

### 2.2 嵌套校验

```java
public class OrderDTO {
    @NotNull
    @Valid  // MUST 加 @Valid 才会校验嵌套对象
    public List<OrderItemDTO> items;
}

public class OrderItemDTO {
    @NotNull
    public Long productId;

    @Min(1)
    public Integer quantity;
}
```

### 2.3 分组校验

```java
public interface Create { }
public interface Update { }

public class UserDTO {
    @NotNull(groups = Update.class)
    public Long id;

    @NotBlank(groups = {Create.class, Update.class})
    public String username;
}

// Resource 中使用
@POST
public Response create(@Valid CreateUserDTO dto) { ... }

@PUT
@Path("/{id}")
public Response update(@PathParam("id") Long id, @Valid UpdateUserDTO dto) { ... }
```

---

## 3. 自定义校验

### 3.1 自定义注解

```java
@Target({ElementType.FIELD})
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = PhoneValidator.class)
public @interface Phone {
    String message() default "手机号格式不正确";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}
```

### 3.2 自定义校验器

```java
public class PhoneValidator implements ConstraintValidator<Phone, String> {
    private static final Pattern PATTERN = Pattern.compile("^1[3-9]\\d{9}$");

    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        if (value == null) {
            return true;  // null 由 @NotNull 处理
        }
        return PATTERN.matcher(value).matches();
    }
}
```

### 3.3 类级别校验

```java
@Target({ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = DateRangeValidator.class)
public @interface ValidDateRange {
    String message() default "开始时间不能晚于结束时间";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}

@ValidDateRange
public class DateRangeDTO {
    public LocalDateTime startTime;
    public LocalDateTime endTime;
}
```

---

## 4. Resource 校验

### 4.1 请求体校验

```java
@POST
public Response create(@Valid CreateUserDTO dto) {
    // @Valid 触发校验，失败抛出 ConstraintViolationException
    return Response.status(Response.Status.CREATED).entity(userService.create(dto)).build();
}
```

### 4.2 查询参数校验

```java
@GET
@Path("/page")
public Response page(
        @QueryParam("pageNum") @DefaultValue("1") @Min(1) Integer pageNum,
        @QueryParam("pageSize") @DefaultValue("20") @Min(1) @Max(100) Integer pageSize) {
    return Response.ok(userService.page(pageNum, pageSize)).build();
}
```

---

## 5. 全局异常处理

```java
@Provider
public class ValidationExceptionMapper implements ExceptionMapper<ConstraintViolationException> {

    @Override
    public Response toResponse(ConstraintViolationException exception) {
        String message = exception.getConstraintViolations().stream()
            .map(v -> v.getPropertyPath() + ": " + v.getMessage())
            .collect(Collectors.joining("; "));
        return Response.status(Response.Status.BAD_REQUEST)
            .entity(new ErrorResponse(400, message))
            .build();
    }
}
```

**注意**：Quarkus RESTEasy Reactive 校验失败直接抛出 `ConstraintViolationException`（Jakarta 标准），不同于 Spring Boot 的 `MethodArgumentNotValidException`。

---

## 6. 校验规范（MUST）

### 6.1 校验位置

- Resource 入口 MUST 校验所有入参（`@Valid`）
- 对外暴露的 REST Client 接口 SHOULD 校验入参
- Service 层内部调用 MAY 不做重复校验

### 6.2 校验消息

- 所有校验注解 MUST 提供 `message`
- 消息内容应具体、可指导用户修正

### 6.3 禁止

- **禁止**在 Resource 方法体内手写 `if-else` 校验
- **禁止**嵌套对象不加 `@Valid`
- **禁止**校验消息中包含敏感信息

---

## 7. 常用模式

### 7.1 枚举值校验

```java
@Target({ElementType.FIELD})
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = EnumValueValidator.class)
public @interface EnumValue {
    String message() default "值不在允许范围内";
    Class<? extends Enum<?>> enumClass();
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}

// 使用
@EnumValue(enumClass = StatusEnum.class, message = "状态值无效")
public String status;
```

### 7.2 条件校验

```java
public class PasswordChangeDTO {

    @NotBlank
    public String newPassword;

    @NotBlank
    public String confirmPassword;

    @AssertTrue(message = "两次密码不一致")
    public boolean isPasswordMatch() {
        return newPassword != null && newPassword.equals(confirmPassword);
    }
}
```
