package uz.yolyolakay.mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    /**
     * Ilovaning BILDIRISHNOMA sozlamalari sahifasini ochadi.
     *
     * Kerak bo'lgan holat: foydalanuvchi ruxsatni "boshqa so'ramang" bilan rad
     * etgan. Bunda tizim dialogi endi umuman chiqmaydi va uni faqat qo'lda
     * yoqish mumkin — ilova esa aks holda jimgina ishlayverib, odam
     * bildirishnoma kelmasligini bizning aybimiz deb o'ylaydi.
     *
     * Alohida paket qo'shmadik: butun kerakli narsa shu bitta Intent
     * (izohi `lib/core/app_settings.dart` da).
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "uz.yolyolakay.mobile/settings",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationSettings" -> result.success(openNotificationSettings())

                /*
                 * BOSH EKRAN VIDJETI — ilova qiymatlarni shu yerga
                 * yozadi, vidjet esa ularni chizadi.
                 *
                 * 🔴 NEGA PAKETSIZ: `home_widget` plagini
                 * `glance-appwidget` alfa versiyasini tortadi va
                 * compileSdk 37 talab qiladi (bizda 36). Bitta vidjet
                 * uchun butun build'ni alfaga bog'lash arzimaydi —
                 * kerak narsa esa mana shu o'n qator.
                 *
                 * ⚠️ Matnlar ILOVADAN keladi (til u yerda tanlanadi),
                 * bu yerda tarjima YO'Q.
                 */
                "updateHomeWidget" -> {
                    val prefs = getSharedPreferences(
                        YolWidgetProvider.PREFS,
                        MODE_PRIVATE,
                    )
                    prefs.edit()
                        .putString("route", call.argument<String>("route") ?: "")
                        .putString("when", call.argument<String>("when") ?: "")
                        .putString("note", call.argument<String>("note") ?: "")
                        .putString("empty", call.argument<String>("empty") ?: "")
                        .apply()
                    YolWidgetProvider.refresh(applicationContext)
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun openNotificationSettings(): Boolean = try {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        } else {
            // Eski Android'da bildirishnoma sahifasi yo'q — ilova haqidagi
            // umumiy sahifa ochiladi, u yerdan ham yoqish mumkin.
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(android.net.Uri.parse("package:$packageName"))
        }
        startActivity(intent)
        true
    } catch (e: Exception) {
        // Ba'zi qobiqlarda (xitoy proshivkalari) bu sahifa yo'q bo'lishi
        // mumkin — ilova yiqilmasin, ekranda matnli yo'riqnoma qoladi.
        false
    }

    /**
     * Bildirishnoma kanalini oldindan yaratadi.
     *
     * Kanalsiz FCM o'zining "Miscellaneous" nomli zaxira kanalidan foydalanadi —
     * u tizim sozlamalarida shu tushunarsiz nom bilan ko'rinadi va MUHIMLIGI
     * past bo'lgani uchun bildirishnoma ekran tepasida qalqib chiqmaydi.
     * Safarga javob kelgani kabi xabarlar esa darhol ko'rinishi kerak.
     *
     * Kanal ilova birinchi ochilganda yaratiladi — pushdan oldin, chunki token
     * baribir kirgandan keyin ro'yxatdan o'tadi.
     *
     * DIQQAT: kanal bir marta yaratilgach uning muhimligini kod O'ZGARTIRA
     * OLMAYDI (Android ataylab bloklaydi — foydalanuvchi sozlamasi ustun).
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        // 🔴 IMPORTANCE_MAX — «HIGH» emas. Bu funksiya Dart tomonidagi
        // `_ensureChannels` dan OLDIN ishlaydi, ya'ni kanalni AMALDA shu
        // yaratadi. Ilgari bu yerda HIGH turgani uchun Dart'dagi
        // `Importance.max` hech qachon kuchga kirmasdi: Android kanal
        // yaratilgach muhimlikni KO'TARISHGA ruxsat bermaydi.
        //
        // Ovoz ham shu sababdan aynan shu yerda berilishi shart —
        // ovozsiz yaratilgan kanalga keyin ovoz qo'shib bo'lmaydi.
        manager.createNotificationChannel(
            NotificationChannel(
                getString(R.string.default_notification_channel_id),
                getString(R.string.default_notification_channel_name),
                NotificationManager.IMPORTANCE_MAX,
            ).apply {
                enableVibration(true)
                setSound(
                    Uri.parse("android.resource://$packageName/raw/yol_ovoz"),
                    AudioAttributes.Builder()
                        // USAGE_NOTIFICATION: ovoz media emas, bildirishnoma
                        // kanalidan chiqsin — telefon jim rejimida va
                        // «Bezovta qilmang» da to'g'ri ishlansin.
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
            }
        )

        // Chat ALOHIDA kanalda. Sabab: bu ikki oqimning qiymati boshqa-boshqa —
        // safar arizasini o'tkazib yuborish pul yo'qotish, chat esa kun bo'yi
        // keladi. Alohida kanal foydalanuvchiga birini o'chirib, ikkinchisini
        // qoldirish imkonini beradi (tizim sozlamalarida ikkita qator).
        //
        // Ovoz kanalning O'ZIDA: Android'da bildirishnomaning emas, KANALning
        // sozlamasi ovozni belgilaydi — "ekran o'chiq bo'lsa ham ovozli signal"
        // talabi aynan shu yerda hal bo'ladi.
        manager.createNotificationChannel(
            NotificationChannel(
                getString(R.string.chat_notification_channel_id),
                getString(R.string.chat_notification_channel_name),
                NotificationManager.IMPORTANCE_MAX,
            ).apply {
                // Chatda ovozli xabar ATAYIN YO'Q — tizim ovozi qoladi.
                // Yozishma kuniga o'nlab keladi va har biriga odam ovozi
                // gapirsa, foydalanuvchi butun bildirishnomani o'chiradi.
                enableVibration(true)
                enableLights(true)
                // Qulflangan ekranda xabar matni ham ko'rinsin.
                lockscreenVisibility = Notification.VISIBILITY_PRIVATE
            }
        )
    }
}
