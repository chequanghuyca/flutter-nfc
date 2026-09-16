import groovy.json.JsonSlurper
import java.util.Base64

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Flutter only exposes String.fromEnvironment values that are present while
// compiling Dart. Merge the ignored local env automatically so Android Studio
// and plain `flutter run` behave like `--dart-define-from-file` builds.
val luxandEnvFile = rootProject.file("../.luxand.env.json")
if (luxandEnvFile.isFile) {
    val env = JsonSlurper().parse(luxandEnvFile) as? Map<*, *> ?: emptyMap<Any, Any>()
    val decoder = Base64.getDecoder()
    val encoder = Base64.getEncoder()
    val existingDefines = providers.gradleProperty("dart-defines")
        .orNull
        .orEmpty()
        .split(',')
        .filter(String::isNotBlank)
    val existingKeys = existingDefines.mapNotNull { encoded ->
        runCatching {
            String(decoder.decode(encoded), Charsets.UTF_8).substringBefore('=')
        }.getOrNull()
    }.toSet()
    val localDefines = env.entries
        .filter { (key, value) -> key is String && value != null && key !in existingKeys }
        .map { (key, value) ->
            encoder.encodeToString("$key=$value".toByteArray(Charsets.UTF_8))
        }

    extensions.extraProperties["dart-defines"] =
        (existingDefines + localDefines).joinToString(",")
}

android {
    namespace = "com.example.nfc_ekyc_demo"
    compileSdk = flutter.compileSdkVersion
    // Match the NDK used to build the Luxand 8.3 bridge. NDK r28 emits
    // 16 KB-page-compatible ELF files by default for native dependencies.
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.nfc_ekyc_demo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // The vendored Luxand 8.3 SDK only ships production ARM binaries.
        // Let Flutter own the ABI filter for explicit split builds so a small,
        // single-architecture tester APK can be produced without conflicts.
        if (providers.gradleProperty("split-per-abi").orNull != "true") {
            ndk {
                abiFilters += listOf("armeabi-v7a", "arm64-v8a")
            }
        }
    }

    packaging {
        jniLibs {
            // This mirrors SuperApp: native libraries are extracted before
            // loading, while their ELF LOAD segments remain 16 KB aligned.
            useLegacyPackaging = true
            excludes += listOf("lib/x86/**", "lib/x86_64/**")
            pickFirsts += listOf(
                "lib/armeabi-v7a/libc++_shared.so",
                "lib/arm64-v8a/libc++_shared.so",
            )
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
