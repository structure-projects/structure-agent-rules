# iOS 评审规则

> 角色：structure-reviewer（iOS 评审）。面向审查 iOS PR / diff 的 AI Agent。

## 审查清单

### 架构
- [ ] 是否遵循 MVVM 模式，ViewModel 不持有 View 引用
- [ ] Repository 是否正确封装数据源
- [ ] 依赖是否通过构造函数注入
- [ ] ViewModel 是否标注 `@MainActor`

### Swift 代码质量
- [ ] 数据模型是否使用 `struct` + `Codable` + `Identifiable`
- [ ] UI 状态是否使用 `enum` 封装（`.idle`/`.loading`/`.loaded`/`.error`）
- [ ] 是否有 `try!` / `as!` 强制解包（应使用 `try?` / `as?` + `guard let`）
- [ ] 字符串是否通过 `NSLocalizedString` 或 String Catalog 本地化
- [ ] 是否使用 `@MainActor` 保护 UI 更新

### SwiftUI
- [ ] 列表是否使用 `LazyVStack` / `List` + `ForEach`
- [ ] 异步图片是否使用 `AsyncImage`，处理 loading/error
- [ ] 导航是否使用 `NavigationStack`（非 `NavigationView`）
- [ ] 是否使用 `.contentShape(Rectangle())` 扩大点击区域

### 性能
- [ ] 网络请求是否使用 `async/await`（非主线程阻塞）
- [ ] 图片是否使用 `AsyncImage` / Kingfisher 缓存
- [ ] View `body` 中是否有复杂计算（应提取到 ViewModel）
- [ ] 是否有不必要的 `@StateObject` 重建

### 安全
- [ ] 敏感数据是否存储在 Keychain（非 `UserDefaults`）
- [ ] API 密钥是否通过 `.xcconfig` / `Info.plist` 注入
- [ ] App Transport Security（ATS）是否保持默认（HTTPS 强制）
- [ ] Keychain 是否使用 `SecAccessControl` 限制访问

### 依赖管理
- [ ] 所有依赖是否通过 SPM 引入
- [ ] 是否引入不必要的第三方库（能用系统框架解决的不用第三方）
- [ ] 版本约束是否合理（使用 `from:` 而非 `exact:`）

### 测试
- [ ] 新增 ViewModel 是否有 XCTest 单元测试
- [ ] 新增 View 是否有 XCUITest
- [ ] 测试是否有有意义的断言

### 配置
- [ ] Deployment Target >= iOS 16.0
- [ ] SwiftLint 配置完善，`--strict` 无警告
- [ ] Info.plist 权限描述完整
- [ ] `.xcconfig` 区分 Debug/Release

## 常见驳回原因

1. **MVVM 违规**：ViewModel 持有 View 引用
2. **强制解包**：使用 `try!` / `as!` 而非安全处理
3. **敏感数据泄露**：Token/密码存储在 `UserDefaults`
4. **使用废弃 API**：`NavigationView`、旧版 `async` 方式
5. **缺少权限描述**：Info.plist 未声明用途
6. **引入 CocoaPods**：使用 CocoaPods/Carthage 而非 SPM
7. **主线程阻塞**：在 View 中直接调用网络请求
8. **缺少测试**：新增功能无对应测试
