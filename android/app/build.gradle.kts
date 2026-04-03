// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
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
            // Setting this to true manually in Gradle often breaks Firebase in 2026.
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
    // --- DO NOT hardcode io.flutter:flutter_embedding_debug here ---
    // The dev.flutter.flutter-gradle-plugin injects the correct engine
    // artifact automatically from the local SDK Maven cache.
    // Hardcoding it with a specific hash forces Gradle to search remote repos
    // where hash-versioned artifacts don't exist — that's what caused the failure.

    // --- MODERN FIREBASE BoM ---
    implementation(platform("com.google.firebase:firebase-bom:34.11.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")

    // --- STABILIZED ANDROIDX & KOTLIN ---
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.1.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
}