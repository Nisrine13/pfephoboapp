// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // 🔥 corrige ici ("kotlin-android" ➔ "org.jetbrains.kotlin.android")
    id("com.google.gms.google-services") // 👈 plugin Firebase
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.nisrine.monapp.pfephoboapp"
    compileSdk = flutter.compileSdkVersion.toInt()
    ndkVersion = "27.0.12077973" // 🔥 corrige pour respecter la demande du NDK version 27

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11" // 🔥 juste mettre "11" directement, plus propre
    }

    defaultConfig {
        applicationId = "com.nisrine.monapp.pfephoboapp"
        minSdk = 23 // 🔥 car Firebase exige minSdk >= 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Dépendances Firebase via BoM (Bill Of Materials)
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))

    // Firebase services utilisés
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")
}
