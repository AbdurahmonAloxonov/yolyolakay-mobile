import 'dart:io';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Qurilma identifikatsiyasi.
///
/// ⚠ Backendning IKKI avlodi ikki xil joyni kutadi (2026-07-29 jonli tekshiruv):
///  - deploy qilingan gateway — `X-Device-ID` / `X-OS-Type` HEADERLARI;
///  - monolit (`yolyolakaytoliq/backend`) — tanada `device_fingerprint`
///    (`binding:"required"`), u bo'lmasa `400 invalid payload`.
///
/// Shuning uchun IKKALASI ham yuboriladi: ortiqcha maydonni kerak
/// bo'lmagan xizmat e'tiborsiz qoldiradi, yetishmagani esa kirishni
/// butunlay to'sib qo'yadi.
///
/// ID bir marta yaratilib qurilmada barqaror saqlanadi: sessiyalar ro'yxati
/// (GET /auth/sessions) va sessiyani yopish (DELETE /auth/sessions/{device_id})
/// ham AYNAN shu ID bilan ishlaydi — har ishga tushirishda yangisi yaratilsa,
/// foydalanuvchida sessiyalar to'planib ketadi.
class DeviceInfo {
  const DeviceInfo._();

  static const String _key = 'device_id';
  static String? _cached;

  static Future<String> id() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null || id.isEmpty) {
      id = _uuidV4();
      await prefs.setString(_key, id);
    }
    _cached = id;
    return id;
  }

  /// Gateway `web` dan tashqari qiymatlarni ham qabul qiladi (Swagger: erkin matn).
  static String get osType => Platform.isIOS ? 'ios' : 'android';

  static Future<Map<String, String>> headers() async => {
    'X-Device-ID': await id(),
    'X-OS-Type': osType,
  };

  /// UUID v4 — shu bitta ehtiyoj uchun alohida paket olib kelmaymiz.
  static String _uuidV4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // versiya 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10xx
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
