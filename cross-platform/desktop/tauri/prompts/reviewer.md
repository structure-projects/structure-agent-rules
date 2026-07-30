# Tauri 评审规则

> 角色：structure-reviewer（Tauri 评审）。面向审查 Tauri PR / diff 的 AI Agent。

## 审查清单

### 架构
- [ ] Rust 后端 + Web 前端分层清晰
- [ ] Command 层 / Service 层 / Repository 层分离
- [ ] IPC 通信是否正确（`invoke` / `emit` / `listen`）
- [ ] Rust 命令函数是否标注 `#[tauri::command]`
- [ ] 前端 IPC 调用是否封装在 Service 层（非组件直接 `invoke`）

### Rust 端（src-tauri/）
- [ ] 命令函数返回 `Result<T, E>`（非 `panic!` / `unwrap()`）
- [ ] 全局状态是否使用 `tauri::State<T>` 管理
- [ ] 错误处理是否使用 `anyhow` / `thiserror`
- [ ] 异步命令是否使用 `async` + `tokio`
- [ ] 是否有不必要的 `unwrap()` / `expect()`（生产代码）
- [ ] 输入验证是否在命令入口处完成
- [ ] `Cargo.toml` 依赖版本是否锁定（非 `*`）

### 前端
- [ ] IPC 调用是否通过 Service 封装（非组件直接 `invoke`）
- [ ] 事件监听是否正确使用 `listen()` / `once()`
- [ ] 事件监听是否在组件卸载时取消（`unlisten`）
- [ ] 状态管理方案是否与框架匹配
- [ ] 是否使用了 `@tauri-apps/api`（非 `window.__TAURI__`）

### 安全
- [ ] CSP 是否在 `tauri.conf.json` 中配置
- [ ] `capabilities` 是否最小权限原则
- [ ] 文件访问 scope 是否合理（非通配符）
- [ ] 是否禁用了 `dangerousRemoteDomainIpcAccess`
- [ ] Rust 命令是否做了输入验证和转义
- [ ] 命令中是否避免了 `eval` / `exec` 用户输入
- [ ] 敏感数据是否使用 `plugin-store` 加密存储

### 窗口管理
- [ ] 窗口配置是否在 `tauri.conf.json` 中
- [ ] 多窗口场景是否正确管理窗口生命周期
- [ ] 系统托盘是否提供"显示"/"退出"选项
- [ ] 窗口关闭事件是否正确处理

### 性能
- [ ] Rust 命令是否有不必要的阻塞操作（应使用 `async`）
- [ ] 大文件操作是否异步 + 分块
- [ ] 前端是否有不必要的重渲染
- [ ] IPC 调用频率是否合理（避免高频轮询）

### 测试
- [ ] Rust 端是否有 `#[cfg(test)]` 单元测试
- [ ] 前端 IPC Service 是否有单元测试
- [ ] 核心 IPC 流程是否有集成测试
- [ ] E2E 是否覆盖关键用户路径

### 配置
- [ ] `tauri.conf.json` 各字段是否正确
- [ ] `Cargo.toml` features 是否合理
- [ ] 前端构建输出是否与 `frontendDist` 路径一致
- [ ] `identifier` 是否使用反向域名

## 常见驳回原因

1. **命令函数 `panic!` / `unwrap()` 生产代码**：应返回 `Result::Err`
2. **组件中直接 `invoke()`**：应封装在 IPC Service 中
3. **事件监听未清理**：`useEffect` 中缺少 `unlisten`
4. **CSP 未配置**：安全风险
5. **`capabilities` 权限过大**：最小权限原则
6. **文件 scope 使用通配符**：安全风险
7. **Rust 命令未做输入验证**：安全风险
8. **使用 `window.__TAURI__`**：应使用 `@tauri-apps/api`
9. **缺少 `Cargo.lock`**：依赖锁定
10. **前端直接访问文件系统**：应通过 Tauri FS plugin
