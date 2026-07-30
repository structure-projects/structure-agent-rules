# iOS 测试规则

> 角色：structure-tester（iOS 测试）。面向编写 iOS 测试代码的 AI Agent。

## 测试分层

| 层级 | 工具 | 覆盖范围 | 速度 |
|---|---|---|---|
| **单元测试** | XCTest | ViewModel、Repository、Service | 快 |
| **UI 测试** | XCUITest | SwiftUI View 交互 | 慢 |
| **快照测试** | Swift-Snapshot-Testing | UI 外观回归 | 中 |

## 单元测试

### ViewModel 测试

```swift
import XCTest
@testable import MyApp

final class UserViewModelTests: XCTestCase {
    private var sut: UserViewModel!
    private var mockRepository: MockUserRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockUserRepository()
        sut = UserViewModel(repository: mockRepository)
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    @MainActor
    func test_loadUsers_success() async {
        let expectedUsers = [User(id: 1, name: "张三", email: "zhang@test.com")]
        mockRepository.users = expectedUsers
        
        await sut.loadUsers()
        
        if case .loaded(let users) = sut.state {
            XCTAssertEqual(users, expectedUsers)
        } else {
            XCTFail("Expected .loaded state, got \(sut.state)")
        }
    }
    
    @MainActor
    func test_loadUsers_failure() async {
        mockRepository.error = APIError.invalidResponse
        
        await sut.loadUsers()
        
        if case .error(let message) = sut.state {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected .error state")
        }
    }
}

// Mock Repository
final class MockUserRepository: UserRepository {
    var users: [User] = []
    var error: Error?
    
    func getUsers() async throws -> [User] {
        if let error { throw error }
        return users
    }
}
```

- **MUST** 使用 `XCTest` 框架
- **MUST** 使用 Mock 对象（手动创建 Mock 类）
- **MUST** `@MainActor` 标注测试 ViewModel 的方法
- **MUST** `setUp()` / `tearDown()` 中初始化/清理 `sut`（System Under Test）
- **MUST** 使用 `XCTAssert*` 系列断言

### Repository 测试

```swift
final class UserRepositoryTests: XCTestCase {
    func test_getUsers_parsesResponse() async throws {
        // 使用 URLProtocol mock 或自定义 mock
        let repository = MockUserRepository()
        repository.users = [User(id: 1, name: "Test", email: "test@test.com")]
        
        let users = try await repository.getUsers()
        
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.name, "Test")
    }
}
```

### 异步测试

```swift
func test_asyncOperation() async throws {
    let expectation = XCTestExpectation(description: "Async operation")
    
    Task {
        // async work
        expectation.fulfill()
    }
    
    await fulfillment(of: [expectation], timeout: 5.0)
}
```

- **MUST** 异步测试使用 `async/await` 或 `XCTestExpectation`
- **MUST** 设置合理的 `timeout`（默认 5 秒）

## UI 测试（XCUITest）

```swift
final class UserListUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        app.launchArguments = ["-UITesting"]
        app.launch()
    }
    
    func test_userList_displaysUsers() {
        XCTAssertTrue(app.navigationBars["用户列表"].exists)
        XCTAssertTrue(app.staticTexts["张三"].exists)
    }
    
    func test_tapUser_navigatesToDetail() {
        app.staticTexts["张三"].tap()
        XCTAssertTrue(app.navigationBars["用户详情"].exists)
    }
}
```

- **MUST** UI 测试继承 `XCTestCase`
- **MUST** 使用 `app.launchArguments` 区分 UI 测试模式
- **MUST** 使用 `XCUIApplication().launch()` 启动 App
- **MUST** 使用 `accessibilityIdentifier` 定位元素（比 label 更稳定）

## 测试工作流

- **MUST** 每开发一个功能立即写单元测试，通过才能做下一个功能
- **MUST** 功能修改时同步修改测试并通过
- **MUST** 核心流程写 XCUITest
- **MUST** 提交前 `xcodebuild test` + `swiftlint --strict` 全部通过
- **禁止** 测试/Lint 失败仍提交

## 测试文件命名

| 类型 | 命名 | Target |
|---|---|---|
| 单元测试 | `{Target}Tests.swift` | `MyAppTests` |
| UI 测试 | `{Feature}UITests.swift` | `MyAppUITests` |

## 测试依赖

```swift
// Package.swift 或 Xcode Target 中添加
testTarget(
    name: "MyAppTests",
    dependencies: ["MyApp"]
)
```

- **MUST** 测试 Target 依赖主 Target（`@testable import`）
- **MAY** 引入 `Swift-Snapshot-Testing` 用于快照测试
