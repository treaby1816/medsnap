// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    // Use the modern Kotlin plugin ID
    id("org.jetbrains.kotlin.android") 
    id("com.google.gms.google-services")
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
    // --- UNIVERSAL ANTIGRAVITY FIX FOR CODEMAGIC & LOCAL ---
    // This dynamically finds the Flutter engine whether on Windows D: drive or Codemagic Linux servers
    val flutterSdkPath = project.findProperty("flutter.sdk")?.toString() ?: ""
    val flutterJarPath = file("$flutterSdkPath/bin/cache/artifacts/engine/android-arm64-release/flutter.jar")
    
    if (flutterJarPath.exists()) {
        implementation(files(flutterJarPath))
    } else {
        implementation(fileTree("$flutterSdkPath/bin/cache/artifacts/engine") {
            include("**/*.jar")
        })
    }

    // --- FIREBASE 2026 BoM ---
    implementation(platform("com.google.firebase:firebase-bom:34.11.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")

    // --- MODERN ANDROIDX & KOTLIN ---
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.1.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.appcompat:appcompat:1.7.0")
}