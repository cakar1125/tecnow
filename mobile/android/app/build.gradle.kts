import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Yayın imzası deponun **dışında** durur.
//
// `android/key.properties` ve `*.jks` dosyaları `.gitignore`'da; anahtar
// deposu ele geçirilirse mağazadaki uygulamanın yerine sahte bir sürüm
// yayımlanabilir, ve Play'de bir uygulamanın imza anahtarı **değiştirilemez**.
// Bu yüzden dosya yolu ve parolalar koda gömülmez, yerel bir dosyadan okunur.
//
// Dosya yoksa derleme durmaz: aşağıda debug anahtarına düşülür, böylece
// `flutter run --release` anahtar olmadan da çalışır. Ama o çıktı
// **mağazaya yüklenemez** — Play debug anahtarıyla imzalanmış paketi reddeder.
//
// Kurulum: docs/RELEASE_SIGNING.md
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasReleaseKeystore = keystorePropertiesFile.exists()

android {
    namespace = "com.tecos.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Mağaza yayınından sonra **değiştirilemez**. Değiştirmek Play'de yeni
        // bir uygulama demektir: yükleme sayısı, yorumlar ve puan taşınmaz.
        applicationId = "com.tecos.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Anahtar yok: yerel denemeler sürsün diye debug anahtarı.
                // Bu çıktı mağazaya yüklenemez.
                // Not: Gradle günlüğü Windows konsolunda cp1252 ile yazılıyor;
                // Türkçe karakterler bozuk görünüyordu. Bu satır bilerek ASCII.
                logger.warn(
                    "UYARI: android/key.properties bulunamadi. Surum derlemesi " +
                        "DEBUG anahtariyla imzalaniyor; Play Console bunu reddeder. " +
                        "Kurulum: docs/RELEASE_SIGNING.md",
                )
                signingConfigs.getByName("debug")
            }

            // R8/kod küçültme **bilerek kapalı**. Açmak APK'yı küçültür ama
            // yansımayla çözülen kodu sessizce budayabilir; açıldığı gün
            // gerçek bir cihazda sürüm derlemesiyle baştan sona doğrulanmalı.
            // Ölçülmeden açılmayacak.
            isMinifyEnabled = false
            isShrinkResources = false
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
