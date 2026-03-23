// android/app/build.gradle.kts

repositories {
    // Keep your custom mirrors for faster downloads in your region
    maven { url = uri("https://maven.aliyun.com/repository/public") }
    maven { url = uri("https://maven.aliyun.com/repository/google") }
    google()
    mavenCentral() // FIXED: This must be 'mavenCentral()' in Kotlin DSL
    maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
}

plugins {
    id("com.android.application")
    // This connects your app to the google-services.json file
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
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

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = "21"
    }
}

flutter {
    source = "../.."
}

dependencies {
    // --- FIREBASE 2026 CONFIGURATION ---
    implementation(platform("com.google.firebase:firebase-bom:34.11.0"))
    implementation("com.google.firebase:firebase-analytics")

    // --- KOTLIN & ANDROIDX ---
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.1.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.appcompat:appcompat:1.7.0")

    // --- YOUR CUSTOM ENGINE FIX ---
    implementation(files("D:/flutter/bin/cache/artifacts/engine/android-arm64/flutter.jar"))

    // --- PLUGIN RESOLUTION FIX ---
    implementation(fileTree(mapOf("dir" to "../../build/host/outputs/repo", "include" to listOf("*.jar"))))
}