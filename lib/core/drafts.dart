import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// QORALAMALAR — yozilgan, lekin yuborilmagan narsa yo'qolmasin.
///
/// 🔴 IKKI HOLAT, BITTA SABAB (2026-08-25 auditi):
///
///  1. **E'lon formasi** 1007 qator. Odam yarim soat to'ldiradi, tasodifan
///     «orqaga» bosadi — va HAMMASI yo'qoladi. Sababsiz ikkinchi marta
///     to'ldirmaydi, ketadi. Haydovchi esa bizga eng kerak odam.
///  2. **Chat**: matn yozib bo'lib, ro'yxatga qaytsa matn yo'qoladi.
///     Telegramda u saqlanadi va odam shunga o'rgangan.
///
/// Ikkalasi ham «mehnat yo'qoldi» degan bitta his. Shuning uchun
/// mexanizm ham bitta.
///
/// ⚠️ QORALAMA — YUBORILGAN narsa emas. U faqat qurilmada yotadi va
/// serverga hech qachon o'zi ketmaydi. Yuborilgach O'CHIRILADI: eski
/// qoralama qaytib chiqishi «men buni allaqachon yubordim shekilli»
/// degan chalkashlik beradi.
class Drafts {
  const Drafts(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'draft_';

  /// Chat qoralamasi kaliti — suhbatdosh bo'yicha (safar bo'yicha EMAS:
  /// suhbat ODAM bilan bo'ladi, izohi `chat-odam-boyicha` xotirasida).
  static String chat(String peerId) => 'chat_$peerId';

  /// E'lon formasi qoralamasi — bitta, chunki bir vaqtda bitta e'lon
  /// tayyorlanadi.
  static const createRide = 'create_ride';

  /// Haydovchi tekshiruvi qoralamasi (2026-08-27).
  ///
  /// 🔴 NEGA KERAK: oqim SAKKIZTA suratga o'sdi (hujjatlar ikki tomondan,
  /// mashina uch rakursda). Telefon jiringlasa, tizim ilovani o'chirsa
  /// yoki odam orqaga bossa — hammasi yo'qolardi va u qaytib kelmasdi.
  /// Suratlar allaqachon serverga yuklangan bo'ladi, ya'ni saqlanadigan
  /// narsa — atigi manzillar ro'yxati.
  static const driverVerification = 'driver_verification';

  String? read(String key) {
    final value = _prefs.getString('$_prefix$key');
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> write(String key, String value) async {
    final trimmed = value.trim();
    // Bo'sh qoralama saqlanmaydi: odam matnni O'CHIRGAN bo'lsa, uni
    // qaytarib qo'yish g'alati.
    if (trimmed.isEmpty) return clear(key);
    await _prefs.setString('$_prefix$key', trimmed);
  }

  Map<String, dynamic>? readMap(String key) {
    final raw = read(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? decoded.cast<String, dynamic>() : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeMap(String key, Map<String, dynamic> value) async {
    try {
      await _prefs.setString('$_prefix$key', jsonEncode(value));
    } catch (_) {
      /* kodlanmadi — qoralamasiz davom etamiz */
    }
  }

  Future<void> clear(String key) => _prefs.remove('$_prefix$key');
}
