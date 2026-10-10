/// MAHALLIY BELGILAR — server saqlay olmaydigan holat.
///
/// 🔴 NEGA YOZILDI (2026-08-25): gateway'da ba'zi oddiy amal uchun ruchka
/// UMUMAN YO'Q, lekin odam uni kutadi. Ikki aniq holat:
///
///   1. **Yo'lovchi bronni bekor qila olmaydi.** Kontraktда faqat
///      `.../bookings/{id}/reject` (HAYDOVCHI rad etadi) va
///      `rides/{id}/cancel` (haydovchi safarni bekor qiladi) bor. Yo'lovchi
///      esa fikridan qaytsa — hech qanday tugma yo'q edi va u shunchaki
///      "kelmay qo'yardi" (haydovchi uchun eng yomon holat).
///
///   2. **Posilka `accepted` da abadiy qotib qoladi.** Yetkazilganini
///      YOZADIGAN chaqiruv ilova oqimida yo'q, ya'ni tugagan posilka
///      ro'yxatда faol bo'lib turaveradi va ro'yxat axlatga aylanadi.
///
/// ═══ QAT'IY QOIDALAR — bularsiz mahalliy belgi YOLG'ONGA aylanadi ═══
///
///  1. Mahalliy belgi SERVER haqiqatini BEKOR QILMAYDI. U faqat server
///     hech nima demagan joyni to'ldiradi. Server "bron faol" desa, biz
///     "bekor qilindi" deb ko'rsatmaymiz — «bekor qilish so'raldi» deymiz.
///  2. Belgi EKRANDA AYTILADI. Jimgina holat o'zgartirish — odam ilovaga
///     ishonchini yo'qotadigan eng tez yo'l.
///  3. Belgi FAQAT shu qurilmada. Boshqa telefonda ko'rinmaydi va buni
///     yashirmaymiz.
///
/// Backendga xat yozilgan (`BACKEND_XAT_BEKOR_VA_PUSH_2026-08-25.txt`).
/// Ruchka paydo bo'lsa — bu fayl emas, uni CHAQIRADIGAN joylar o'zgaradi.
library;

import 'package:shared_preferences/shared_preferences.dart';

class LocalFlags {
  const LocalFlags(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'flag_';

  /// Yo'lovchi bronni bekor qilishni SO'RAGAN.
  static String cancelRequested(String bookingId) => 'cancel_req:$bookingId';

  /// Posilka yetkazilgani mahalliy belgilangan.
  static String parcelDelivered(String parcelId) => 'parcel_done:$parcelId';

  /// «Yetib keldim» xabari yuborilgani (yoki rad etilgani) belgilangan.
  ///
  /// 🔴 Belgi rad etishда HAM qo'yiladi: karta «kerak emas» deyilgach
  /// qayta chiqsa, u yordam emas, bezorilik bo'lardi.
  static String arrivalSent(String rideId) => 'arrival:$rideId';

  /// Yo'lovchi NAQD pulni to'lagani belgilangan (haydovchining kassasi).
  ///
  /// 🔴 NEGA MAHALLIY (2026-08-25): ilovada onlayn to'lov YO'Q — pul yo'lda,
  /// naqd, qo'ldan qo'lga beriladi. Backendда buni yozadigan joy ham yo'q.
  /// Haydovchi esa 4 yo'lovchidan kimdan olganini BOSHIDA saqlaydi va
  /// adashadi. Belgi shu bitta telefonda yashaydi — bu yetarli, chunki
  /// pulni ham shu bitta odam yig'adi.
  static String bookingPaid(String bookingId) => 'paid:$bookingId';

  bool has(String key) => _prefs.containsKey('$_prefix$key');

  /// Belgi QO'YILGAN vaqt — ekranда «2 soat oldin so'raldi» deyish uchun.
  /// Odam kutish qancha cho'zilganini ko'rsin.
  DateTime? at(String key) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> set(String key) =>
      _prefs.setString('$_prefix$key', DateTime.now().toIso8601String());

  /// Belgini olib tashlaydi — server haqiqatni aytganda chaqiriladi.
  ///
  /// Masalan haydovchi bronni rad etsa, server holati `rejected` bo'ladi:
  /// endi «bekor qilish so'raldi» degan mahalliy belgi keraksiz va uni
  /// qoldirish ikki xil gap aytish bo'lardi.
  Future<void> clear(String key) => _prefs.remove('$_prefix$key');
}
