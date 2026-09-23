import java.io.FileInputStream
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing comes from android/key.properties, which is git-ignored —
// see android/key.properties.example for the template. Deliberately NOT
// falling back to the debug signingConfig here: a release build with an
// unconfigured "release" signingConfig fails at sign time with a clear
// Gradle error instead of silently shipping under the public debug key.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Pentest V-14 evidence noted that the shipped APK's manifest declares the
// OAuth-redirect App Link host for all three environments (dev/uat/prod) at
// once, since this app has no Gradle product flavors and every environment
// ships from the same manifest. Rather than introduce flavors, read the same
// APP_ENV value the Dart side already resolves from --dart-define /
// --dart-define-from-file=.env: Flutter forwards every dart-define to Gradle
// as the "dart-defines" project property (comma-separated, each entry
// individually base64-encoded — see flutter_tools' encodeDartDefines) purely
// so its own tasks can thread them through to the Dart compiler, but nothing
// stops a project's own build.gradle.kts from reading the same property.
// That means this needs no new build flag: `flutter build apk
// --dart-define-from-file=.env --dart-define=APP_ENV=uat`, exactly as
// documented in the README already, is enough for AndroidManifest.xml's
// single ${oauthRedirectHost} placeholder below to resolve to only that
// environment's host — the other two never appear in the built APK.
fun resolveOauthRedirectHost(project: Project): String {
    val dartDefines =
        project.findProperty("dart-defines")?.toString().orEmpty()
            .split(",")
            .filter { it.isNotEmpty() }
            .associate {
                val decoded = String(Base64.getDecoder().decode(it), Charsets.UTF_8)
                val separatorIndex = decoded.indexOf('=')
                decoded.substring(0, separatorIndex) to decoded.substring(separatorIndex + 1)
            }
    return when (dartDefines["APP_ENV"]) {
        "prod" -> "chequetracker-api.sobhaapps.com"
        "uat" -> "chqtrk-api-uat.sobhaapps.com"
        else -> "chqtrk-api-dev.sobhaapps.com" // matches AppEnvironment.name's own "dev" default
    }
}

android {
    namespace = "com.sobha.chequetracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.sobha.chequetracker"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // flutter_appauth's redirect-URI receiver activity — must match
        // AzureAdConfig.redirectUri's scheme (com.sobha.chequetracker://...)
        // and the platform registered on the Entra ID app registration.
        manifestPlaceholders["appAuthRedirectScheme"] = "com.sobha.chequetracker"
        // Pentest V-14 — see resolveOauthRedirectHost() above.
        manifestPlaceholders["oauthRedirectHost"] = resolveOauthRedirectHost(project)
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
