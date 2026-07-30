# Django Validation Rules

> 本规则适用于 Django 项目中的数据验证。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. Model 层验证

- **MUST** 在 Django Model 中使用 `Field` 约束定义数据验证规则。
- **MUST** 使用 `validators` 参数添加自定义验证器。
- **SHOULD** 使用 `clean()` 方法实现跨字段验证。
- **SHOULD** 使用 `Meta.constraints` 定义数据库级别约束。

```python
from django.core.validators import MinLengthValidator, MaxLengthValidator, RegexValidator
from django.db import models

class User(models.Model):
    username = models.CharField(
        max_length=50,
        unique=True,
        validators=[
            MinLengthValidator(3),
            RegexValidator(r"^[a-zA-Z0-9_]+$", "仅允许字母、数字和下划线"),
        ],
    )
    email = models.EmailField(unique=True)
    age = models.PositiveSmallIntegerField(null=True, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        constraints = [
            models.CheckConstraint(
                check=models.Q(age__gte=0) & models.Q(age__lte=150),
                name="age_between_0_and_150",
            ),
        ]

    def clean(self):
        if self.username.lower() in {"admin", "root", "system"}:
            raise ValidationError({"username": "保留的用户名"})
```

## 2. DRF Serializer 验证

- **MUST** 使用 DRF Serializer 进行 API 层数据验证。
- **MUST** 使用 `Field` 参数声明约束：`min_length`、`max_length`、`required`、`allow_null`。
- **SHOULD** 使用 `validate_<field_name>()` 方法实现字段级验证。
- **SHOULD** 使用 `validate()` 方法实现跨字段验证。

```python
from rest_framework import serializers

class UserCreateSerializer(serializers.Serializer):
    username = serializers.CharField(min_length=3, max_length=50)
    email = serializers.EmailField()
    password = serializers.CharField(min_length=8, max_length=128, write_only=True)
    password_confirm = serializers.CharField(min_length=8, max_length=128, write_only=True)

    def validate_username(self, value):
        reserved = {"admin", "root", "system"}
        if value.lower() in reserved:
            raise serializers.ValidationError(f"'{value}' 是保留的用户名")
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("用户名已存在")
        return value

    def validate(self, data):
        if data["password"] != data["password_confirm"]:
            raise serializers.ValidationError({"password_confirm": "两次密码不一致"})
        return data
```

## 3. ModelSerializer 验证

- **SHOULD** 使用 `ModelSerializer` 继承 Model 层的验证规则。
- **MAY** 在 Serializer 中添加额外验证（API 特有的验证逻辑）。

```python
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "username", "email", "age", "is_active"]
        read_only_fields = ["id"]
        extra_kwargs = {
            "username": {"min_length": 3, "max_length": 50},
            "age": {"min_value": 0, "max_value": 150},
        }

    def validate_age(self, value):
        if value is not None and value < 18:
            raise serializers.ValidationError("用户必须年满 18 岁")
        return value
```

## 4. 查询参数验证

- **MUST** 使用 `django-filter` 进行查询参数验证和过滤。
- **SHOULD** 使用 `FilterSet` 声明过滤字段和验证规则。

```python
import django_filters

class UserFilter(django_filters.FilterSet):
    username = django_filters.CharFilter(lookup_expr="icontains")
    is_active = django_filters.BooleanFilter()
    date_joined_after = django_filters.DateFilter(field_name="date_joined", lookup_expr="gte")
    date_joined_before = django_filters.DateFilter(field_name="date_joined", lookup_expr="lte")

    class Meta:
        model = User
        fields = ["username", "is_active"]
```

## 5. 表单验证（Django Admin / 传统视图）

- **MUST** 使用 Django `Form` 或 `ModelForm` 进行表单验证。
- **MUST** 使用 `clean_<field_name>()` 和 `clean()` 方法。

```python
from django import forms

class UserForm(forms.ModelForm):
    password_confirm = forms.CharField(min_length=8, max_length=128)

    class Meta:
        model = User
        fields = ["username", "email", "password"]

    def clean(self):
        cleaned = super().clean()
        if cleaned.get("password") != cleaned.get("password_confirm"):
            raise forms.ValidationError("两次密码不一致")
        return cleaned
```

## 6. 自定义验证器

- **SHOULD** 将可复用的验证逻辑提取为独立的 validator 函数。
- **MAY** 使用 Django `BaseValidator` 或 DRF `Validator` 基类。

```python
from django.core.exceptions import ValidationError
from django.core.validators import BaseValidator

class PhoneNumberValidator(BaseValidator):
    def __call__(self, value):
        import re
        if not re.match(r"^\+?1?\d{9,15}$", value):
            raise ValidationError(f"无效的电话号码: {value}")
```

## 7. 验证错误处理

- **MUST** DRF 自动返回 400 Bad Request 当验证失败时。
- **SHOULD** 自定义 `exception_handler` 统一验证错误格式。

```python
from rest_framework.views import exception_handler

def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is not None and response.status_code == 400:
        response.data = {
            "code": "VALIDATION_ERROR",
            "message": "请求参数验证失败",
            "errors": response.data,
        }
    return response

REST_FRAMEWORK["EXCEPTION_HANDLER"] = "core.exceptions.custom_exception_handler"
```
