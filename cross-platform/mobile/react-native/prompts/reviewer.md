# React Native 评审规则

> 角色：structure-reviewer（React Native 评审）。面向审查 React Native PR / diff 的 AI Agent。

## 审查清单

### 架构
- [ ] 业务逻辑是否在 Custom Hook 中，UI 组件保持纯净
- [ ] API 调用是否封装在 Service 层，不直接在组件中调用
- [ ] 全局状态（Zustand）与服务端状态（TanStack Query）是否正确分离
- [ ] 是否有不必要的 prop drilling（应使用 Store 或 Context）

### TypeScript
- [ ] 是否使用 TypeScript strict 模式
- [ ] Props 是否有完整的 interface 声明
- [ ] 导航参数是否有类型定义
- [ ] 是否有 `any` 类型使用（应使用具体类型或 `unknown`）

### 导航
- [ ] 是否使用 `createNativeStackNavigator`（非 `createStackNavigator`）
- [ ] 导航参数是否类型安全
- [ ] `NavigationContainer` 是否在根组件中

### 性能
- [ ] 列表是否使用 `FlatList`（非 `ScrollView` + `map`）
- [ ] `FlatList` 是否配置 `keyExtractor`
- [ ] 回调是否使用 `useCallback` 包裹
- [ ] 复杂计算是否使用 `useMemo`
- [ ] 图片是否使用 `FastImage` 加载
- [ ] 动画是否使用 `react-native-reanimated`

### 样式
- [ ] 是否使用 `StyleSheet.create()` 定义样式
- [ ] 无内联样式对象在 JSX 中
- [ ] 颜色/间距是否使用主题变量（非硬编码）

### 平台适配
- [ ] 平台差异是否使用 `Platform.select()` 或 `.ios.tsx` / `.android.tsx`
- [ ] 是否有未处理的平台特定行为

### 安全
- [ ] 敏感数据是否存储在 `expo-secure-store` 或 `react-native-keychain`
- [ ] API 密钥是否通过环境变量注入
- [ ] 是否配置 SSL Pinning（生产环境）

### 测试
- [ ] 新增组件是否有 RNTL 测试
- [ ] 新增 Hook 是否有单元测试
- [ ] 测试是否有有意义的断言

### 构建
- [ ] Hermes 是否启用（生产构建）
- [ ] `babel.config.js` 是否配置 `react-native-reanimated/plugin`
- [ ] `GestureHandlerRootView` 是否包裹根组件
- [ ] EAS Build 配置是否正确

## 常见驳回原因

1. **直接调用 API**：组件中直接使用 axios，应封装在 Hook 中
2. **使用 JS Stack Navigator**：应用 `createNativeStackNavigator`
3. **缺少类型定义**：Props/导航参数无 TypeScript 类型
4. **使用 `any`**：TypeScript strict 模式下的 `any` 使用
5. **大列表用 ScrollView**：应用 `FlatList` / `SectionList`
6. **内联样式**：JSX 中使用内联样式对象
7. **敏感数据存 AsyncStorage**：应用 SecureStore 或 Keychain
8. **缺少测试**：新增功能无对应测试
9. **Reanimated plugin 缺失**：babel 配置中未添加 plugin
10. **未包裹 GestureHandlerRootView**
