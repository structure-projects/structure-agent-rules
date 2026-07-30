# React Native 组件使用规范

> 本文件描述 React Native 开发中的核心组件、导航和第三方库使用规范。
> 本规则自包含，不依赖其他技术栈目录。

## React Navigation

### Stack Navigator

```tsx
import { createNativeStackNavigator } from '@react-navigation/native-stack'
import { NavigationContainer } from '@react-navigation/native'

const Stack = createNativeStackNavigator<RootStackParamList>()

function RootNavigator() {
  return (
    <NavigationContainer>
      <Stack.Navigator
        screenOptions={{
          headerStyle: { backgroundColor: '#fff' },
          headerTintColor: '#333',
          contentStyle: { backgroundColor: '#f5f5f5' }
        }}
      >
        <Stack.Screen name="Home" component={HomeScreen} />
        <Stack.Screen
          name="Detail"
          component={DetailScreen}
          options={({ route }) => ({ title: route.params.title })}
        />
      </Stack.Navigator>
    </NavigationContainer>
  )
}
```

- **MUST** 使用 `createNativeStackNavigator`（非 `createStackNavigator`）
- **MUST** 类型安全导航参数（`NativeStackNavigator<ParamList>`）
- **MUST** `NavigationContainer` 包裹根导航器

### Tab Navigator

```tsx
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs'

const Tab = createBottomTabNavigator()

<Tab.Navigator>
  <Tab.Screen name="Home" component={HomeScreen} />
  <Tab.Screen name="Profile" component={ProfileScreen} />
</Tab.Navigator>
```

## TanStack Query（服务端状态）

```tsx
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

// 查询
function useUsers() {
  return useQuery({
    queryKey: ['users'],
    queryFn: () => apiService.getUsers(),
    staleTime: 5 * 60 * 1000 // 5 分钟缓存
  })
}

// 变更
function useCreateUser() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (data: CreateUserDTO) => apiService.createUser(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] })
    }
  })
}

// 使用
function UserList() {
  const { data: users, isLoading, error } = useUsers()
  
  if (isLoading) return <ActivityIndicator />
  if (error) return <Text>加载失败</Text>
  return <FlatList data={users} renderItem={renderUser} />
}
```

- **MUST** 服务端数据使用 TanStack Query，禁止手动管理 loading/error
- **MUST** 设置合理的 `staleTime` 避免重复请求
- **MUST** mutation 成功后 `invalidateQueries` 刷新相关数据

## Zustand（全局状态）

```tsx
import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import AsyncStorage from '@react-native-async-storage/async-storage'

interface SettingsStore {
  theme: 'light' | 'dark'
  language: string
  setTheme: (theme: 'light' | 'dark') => void
}

export const useSettingsStore = create<SettingsStore>()(
  persist(
    (set) => ({
      theme: 'light',
      language: 'zh-CN',
      setTheme: (theme) => set({ theme })
    }),
    {
      name: 'settings-storage',
      storage: createJSONStorage(() => AsyncStorage)
    }
  )
)
```

- **MUST** 持久化数据使用 `persist` middleware + AsyncStorage
- **MUST** 非持久化状态使用普通 `create`

## 样式方案

### StyleSheet（内置）

```tsx
import { StyleSheet } from 'react-native'

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    backgroundColor: '#f5f5f5'
  },
  title: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333'
  }
})
```

### NativeWind（Tailwind CSS）

```tsx
// NativeWind 方式
<View className="flex-1 p-4 bg-gray-100">
  <Text className="text-lg font-semibold text-gray-800">标题</Text>
</View>
```

- **MUST** 基础项目使用 `StyleSheet.create()`
- **MAY** 使用 NativeWind（Tailwind CSS 风格）作为替代
- **禁止** 内联样式对象（`style={{ flex: 1 }}`）在 JSX 中

## 动画

```tsx
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring
} from 'react-native-reanimated'

function AnimatedCard() {
  const scale = useSharedValue(1)
  
  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }]
  }))
  
  return (
    <Animated.View
      style={animatedStyle}
      onTouchStart={() => scale.value = withSpring(0.95)}
      onTouchEnd={() => scale.value = withSpring(1)}
    >
      <Text>卡片内容</Text>
    </Animated.View>
  )
}
```

- **MUST** 使用 `react-native-reanimated` 实现动画
- **MUST** 使用 `react-native-gesture-handler` 处理手势
- **禁止** 使用 `Animated` API（React Native 内置版，性能不如 Reanimated）

## 图片

```tsx
import FastImage from 'react-native-fast-image'

<FastImage
  style={{ width: 48, height: 48, borderRadius: 24 }}
  source={{ uri: user.avatar, priority: FastImage.priority.normal }}
  resizeMode={FastImage.resizeMode.cover}
/>
```

- **MUST** 使用 `react-native-fast-image` 加载远程图片
- **MUST** 设置 `priority` 控制加载优先级
- **MUST** 配置 `resizeMode`

## 本地存储

```tsx
import { MMKV } from 'react-native-mmkv'

export const storage = new MMKV()

// 读写
storage.set('user.name', '张三')
const name = storage.getString('user.name')
```

- **SHOULD** 使用 MMKV 替代 AsyncStorage（性能更好）
- **MUST** MMKV 用于非敏感键值对
- **MUST** 敏感数据使用 `react-native-keychain` 或 `expo-secure-store`
