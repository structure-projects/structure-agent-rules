# iOS 原生架构规则

> 角色：structure-architect（移动端架构）。面向需要做 iOS 架构选型与技术决策的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。IDE 包装文件使用 `ios-` 前缀。

## 架构模式

### MVVM + Combine / async/await

- **MUST** 采用 MVVM 架构，ViewModel 为 `@Observable` class（iOS 17+）或 `ObservableObject`
- **MUST** Service/Repository 层封装数据源（本地 Core Data + 远程 API），对 ViewModel 暴露统一接口
- **MUST** ViewModel 不持有 View 引用，使用 `@Published` 或 Combine Publisher 暴露状态
- **SHOULD** 使用 UseCase 层封装复杂业务逻辑（可选，简单 CRUD 可省略）

```
Sources/
├── App/                   # App 入口、AppDelegate、SceneDelegate
├── UI/
│   ├── Screens/           # SwiftUI View 页面
│   ├── Components/        # 可复用 SwiftUI View
│   └── Theme/             # 颜色、字体、样式常量
├── Domain/
│   ├── Models/            # 领域实体（struct/enum）
│   ├── Repositories/      # Repository 协议
│   └── UseCases/          # 业务用例（可选）
├── Data/
│   ├── Local/             # Core Data / SwiftData 模型
│   ├── Remote/            # API Service、DTO
│   └── Repositories/      # Repository 实现
└── Core/
    ├── Networking/        # URLSession 配置
    ├── Storage/           # Keychain 封装
    └── Extensions/        # Foundation/SwiftUI 扩展
```

### 依赖注入

- **SHOULD** 使用 Swift Package Manager 中的 DI 方案（Factory、Resolver）或手动注入
- **MAY** 使用 `@Environment` / `@EnvironmentObject` 传递全局依赖
- **MUST** 通过构造函数注入依赖，避免隐式单例

## UI 架构

### SwiftUI（推荐）

- **MUST** 新项目使用 SwiftUI 构建 UI
- **MUST** 使用 `@State` 管理 View 内部状态，`@StateObject` / `@ObservedObject` 管理外部对象
- **MUST** 使用 `NavigationStack`（iOS 16+）替代 `NavigationView`
- **MUST** 使用 `@Environment(\.dismiss)` 进行返回操作
- **SHOULD** 复杂列表使用 `List` + `ForEach`，确保 `id` 稳定

### UIKit 互操作

- **MUST** 使用 `UIViewRepresentable` / `UIViewControllerRepresentable` 包装 UIKit 组件
- **MAY** 使用 `UIHostingController` 在 UIKit 中嵌入 SwiftUI

## 导航

- **MUST** 使用 `NavigationStack` + `NavigationLink`（或 `navigationDestination`）进行页面导航
- **MUST** iPad 使用 `NavigationSplitView` 实现侧边栏导航
- **MUST** 使用 `.sheet()` / `.fullScreenCover()` 展示模态页面
- **SHOULD** Tab 导航使用 `TabView` + `tabItem`

```swift
NavigationStack {
    List(users) { user in
        NavigationLink(user.name, value: user)
    }
    .navigationDestination(for: User.self) { user in
        UserDetailView(user: user)
    }
}
```

## 数据持久化

- **MUST** 复杂数据模型使用 Core Data 或 SwiftData（iOS 17+）
- **MUST** 简单键值对使用 `@AppStorage` 或 `UserDefaults`
- **MUST** 敏感数据（Token、密码）使用 Keychain
- **MAY** SwiftData 用于新项目（模型类用 `@Model` 宏注解）

## 网络层

- **MUST** 使用 `URLSession` 的 async/await API（`async let` / `try await`）
- **MAY** 使用 Alamofire 作为备选（需要更丰富的拦截器功能时）
- **MUST** 网络请求通过 Repository 封装，不在 View 直接调用
- **MUST** 使用 `Codable` 进行 JSON 解析

```swift
protocol UserRepository {
    func getUsers(page: Int) async throws -> [User]
}

actor RemoteUserRepository: UserRepository {
    func getUsers(page: Int) async throws -> [User] {
        let url = URL(string: "https://api.example.com/users?page=\(page)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([User].self, from: data)
    }
}
```

## 异步处理

- **MUST** 使用 Swift Concurrency（`async/await`、`Task`、`Actor`）
- **MUST** 使用 `Task { @MainActor in }` 在主线程更新 UI
- **MUST** `Actor` 用于保护可变状态（替代锁）
- **MUST** 使用 `TaskGroup` / `async let` 并发多个请求
- **SHOULD** 使用 `@MainActor` 注解 ViewModel，确保 UI 更新在主线程

## 项目配置

- **MUST** 使用 Xcode 管理项目（`.xcodeproj` / `.xcworkspace`）
- **MUST** 依赖管理使用 Swift Package Manager（SPM）
- **MUST** 设置合理的 deployment target（iOS 16+ 推荐）
- **MUST** 配置 `.xcconfig` 文件区分 Debug/Release 环境

## 安全

- **MUST** 敏感数据存储使用 Keychain（非 UserDefaults）
- **MUST** API 密钥通过 `.xcconfig` 或 Info.plist 注入，**禁止** 硬编码
- **MUST** App Transport Security（ATS）默认开启，HTTPS 强制
- **SHOULD** 使用 `SecAccessControl` 限制 Keychain 项的可访问性
- **SHOULD** 使用 DeviceCheck 验证设备完整性
