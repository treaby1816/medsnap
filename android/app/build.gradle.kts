// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
}

// --- DECLARATIVE ENGINE CLASSPATH MAPPING ---
// Reads Flutter SDK path from local.properties using pure Kotlin (no java.util imports).
// Then reads the engine version hash and maps the engine onto the classpath directly.
val flutterSdkPath: String? = run {
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.readLines()
            .firstOrNull { it.startsWith("flutter.sdk=") }
            ?.substringAfter("=")
            ?.trim()
    } else null
} ?: System.getenv("FLUTTER_ROOT") ?: System.getenv("FLUTTER_SDK")

val engineVersion: String? = if (flutterSdkPath != null) {
    val versionFile = file("$flutterSdkPath/bin/internal/engine.version")
    if (versionFile.exists()) "1.0.0-${versionFile.readText().trim()}" else null
} else null

// Add local engine Maven repo directly to :app project
if (flutterSdkPath != null) {
    repositories {
        maven {
            url = uri("$flutterSdkPath/bin/cache/artifacts/engine")
            content {
                includeGroup("io.flutter")
            }
        }
    }
}

android {
    namespace = "com.vailmeds.v2"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.vailmeds.v2"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}

dependencies {
    // --- CORE LIBRARY DESUGARING ---
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    // --- DECLARATIVE ENGINE INJECTION (per build type) ---
    if (engineVersion != null) {
        add("debugImplementation", "io.flutter:flutter_embedding_debug:$engineVersion")
        add("releaseImplementation", "io.flutter:flutter_embedding_release:$engineVersion")
        add("profileImplementation", "io.flutter:flutter_embedding_profile:$engineVersion")
    }

    // --- MODERN FIREBASE BoM ---
    implementation(platform("com.google.firebase:firebase-bom:34.11.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")

    // --- STABILIZED ANDROIDX & KOTLIN ---
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.1.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
}