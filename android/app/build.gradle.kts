import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val tfSigningFile = rootProject.file("key.properties")
val tfSigning = Properties()
if (tfSigningFile.exists()) { tfSigningFile.inputStream().use { tfSigning.load(it) } }

android {
    namespace = "com.example.trainforge"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.trainforge"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (tfSigningFile.exists()) {
            create("evaluationRelease") {
                storeFile = file(tfSigning.getProperty("storeFile"))
                storePassword = tfSigning.getProperty("storePassword")
                keyAlias = tfSigning.getProperty("keyAlias")
                keyPassword = tfSigning.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (tfSigningFile.exists()) { signingConfig = signingConfigs.getByName("evaluationRelease") }
        }
    }
}

flutter {
    source = "../.."
}

// Never silently sign a release with the debug certificate.
gradle.taskGraph.whenReady {
    if (allTasks.any { it.name.contains("Release") } && !tfSigningFile.exists()) {
        throw GradleException("Release requires the local signing configuration: android/key.properties")
    }
}
