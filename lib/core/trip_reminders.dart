import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'push.dart';

/// SAFAR ESLATMALARI — qurilmaning O'ZIDA rejalashtiriladi.
///
/// 🔴 NEGA MUHIM: biz uzoq vaqt "safar eslatmalari backendni kutadi" deb
/// hisoblab keldik, chunki push'ni server yubormaydi. Bu YARIM to'g'ri
/// edi: eslatma uchun server UMUMAN kerak emas. Bron tasdiqlanganda vaqt
/// bizga ma'lum, demak bildirishnomani telefonning o'zi belgilangan
/// paytda ko'rsata oladi.
///
/// Ikkita eslatma qo'yiladi:
///   1. jo'nashdan 1 soat oldin — "tayyorlaning";
///   2. taxminiy yetib borish vaqtida — "safar qanday o'tdi?" (baholash).
///
/// 🔴 Ikkinchisi nega: baholash tizimi bizda ANCHADAN BERI bor, lekin
/// hech kim so'ramaydi — shuning uchun baholar deyarli yo'q. Eslatma
/// aynan shu bo'shliqni yopadi.
///
/// ⚠️ ANIQ BO'LMAGAN rejim (`inexactAllowWhileIdle`) ATAYIN: Android 13+
/// da aniq budilnik `SCHEDULE_EXACT_ALARM` ruxsatini talab qiladi va
/// Play uni alohida asoslashni so'raydi. Eslatma uchun bir necha
/// daqiqalik farq ahamiyatsiz, ruxsat esa reliz uchun ortiqcha xavf.
///
/// ⚠️ Ilova KAMIDA BIR MARTA ochilgan bo'lishi kerak (bron tasdiqlangач
/// ekran ochilganda qo'yiladi). Server tomondan hech nima kelmaydi —
/// bu bildirishnoma faqat SHU qurilmada yashaydi.
class TripReminders {
  TripReminders(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static bool _tzReady = false;

  /// Manifestdagi kanal bilan bir xil (`push.dart` dagi izohga qarang).
  /// 🔴 07.09.2026: bu yerda `'yolyolakay_default'` qotirib yozilgandi,
  /// push esa `_v3` kanalini yaratadi — ya'ni bu bildirishnomalar
  /// ALOHIDA, ovozsiz kanalga tushardi va foydalanuvchi asosiy kanalni
  /// jimlatганda ham chiqaverardi. Endi yagona manba `push.dart` da.
  static const _channelId = defaultChannelId;

  /// Bitta safar uchun BARQAROR id'lar: qayta rejalashtirilganda eski
  /// bildirishnoma almashadi, ikkitasi to'planib qolmaydi.
  static int _idFor(String rideId, int slot) {
    var hash = 0;
    for (final unit in rideId.codeUnits) {
      hash = (hash * 31 + unit) & 0x3fffffff;
    }
    // Android bildirishnoma id'si 32-bit int; slot oxirgi raqamda.
    return (hash % 100000000) * 10 + slot;
  }

  static Future<void> _ensureTz() async {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    // O'zbekiston yagona mintaqada (UTC+5, yozgi vaqt yo'q) — qurilma
    // mintaqasini aniqlash uchun qo'shimcha paket olib kelmaymiz.
    tz.setLocalLocation(tz.getLocation('Asia/Tashkent'));
    _tzReady = true;
  }

  /// Safar uchun ikkala eslatmani qo'yadi (eskisi ustiga yozadi).
  ///
  /// O'tib ketgan vaqtga eslatma QO'YILMAYDI: tizim uni darhol
  /// ko'rsatib yuborardi va odam "nega hozir?" deb hayron bo'lardi.
  Future<void> schedule({
    required String rideId,
    required DateTime departure,
    required String route,
    required String beforeTitle,
    required String beforeBody,
    required String rateTitle,
    required String rateBody,
    Duration tripDuration = const Duration(hours: 2),
  }) async {
    await _ensureTz();

    await _put(
      id: _idFor(rideId, 1),
      at: departure.subtract(const Duration(hours: 1)),
      title: beforeTitle,
      body: '$route — $beforeBody',
      payload: 'ride:$rideId',
    );

    await _put(
      id: _idFor(rideId, 2),
      at: departure.add(tripDuration),
      title: rateTitle,
      body: '$route — $rateBody',
      payload: 'ride:$rideId',
    );
  }

  /// Safar bekor qilinsa/bron rad etilsa — eslatmalarni olib tashlaydi.
  Future<void> cancel(String rideId) async {
    for (final slot in [1, 2]) {
      try {
        await _plugin.cancel(_idFor(rideId, slot));
      } catch (_) {
        // Bildirishnoma yo'q bo'lishi mumkin — bu xato emas.
      }
    }
  }

  Future<void> _put({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (at.isBefore(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(at, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'YolYolakay',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    } catch (_) {
      // Ruxsat yo'q yoki tizim rad etdi — eslatma IXTIYORIY funksiya,
      // uning yiqilishi bron oqimini to'xtatmasligi kerak.
    }
  }
}
