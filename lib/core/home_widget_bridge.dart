import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform;
import 'package:flutter/services.dart';

/// BOSH EKRAN VIDJETI — «yaqin safar» telefon ekranida.
///
/// 🔴 NEGA (2026-09-08): ilova ochilmasa u umuman ko'rinmaydi. Vidjet
/// esa telefon ekranida turadi va odam kuniga o'nlab marta ko'radi —
/// safar yaqinlashganda ilovani ochishga sabab bo'ladi.
///
/// ═══ NEGA PAKETSIZ ═══
///
/// `home_widget` paketi sinab ko'rildi va RAD ETILDI: u
/// `androidx.glance:glance-appwidget:1.3.0-alpha02` ni tortadi, u esa
/// **compileSdk 37** talab qiladi (bizda 36, AGP 9 uchun tavsiya
/// etilgani ham 36). Ya'ni bitta vidjet uchun butun build'ni alfa
/// kutubxonaga bog'lash kerak bo'lardi.
///
/// Bizga kerak narsa juda oz: qiymatlarni `SharedPreferences` ga yozish
/// va vidjetga «yangilan» deb aytish. Bu — o'ttiz qator Kotlin, va
/// kanal ALLAQACHON bor (`MainActivity` dagi `.../settings`).
///
/// ═══ FON ISHI YO'Q ═══
///
/// Vidjet HECH QACHON o'zi tarmoqqa chiqmaydi. Ilova safarni bilganda
/// yozadi, vidjet oxirgi yozilganni chizadi. Sabab: fon ishi batareya
/// yeydi, Android uni baribir o'ldiradi, va u token yangilashni talab
/// qilib sessiya uzilishining yana bitta manbaiga aylanardi.
///
/// Natijada vidjet ESKIRISHI mumkin — shuning uchun u SANA/VAQTni
/// ko'rsatadi («9-sentabr, 07:00»), «2 soatdan keyin» kabi o'zi
/// eskiradigan yozuvni EMAS: eskirgan sana yolg'on gapirmaydi,
/// eskirgan hisob esa gapiradi.
///
/// ⚠️ Matnlar SHU YERDAN uzatiladi, Android resurslaridan emas: til
/// ilovada tanlanadi va uni ikki joyda saqlash ertaga ajralib ketardi.
abstract final class HomeWidgetBridge {
  /// `MainActivity` dagi kanal bilan AYNAN bir xil bo'lishi shart.
  static const _channel = MethodChannel('uz.yolyolakay.mobile/settings');

  /// Safar bor: yo'nalish, vaqt va qo'shimcha qator (narx yoki joy).
  static Future<void> publishTrip({
    required String route,
    required String when,
    String? note,
  }) => _send(route: route, when: when, note: note ?? '', empty: '');

  /// Safar yo'q: vidjet BO'SH QOLMAYDI, taklif ko'rsatadi.
  ///
  /// Bo'sh vidjet — ekrandagi o'lik to'rtburchak; odam uni birinchi
  /// bo'lib olib tashlaydi. Loyihadagi «bo'sh holat chiqish yo'li bilan
  /// bo'lsin» qoidasi bu yerda ham amal qiladi.
  static Future<void> publishEmpty(String invitation) =>
      _send(route: '', when: '', note: '', empty: invitation);

  static Future<void> _send({
    required String route,
    required String when,
    required String note,
    required String empty,
  }) async {
    // iOS'da vidjet YO'Q (alohida extension va App Group kerak) —
    // bekorga kanal chaqirmaymiz.
    //
    // ⚠️ `Platform.isAndroid` EMAS, `defaultTargetPlatform`: birinchisi
    // testda DOIM `false` beradi (sinov host mashinada yuguradi) va
    // vidjet mantig'i umuman sinalmay qolardi — buni birinchi yozishda
    // aynan shu test ushladi.
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('updateHomeWidget', {
        'route': route,
        'when': when,
        'note': note,
        'empty': empty,
      });
    } catch (error) {
      // Vidjet — IXTIYORIY qulaylik. Uning yiqilishi ilovaning biror
      // ekraniga ta'sir qilmasligi kerak (sinov muhitida platforma
      // kanali umuman yo'q va bu NORMAL).
      debugPrint('Vidjet yangilanmadi: $error');
    }
  }
}
