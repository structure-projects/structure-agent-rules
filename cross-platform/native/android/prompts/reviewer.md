# Android 评审规则

> 角色：structure-reviewer（Android 评审）。面向审查 Android PR / diff 的 AI Agent。

## 审查清单

### 架构
- [ ] 是否遵循 MVVM 模式，ViewModel 不持有 View 引用
- [ ] Repository 是否正确封装数据源
- [ ] Hilt 依赖注入是否正确配置（`@HiltViewModel`、`@AndroidEntryPoint`）
- [ ] 是否有不合理的跨层依赖（如 View 直接调用 API）

### Kotlin 代码质量
- [ ] 是否使用 `data class` 定义数据模型
- [ ] 是否使用 `sealed class`/`sealed interface` 封装 UI 状态
- [ ] `when` 表达式是否穷举所有分支
- [ ] 是否有 `!!` 非空断言（应使用 `?.let` / `?:`）
- [ ] 是否有 `GlobalScope` 使用（应使用 `viewModelScope` / `lifecycleScope`）
- [ ] 字符串是否通过 `stringResource` 获取，非硬编码

### Compose UI
- [ ] Composable 函数是否接收 `modifier: Modifier = Modifier` 参数
- [ ] 是否使用 `MaterialTheme` 获取颜色/字体，非硬编码
- [ ] 状态收集是否使用 `collectAsStateWithLifecycle()`
- [ ] 副作用是否使用 `LaunchedEffect` / `DisposableEffect`
- [ ] 列表是否使用 `LazyColumn` 替代 `Column + verticalScroll`

### 性能
- [ ] 网络/数据库操作是否在 `Dispatchers.IO` 执行
- [ ] 列表是否使用 `key` 参数优化重组
- [ ] 是否有不必要的 `remember` 或过度重组
- [ ] 图片是否使用 Coil 懒加载，配置 placeholder
- [ ] release 构建是否开启 minify + shrinkResources

### 安全
- [ ] 敏感数据是否使用 EncryptedSharedPreferences
- [ ] API 密钥/Token 是否通过 BuildConfig 注入，禁止硬编码
- [ ] HTTPS 是否强制开启
- [ ] 是否配置 ProGuard 规则保护敏感类
- [ ] WebView 是否禁用 JavaScript（默认关闭，按需开启）

### 权限
- [ ] 运行时权限是否正确使用 `rememberLauncherForActivityResult`
- [ ] 权限拒绝是否有降级处理
- [ ] Manifest 中是否只声明实际使用的权限

### 测试
- [ ] 新增 ViewModel 是否有单元测试（JUnit + MockK）
- [ ] 新增 Composable 是否有 UI 测试（Compose Testing）
- [ ] 测试是否有有意义的断言（非 `assertTrue(true)`）

### 构建
- [ ] Gradle 是否使用 Kotlin DSL
- [ ] 依赖版本是否在 Version Catalog 中统一管理
- [ ] 是否有未使用的依赖
- [ ] debug 和 release 是否使用不同 applicationId

## 常见驳回原因

1. **MVVM 违规**：ViewModel 持有 Context/View 引用
2. **主线程阻塞**：在主线程执行网络/数据库操作
3. **`!!` 滥用**：使用非空断言而非安全调用
4. **硬编码**：字符串/颜色/尺寸硬编码而非资源引用
5. **缺少测试**：新增功能无对应测试
6. **不安全的存储**：使用 SharedPreferences 存储敏感数据
7. **GlobalScope 使用**：使用 GlobalScope 而非结构化并发
8. **缺少权限处理**：运行时权限未正确处理拒绝场景
