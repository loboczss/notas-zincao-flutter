import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasKeystoreProperties = keystorePropertiesFile.exists()
if (hasKeystoreProperties) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

val keystorePathFromProps = keystoreProperties["storeFile"] as String?
val keystoreFile = if (!keystorePathFromProps.isNullOrBlank()) {
    val configured = file(keystorePathFromProps)
    if (configured.exists()) {
        configured
    } else {
        // Backward compatible fallback for projects that keep the keystore in android/app.
        file("app/$keystorePathFromProps")
    }
} else {
    null
}

android {
    namespace = "cloud.loboczss.notaszincao"
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
        applicationId = "cloud.loboczss.notaszincao"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasKeystoreProperties) {
            create("release") {
                if (keystoreFile == null || !keystoreFile.exists()) {
                    throw GradleException("Keystore de release nao encontrado. Verifique storeFile em android/key.properties")
                }
                storeFile = keystoreFile
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            // Keep the same signature as release to allow in-place updates during internal tests.
            if (hasKeystoreProperties) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
        release {
            signingConfig = if (hasKeystoreProperties) {
                signingConfigs.getByName("release")
            } else {
                throw GradleException("android/key.properties ausente. Release deve ser gerado com assinatura de release.")
            }
            packaging {
                jniLibs {
                    keepDebugSymbols += setOf("**/*.so")
                }
            }
        }
    }
}

flutter {
    source = "../.."
}
