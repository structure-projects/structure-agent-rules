# spring-boot 技术栈规则

> 通用 Spring Boot 项目开发规范。适用场景：任何标准 Spring Boot 项目。

## 规则文件

| 文件 | 说明 |
|---|---|
| [developer.md](prompts/developer.md) | 开发约束 |
| [architect.md](prompts/architect.md) | 架构与设计 |
| [reviewer.md](prompts/reviewer.md) | 代码评审 |
| [tester.md](prompts/tester.md) | 测试规范 |
| [components.md](prompts/components.md) | 组件用法 |
| [project-scaffolding.md](prompts/project-scaffolding.md) | 项目搭建 |
| [swagger.md](prompts/swagger.md) | API 文档 |
| [validation.md](prompts/validation.md) | 参数校验 |
| [ci-cd.md](prompts/ci-cd.md) | 持续集成 |

## 快速约束

- Spring Boot 3.x + JDK 17+，`jakarta.*`
- 构造器注入优先，POJO 必须无参构造
- Controller 无业务逻辑，Service 接口与实现分离
- 统一异常处理 + 统一响应体 `Result<T>`
- `@FeignClient` 服务间调用，必须 `fallback`
- 提交前 `mvn clean test` 全部通过
