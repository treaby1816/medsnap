pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localPropertiesFile = file("local.properties")
        if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { properties.load(it) }
            properties.getProperty("flutter.sdk") ?: "D:/flutter"
        } else {
            "D:/flutter"
        }
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // PRIORITY: Google and MavenCentral must come first for GMS plugins
        google()
        mavenCentral()
        gradlePluginPortal()
        
        // MIRRORS: Fallback for other dependencies
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
    }
}

plugins {
    id("com.android.application") version "8.7.0" apply false
    // Using 4.4.2 is correct, but the repo priority above is what makes it "findable"
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("dev.flutter.flutter-plugin-loader") version "1.0.0" apply false
}

dependencyResolutionManagement {
    // PREFER_PROJECT is safer for Flutter projects with multiple plugin dependencies
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
        
        // Aliyun mirrors
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

rootProject.name = "vail_meds_v2"
include(":app")