# Micronaut 参数校验规范

> Micronaut 4.x 项目 Bean Validation 规范（jakarta.validation）。

---

## 1. 依赖与基础

Micronaut 需要显式添加校验依赖：

```kotlin
// build.gradle.kts
dependencies {
    annotationProcessor("io.micronaut.validation:micronaut-validation-processor")
    implementation("io.micronaut.validation:micronaut-validation")
    implementation("jakarta.validation:jakarta.validation-api")
}
```

**注意**：Micronaut 支持编译时校验（通过 `micronaut-validation-processor`），可提前发现校验错误。

---

## 2. 常用校验注解

### 2.1 基础校验

| 注解 | 说明 | 示例 |
|---|---|---|
| `@NotNull` | 不能为 null | `@NotNull` |
| `@NotBlank` | 不能为 null 且 trim 后长度 > 0（String） | `@NotBlank` |
| `@NotEmpty` | 不能为 null 且 size > 0（String/Collection/Map） | `@NotEmpty` |
| `@Size(min, max)` | 长度范围（String/Collection） | `@Size(min=2, max=50)` |
| `@Min(value)` | 最小值（数字） | `@Min(0)` |
| `@Max(value)` | 最大值（数字） | `@Max(150)` |
| `@Email` | 邮箱格式 | `@Email` |
| `@Pattern(regexp)` | 正则匹配 | `@Pattern(regexp="^1[3-9]\\d{9}$")` |
| `@Positive` | 正数（> 0） | `@Positive` |
| `@PositiveOrZero` | 非负数（≥ 0） | `@PositiveOrZero` |
| `@Negative` | 负数（< 0） | `@Negative` |
| `@DecimalMin(value)` | 最小值（BigDecimal） | `@DecimalMin("0.01")` |
| `@DecimalMax(value)` | 最大值（BigDecimal） | `@DecimalMax("999999.99")` |
| `@Digits(integer, fraction)` | 整数和小数位数 | `@Digits(integer=10, fraction=2)` |
| `@Past` | 过去日期 | `@Past` |
| `@Future` | 未来日期 | `@Future` |
| `@AssertTrue` / `@AssertFalse` | 布尔断言 | `@AssertTrue` |

### 2.2 嵌套校验

```java
@Introspected
public class OrderDTO {
    @NotNull
    @Valid  // MUST 加 @Valid 才会校验嵌套对象
    private List<OrderItemDTO> items;
}

@Introspected
public class OrderItemDTO {
    @NotNull
    private Long productId;

    @Min(1)
    private Integer quantity;
}
```

### 2.3 分组校验

```java
// 定义分组接口
public interface Create { }
public interface Update { }

@Introspected
public class UserDTO {
    @NotNull(groups = Update.class)          // 仅更新时需要 ID
    private Long id;

    @NotBlank(groups = {Create.class, Update.class})  // 创建和更新都需要
    private String username;
}

// Controller 中使用
@Post
public HttpResponse<Void> create(@Body @Validated(Create.class) UserDTO dto) { }

@Put("/{id}")
public HttpResponse<Void> update(@PathVariable Long id,
                                  @Body @Validated(Update.class) UserDTO dto) { }
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

### 3.3 类级别校验（跨字段校验）

```java
@Target({ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = DateRangeValidator.class)
public @interface ValidDateRange {
    String message() default "开始时间不能晚于结束时间";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}

@Introspected
public class DateRangeDTO implements DateRangeValidatable {
    private LocalDateTime startTime;
    private LocalDateTime endTime;

    @Override
    public boolean isValid() {
        return startTime == null || endTime == null || !startTime.isAfter(endTime);
    }
}
```

---

## 4. Controller 校验

### 4.1 请求体校验

```java
@Post
public HttpResponse<UserVO> create(@Body @Valid CreateUserDTO dto) {
    // @Valid 触发校验，失败抛出 ConstraintViolationException
    return HttpResponse.created(userService.create(dto));
}
```

### 4.2 路径参数和查询参数校验

```java
@Controller("/api/v1/users")
public class UserController {

    @Get("/{id}")
    public HttpResponse<UserVO> findById(
            @PathVariable @Min(1) Long id) {
        // 校验失败抛出 ConstraintViolationException
        return userService.findById(id)
            .map(HttpResponse::ok)
            .orElse(HttpResponse.notFound());
    }

    @Get("/page{?pageNum,pageSize}")
    public HttpResponse<Page<UserVO>> page(
            @QueryValue(defaultValue = "1") @Min(1) Integer pageNum,
            @QueryValue(defaultValue = "20") @Min(1) @Max(100) Integer pageSize) {
        return HttpResponse.ok(userService.page(pageNum, pageSize));
    }
}
```

---

## 5. Service 层校验

```java
@Singleton
public class UserApplicationService {

    public UserVO createUser(@Valid CreateUserDTO dto) {
        // Service 层也可以触发校验（需在 Controller 层手动调用 validate）
        return convert(userRepository.save(convert(dto)));
    }
}
```

---

## 6. 全局异常处理

```java
@Singleton
@Produces
public class ValidationExceptionHandler
        implements ExceptionHandler<ConstraintViolationException, HttpResponse<ErrorResponse>> {

    @Override
    public HttpResponse<ErrorResponse> handle(HttpRequest request, ConstraintViolationException e) {
        String message = e.getConstraintViolations().stream()
            .map(v -> v.getPropertyPath() + ": " + v.getMessage())
            .collect(Collectors.joining("; "));
        return HttpResponse.badRequest(new ErrorResponse(400, message));
    }
}
```

**注意**：Micronaut 校验失败抛出 `ConstraintViolationException`（不同于 Spring Boot 的 `MethodArgumentNotValidException`）。

---

## 7. 校验规范（MUST）

### 7.1 校验位置

- Controller 入口 MUST 校验所有入参（`@Valid` / `@Validated`）
- 对外暴露的 `@Client` 接口 SHOULD 校验入参
- Service 层内部调用 MAY 不做重复校验（信任上层已校验）

### 7.2 校验消息

- 所有校验注解 MUST 提供 `message`（中文或英文统一即可）
- 消息内容应具体、可指导用户修正（如 "用户名长度为 2-50 个字符" 而非 "参数错误"）

### 7.3 DTO 要求

- 所有 DTO/VO 类 MUST 标注 `@Introspected`（Micronaut AOT 要求）
- **禁止**在 Controller 方法体内手写 `if-else` 校验（应用注解）
- **禁止**嵌套对象不加 `@Valid`（校验不会递归）
- **禁止**校验消息中包含敏感信息

### 7.4 禁止

- **禁止**在 Controller 方法体内手写 `if-else` 校验（应用注解）
- **禁止**嵌套对象不加 `@Valid`（校验不会递归）
- **禁止**校验消息中包含敏感信息（如 "ID 为 123 的用户不存在" 暴露内部数据）

---

## 8. 常用模式

### 8.1 枚举值校验

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

public class EnumValueValidator implements ConstraintValidator<EnumValue, String> {
    private Set<String> allowedValues;

    @Override
    public void initialize(EnumValue annotation) {
        allowedValues = Arrays.stream(annotation.enumClass().getEnumConstants())
            .map(Enum::name)
            .collect(Collectors.toSet());
    }

    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        return value == null || allowedValues.contains(value);
    }
}

// 使用
@EnumValue(enumClass = StatusEnum.class, message = "状态值无效")
private String status;
```

### 8.2 条件校验

```java
@Introspected
public class PasswordChangeDTO {

    @NotBlank
    private String newPassword;

    @NotBlank
    private String confirmPassword;

    @AssertTrue(message = "两次密码不一致")
    public boolean isPasswordMatch() {
        return newPassword != null && newPassword.equals(confirmPassword);
    }
}
```
