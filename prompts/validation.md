# Validation — structure-projects 参数验证规范

> 角色：在 structure-projects 生态内做 **接口参数校验** 的 AI。
> 本文件是工具无关的单一内容源。

## 1. 常用验证注解（Jakarta Validation）

| 注解 | 说明 | 示例 |
|---|---|---|
| `@NotNull` | 不能为 null | `@NotNull(message = "不能为空")` |
| `@NotBlank` | 不能为空字符串 | `@NotBlank(message = "不能为空")` |
| `@NotEmpty` | 不能为空（集合/数组） | `@NotEmpty(message = "不能为空")` |
| `@Size` | 长度/大小范围 | `@Size(min=2, max=32)` |
| `@Min` / `@Max` | 数值最小/最大值 | `@Min(0)` / `@Max(150)` |
| `@DecimalMin` / `@DecimalMax` | BigDecimal 最小/最大值 | `@DecimalMin("0.01")` |
| `@Email` | 邮箱格式 | `@Email` |
| `@Pattern` | 正则表达式 | `@Pattern(regexp = "^1[3-9]\\d{9}$")` |
| `@Valid` | 开启级联验证 | `@Valid private AddressDTO address;` |

⚠️ Spring Boot 4 / Jakarta EE 环境下使用 `jakarta.validation.constraints.*`，**不是** `javax.validation.*`。

## 2. DTO 验证基础模板

```java
package cn.structured.example.common.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import lombok.Data;
import java.math.BigDecimal;

@Data
@Schema(description = "示例DTO")
public class ExampleDTO {

    @NotBlank(message = "编码不能为空")
    @Size(min = 2, max = 32, message = "编码长度为2-32个字符")
    @Pattern(regexp = "^[a-z][a-z0-9_]*$", message = "编码必须小写字母开头")
    @Schema(description = "编码", example = "example_001")
    private String code;

    @NotBlank(message = "名称不能为空")
    @Size(min = 1, max = 64, message = "名称长度为1-64个字符")
    @Schema(description = "名称", example = "示例名称")
    private String name;

    @NotNull(message = "年龄不能为空")
    @Min(value = 0, message = "年龄最小为0")
    @Max(value = 150, message = "年龄最大为150")
    @Schema(description = "年龄", example = "25")
    private Integer age;

    @DecimalMin(value = "0.01", message = "金额最小为0.01")
    @DecimalMax(value = "999999999.99", message = "金额最大为999999999.99")
    @Schema(description = "金额", example = "99.99")
    private BigDecimal amount;

    @Email(message = "邮箱格式不正确")
    @Schema(description = "邮箱", example = "example@example.com")
    private String email;

    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
    @Schema(description = "手机号", example = "13800138000")
    private String phone;
}
```

## 3. 分组验证（生态统一模式）

### 3.1 验证组定义（**生态统一命名**）

**MUST** 使用统一的 `ValidationGroups` 类 + `Add` / `Update` / `Query` / `Delete` 四个内部接口：

```java
package cn.structured.example.common.group;

public class ValidationGroups {

    public interface Add {
    }

    public interface Update {
    }

    public interface Query {
    }

    public interface Delete {
    }
}
```

### 3.2 DTO 分组标注

```java
@Data
@Schema(description = "示例DTO")
public class ExampleDTO {

    @NotNull(groups = {ValidationGroups.Update.class}, message = "ID不能为空")
    @Schema(description = "ID")
    private Long id;

    @NotBlank(groups = {ValidationGroups.Add.class}, message = "编码不能为空")
    @Schema(description = "编码")
    private String code;

    @NotBlank(message = "名称不能为空")  // 无 groups：Add 和 Update 都生效
    @Schema(description = "名称")
    private String name;
}
```

### 3.3 Controller 分组指定

```java
@RestController
@RequestMapping("/api/example")
@RequiredArgsConstructor
@Validated
public class ExampleController {

    private final IExampleService exampleService;

    @PostMapping
    public ResResultVO<Long> create(
            @Validated({ValidationGroups.Add.class, Default.class}) @RequestBody ExampleDTO dto) {
        return ResultUtilSimpleImpl.success(exampleService.create(dto));
    }

    @PutMapping("/{id}")
    public ResResultVO<Void> update(
            @PathVariable Long id,
            @Validated({ValidationGroups.Update.class, Default.class}) @RequestBody ExampleDTO dto) {
        exampleService.update(id, dto);
        return ResultUtilSimpleImpl.success(null);
    }
}
```

**约束**：
- **MUST** Controller 用 `@Validated({...Group.class, Default.class})` 显式指定分组，包含 `Default.class` 保证无 groups 的注解仍生效。
- **MUST** 不要用 `@Valid` 替代 `@Validated` 在 Controller 参数上 —— `@Valid` 不支持分组。
- **SHOULD** ID 字段在 Add 时不校验、Update 时 `@NotNull`。

## 4. 级联验证（嵌套对象）

```java
@Data
@Schema(description = "订单DTO")
public class OrderDTO {

    @NotNull(message = "订单ID不能为空")
    private Long orderId;

    @NotBlank(message = "客户名称不能为空")
    private String customerName;

    @Valid  // 开启级联验证
    @NotNull(message = "收货地址不能为空")
    private AddressDTO address;

    @Valid  // 集合内每个元素都校验
    private List<OrderItemDTO> items;
}
```

## 5. 自定义验证注解（以 `@EnumValue` 为例）

### 5.1 注解定义

```java
package cn.structured.example.common.valid;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;
import java.lang.annotation.*;

@Documented
@Target({ElementType.FIELD, ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = EnumValueValidator.class)
public @interface EnumValue {

    String message() default "值不在允许的范围内";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};

    Class<? extends Enum<?>> value();

    boolean ignoreCase() default false;
}
```

### 5.2 验证器实现

```java
package cn.structured.example.common.valid;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

public class EnumValueValidator implements ConstraintValidator<EnumValue, Object> {

    private List<Object> enumValues;
    private boolean ignoreCase;

    @Override
    public void initialize(EnumValue annotation) {
        this.ignoreCase = annotation.ignoreCase();
        this.enumValues = Arrays.stream(annotation.value().getEnumConstants())
                .collect(Collectors.toList());
    }

    @Override
    public boolean isValid(Object value, ConstraintValidatorContext context) {
        if (value == null) {
            return true;  // null 由 @NotNull 负责
        }
        if (value instanceof String && ignoreCase) {
            return enumValues.stream()
                    .anyMatch(e -> e.toString().equalsIgnoreCase((String) value));
        }
        return enumValues.contains(value);
    }
}
```

### 5.3 DTO 使用

```java
@Data
public class ExampleDTO {

    @NotNull(message = "状态不能为空")
    @EnumValue(value = StatusEnum.class, message = "状态只能是启用或禁用")
    private Integer status;
}
```

**约束**：
- **MUST** 自定义验证注解放在 `common/valid/` 包下。
- **SHOULD** `isValid` 对 `null` 返回 `true`，把"必填"留给 `@NotNull`（职责分离）。
- **SHOULD** 通用验证注解（如 `@EnumValue`）考虑贡献到 `structure-common`，而非各业务重复定义。

## 6. 全局异常处理（生态统一模式）

**MUST** 业务服务通过 `@RestControllerAdvice` 统一处理验证异常与业务异常：

```java
package cn.structured.example.interfaces.config;

import cn.structure.common.entity.ResResultVO;
import cn.structure.common.exception.CommonException;
import cn.structure.common.utils.ResultUtilSimpleImpl;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.bind.MethodArgumentNotValidException;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResResultVO<Void> handleValidException(MethodArgumentNotValidException e) {
        String message = e.getBindingResult().getFieldError().getDefaultMessage();
        return ResultUtilSimpleImpl.fail("400", message);
    }

    @ExceptionHandler(CommonException.class)
    public ResResultVO<Void> handleCommonException(CommonException e) {
        return ResultUtilSimpleImpl.fail(e.getCode(), e.getMessage());
    }
}
```

**约束**：
- **MUST** `GlobalExceptionHandler` 放在 `interfaces/config/` 或 `interfaces/advice/` 包。
- **MUST** 验证失败返回统一响应 `ResResultVO<Void>` + HTTP 400 或业务错误码，**禁止**返回堆栈或裸 500。
- **SHOULD** 业务项目 **不重复定义** 此 Handler —— 检查 `structure-restful-web-starter` 是否已提供，若已提供则业务侧无需再写。

## 7. 业务异常抛出（与 developer.md 对齐）

```java
// ✅ 推荐：枚举 + CommonException
throw new CommonException(
        ExampleExceptionEnum.EXAMPLE_CODE_DUPLICATE.getCode(),
        ExampleExceptionEnum.EXAMPLE_CODE_DUPLICATE.getMessage());

// ❌ 禁止：字面量
throw new CommonException("100002", "编码重复");
```

## 8. 提交前自检

- [ ] DTO 字段是否都有合适的验证注解（`@NotBlank` / `@Size` / `@Pattern` 等）？
- [ ] Controller 参数是否用 `@Validated({...Group.class, Default.class})` 指定分组？
- [ ] 嵌套对象是否加 `@Valid` 开启级联？
- [ ] 是否避免了 `javax.validation.*`（应使用 `jakarta.validation.*`）？
- [ ] 自定义验证注解是否放在 `common/valid/`？
- [ ] 全局异常处理是否统一返回 `ResResultVO`？
