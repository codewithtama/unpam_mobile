import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.unpam.mobile.lms"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.unpam.mobile.lms"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyPropFile = rootProject.file("key.properties")
            if (keyPropFile.exists()) {
                val p = Properties().apply { load(FileInputStream(keyPropFile)) }
                keyAlias = p.getProperty("keyAlias")
                keyPassword = p.getProperty("keyPassword")
                val storeFilePath = p.getProperty("storeFile")
                storeFile = if (storeFilePath != null) file(storeFilePath) else null
                storePassword = p.getProperty("storePassword")
            } else if (file("upload-keystore.jks").exists()) {
                keyAlias = "unpam_release_key"
                keyPassword = "unpam123456"
                storeFile = file("upload-keystore.jks")
                storePassword = "unpam123456"
            }
            enableV1Signing = true
            enableV2Signing = true
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.findByName("release")
            signingConfig = if (releaseSigning?.storeFile?.exists() == true) {
                releaseSigning
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
