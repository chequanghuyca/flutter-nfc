import com.android.build.api.dsl.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    afterEvaluate {
        if (plugins.hasPlugin("com.android.library")) {
            extensions.configure<LibraryExtension> {
                // Older ML Kit plugins set compileSdk 29 inside their own
                // build script, so apply the compatibility value afterwards.
                compileSdk = 36
            }
        }
    }

    configurations.configureEach {
        resolutionStrategy {
            // 16.0.1 is the same 16 KB-compatible OCR artifact selected by
            // SuperApp instead of the plugin's older 16.0.0 transitive pin.
            force("com.google.mlkit:text-recognition:16.0.1")
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
