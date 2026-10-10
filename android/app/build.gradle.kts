import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

/*
 * FIREBASE (push) — plagin SHARTLI qo'llanadi.
 *
 * `com.google.gms.google-services` plagini `app/google-services.json` fayli
 * BO'LMASA build'ni yiqitadi ("File google-services.json is missing").
 * Fayl esa hozircha yo'q — backend uni hali bermadi (bergani soxta chiqdi:
 * project_number 123456789012, api_key "AIzaSy_REPLACE_THIS_WITH_REAL_API_KEY").
 *
 * Shuning uchun shart: fayl paydo bo'lgan kuni plagin O'ZI ishga tushadi va
 * pushlar ishlaydi — Gradle'ga qayta tegish, hech kimning "esida saqlashi"
 * kerak emas. Fayl yo'q bo'lsa ilova avvalgidek yig'ilaveradi (pushsiz).
 *
 * ⚠️ Firebase kutubxonalari (BoM, analytics) QO'LDA qo'shilmaydi: Flutter'da
 * ularni `firebase_core`/`firebase_messaging` paketlari o'zi tortadi.
 * Konsoldagi ko'rsatma native Android loyihalar uchun — bizga faqat shu
 * plagin va JSON kerak.
 */
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

/*
 * RELIZ IMZOSI.
 *
 * Play Market DEBUG kalit bilan imzolangan paketni QABUL QILMAYDI
 * ("You uploaded an APK that was signed in debug mode"). Shu paytgacha bu fayl
 * `signingConfig = signingConfigs.getByName("debug")` bilan turgan edi, ya'ni
 * `--release` yig'ilgan paket ham amalda debug kalit bilan imzolanardi.
 *
 * Endi kalit `android/key.properties` dan o'qiladi (u `.gitignore` da — repozitoriyga
 * TUSHMAYDI). Fayl yo'q bo'lsa lokal `flutter run --release` ishlashi uchun debug
 * imzoga qaytamiz, LEKIN yig'ish paytida ogohlantirish chiqadi.
 *
 * ✅ 2026-08-07: KALIT SOZLANDI. Yangi kalit YARATILMADI — Capacitor ilovasi uchun
 * 2026-07-22 da yasalgan MAVJUD kalit ishlatiladi:
 *
 *   ~/yolyolakay-release.keystore   alias `yolyolakay`
 *   CN=YolYolakay, O=YolYolakay, L=Tashkent, C=UZ   RSA-2048/SHA256, 2053-gacha
 *   SHA-256: AF:46:E1:48:A5:D8:76:3B:87:E1:13:B8:20:A6:B1:B3:
 *            B1:CD:C0:B3:9F:62:A6:76:EA:73:1D:51:AD:C7:9C:D3
 *
 * NEGA MAVJUDI: bitta keystore bir nechta ilovani imzolay oladi, ya'ni yangi kalit
 * yasash keraksiz ikkinchi "yo'qotib bo'lmaydigan fayl" tug'dirardi. Ayni kalit
 * `~/Desktop/yolyolakay-mobile/android/` da ham yotibdi (Capacitor build'i unga
 * qaraydi), shuning uchun ko'chirilmadi — nusxalandi.
 *
 * appId QAROR YOPILDI (2026-08-07): `uz.yolyolakay.mobile` QOLADI.
 * Eski rejada "keyin `uz.yolyolakay.app` ga o'tamiz" deyilgandi, lekin uning
 * MAQSADI Capacitor ilovasining Play'dagi listing'ini meros qilib olish edi.
 * Egasi tasdiqladi: Capacitor HECH QACHON chop etilmagan → meros qiladigan
 * listing yo'q → ko'chishning sababi ham yo'q. `.app` ning yutug'i faqat
 * kosmetik (do'kon havolasi), narxi esa haqiqiy: appId 20 dan ortiq joyda,
 * shu jumladan MyID'ga RO'YXATDAN O'TKAZILGAN `uz.yolyolakay.mobile://myid/callback`
 * — MyID redirect_uri ni aynan mos tekshiradi va o'zgartirish ular tomonida
 * qayta ro'yxatdan o'tkazishni talab qiladi.
 *
 * 🔴 ZAXIRA: kalit hozir FAQAT shu mashinada (ikkita nusxa, bitta disk). Disk
 * yo'qolsa ilovani BOSHQA HECH QACHON yangilab bo'lmaydi. Kalitni + parolni
 * mashinadan TASHQARIGA (parol menejeri / shifrlangan bulut) chiqarish SHART.
 * Play App Signing'ga yozilsangiz bu faqat "upload key" bo'ladi va yo'qolsa
 * Google uni tiklab beradi — tavsiya etiladi.
 *
 * Tekshirilgan (2026-08-07): `flutter build apk --release` -> apksigner
 * `Signer #1 certificate DN: CN=YolYolakay, ...`, SHA-256 keystore bilan AYNAN mos,
 * `v2 scheme: true` (minSdk 24 -> v1 talab qilinmaydi).
 */
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    logger.warn(
        "\n⚠️  android/key.properties topilmadi — RELIZ DEBUG KALIT bilan imzolanadi.\n" +
            "   Play Market bunday paketni rad etadi. Yo'riqnoma: build.gradle.kts izohi.\n"
    )
}

android {
    namespace = "uz.yolyolakay.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // `flutter_local_notifications` (ma'lumotli push uchun kerak) eski
        // Android'larda ham java.time bilan ishlaydi — buning uchun
        // "core library desugaring" YOQILGAN bo'lishi shart, aks holda
        // yig'ish `checkReleaseAarMetadata` bosqichida yiqiladi.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "uz.yolyolakay.mobile"
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
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Kalit bo'lsa — haqiqiy imzo; bo'lmasa lokal ishlash uchun debug
            // (yuqorida ogohlantirish chiqadi).
            signingConfig =
                if (hasReleaseKeystore) signingConfigs.getByName("release")
                else signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
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

dependencies {
    // Yuqoridagi `isCoreLibraryDesugaringEnabled` uchun kutubxona.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
