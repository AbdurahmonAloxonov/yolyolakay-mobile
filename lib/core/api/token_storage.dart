import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tokenlar — Keystore/Keychain'da (SharedPreferences'da EMAS: refresh token
/// uzoq yashaydi, root qilingan qurilmada ochiq turmasin).
///
/// Xotiradagi nusxa (`access`/`refresh`) so'rov interceptor'i sinxron ishlashi
/// uchun — har so'rovda diskka kirmaydi. Ishga tushishda [load] chaqiriladi.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  String? access;
  String? refresh;

  bool get hasSession => access != null && access!.isNotEmpty;

  Future<void> load() async {
    access = await _storage.read(key: _accessKey);
    refresh = await _storage.read(key: _refreshKey);
  }

  /// Tokenlarni saqlaydi.
  ///
  /// 🔴 TARTIB MUHIM: avval DISKKA, keyin xotiraga.
  ///
  /// Backend refresh tokenni AYLANTIRADI — yangisi kelishi bilan eskisi
  /// serverda O'LADI (jonli o'lchov 2026-08-24: takroran ishlatilsa
  /// `401 invalid or expired session`). Ilgari bu yerda avval xotira
  /// yangilanardi. Ilova aynan shu ikki qator orasida yopilsa (foydalanuvchi
  /// "orqaga" bosdi, tizim xotira uchun o'ldirdi), diskda O'LIK refresh token
  /// qolardi — keyingi ochilishda u bilan yangilashga urinilib 401 kelardi va
  /// odam sababsiz login ekraniga tushardi.
  ///
  /// Endi diskdagi nusxa hech qachon xotiradagidan eski bo'lmaydi.
  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: _refreshKey, value: refresh);
    await _storage.write(key: _accessKey, value: access);
    this.access = access;
    this.refresh = refresh;
  }

  Future<void> clear() async {
    access = null;
    refresh = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
