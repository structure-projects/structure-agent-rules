# API 设计通用原则

> 通用规则，适用范围：所有技术栈和项目类型。
> 本文定义 HTTP 层面的通用 API 规范与统一响应/入参/出参结构；各技术栈在其 `developer.md` 中定义具体的实体类名和工具类。

## RESTful 设计

### URL 规范

- **MUST** 资源 URL 使用名词复数 + 层级结构：
  ```
  GET    /api/users              # 用户列表
  GET    /api/users/{id}         # 单个用户
  POST   /api/users              # 创建用户
  PUT    /api/users/{id}         # 全量更新
  PATCH  /api/users/{id}         # 部分更新
  DELETE /api/users/{id}         # 删除用户
  GET    /api/users/{id}/orders  # 用户的订单
  ```
- **MUST** 查询参数用于过滤/排序/分页，不在 URL 路径中体现。
- **SHOULD** 版本号通过请求头（`API-Version: v1`）管理，项目内统一选一种。路径前缀 `/api/v1/` 可作为替代方案（如结构较大变更时），但需项目统一。
- **禁止** URL 中使用动词（如 `/getUser`、`/createOrder`）—— 用 HTTP 方法表达操作。

### HTTP 方法与语义

| 方法 | 语义 | 幂等性 | 请求体 | 响应体 |
|------|------|:--:|:--:|:--:|
| `GET` | 查询资源 | ✅ | 无 | 单资源或列表 |
| `POST` | 创建资源 | ❌ | 新资源数据 | 创建后的资源 |
| `PUT` | 全量替换 | ✅ | 完整资源数据 | 更新后的资源 |
| `PATCH` | 部分更新 | ❌ | 变更字段 | 更新后的资源 |
| `DELETE` | 删除资源 | ✅ | 无 | 空或无内容 |

### HTTP 状态码

| 状态码 | 使用场景 |
|:------:|---------|
| `200` | GET/PUT/PATCH 成功 |
| `201` | POST 创建成功（含 `Location` 头指向新资源） |
| `204` | DELETE 成功（无响应体） |
| `400` | 请求参数校验失败 |
| `401` | 未认证（缺少或无效 Token） |
| `403` | 已认证但无权限 |
| `404` | 资源不存在 |
| `409` | 资源冲突（如唯一键重复） |
| `422` | 语义错误（参数格式正确但业务不合法） |
| `429` | 请求频率超限 |
| `500` | 服务端内部错误 |

- **禁止** 所有响应都返回 `200` 然后在 body 中区分错误码。

## 统一响应格式

### 响应体结构

所有 API 响应 MUST 使用统一的外层结构（`ResResultVO`）：

```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "成功！",
  "data": { ... },
  "timestamp": 1753914123456
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `success` | `boolean` | 业务操作是否成功。`true` 表示成功，`false` 表示失败 |
| `code` | `string` | 业务状态码。**字符串类型**，具备更强的编码灵活性。成功为 `"SUCCESS"`，失败使用 `{服务前缀}_{序号}` 编码（如 `"U-001"`、`"ORG_001"`、`"O-002"`） |
| `message` | `string` | 面向用户的提示信息。成功为 `"成功！"`，失败为可读的业务错误描述 |
| `data` | `object` / `array` / `null` | 响应数据。单资源为对象，列表为数组，操作无返回数据时为 `null` |
| `timestamp` | `number` | 响应时间戳（毫秒），用于调试和性能追踪 |

### code 码编码规范

- **MUST** `code` 使用 **字符串** 类型（非 int），按 `{服务前缀}_{序号}` 格式编码。
- **MUST** 成功统一用 `"SUCCESS"`。
- **MUST** 业务异常由 `{X}ExceptionEnum` 枚举管理，**禁止**使用字符串字面量直接写 code。

**code 编码示例**：

| 服务/领域 | 前缀 | 错误码示例 | 含义 |
|-----------|:--:|-----------|------|
| 通用 | — | `"SUCCESS"` | 成功 |
| 用户 (user) | `U` | `"U-001"` | 用户不存在 |
| 组织 (org) | `ORG` | `"ORG_001"` | 部门不存在 |
| 订单 (order) | `O` | `"O-002"` | 订单已取消不可修改 |
| 支付 (payment) | `P` | `"P-001"` | 余额不足 |
| 资源 (resource) | `R` | `"R-003"` | 角色已被用户引用不可删除 |
| 认证 | `AUTH` | `"AUTH_001"` | Token 已过期 |

- **SHOULD** 分隔符在项目内统一（`-` 或 `_`），不混用。
- **SHOULD** 错误码具有唯一性，一个 code 对应一个明确的业务语义。
- **SHOULD** 同类错误按序号递增分配，便于记忆和排查。

### 成功响应示例

```json
// 单资源
{
  "success": true,
  "code": "SUCCESS",
  "message": "成功！",
  "data": { "id": 10001, "username": "zhangsan", "email": "zhangsan@example.com" },
  "timestamp": 1753914123456
}

// 列表
{
  "success": true,
  "code": "SUCCESS",
  "message": "成功！",
  "data": [
    { "id": 10001, "username": "zhangsan" },
    { "id": 10002, "username": "lisi" }
  ],
  "timestamp": 1753914123456
}

// 无数据返回（删除等操作）
{
  "success": true,
  "code": "SUCCESS",
  "message": "成功！",
  "data": null,
  "timestamp": 1753914123456
}
```

### 错误响应示例

```json
{
  "success": false,
  "code": "U-001",
  "message": "用户不存在",
  "data": null,
  "timestamp": 1753914123456
}
```

- **MUST** 错误信息面向 API 调用方，不含内部敏感信息（如 SQL 语句、堆栈跟踪）。
- **禁止** 在 `message` 中暴露内部实现细节。

### 追踪信息规范

- **MUST** 每个响应携带 `timestamp`（毫秒时间戳），用于请求时间定位和性能追踪。
- **SHOULD** 分布式系统额外增加 `traceId` 字段（UUID 或雪花 ID），由网关/首层服务注入，下游服务透传（读取 Header 或上下文），用于全链路日志关联与问题排查。
- **SHOULD** 所有业务日志携带 `traceId`，便于搜索排查。

## API 出入参

### 三族对象

- **MUST** API 出入参使用 **DTO / VO / Query** 三族对象，遵循 **CQRS** 方法论：
  - 写操作入参：`{X}DTO`（或 `{X}Command`）
  - 读操作入参：`{X}Query`
  - 出参：`{X}VO`
- **MUST** Controller 返回 `ResResultVO<T>`（包在统一响应体中），**禁止**返回裸的 VO。
- **禁止** API 返回裸数据类型（如直接返回 `String`、`Map`、`List`）。

### Controller 方法签名

```java
// 标准 CRUD
ResResultVO<XxxVO> create(@RequestBody @Valid XxxDTO dto);
ResResultVO<XxxVO> update(@PathVariable Long id, @RequestBody @Valid XxxDTO dto);
ResResultVO<XxxVO> delete(@PathVariable Long id);
ResResultVO<XxxVO> findById(@PathVariable Long id);
```

```java
// 构造响应
return ResultUtilSimpleImpl.success(vo);                       // 成功：success=true, code="SUCCESS", message="成功！"
return ResultUtilSimpleImpl.fail("U-001", "用户不存在");        // 失败：success=false
```

- **MUST** 函数命名**见名知意**，相同功能**命名必须统一**：
  - 分页一律 `page(...)`，不一处 `list`、一处 `page`、一处 `queryPage`
  - CRUD 使用固定标准：`create` / `update` / `delete` / `findById` / `page`

## 分页入参与出参

### 分页入参 — `ReqPage`

- **MUST** 分页接口签名为双参数：`page(XxxQuery query, ReqPage reqPage)`。
- **MUST** `ReqPage` 为框架统一分页请求对象，包含以下字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `page` | `int` | 当前页码（从 1 开始，默认 1） |
| `size` | `int` | 每页条数（默认 10） |
| `keyword` | `string` | 模糊搜索关键字（可选） |
| `beginTime` | `string` | 查询起始时间，格式 `yyyy-MM-dd HH:mm:ss`（可选） |
| `endTime` | `string` | 查询截止时间，格式 `yyyy-MM-dd HH:mm:ss`（可选） |

- **SHOULD** 默认 `size` 为 10，最大不超过 100。
- **禁止** 自定义分页包装类替代 `ReqPage`。

### 分页出参 — `ResPage<T>`

- **MUST** 分页接口返回 `ResPage<T>`（包裹在 `ResResultVO.data` 中）。

```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "成功！",
  "data": {
    "current": 1,
    "size": 10,
    "pages": 15,
    "total": 150,
    "records": [ ... ]
  },
  "timestamp": 1753914123456
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `current` | `number` | 当前页码 |
| `size` | `number` | 每页条数 |
| `pages` | `number` | 总页数 |
| `total` | `number` | 总记录数 |
| `records` | `array<T>` | 当前页数据列表 |

- **MUST** 分页响应提供 `total`（总记录数）和 `pages`（总页数），供前端计算页码。
- **SHOULD** 空页时 `records` 为空数组 `[]`（非 `null`），`total` 和 `pages` 为 `0`。

## API 文档

- **MUST** 每个 API 必须有文档，包含：URL、方法、请求参数、响应示例、错误码。
- **SHOULD** 使用 OpenAPI 3.0+（Swagger / springdoc）自动生成文档。
- **SHOULD** 文档随代码一起版本化管理，发布时同步更新。

## 版本兼容

- **MUST** 向后兼容：新增字段不破坏旧客户端，删除/重命名字段需要新版本号。
- **SHOULD** 废弃字段先标记 `@deprecated`，至少保留一个版本后再删除。
- **SHOULD** 重大变更（Breaking Change）发布新的大版本（`v1` → `v2`）。

## 安全相关

- **MUST** 所有 API 默认需要认证（白名单除外，如登录/注册/健康检查）。
- **MUST** 敏感数据（密码、Token）不在 URL 中传递——用 POST body 或 Header。
- **MUST** 所有 API 通过 HTTPS 提供服务（生产环境 TLS 1.2+）。
- **SHOULD** CORS 配置白名单，禁止 `Access-Control-Allow-Origin: *` 用于需凭证的接口。

## 禁止事项

- **禁止** API 返回裸数据类型（如直接返回 `String`、`Map`、`List`）—— 必须包裹在 `ResResultVO` 中。
- **禁止** 在 URL 中暴露内部实现细节（如 `/api/getUserById`、`/api/updateOrderStatus`）。
- **禁止** GET 请求修改资源状态。
- **禁止** 响应体中返回数据库错误信息给客户端。
- **禁止** 生产环境使用 `TRACE` / `OPTIONS` 之外的未文档化 HTTP 方法。
- **禁止** 所有响应都返回 HTTP `200` 再在 body 中区分错误码—— HTTP 状态码和业务 code 各有职责。
- **禁止** 在 Controller 中 `try-catch` + 手动构造错误响应——用全局异常处理器。
