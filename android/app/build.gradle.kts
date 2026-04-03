// android/app/build.gradle.kts

repositories {
    // Keep your custom mirrors for faster downloads in your region
    maven { url = uri("https://maven.aliyun.com/repository/public") }
    maven { url = uri("https://maven.aliyun.com/repository/google") }
    google()
    mavenCentral() 
    maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
}

plugins {
    id("com.android.application")
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
        
        // REMOVED: ndk { abiFilters ... } 
        // Flutter's --split-per-abi command handles this automatically now.
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
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
    implementation("com.google.firebase:firebase-auth")

    // --- KOTLIN & ANDROIDX ---
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.1.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.appcompat:appcompat:1.7.0")

    // --- ENGINE & PLUGIN RESOLUTION ---
    implementation(files("D:/flutter/bin/cache/artifacts/engine/android-arm64/flutter.jar"))
    implementation(fileTree(mapOf("dir" to "../../build/host/outputs/repo", "include" to listOf("*.jar"))))
}