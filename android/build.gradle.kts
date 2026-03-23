// android/build.gradle.kts

// 1. We only define the Google Services plugin here. 
// We DON'T define com.android.application or library here because 
// Flutter handles those automatically in the background.
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}

// 2. Your 2026 Lazy Properties logic
rootProject.layout.buildDirectory.set(file("../build"))

subprojects {
    project.layout.buildDirectory.set(
        rootProject.layout.buildDirectory.dir(project.name)
    )
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Modern Clean Task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}