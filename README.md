# structure-agent-rules

[structure-projects](https://github.com/structure-projects) 开源生态的 **多技术栈 AI 规则集合**。

不写业务代码，产出物是 AI Agent（Claude Code / Cursor / CodeBuddy / Trae / 通义灵码）可加载的规则与提示词。

## 速览

```bash
# 安装到项目
./install.sh -t ../my-erp -s structure-boot,vue3 -w cursor,codebuddy

# 列出所有可用技术栈
./install.sh --list

# 交互模式
./install.sh -i
```

## 目录结构

```
structure-agent-rules/
├── AGENTS.md                 # 总索引
├── README.md                 # 本文件
├── install.sh                # 安装脚本
├── _common/                  # 通用规则（命名/API/安全/架构/测试等 10 项）
├── backend/                  # 后端 → 按语言 → 按框架
├── frontend/                 # 前端 → 按框架
└── cross-platform/           # 跨平台 → 按平台
```

## 已完成的规则

| 技术栈 | 说明 |
|---|---|
| `backend/java/structure-boot/` | structure-projects Spring Boot 开发约束 |
| `frontend/vue3/` | Vue 3 + Element Plus + wujie 前端规范 |

## 设计原则

1. **自包含**：每个技术栈目录独立可用，不依赖 `_shared/`
2. **前缀命名**：IDE 包装文件名带技术栈前缀，组合使用时自然不冲突
3. **项目级安装**：规则安装到目标项目的 `.structure-rules/`，不全局污染
4. **可扩展**：占位目录按需补充，`install.sh` 自动发现

## 贡献

占位技术栈（标记 📋）欢迎补充。参考已有完整目录的结构创建。
