# Spring Boot 评审规范

> 通用 Spring Boot 项目代码评审规则，适用于 PR / diff / 设计文档评审。

---

## 1. 评审流程

### 1.1 评审顺序

按以下顺序逐项检查，前一项通过再进行下一项：

1. 包名与坐标 → 2. 模块依赖方向 → 3. Bean 注入 → 4. 分层职责 → 5. 异常处理 → 6. POJO 规范 → 7. 持久化规范 → 8. 事务管理 → 9. 安全 → 10. 性能 → 11. 测试 → 12. 文档

### 1.2 反馈格式

每条反馈 MUST 包含：
- **位置**：`file:line`
- **级别**：`MUST-FIX` / `SHOULD-FIX` / `NIT` / `QUESTION`
- **依据**：引用规则条目
- **建议**：可落地的修改方案

---

## 2. 硬性驳回项（MUST-FIX）

以下情况 MUST 驳回，修复后才能合入：

### 2.1 架构违规

- [ ] Controller 包含业务逻辑
- [ ] Service 层直接操作 HttpServletRequest / HttpServletResponse
- [ ] `core` 模块依赖 `biz` 模块（反向依赖）
- [ ] `domain` 层直接注入 `Mapper` / `JpaRepository`
- [ ] 循环依赖（A → B → A）

### 2.2 注入违规

- [ ] `@Configuration` 类外用 `new` 创建 Service/Repository
- [ ] 静态字段注入 Bean
- [ ] `@Autowired` 字段注入（应使用构造器注入）

### 2.3 异常处理违规

- [ ] Service 层返回 null 表示"未找到"
- [ ] 使用 `try-catch` 吞掉异常不处理
- [ ] Controller 层手动 try-catch 业务异常（应由全局异常处理器处理）
- [ ] 异常消息暴露敏感信息（SQL 语句、密码、Token）

### 2.4 持久化违规

- [ ] SQL 拼接（防注入）
- [ ] 在循环中执行数据库操作（N+1 查询）
- [ ] Controller 层使用 `@Transactional`
- [ ] 事务方法中捕获异常不抛出（事务可能不回滚）
- [ ] 私有方法上加 `@Transactional`（AOP 不生效）

### 2.5 POJO 违规

- [ ] Entity / DTO / VO 缺少无参构造
- [ ] JPA Entity 使用 `@Data`（可能触发懒加载）
- [ ] 方法参数 > 5 个未使用包装对象

### 2.6 安全违规

- [ ] 密码明文存储或日志打印
- [ ] Token / API Key 硬编码
- [ ] 文件上传未校验类型和大小
- [ ] 敏感接口无权限校验
- [ ] 直接使用 `@RequestMapping` 未限制 HTTP 方法

### 2.7 测试违规

- [ ] 新功能无单元测试
- [ ] 修改功能未同步更新测试
- [ ] 集成测试 Mock 数据库/Redis/MQ（应用 Testcontainers 或真实中间件）
- [ ] 僵尸断言（只 `assertNotNull`，无实质验证）
- [ ] 测试/编译失败仍提交
- [ ] 无关联 issue 的 `@Disabled` 测试

### 2.8 配置与依赖违规

- [ ] 敏感信息（密码、密钥）硬编码在配置文件
- [ ] 引入未使用的依赖
- [ ] 依赖版本使用 SNAPSHOT（生产环境）

---

## 3. 建议性反馈（SHOULD-FIX）

### 3.1 代码质量

- [ ] 方法过长（> 50 行）
- [ ] 类过大（> 500 行）
- [ ] 嵌套过深（> 3 层 if/for）
- [ ] 魔法数字未定义常量
- [ ] 重复代码未抽取公共方法

### 3.2 性能

- [ ] 查询未使用索引字段
- [ ] `SELECT *` 查询全部字段（应指定需要的字段）
- [ ] 大事务（事务内包含 RPC 调用或文件 I/O）
- [ ] 频繁创建大对象（应使用对象池或缓存）

### 3.3 命名

- [ ] 命名不遵循 Java 命名规范（驼峰）
- [ ] CRUD 方法命名不统一（`list`/`page`/`queryPage` 混用）
- [ ] 变量名无意义（`a`、`b`、`temp`）

### 3.4 日志

- [ ] 使用 `System.out.println`（应用 `@Slf4j`）
- [ ] 日志级别不当（INFO 级别打印大量 DEBUG 信息）
- [ ] 异常日志未打印堆栈（`log.error(e.getMessage())` 应 `log.error("msg", e)`）

---

## 4. 可忽略项（NIT）

- 注释格式不一致（不影响理解）
- import 未按字母排序
- 空行数量不一致
- JavaDoc 缺少 `@param` / `@return`（非公开 API 时）

---

## 5. 专项检查

### 5.1 事务检查清单

- [ ] 事务边界是否正确（Service 方法粒度）
- [ ] `@Transactional` 方法是否 public
- [ ] 是否考虑了事务传播行为
- [ ] 只读操作是否使用 `readOnly = true`
- [ ] 异常是否正确触发回滚（默认 RuntimeException 和 Error）

### 5.2 并发检查清单

- [ ] 共享变量是否有线程安全问题
- [ ] 数据库更新是否考虑乐观锁/悲观锁
- [ ] Redis 操作是否考虑原子性
- [ ] 定时任务是否考虑分布式锁

### 5.3 性能检查清单

- [ ] 是否避免了 N+1 查询
- [ ] 批量操作是否使用批量接口
- [ ] 大列表是否分页
- [ ] 是否有必要的缓存

---

## 6. 评审模板

```
## Code Review: {PR标题}

### 整体评价
{简要总结本次变更的质量和主要问题}

### 问题列表

#### 1. [MUST-FIX] {问题标题}
- 位置：{file}:{line}
- 问题：{描述}
- 建议：{修改方案}

#### 2. [SHOULD-FIX] {问题标题}
- 位置：{file}:{line}
- 问题：{描述}
- 建议：{修改方案}

### 总结
- MUST-FIX: {N} 项
- SHOULD-FIX: {M} 项
- NIT: {K} 项
```
