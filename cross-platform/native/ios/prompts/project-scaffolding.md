# iOS 项目脚手架规则

> 面向创建 iOS 原生项目的 AI Agent。

## 创建步骤

1. **MUST** 使用 Xcode 16+ 创建项目
2. **MUST** 选择 "App" 模板，Interface 选择 "SwiftUI"，Language 选择 "Swift"
3. **MUST** 最低部署目标 iOS 16.0（推荐 17.0 以使用 SwiftData 等新特性）
4. **MUST** 组织标识符遵循反向域名：`com.{company}.{app}`

## 项目配置

### Deployment Target

- **MUST** `iOS Deployment Target` >= 16.0
- **SHOULD** 新项目使用 iOS 17.0 以利用 SwiftData、`@Observable` 等新特性

### Info.plist 关键配置

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
</dict>
<key>NSCameraUsageDescription</key>
<string>需要使用相机来扫描二维码</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册来选择头像</string>
```

- **MUST** 所有需要权限的功能在 Info.plist 中声明用途描述
- **MUST** `UIApplicationSceneManifest` 按需配置多场景支持

### Swift Package Manager 依赖

```swift
// Package.swift 或 Xcode > File > Add Package Dependencies
dependencies: [
    .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.9.0"),
    .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.12.0"),
    .package(url: "https://github.com/realm/SwiftLint.git", from: "0.55.0"),
]
```

- **MUST** 依赖管理使用 SPM
- **MUST** 版本约束使用 `from:` 指定最低版本
- **禁止** 使用 CocoaPods / Carthage

## 环境配置

### .xcconfig 文件

```
// Debug.xcconfig
API_BASE_URL = https:/$()/api-dev.example.com
BUNDLE_ID_SUFFIX = .debug

// Release.xcconfig
API_BASE_URL = https:/$()/api.example.com
BUNDLE_ID_SUFFIX = 
```

- **SHOULD** 使用 `.xcconfig` 区分 Debug/Release 环境
- **MUST** API 地址通过 Build Settings 注入，**禁止** 硬编码

### 环境变量读取

```swift
enum Environment {
    static let apiBaseURL: String = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String else {
            fatalError("API_BASE_URL not set in Info.plist")
        }
        return url
    }()
}
```

## 项目结构

```
MyApp/
├── MyApp.xcodeproj/
├── MyApp/                          # 主 Target
│   ├── App/
│   │   ├── MyAppApp.swift          # @main 入口
│   │   └── AppDelegate.swift       # 可选
│   ├── UI/
│   │   ├── Screens/                # 页面
│   │   ├── Components/             # 可复用组件
│   │   └── Theme/                  # 颜色/字体
│   ├── Domain/
│   │   ├── Models/
│   │   └── Repositories/
│   ├── Data/
│   │   ├── Local/
│   │   ├── Remote/
│   │   └── Repositories/
│   ├── Core/
│   │   ├── Networking/
│   │   ├── Storage/
│   │   └── Extensions/
│   └── Resources/
│       ├── Assets.xcassets/
│       └── Info.plist
├── MyAppTests/                     # 单元测试
├── MyAppUITests/                   # UI 测试
├── Config/
│   ├── Debug.xcconfig
│   └── Release.xcconfig
├── .swiftlint.yml
└── .gitignore
```

## 检查清单

- [ ] Deployment Target >= iOS 16.0
- [ ] SwiftUI 为 Interface 选项
- [ ] SPM 管理所有依赖
- [ ] `.swiftlint.yml` 配置并提交
- [ ] `.xcconfig` 区分 Debug/Release 环境
- [ ] `Info.plist` 权限描述完整
- [ ] `.gitignore` 排除 `DerivedData/`、`.xcworkspace/xcuserdata/`
- [ ] SwiftLint Build Phase 集成（或 SPM Plugin）
- [ ] 代码签名配置为自动管理（个人开发）或 Fastlane Match（团队）
- [ ] Scheme 共享（`MyApp.xcodeproj/xcshareddata/`）

## App 入口

```swift
import SwiftUI

@main
struct MyAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

- **MUST** 使用 `@main` + `App` 协议定义入口
- **MUST** `WindowGroup` 作为根 Scene
- **MAY** 在 `App` 的 `init()` 中初始化全局依赖

## 禁止事项

- **禁止** Deployment Target < iOS 16.0（新项目）
- **禁止** 使用 UIKit App Delegate 生命周期（除非必要）
- **禁止** 使用 Storyboard 构建 UI（新项目统一 SwiftUI）
- **禁止** 使用 CocoaPods / Carthage
- **禁止** 硬编码 API 地址和密钥
- **禁止** 将 `.xcconfig` 中的敏感信息提交到 Git
