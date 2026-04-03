// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.android") 
    id("com.google.gms.google-services")
}

android {
    namespace = "com.vailmeds.v2"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.vailmeds.v2"
        minSdk = 24
        targetSdk = 34
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
    // --- NUCLEAR FIX: MANUAL ENGINE INJECTION ---
    // Forces the io.flutter package onto the classpath if the plugin fails to auto-inject in CI
    implementation("io.flutter:flutter_embedding_debug:1.0.0-e672b0064972ad517558DFB0c3f5969a53d69957")

    // --- MODERN FIREBASE BoM ---
    implementation(platform("com.google.firebase:firebase-bom:34.11.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")

    // --- STABILIZED ANDROIDX & KOTLIN ---
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.0.21")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
}