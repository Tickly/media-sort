import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.media_sort"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.media_sort"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile")!!)
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }
}

afterEvaluate {
    // AGP 8+ 的公开 Variant API 不再稳定暴露 outputFileName，这里用 assemble 后重命名方式，兼容本地与 CI。
    // Flutter 默认输出：<buildDir>/outputs/flutter-apk/app-<buildType>.apk
    tasks.matching { it.name == "assembleRelease" }.configureEach {
        doLast {
            val baseName = (rootProject.name ?: "app").replace("\\s+".toRegex(), "_")
            val versionName = android.defaultConfig.versionName ?: "0.0.0"
            val outDir = layout.buildDirectory.dir("outputs/flutter-apk").get().asFile

            val from = java.io.File(outDir, "app-release.apk")
            if (!from.exists()) return@doLast

            val to = java.io.File(outDir, "${baseName}_v${versionName}-release.apk")
            from.copyTo(to, overwrite = true)
        }
    }
}

flutter {
    source = "../.."
}
