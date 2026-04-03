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
    // This is the ONLY place in the entire project where versions are defined.
    // Senior-Level Stabilization: AGP 8.5.2 and Kotlin 2.0.21 for high-reliability CI
    id("com.android.application") version "8.5.2" apply false
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
}

rootProject.name = "vail_meds_v2"
include(":app")