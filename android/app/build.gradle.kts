






plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.geo.debit_tracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.geo.debit_tracker"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["googleClientId"] = "@string/google_client_id"
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            } else {
                println("Warning: key.properties not found, using debug signing")
                keyAlias = "androiddebugkey"
                keyPassword = "android"
                storeFile = file(System.getProperty("user.home") + "/.android/debug.keystore")
                storePassword = "android"
            }
        }
    }

    splits {
        abi {
            isEnable = true
            reset()
            include("arm64-v8a", "armeabi-v7a")
            isUniversalApk = true
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            isDebuggable = false
            isJniDebuggable = false
            isPseudoLocalesEnabled = false
            isCrunchPngs = true
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = true
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
    }

    buildFeatures {
        buildConfig = true
        aidl = false
        renderScript = false
        shaders = false
        compose = false
        mlModelBinding = false
        prefab = false
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
        baseline = file("lint-baseline.xml")
    }

    packaging {
        resources {
            excludes += listOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/NOTICE"
            )
        }
        jniLibs {
            useLegacyPackaging = false
        }
        dex {
            useLegacyPackaging = false
        }
    }

    bundle {
        language { enableSplit = true }
        density { enableSplit = true }
        abi { enableSplit = true }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.2")
    
    // Google Play Services for AdMob and authentication
    implementation("com.google.android.gms:play-services-ads:22.6.0")
    implementation("com.google.android.gms:play-services-auth:20.7.0")
    implementation("com.google.android.gms:play-services-base:18.3.0")
    
    // AndroidX support
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("androidx.core:core-ktx:1.12.0")
    
    // Biometric authentication
    implementation("androidx.biometric:biometric:1.1.0")
    
    // WorkManager for background tasks
    implementation("androidx.work:work-runtime-ktx:2.9.0")
}

flutter {
    source = "../.."
}
