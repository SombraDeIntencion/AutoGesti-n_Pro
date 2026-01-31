import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Leer versión del pubspec.yaml directamente
val pubspecFile = rootProject.file("../pubspec.yaml")
val pubspecContent = pubspecFile.readText()
val versionMatch = Regex("version:\\s*([0-9.]+)\\+(\\d+)").find(pubspecContent)
val flutterVersionName = versionMatch?.groupValues?.get(1) ?: "1.0.0"
val flutterVersionCode = versionMatch?.groupValues?.get(2)?.toInt() ?: 1

// Cargar propiedades de firma
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.mahondev.autogestionmax"
    compileSdk = 36  // API 36 requerido por plugins
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.mahondev.autogestionmax"
        // Versioning from pubspec.yaml via Flutter plugin
        versionCode = flutterVersionCode
        versionName = flutterVersionName
        minSdk = 24
        targetSdk = 36
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Ignorar advertencias de clases faltantes de Play Core
            packaging {
                resources.excludes.add("META-INF/DEPENDENCIES")
            }
        }
        debug {
            isMinifyEnabled = false
        }
    }
}

flutter {
    source = "../.."
}
