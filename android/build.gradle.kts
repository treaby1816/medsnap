// android/build.gradle.kts

// --- THE AMNESIA FIX: MASTER REPOSITORY ALIGNMENT ---
// This ensures every subproject (app, plugins, Firebase) can find the internet.
allprojects {
    repositories {
        google()
        mavenCentral()
        // Essential for Flutter engine and plugin artifacts
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        
        // Optional: High-performance mirrors for builds in Nigeria/Global
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
    }
}

plugins {
    // DO NOT add 'version "..."' here. 
    // Versions are strictly managed in settings.gradle.kts.
    id("com.android.application") apply false
    id("com.android.library") apply false
    id("org.jetbrains.kotlin.android") apply false
    id("com.google.gms.google-services") apply false
    id("dev.flutter.flutter-gradle-plugin") apply false
}

rootProject.layout.buildDirectory.set(file("../build"))

subprojects {
    project.layout.buildDirectory.set(
        rootProject.layout.buildDirectory.dir(project.name)
    )
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}