# FastAPI Code Review Rules

> 本规则适用于对 FastAPI 项目代码进行审查的 AI 审查者角色。
> 规则使用 RFC 2119 风格标注强制级别：**MUST**（必须）、**SHOULD**（推荐）、**MAY**（可选）、**禁止**。

---

## 1. 类型安全审查

- **MUST** 检查所有函数是否具有完整的类型注解（参数 + 返回值）。
- **MUST** 检查是否存在 `Any` 类型的滥用，评估是否可以用更精确的类型替代。
- **MUST** 确认 `mypy` 配置中 `strict = true`，检查是否有 `# type: ignore` 注释且是否有充分理由。
- **SHOULD** 检查 `Optional[T]` 是否可替换为 `T | None`（Python 3.10+）。

## 2. Pydantic 模型审查

- **MUST** 检查请求/响应模型是否使用 Pydantic v2 API（`model_config` 而非 `class Config`）。
- **MUST** 验证字段约束（`min_length`、`max_length`、`gt`、`lt`、`pattern`）是否合理且充分。
- **MUST** 确认 `from_attributes = True` 是否在 ORM 响应模型中设置。
- **禁止** 在 Pydantic 模型中使用 `Any` 类型字段。
- **SHOULD** 检查是否存在缺少必要 `Field(description=...)` 的公共 API 模型。

## 3. 异步正确性

- **MUST** 检查 `async def` 函数内是否存在同步阻塞调用（如 `requests.get()`、`time.sleep()`）。
- **MUST** 确认数据库操作是否使用 `await session.execute(stmt)` 而非同步方式。
- **MUST** 验证 `AsyncSession` 是否通过 `Depends(get_db)` 正确注入和管理生命周期。
- **禁止** 在异步上下文中使用 `asyncio.get_event_loop()` 创建新事件循环。

## 4. 错误处理审查

- **MUST** 检查是否使用 `HTTPException` 返回错误，而非裸字典。
- **MUST** 确认业务异常是否在 Service 层抛出、Router 层或全局处理器捕获。
- **SHOULD** 验证是否存在全局异常处理器覆盖未捕获异常。
- **禁止** 使用 `try: ... except: pass` 吞掉异常。

## 5. 安全性审查

- **MUST** 检查敏感信息（密码、密钥、Token）是否从环境变量读取，**禁止**硬编码。
- **MUST** 验证认证端点是否使用 `Depends(get_current_user)` 保护。
- **MUST** 检查 CORS 配置是否明确限制 `allow_origins`，**禁止**使用 `["*"]` 与 `allow_credentials=True` 组合。
- **SHOULD** 检查 SQL 查询是否存在注入风险（即使使用 ORM，原生 SQL 仍需参数化）。

## 6. 性能审查

- **MUST** 检查 N+1 查询问题：是否在循环中执行数据库查询。
- **SHOULD** 验证列表端点是否有分页限制（`limit` + `offset`）。
- **SHOULD** 检查是否对频繁查询结果使用了缓存。
- **MUST** 验证数据库查询是否使用了 `selectinload()` 或 `joinedload()` 预加载关联数据。

## 7. 代码组织

- **MUST** 检查路由是否按资源拆分到独立模块。
- **MUST** 验证 Service 层是否不包含 HTTP 相关代码（`Request`、`Response` 对象）。
- **SHOULD** 检查是否存在超过 200 行的函数，评估是否需要拆分。

## 8. 测试覆盖

- **MUST** 检查新增端点是否有对应的测试用例。
- **SHOULD** 验证测试是否覆盖了正常路径、异常路径和边界条件。
- **禁止** 在测试中使用真实的外部服务（数据库除外），**MUST** 使用 mock 或 TestClient。

## 9. 迁移审查

- **MUST** 检查数据库 schema 变更是否有对应的 Alembic 迁移脚本。
- **MUST** 验证迁移脚本的 `upgrade()` 和 `downgrade()` 是否都可执行。
- **禁止** 手动修改已合并的迁移脚本。
