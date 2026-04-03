// android/settings.gradle.kts

pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localPropertiesFile = file("local.properties")
        if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { properties.load(it) }
        }
        properties.getProperty("flutter.sdk") ?: System.getenv("FLUTTER_ROOT")
            ?: System.getenv("FLUTTER_SDK")
            ?: throw GradleException("Flutter SDK not found. Define flutter.sdk in local.properties or set FLUTTER_ROOT environment variable.")
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    // SINGLE SOURCE OF TRUTH for all plugin versions.
    // AGP 8.7.0: Resolves the deprecation warning and aligns with Gradle 8.10+
    // Kotlin 2.1.0: Aligned with Flutter 2026 Stable requirements
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
}

rootProject.name = "vail_meds_v2"
include(":app")