// android/app/build.gradle.kts

repositories {
    // Custom mirrors for faster downloads in Nigeria
    maven { url = uri("https://maven.aliyun.com/repository/public") }
    maven { url = uri("https://maven.aliyun.com/repository/google") }
    google()
    mavenCentral() 
    maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
}

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // Use the modern Kotlin plugin ID
    id("org.jetbrains.kotlin.android") 
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
        
        // Let Flutter handle the ABI splits via command line
    }

    buildTypes {
        getByName("release") {
            // High-performance optimization for production
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
    // --- FIREBASE 2026 BoM ---
    implementation(platform("com.google.firebase:firebase-bom:34.11.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")

    // --- MODERN ANDROIDX & KOTLIN ---
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.1.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.appcompat:appcompat:1.7.0")

    // --- PLUGIN RESOLUTION ---
    // Standard Flutter plugin resolution logic
    implementation(fileTree(mapOf("dir" to "../../build/host/outputs/repo", "include" to listOf("*.jar"))))
}