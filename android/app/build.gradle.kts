import java.util.Base64
import java.util.Properties

val defaultAdmobAndroidAppId = "ca-app-pub-3940256099942544~3347511713"

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun dartDefinesMap(): Map<String, String> {
    val dartDefines = project.findProperty("dart-defines") as String? ?: return emptyMap()

    return dartDefines
        .split(",")
        .filter { it.isNotBlank() }
        .mapNotNull { encodedValue ->
            val decodedValue = String(Base64.getDecoder().decode(encodedValue))
            val separatorIndex = decodedValue.indexOf('=')
            if (separatorIndex == -1) {
                null
            } else {
                decodedValue.substring(0, separatorIndex) to
                    decodedValue.substring(separatorIndex + 1)
            }
        }
        .toMap()
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists().also { exists ->
    if (exists) {
        keystorePropertiesFile.inputStream().use(keystoreProperties::load)
    }
}

android {
    namespace = "com.pablosanchez.trulybudget"
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
        applicationId = "com.pablosanchez.trulybudget"
        minSdk = flutter.minSdkVersion
        manifestPlaceholders["admobAppId"] =
            dartDefinesMap()["ADMOB_ANDROID_APP_ID"] ?: defaultAdmobAndroidAppId
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

gradle.taskGraph.whenReady {
    val requiresReleaseSigning = allTasks.any { task ->
        task.name.contains("Release", ignoreCase = true)
    }

    if (requiresReleaseSigning && !hasReleaseSigning) {
        throw GradleException(
            "Release signing is not configured. Copy android/key.properties.example " +
                "to android/key.properties and point storeFile at your upload keystore."
        )
    }
}

flutter {
    source = "../.."
}
