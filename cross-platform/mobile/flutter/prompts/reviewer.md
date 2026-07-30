# Flutter 评审规则

> 角色：structure-reviewer（Flutter 评审）。面向审查 Flutter PR / diff 的 AI Agent。

## 审查清单

### 架构
- [ ] 是否遵循 Feature-first 分层架构（data/domain/presentation）
- [ ] Repository 接口是否在 domain 层，实现在 data 层
- [ ] DTO 和 Entity 是否正确分离
- [ ] Riverpod Provider 是否正确组织

### Dart 代码质量
- [ ] 数据模型是否使用 `@freezed` + `json_serializable`
- [ ] 是否使用 `const` 构造函数和常量
- [ ] `build` 方法中是否有异步操作（禁止）
- [ ] 是否有 `late` 变量未初始化
- [ ] 是否使用 `AsyncValue.guard()` 安全处理异步

### Riverpod
- [ ] 是否使用 `@riverpod` code generation
- [ ] `ConsumerWidget` / `ConsumerStatefulWidget` 使用正确
- [ ] `ref.watch()` vs `ref.read()` 使用正确
- [ ] 是否使用 `ref.invalidate()` 刷新数据
- [ ] Provider 是否有合理的 dispose 逻辑

### Widget
- [ ] 是否使用 `const` 构造函数
- [ ] 样式是否使用 `Theme.of(context)`（非硬编码）
- [ ] 间距是否使用 `SizedBox`（非 `Padding`）
- [ ] 列表是否使用 `ListView.builder`（非 `ListView(children: [...])`）
- [ ] 是否使用 `asyncValue.when()` 处理三态

### 路由
- [ ] 是否使用 GoRouter + GoRouteData 类型安全路由
- [ ] 路由守卫是否正确配置（`redirect`）
- [ ] 深层链接是否正确声明

### 性能
- [ ] `build` 方法是否轻量（无复杂计算）
- [ ] 列表是否使用 `ListView.builder`
- [ ] 图片是否使用 `CachedNetworkImage`
- [ ] 是否有不必要的 Widget 重建

### 安全
- [ ] Token/密码是否使用 `flutter_secure_storage`
- [ ] API 密钥是否通过 `--dart-define` 或 `.env` 注入
- [ ] HTTPS 是否强制

### 测试
- [ ] 新增 Repository 是否有单元测试
- [ ] 新增 Widget 是否有 Widget 测试
- [ ] 测试是否有有意义的断言

### 构建
- [ ] 生成代码是否提交（`*.g.dart`、`*.freezed.dart`）
- [ ] `analysis_options.yaml` 配置正确
- [ ] `dart format` 是否通过
- [ ] `flutter analyze` 无错误

## 常见驳回原因

1. **使用 ChangeNotifier**：旧版 Provider，应迁移到 Riverpod
2. **Navigator.push()**：使用 Navigator 1.0 API，应用 GoRouter
3. **build 中异步操作**：在 build 方法中进行网络请求
4. **硬编码样式**：颜色/字号硬编码而非 Theme 引用
5. **缺失 const**：未使用 const 构造函数
6. **无 Freezed**：数据类未使用 @freezed 注解
7. **生成代码未提交**：`*.g.dart` 未提交导致 CI 失败
8. **敏感数据存 SharedPreferences**：应用 SecureStorage
9. **ListView(children: [...])** 替代 builder 构造函数
10. **缺少测试**：新增功能无对应测试
