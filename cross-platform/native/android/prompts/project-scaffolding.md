# Android 项目脚手架规则

> 面向创建 Android 原生项目的 AI Agent。

## 创建步骤

1. **MUST** 使用 Android Studio Hedgehog (2023.1.1) 或更新版本
2. **MUST** 选择 "Empty Activity" 模板（Compose）或 "Empty Views Activity"（XML）
3. **MUST** 包名遵循反向域名：`com.{company}.{app}`
4. **MUST** Minimum SDK 至少 API 26 (Android 8.0)

## Gradle 配置

### 项目级 `build.gradle.kts`

```kotlin
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.compose) apply false
    alias(libs.plugins.hilt.android) apply false
    alias(libs.plugins.ksp) apply false
}
```

### 模块级 `build.gradle.kts`

```kotlin
android {
    namespace = "com.example.app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.app"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            isDebuggable = true
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }
}
```

## Version Catalog (`libs.versions.toml`)

```toml
[versions]
agp = "8.5.0"
kotlin = "2.0.0"
compose-bom = "2024.06.00"
hilt = "2.51.1"
room = "2.6.1"
retrofit = "2.11.0"
okhttp = "4.12.0"
navigation = "2.7.7"
lifecycle = "2.8.2"
coil = "2.6.0"
junit = "4.13.2"
mockk = "1.13.11"
espresso = "3.6.1"

[libraries]
# Compose BOM
compose-bom = { group = "androidx.compose", name = "compose-bom", version.ref = "compose-bom" }
compose-ui = { group = "androidx.compose.ui", name = "ui" }
compose-material3 = { group = "androidx.compose.material3", name = "material3" }
compose-ui-tooling = { group = "androidx.compose.ui", name = "ui-tooling" }
compose-ui-tooling-preview = { group = "androidx.compose.ui", name = "ui-tooling-preview" }

# Hilt
hilt-android = { group = "com.google.dagger", name = "hilt-android", version.ref = "hilt" }
hilt-compiler = { group = "com.google.dagger", name = "hilt-android-compiler", version.ref = "hilt" }

# Room
room-runtime = { group = "androidx.room", name = "room-runtime", version.ref = "room" }
room-ktx = { group = "androidx.room", name = "room-ktx", version.ref = "room" }
room-compiler = { group = "androidx.room", name = "room-compiler", version.ref = "room" }

# Network
retrofit = { group = "com.squareup.retrofit2", name = "retrofit", version.ref = "retrofit" }
okhttp = { group = "com.squareup.okhttp3", name = "okhttp", version.ref = "okhttp" }

# Navigation
navigation-compose = { group = "androidx.navigation", name = "navigation-compose", version.ref = "navigation" }

# Lifecycle
lifecycle-viewmodel-compose = { group = "androidx.lifecycle", name = "lifecycle-viewmodel-compose", version.ref = "lifecycle" }
lifecycle-runtime-compose = { group = "androidx.lifecycle", name = "lifecycle-runtime-compose", version.ref = "lifecycle" }

# Coil
coil-compose = { group = "io.coil-kt", name = "coil-compose", version.ref = "coil" }

# Testing
junit = { group = "junit", name = "junit", version.ref = "junit" }
mockk = { group = "io.mockk", name = "mockk", version.ref = "mockk" }
espresso-core = { group = "androidx.test.espresso", name = "espresso-core", version.ref = "espresso" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
kotlin-compose = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
hilt-android = { id = "com.google.dagger.hilt.android", version.ref = "hilt" }
ksp = { id = "com.google.devtools.ksp", version = "2.0.0-1.0.21" }
```

## 检查清单

- [ ] `compileSdk` 使用最新稳定版（当前 35）
- [ ] `minSdk` >= 26
- [ ] `targetSdk` = `compileSdk`
- [ ] Gradle Kotlin DSL（`build.gradle.kts`）
- [ ] Version Catalog（`libs.versions.toml`）
- [ ] Compose compiler 通过 Kotlin 编译器插件配置
- [ ] Hilt KSP 替代 kapt（更快的编译速度）
- [ ] `proguard-rules.pro` 配置完善（release 混淆）
- [ ] debug 构建 `applicationIdSuffix = ".debug"`
- [ ] `.gitignore` 排除 `*.jks`、`google-services.json`、`local.properties`
- [ ] `Application` 类注解 `@HiltAndroidApp`
- [ ] `MainActivity` 注解 `@AndroidEntryPoint`

## AndroidManifest 配置

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:name=".App"
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:supportsRtl="true"
        android:theme="@style/Theme.MyApp">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.MyApp">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

- **MUST** `android.permission.INTERNET` 在需要网络时声明
- **MUST** `android:name=".App"` 指向 Hilt Application 类
- **MUST** `android:exported` 明确声明（Android 12+ 要求）

## 禁止事项

- **禁止** 使用 Groovy DSL（`build.gradle`），统一 Kotlin DSL
- **禁止** 使用 kapt（改用 KSP，编译更快）
- **禁止** 使用 `android:allowBackup="false"` 作为默认值（按需设置）
- **禁止** 签名密钥文件提交到 Git
- **禁止** minSdk < 26（不再支持 Android 7.x 及以下）
