# iOS 原生开发规则

> 角色：structure-developer（iOS）。面向开发 iOS 原生应用的 AI Agent。
> 本规则自包含，不依赖其他技术栈目录。IDE 包装文件使用 `ios-` 前缀。

## 硬约束

- **MUST** 主语言：Swift 5.9+
- **MUST** UI 框架：SwiftUI（iOS 16+），UIKit 仅用于互操作
- **MUST** 架构：MVVM（`@Observable` class 或 `ObservableObject`）
- **MUST** 异步：Swift Concurrency（`async/await`、`Task`、`Actor`）
- **MUST** 数据库：Core Data / SwiftData（iOS 17+）+ Keychain
- **MUST** 网络：URLSession async/await API
- **MUST** 依赖管理：Swift Package Manager（SPM）
- **MUST** 代码风格：SwiftLint（`swiftlint --strict`）

## 关键优先级

- **框架**：SwiftUI > UIKit（仅互操作场景）
- **数据**：SwiftData > Core Data（新项目），Keychain > UserDefaults（敏感数据）
- **网络**：URLSession > Alamofire
- **异步**：async/await > Combine > GCD
- **导航**：NavigationStack > NavigationView

## 命名规范

- **MUST** 类型名 PascalCase（`UserProfileView`、`UserRepository`）
- **MUST** 变量/函数名 camelCase（`userName`、`fetchUsers()`）
- **MUST** 常量 camelCase（`maxRetryCount`）
- **MUST** Protocol 名以名词或 -able/-ible 结尾（`UserRepository`、`Codable`）
- **MUST** Extension 文件命名 `{Type}+{Feature}.swift`
- **SHOULD** 布尔变量以 `is`/`has`/`should` 开头

## 文件组织

```
MyApp/
├── App/
│   ├── MyAppApp.swift           # @main App 入口
│   └── AppDelegate.swift        # AppDelegate（如需要）
├── UI/
│   ├── Screens/
│   │   ├── Home/
│   │   │   ├── HomeView.swift
│   │   │   └── HomeViewModel.swift
│   │   └── Detail/
│   │       ├── DetailView.swift
│   │       └── DetailViewModel.swift
│   ├── Components/
│   │   ├── UserAvatar.swift
│   │   └── LoadingIndicator.swift
│   └── Theme/
│       ├── Colors.swift
│       └── Fonts.swift
├── Domain/
│   ├── Models/
│   │   └── User.swift
│   └── Repositories/
│       └── UserRepository.swift       # Protocol
├── Data/
│   ├── Local/
│   │   └── CoreData/
│   │       └── UserEntity+CoreData.swift
│   ├── Remote/
│   │   ├── APIService.swift
│   │   └── DTOs/
│   └── Repositories/
│       └── UserRepositoryImpl.swift
└── Core/
    ├── Networking/
    │   └── Endpoint.swift
    ├── Storage/
    │   └── KeychainManager.swift
    └── Extensions/
        └── View+Extensions.swift
```

## 编码规范

### Swift 风格

```swift
// ✅ 正确：struct 用于数据模型
struct User: Identifiable, Codable {
    let id: Int
    let name: String
    let email: String
}

// ✅ 正确：enum 封装 UI 状态
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(String)
}

// ✅ 正确：@MainActor ViewModel
@MainActor
@Observable
final class UserViewModel {
    private let repository: UserRepository
    var state: LoadingState<[User]> = .idle
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func loadUsers() async {
        state = .loading
        do {
            let users = try await repository.getUsers()
            state = .loaded(users)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
```

- **MUST** 数据模型使用 `struct` + `Codable` + `Identifiable`
- **MUST** UI 状态使用 `enum` 封装（`.idle`、`.loading`、`.loaded`、`.error`）
- **MUST** ViewModel 标记 `@MainActor` 确保 UI 更新在主线程
- **MUST** ViewModel 通过构造函数注入 Repository

### SwiftUI 规范

```swift
struct UserRow: View {
    let user: User
    var onTap: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: user.avatarURL)) { phase in
                switch phase {
                case .success(let image): image.resizable().scaledToFill()
                case .failure: Image(systemName: "person.circle.fill")
                default: ProgressView()
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(user.name).font(.headline)
                Text(user.email).font(.subheadline).foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }
}
```

- **MUST** View 使用 `struct` 遵循 `View` 协议
- **MUST** 回调使用可选闭包（`var onTap: (() -> Void)?`）
- **MUST** 异步图片使用 `AsyncImage`，处理 loading/error
- **MUST** 点击区域使用 `.contentShape(Rectangle())` + `.onTapGesture`

## 权限处理

- **MUST** 在 `Info.plist` 中声明权限用途描述（`NSCameraUsageDescription` 等）
- **MUST** 运行时使用系统权限 API 请求授权
- **MUST** 权限拒绝时提供合理的降级体验

## 测试工作流

- **MUST** 每开发一个功能立即写单元测试（XCTest）
- **MUST** 功能修改时同步修改测试并通过
- **MUST** UI 测试使用 XCUITest
- **MUST** 提交前 `xcodebuild test` + `swiftlint --strict` 全部通过
- **禁止** 测试/Lint 失败仍提交

## 禁止事项

- **禁止** 在主线程执行网络请求（使用 `async/await`）
- **禁止** 在 ViewModel 中持有 View 引用
- **禁止** 使用 `try!` / `as!` 强制解包（使用 `try?` / `as?` + `guard let`）
- **禁止** 使用 `UserDefaults` 存储敏感数据（使用 Keychain）
- **禁止** 在 View 中直接调用异步网络请求（通过 ViewModel）
- **禁止** 使用 CocoaPods / Carthage（统一 SPM）
- **禁止** 在 View 的 `body` 中进行复杂计算
