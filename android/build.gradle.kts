// android/build.gradle.kts

// --- REPOSITORY ALIGNMENT: LOCAL ENGINE FIRST, THEN REMOTE ---
// The Flutter SDK ships its engine as a local Maven repo inside the SDK cache.
// We read flutter.sdk from local.properties (or env vars) and add that repo
// FIRST so Gradle resolves io.flutter artifacts locally — never hitting the network.
allprojects {
    repositories {
        // 1. Local Flutter engine Maven repo (highest priority)
        //    This is populated by `flutter precache --android` and contains
        //    flutter_embedding_debug/release/profile + arm/x86 .so artifacts.
        val flutterSdkPath = run {
            val properties = java.util.Properties()
            val localPropertiesFile = rootProject.file("local.properties")
            if (localPropertiesFile.exists()) {
                localPropertiesFile.inputStream().use { properties.load(it) }
            }
            properties.getProperty("flutter.sdk")
                ?: System.getenv("FLUTTER_ROOT")
                ?: System.getenv("FLUTTER_SDK")
        }
        if (flutterSdkPath != null) {
            maven {
                url = uri("$flutterSdkPath/bin/cache/artifacts/engine")
                content {
                    includeGroup("io.flutter")
                }
            }
        }

        // 2. Standard remote repositories
        google()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        mavenCentral()

        // 3. Reliability mirrors (fallback for slow/flaky networks)
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

val rootBuildDir = file("../build")
rootProject.layout.buildDirectory.set(rootBuildDir)

subprojects {
    val projectDirStr = project.projectDir.absolutePath
    val rootDirStr = rootProject.projectDir.absolutePath
    if (projectDirStr.substring(0, 3).equals(rootDirStr.substring(0, 3), ignoreCase = true)) {
        project.layout.buildDirectory.set(rootProject.layout.buildDirectory.dir(project.name))
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}