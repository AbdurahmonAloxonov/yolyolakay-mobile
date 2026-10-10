import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// OFFLINE KESH — oxirgi muvaffaqiyatli javob qurilmada qoladi.
///
/// 🔴 NEGA YOZILDI (2026-08-25 auditi): ilovada «offline» degan narsa
/// faqat BANNER va qayta urinish taymeri edi. Ma'lumot esa hech qayerda
/// saqlanmasdi, ya'ni internet uzilishi bilan HAR EKRAN xato ko'rinishiga
/// aylanardi: safarlarim bo'sh, suhbatlar bo'sh, bildirishnomalar bo'sh.
/// Metro, tunnel, qishloq yo'li — ilova amalda oq ekranga aylanardi.
/// Ayni paytda bu ilova aynan YO'LDA ishlatiladi.
///
/// Endi oxirgi javob diskda qoladi va uzilishda o'sha ko'rsatiladi.
///
/// ⚠️ IKKI QAT'IY QOIDA — ular buzilsa kesh foydadan zararga aylanadi:
///
///  1. **Faqat ULANISH xatosida** eski ma'lumot beriladi. `403`, `404` yoki
///     `500` da BERILMAYDI: server "sizda ruxsat yo'q" desa, eski ro'yxatni
///     ko'rsatish yolg'on bo'lardi.
///  2. Eski ma'lumot **JIMGINA** ko'rsatilmaydi — [cachedAt] orqali u
///     qachon olingani ekranda aytiladi. Odam eski narsani yangi deb
///     o'ylab qaror qabul qilmasin.
///
/// XOM JSON saqlanadi (model emas): modellarda to'liq `toJson` yo'q va uni
/// yozish ikkinchi manba yaratardi — parser bilan chetga chiqib ketishi
/// mumkin edi. Xom javob esa parserga AYNAN o'sha ko'rinishda qaytadi.
class LocalCache {
  const LocalCache(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'cache_';
  static const _timePrefix = 'cache_at_';

  /// Ro'yxatni saqlaydi. Xato bo'lsa JIM o'tadi — kesh yozilmagani
  /// asosiy oqimni buzmasligi kerak.
  Future<void> writeList(String key, List<Map<String, dynamic>> rows) async {
    try {
      await _prefs.setString('$_prefix$key', jsonEncode(rows));
      await _prefs.setInt(
        '$_timePrefix$key',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      /* disk to'la yoki JSON kodlanmadi — keshsiz davom etamiz */
    }
  }

  /// Saqlangan ro'yxat. Yo'q yoki buzuq bo'lsa `null`.
  List<Map<String, dynamic>>? readList(String key) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (_) {
      return null;
    }
  }

  /// Ma'lumot QACHON olingani. Ekranda ko'rsatish uchun.
  /// BITTA obyektni saqlaydi (ro'yxat emas) — masalan `/users/me`.
  ///
  /// 🔴 NEGA KERAK (2026-08-25): profil ekrani uzilishda BUTUNLAY singan
  /// ko'rinardi — ism ham, mashina ham, tasdiq holati ham yo'q, faqat
  /// xato. Holbuki bularning hammasi oxirgi javobда bor edi va ular
  /// deyarli o'zgarmaydi. Odam esa aynan yo'lda, aloqasiz joyda «mening
  /// hujjatlarim tasdiqlanganmi?» deb qaraydi.
  Future<void> writeMap(String key, Map<String, dynamic> row) async {
    try {
      await _prefs.setString('$_prefix$key', jsonEncode(row));
      await _prefs.setInt(
        '$_timePrefix$key',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      /* kesh yozilmagani asosiy oqimni buzmasin */
    }
  }

  Map<String, dynamic>? readMap(String key) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? decoded.cast<String, dynamic>() : null;
    } catch (_) {
      return null;
    }
  }

  DateTime? cachedAt(String key) {
    final ms = _prefs.getInt('$_timePrefix$key');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> clear(String key) async {
    await _prefs.remove('$_prefix$key');
    await _prefs.remove('$_timePrefix$key');
  }
}

/// Xato ULANISH xatosimi — ya'ni so'rov serverga UMUMAN yetib bormadimi.
///
/// Status kodli javob (hatto 500) ulanish xatosi EMAS: internet bor,
/// server javob berdi. Bunda keshdan ko'rsatish noto'g'ri bo'lardi —
/// server bizga aniq bir narsa aytyapti.
bool isOfflineError(DioException error) {
  if (error.response != null) return false;
  return const {
    DioExceptionType.connectionError,
    DioExceptionType.connectionTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.sendTimeout,
  }.contains(error.type);
}

/// Kesh kalitlari — bitta joyda, chunki ular ikki tomondan ishlatiladi:
/// repozitoriy yozadi, ekran `cachedAt` ni o'qiydi.
abstract final class CacheKeys {
  static const myRides = 'my_rides';
  static const myBookings = 'my_bookings';
  static const conversations = 'conversations';
  static const notifications = 'notifications';

  /// Profil (`/users/me`) — ism, rol, tasdiq holati, mashinalar.
  static const me = 'me';
}
