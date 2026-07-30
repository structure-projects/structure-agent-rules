# Vue 3 组件使用规范

> 本文件描述在 structure-projects 生态中开发 Vue 3 应用时的组件使用规范。
> 本规则自包含，不依赖其他技术栈目录。

## `@structure-projects/components` (L1 组件库)

### 使用方式

```ts
// ✅ 按需命名导入（不是 Vue 插件，无 install）
import { StructTable, StructForm, StructDialog } from '@structure-projects/components'
```

- **MUST** 按需命名导入，**不是** `app.use(Components)` 插件方式
- **MUST** element-plus 由消费项目自行注册：`app.use(ElementPlus)` + `import 'element-plus/dist/index.css'`

### 可用组件

| 组件 | 说明 | Props |
|---|---|---|
| `StructTable` | 高级表格（分页、排序、筛选、多选） | `columns`, `request`, `pagination`, `selection` |
| `StructForm` | 动态表单（schema 驱动） | `schema`, `modelValue`, `rules` |
| `StructDialog` | 弹窗封装 | `visible`, `title`, `width`, `confirm` |
| `StructSearch` | 搜索面板 | `fields`, `modelValue`, `search`, `reset` |
| `StructTree` | 树形组件 | `data`, `props`, `nodeKey` |
| `StructUpload` | 文件上传（对接 structure-file） | `action`, `limit`, `accept` |
| `StructIcon` | 图标组件 | `name`, `size`, `color` |
| `StructLoading` | 加载状态 | `loading`, `text` |

### element-plus 使用

```ts
// main.ts
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import zhCn from 'element-plus/es/locale/lang/zh-cn'

app.use(ElementPlus, { locale: zhCn })
```

- **MUST** 导入中文 locale
- **SHOULD** 用 `unplugin-vue-components` 按需导入

## `@structure-projects/gateway-client`

### 使用

```ts
import { request } from '@structure-projects/gateway-client'

// GET
const users = await request.get<ResResultVO<ResPage<UserVO>>>('/api/users', { params: req })

// POST
const result = await request.post<ResResultVO<UserVO>>('/api/users', userForm)

// PUT
await request.put<ResResultVO<void>>(`/api/users/${id}`, userForm)

// DELETE
await request.delete<ResResultVO<void>>(`/api/users/${id}`)
```

- **MUST** 所有 HTTP 请求使用 `request` 实例
- 自动附带网关 Header（Token、租户、Trace 等 7 个头）
- 错误自动提示（el-message），**无需** 手动处理

## `@structure-projects/wujie-subapp`

### 初始化

```ts
// main.ts
import { createWujieSubapp } from '@structure-projects/wujie-subapp'

const app = createWujieSubapp()
app.init()
```

- **MUST** 子应用入口唯一调用
- 自动处理 lifecycle、环境变量注入、独立路由

## 自定义组件规范（L2/L3）

### L2 领域组件（`*-ui-components`）

```vue
<!-- UserSelector.vue -->
<script setup lang="ts">
import { ref } from 'vue'
import { request } from '@structure-projects/gateway-client'

interface Props {
  modelValue?: number[]
  multiple?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  multiple: false
})

const emit = defineEmits<{
  'update:modelValue': [value: number[]]
}>()

const options = ref<UserOption[]>([])
const loadOptions = async () => {
  const res = await request.get<ResResultVO<UserOption[]>>('/api/users/options')
  options.value = res.data ?? []
}
</script>
```

- **MUST** L2 组件为业务领域组件，可调用后端 API
- **MUST** 组件在所属领域 `*-ui-components` 中维护
- **SHOULD** 使用 `file:` 协议本地开发引用

### 必传 Props

- **MUST** L2/L3 组件对外暴露的 Props 声明完整 TypeScript 类型
- **MUST** 必传 Props 不设默认值
