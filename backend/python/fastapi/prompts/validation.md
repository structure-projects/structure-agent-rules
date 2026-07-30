# FastAPI Validation Rules

> 本规则适用于 FastAPI 项目中的数据验证。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. Pydantic 模型验证

- **MUST** 所有 API 入参使用 Pydantic v2 模型进行验证。
- **MUST** 使用 `Field()` 声明约束：`min_length`、`max_length`、`gt`、`ge`、`lt`、`le`、`pattern`。
- **SHOULD** 使用 `model_config` 控制验证行为。

```python
from pydantic import BaseModel, Field, model_validator
from typing import Self

class UserCreateRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: str = Field(..., pattern=r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$")
    password: str = Field(..., min_length=8, max_length=128)
    password_confirm: str = Field(..., min_length=8, max_length=128)

    @model_validator(mode="after")
    def passwords_match(self) -> Self:
        if self.password != self.password_confirm:
            raise ValueError("passwords do not match")
        return self
```

## 2. 字段级验证器

- **MUST** 使用 `@field_validator` 实现字段级自定义验证逻辑。
- **SHOULD** 验证器方法使用 `@classmethod` 装饰，参数名使用 `v`（Pydantic 约定）。
- **MAY** 使用 `mode="before"` 在类型转换前进行验证。

```python
from pydantic import BaseModel, Field, field_validator

class ProductCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    price: float = Field(..., gt=0)
    stock: int = Field(..., ge=0)
    sku: str = Field(..., pattern=r"^[A-Z]{2,4}-\d{4,8}$")

    @field_validator("name")
    @classmethod
    def name_must_be_trimmed(cls, v: str) -> str:
        trimmed = v.strip()
        if not trimmed:
            raise ValueError("name must not be empty or whitespace only")
        return trimmed

    @field_validator("price")
    @classmethod
    def price_precision(cls, v: float) -> float:
        return round(v, 2)

    @field_validator("stock")
    @classmethod
    def stock_must_be_reasonable(cls, v: int) -> int:
        if v > 1_000_000:
            raise ValueError("stock exceeds maximum allowed (1,000,000)")
        return v
```

## 3. 模型级验证器

- **SHOULD** 使用 `@model_validator(mode="after")` 进行跨字段验证。
- **MAY** 使用 `@model_validator(mode="before")` 在模型初始化前进行预处理。

```python
from pydantic import BaseModel, model_validator
from typing import Self
from datetime import date

class DateRangeQuery(BaseModel):
    start_date: date
    end_date: date

    @model_validator(mode="after")
    def validate_date_range(self) -> Self:
        if self.start_date > self.end_date:
            raise ValueError("start_date must be before or equal to end_date")
        if (self.end_date - self.start_date).days > 365:
            raise ValueError("date range must not exceed 365 days")
        return self
```

## 4. 自定义类型验证

- **MAY** 使用 `Annotated` + `BeforeValidator` / `AfterValidator` 创建可复用的验证类型。
- **SHOULD** 将通用验证逻辑提取为可复用的验证函数。

```python
from typing import Annotated
from pydantic import BeforeValidator
from pydantic.functional_validators import AfterValidator
import re

def validate_phone(v: str) -> str:
    pattern = r"^\+?1?\d{9,15}$"
    if not re.match(pattern, v):
        raise ValueError(f"invalid phone number: {v}")
    return v

def normalize_email(v: str) -> str:
    return v.strip().lower()

PhoneNumber = Annotated[str, BeforeValidator(str.strip), AfterValidator(validate_phone)]
NormalizedEmail = Annotated[str, AfterValidator(normalize_email)]

class ContactInfo(BaseModel):
    phone: PhoneNumber
    email: NormalizedEmail
```

## 5. 查询参数验证

- **MUST** 查询参数使用 FastAPI `Query()` 声明约束。
- **SHOULD** 分页参数提取为可复用的 `Depends` 依赖。

```python
from fastapi import Query

@router.get("/users/")
async def list_users(
    page: int = Query(1, ge=1, description="页码"),
    size: int = Query(20, ge=1, le=100, description="每页数量"),
    username: str | None = Query(None, min_length=1, max_length=50, description="用户名搜索"),
    is_active: bool | None = Query(None, description="按激活状态过滤"),
):
    ...
```

## 6. 路径参数验证

- **MUST** 路径参数使用类型注解 + `Path()` 进行约束。

```python
from fastapi import Path

@router.get("/users/{user_id}")
async def get_user(
    user_id: int = Path(..., ge=1, description="用户 ID"),
):
    ...
```

## 7. 请求体验证

- **MUST** 请求体使用 Pydantic 模型，FastAPI 自动验证。
- **SHOULD** 使用 `Body(embed=True)` 当需要将单个参数包装为 JSON 对象时。

## 8. 响应验证

- **SHOULD** 使用 `response_model` 过滤返回字段。
- **MUST** 确保响应模型不包含敏感字段（`password_hash`、`secret_key` 等）。
- **MAY** 使用 `response_model_include` / `response_model_exclude` 动态控制返回字段。

## 9. 验证错误处理

- **MUST** FastAPI 自动返回 422 Unprocessable Entity 当验证失败时。
- **SHOULD** 自定义 `RequestValidationError` 处理器统一验证错误格式。

```python
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request, exc: RequestValidationError):
    errors = []
    for error in exc.errors():
        errors.append({
            "field": ".".join(str(loc) for loc in error["loc"]),
            "message": error["msg"],
            "type": error["type"],
        })
    return JSONResponse(status_code=422, content={"detail": errors})
```
