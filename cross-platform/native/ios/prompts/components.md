# iOS 组件使用规范

> 本文件描述 iOS 原生开发中的 SwiftUI 组件、系统框架与第三方库使用规范。
> 本规则自包含，不依赖其他技术栈目录。

## SwiftUI 基础组件

### 布局

```swift
// VStack / HStack / ZStack
VStack(alignment: .leading, spacing: 12) {
    Text("标题")
        .font(.headline)
    Text("副标题")
        .font(.subheadline)
        .foregroundColor(.secondary)
}

// LazyVStack（大列表）
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
}

// Grid（iOS 16+）
LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))]) {
    ForEach(items) { item in
        ItemCell(item: item)
    }
}
```

- **MUST** 列表使用 `LazyVStack` / `LazyVGrid` 而非 `VStack` + `ForEach`
- **MUST** 使用 `.padding()` / `.frame()` 控制布局，避免魔法数字
- **SHOULD** 使用 `ViewThatFits`（iOS 16+）适配不同尺寸

### 文本与图片

```swift
Text("Hello iOS")
    .font(.title)
    .foregroundColor(.primary)

AsyncImage(url: URL(string: avatarURL)) { phase in
    switch phase {
    case .empty: ProgressView()
    case .success(let image): image.resizable().scaledToFill()
    case .failure: Image(systemName: "person.circle.fill")
    @unknown default: EmptyView()
    }
}
.frame(width: 48, height: 48)
.clipShape(Circle())
```

- **MUST** 使用 `AsyncImage` 加载远程图片
- **MUST** 处理 `AsyncImage` 的 loading/error 状态
- **MUST** 使用 SF Symbols 作为系统图标

### 表单与输入

```swift
@State private var username = ""
@State private var password = ""

Form {
    Section("账户信息") {
        TextField("用户名", text: $username)
            .textContentType(.username)
            .autocapitalization(.none)
        SecureField("密码", text: $password)
            .textContentType(.password)
    }
    
    Section {
        Button("登录") { login() }
            .disabled(username.isEmpty || password.isEmpty)
    }
}
```

- **MUST** 表单使用 `Form` + `Section` 组织
- **MUST** 设置 `textContentType` 辅助自动填充
- **MUST** 按钮在条件不满足时 `.disabled()`

## 数据持久化

### Core Data

```swift
// Core Data + SwiftUI 集成
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default
    )
    private var items: FetchedResults<Item>
    
    var body: some View {
        List {
            ForEach(items) { item in
                Text(item.timestamp!, formatter: itemFormatter)
            }
            .onDelete(perform: deleteItems)
        }
    }
}
```

- **MUST** Core Data 使用 `@FetchRequest` 与 SwiftUI 集成
- **MUST** 使用 `@Environment(\.managedObjectContext)` 获取上下文
- **SHOULD** 新项目评估使用 SwiftData（`@Model` 宏）

### SwiftData（iOS 17+）

```swift
@Model
final class User {
    var name: String
    var email: String
    var createdAt: Date
    
    init(name: String, email: String) {
        self.name = name
        self.email = email
        self.createdAt = Date()
    }
}

// 使用
@Query(sort: \User.createdAt) private var users: [User]
@Environment(\.modelContext) private var modelContext
```

### Keychain

```swift
// 使用 Keychain 存储 Token
enum KeychainManager {
    static func save(key: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        SecItemCopyMatching(query as CFDictionary, &item)
        return item as? Data
    }
}
```

- **MUST** Token、密码等敏感数据使用 Keychain 存储
- **禁止** 使用 `UserDefaults` 存储敏感数据

## 网络层

### URLSession（async/await）

```swift
protocol APIService {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

actor DefaultAPIService: APIService {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = try? KeychainManager.loadToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        return try decoder.decode(T.self, from: data)
    }
}
```

- **MUST** 使用 `actor` 封装网络服务（线程安全）
- **MUST** Token 通过 Keychain 获取并自动注入 Header
- **MUST** 检查 HTTP 状态码，非 2xx 抛出错误

## 第三方库

| 库 | 用途 | 引入方式 |
|---|---|---|
| Alamofire | HTTP 网络（备选） | SPM |
| Kingfisher | 图片缓存（非 AsyncImage 场景） | SPM |
| SwiftLint | 代码风格检查 | Homebrew / SPM Plugin |

- **MUST** 优先使用系统框架，仅必要时引入第三方库
- **MUST** 第三方库通过 SPM 引入
- **禁止** 使用 CocoaPods 或 Carthage
