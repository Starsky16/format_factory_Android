plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // 包名（应用唯一标识；如需上架应用商店，建议改为你自己域名的反写，如 com.yourname.xxx）
    namespace = "com.formatfactory.app"
    // 编译 SDK：跟随 Flutter 当前支持的最新版（Android 16 / API 36）
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // 包名（与上方 namespace 保持一致）
        applicationId = "com.formatfactory.app"
        // 最低支持 Android 7.0 (API 24)。
        // ⚠️ 不要再调低：转码引擎 ffmpeg_kit_flutter_new 的底层库要求 minSdk >= 24
        minSdk = 24
        // 目标 SDK：跟随 Flutter 当前支持的最新版（Android 16 / API 36），即"最高到最新版"
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
