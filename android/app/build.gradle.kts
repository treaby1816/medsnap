// android/app/build.gradle.kts

import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
}

// --- DECLARATIVE ENGINE CLASSPATH MAPPING ---
// The Flutter Gradle plugin SHOULD inject io.flutter:flutter_embedding automatically,
// but in CI environments it can fail silently. This block reads the engine version hash
// from the SDK and maps the engine directly onto the compile + runtime classpath.
val flutterSdkPath: String? = run {
    val properties = java.util.Properties()
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { properties.load(it) }
    }
    properties.getProperty("flutter.sdk")
        ?: System.getenv("FLUTTER_ROOT")
        ?: System.getenv("FLUTTER_SDK")
}

val engineVersion: String? = if (flutterSdkPath != null) {
    val versionFile = file("$flutterSdkPath/bin/internal/engine.version")
    if (versionFile.exists()) "1.0.0-${versionFile.readText().trim()}" else null
} else null

// Add local engine Maven repo directly to :app project
// This is where `flutter precache --android` stores the engine JARs/POMs.
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
    compileSdk = 35

    defaultConfig {
        applicationId = "com.vailmeds.v2"
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        getByName("release") {
            // Let Flutter CLI handle minification and obfuscation.
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
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
    // --- DECLARATIVE ENGINE INJECTION (per build type) ---
    // Maps the local Flutter SDK engine directly onto the classpath.
    // The version is read from <flutter_sdk>/bin/internal/engine.version
    // and the JAR is resolved from <flutter_sdk>/bin/cache/artifacts/engine/.
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