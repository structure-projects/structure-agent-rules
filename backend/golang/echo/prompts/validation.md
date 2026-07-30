# Echo 数据校验规则

> 适用场景：Echo 项目的请求参数校验、DTO 校验、业务校验。

## 硬约束

- **MUST** 使用 `go-playground/validator` 作为校验器。
- **MUST** 通过 Echo 的 `e.Validator` 接口注册自定义校验器。
- **MUST** 所有入参 DTO 使用 `validate` 标签。
- **禁止** 在 handler 中手写逐字段校验。

## 注册校验器到 Echo

```go
import "github.com/go-playground/validator/v10"

type CustomValidator struct {
    validator *validator.Validate
}

func NewValidator() *CustomValidator {
    v := validator.New()
    // 注册自定义校验
    v.RegisterValidation("phone", validatePhone)
    return &CustomValidator{validator: v}
}

func (cv *CustomValidator) Validate(i interface{}) error {
    if err := cv.validator.Struct(i); err != nil {
        return echo.NewHTTPError(http.StatusBadRequest, formatValidationError(err))
    }
    return nil
}

// 注册到 Echo
e.Validator = NewValidator()
```

## Handler 中使用

```go
type CreateUserReq struct {
    Username string `json:"username" validate:"required,min=3,max=32"`
    Email    string `json:"email" validate:"required,email"`
    Password string `json:"password" validate:"required,min=8"`
    Role     string `json:"role" validate:"required,oneof=admin user guest"`
}

func (h *UserHandler) Create(c echo.Context) error {
    var req CreateUserReq
    if err := c.Bind(&req); err != nil {
        return err  // 绑定失败
    }
    if err := c.Validate(req); err != nil {
        return err  // 校验失败（会触发 HTTPErrorHandler）
    }
    // 调用 service
}
```

## 常用校验标签

| 标签 | 说明 | 示例 |
|---|---|---|
| `required` | 必填 | `validate:"required"` |
| `min=n` / `max=n` | 最小/最大长度或值 | `validate:"min=3,max=32"` |
| `len=n` | 精确长度 | `validate:"len=11"` |
| `email` | 邮箱格式 | `validate:"email"` |
| `url` | URL 格式 | `validate:"url"` |
| `gte=n` / `lte=n` | 大于等于/小于等于 | `validate:"gte=0,lte=150"` |
| `oneof=a b c` | 枚举值 | `validate:"oneof=admin user"` |
| `omitempty` | 空值时跳过 | `validate:"omitempty,email"` |
| `dive` | 校验切片元素 | `validate:"required,dive,min=1"` |

## 自定义校验器

```go
func validatePhone(fl validator.FieldLevel) bool {
    phone := fl.Field().String()
    matched, _ := regexp.MatchString(`^1[3-9]\d{9}$`, phone)
    return matched
}

// 注册
v.RegisterValidation("phone", validatePhone)

// 使用
type Req struct {
    Phone string `json:"phone" validate:"required,phone"`
}
```

## 校验错误格式化

```go
type ValidationError struct {
    Field   string `json:"field"`
    Message string `json:"message"`
}

func formatValidationError(err error) []ValidationError {
    var errors []ValidationError
    if ve, ok := err.(validator.ValidationErrors); ok {
        for _, fe := range ve {
            errors = append(errors, ValidationError{
                Field:   fe.Field(),
                Message: getErrorMessage(fe),
            })
        }
    }
    return errors
}

func getErrorMessage(fe validator.FieldError) string {
    switch fe.Tag() {
    case "required": return "此字段为必填项"
    case "min": return fmt.Sprintf("最小长度为 %s", fe.Param())
    case "max": return fmt.Sprintf("最大长度为 %s", fe.Param())
    case "email": return "邮箱格式不正确"
    default: return fmt.Sprintf("校验失败: %s", fe.Tag())
    }
}
```

## 自定义 Binder + 校验

```go
type ValidatingBinder struct{}

func (vb *ValidatingBinder) Bind(i interface{}, c echo.Context) error {
    db := new(echo.DefaultBinder)
    if err := db.Bind(i, c); err != nil {
        return err
    }
    // 绑定后自动校验
    if v, ok := i.(interface{ Validate() error }); ok {
        return v.Validate()
    }
    return nil
}

e.Binder = &ValidatingBinder{}
```

## 业务校验（Service 层）

```go
func (s *userServiceImpl) Create(ctx context.Context, req *CreateUserReq) (*model.User, error) {
    exists, _ := s.userRepo.ExistsByEmail(ctx, req.Email)
    if exists {
        return nil, NewAppError(40901, "邮箱已被注册", http.StatusConflict)
    }
    // 创建用户
}
```

## 禁止事项

- **禁止** 仅在前端做校验（后端 MUST 独立校验）。
- **禁止** 在 handler 中手写 `if` 逐字段校验。
- **禁止** 返回原始校验错误给前端。
- **禁止** 依赖 Echo 默认的绑定错误信息。
