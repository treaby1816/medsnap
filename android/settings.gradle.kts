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
    // --- CRITICAL: flutter-plugin-loader MUST be applied (not "apply false") ---
    // This settings-level plugin reads .flutter-plugins-dependencies and
    // includes each Flutter plugin's Android code as a Gradle subproject.
    // Without this, GeneratedPluginRegistrant.java can't find any plugin classes.
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // Version declarations for project plugins (apply false = available but not applied here)
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
}

rootProject.name = "vail_meds_v2"
include(":app")