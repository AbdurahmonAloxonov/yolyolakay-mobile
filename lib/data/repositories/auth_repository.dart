import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/device.dart';
import '../../core/api/token_storage.dart';
import '../../core/env.dart';
import '../models/auth.dart';

/// Auth — IKKI yo'l:
///  1. OTP (asosiy): `verify-otp` yangi hisobni AVTOMATIK yaratadi, ya'ni
///     login va register bitta oqim — alohida "ro'yxatdan o'tish" ekrani yo'q;
///  2. Parol (qo'shimcha): avval OTP bilan kirib `setup-password` qilgan
///     foydalanuvchi keyin SMS'siz kiradi.
///
/// Rate-limit: `send-otp` daqiqasiga 3 marta → 429.
class AuthRepository {
  AuthRepository(this._client, this._tokens);

  final ApiClient _client;
  final TokenStorage _tokens;

  /// 🔴 `type` MAJBURIY (backend 2026-08-03): usiz 400
  /// `invalid request body or missing 'type'` — ya'ni SMS UMUMAN yuborilmaydi.
  /// Ruxsat etilgan qiymatlar: `register` | `login` | `frgt_pswd`.
  ///
  /// Bu ilovada ro'yxatdan o'tish va kirish BITTA oqim (`verify-otp` hisobni
  /// o'zi yaratadi), shuning uchun turni O'ZIMIZ aniqlaymiz: avval `login`
  /// deb urinib ko'ramiz; backend 404 (`user not found`) qaytarsa — bu yangi
  /// raqam, `register` bilan qayta yuboramiz. Foydalanuvchi buni sezmaydi.
  Future<void> sendOtp(String phoneNumber, {String? type}) async {
    if (Env.mockAuth) return;

    Future<void> post(String otpType) => _client.dio.post<dynamic>(
      '/auth/send-otp',
      data: {'phone_number': phoneNumber, 'type': otpType},
    );

    try {
      await post(type ?? 'login');
    } on DioException catch (e) {
      // Tur aniq berilgan bo'lsa (masalan parol tiklash) — qayta urinmaymiz.
      if (type == null && e.response?.statusCode == 404) {
        try {
          await post('register');
          return;
        } on DioException catch (e2) {
          throw ApiException.from(e2);
        }
      }
      throw ApiException.from(e);
    }
  }

  /// Muvaffaqiyatli bo'lsa tokenlar SAQLANADI va javob qaytadi.
  Future<TokenResponse> verifyOtp(String phoneNumber, String code) async {
    if (Env.mockAuth) return _mockLogin(code);
    try {
      final res = await _client.dio.post<dynamic>(
        '/auth/verify-otp',
        data: {
          'phone_number': phoneNumber,
          'code': code,
          // ⚠ Header'ga QO'SHIMCHA, uning o'rniga emas: monolit buni tanada
          // majburiy deb biladi (`400 invalid payload`), gateway esa
          // headerdan oladi. Tafsilot: `core/api/device.dart`.
          // Headerlarni `ApiClient` interceptor'i HAR so'rovga o'zi qo'yadi.
          'device_fingerprint': await DeviceInfo.id(),
        },
      );
      return _persist(asMap(unwrap(res.data)));
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// YANGI QURILMA (backend 2026-08-09): parol TO'G'RI bo'lsa ham, `X-Device-ID`
  /// foydalanuvchining ochiq sessiyalari orasida bo'lmasa, backend O'ZI SMS yuboradi
  /// va `403 {"error":"new_device"}` qaytaradi. Bu xato EMAS — oqim kod ekraniga
  /// o'tishi kerak, shuning uchun alohida [NewDeviceException] tashlanadi.
  /// Ekran qayta `sendOtp` CHAQIRMASLIGI kerak: kod allaqachon ketgan.
  Future<TokenResponse> loginWithPassword(
    String phoneNumber,
    String password,
  ) async {
    if (Env.mockAuth) return _mockLogin('11111');
    try {
      final res = await _client.dio.post<dynamic>(
        '/auth/login',
        data: {
          'phone_number': phoneNumber,
          'password': password,
          'device_fingerprint': await DeviceInfo.id(),
        },
      );
      return _persist(asMap(unwrap(res.data)));
    } on DioException catch (e) {
      // Tartib MUHIM: sms-failed `new_device` dan OLDIN tekshiriladi.
      if (_isSmsNotSent(e)) throw SmsNotSentException();
      if (_isNewDevice(e)) throw NewDeviceException();
      throw ApiException.from(e);
    }
  }

  /// `error` maydonini backend IKKI xil ishlatadi — mashina kodi (`new_device`)
  /// va odamga mo'ljallangan matn (`invalid phone or password`). Shuning uchun
  /// avval kodni ANIQ solishtiramiz.
  ///
  /// Zaxira — matn bo'yicha: `new_device` kaliti backend XATIDA aytilgan, lekin
  /// SWAGGERDA yo'q (u yerda 403 shunchaki erkin `map[string]string`:
  /// "New device detected, OTP required"). Kalit o'zgarsa foydalanuvchi
  /// "parolim noto'g'ri" degan yolg'on xatoga tushardi. `/auth/login` uchun
  /// swaggerda boshqa 403 holati umuman yo'q.
  static bool _isNewDevice(DioException e) {
    if (e.response?.statusCode != 403) return false;
    final body = asMap(unwrap(e.response?.data));
    final text = '${body?['error'] ?? ''} ${body?['message'] ?? ''}';
    // 🔴 `new_device_sms_failed` ANIQ ISTISNO: u ham `new_device` bilan
    // boshlanadi, ya'ni matn bo'yicha zaxira tekshiruv uni xato ravishda
    // "kod yuborildi" deb qabul qilardi va odam kelmaydigan kodni kutardi.
    if (text.contains(_smsFailedCode)) return false;
    final code = body?['error'];
    if (code is String && code.trim().toLowerCase() == 'new_device') {
      return true;
    }
    return RegExp(
      r'new[\s_-]?device|новое устройство',
      caseSensitive: false,
    ).hasMatch(text);
  }

  static const String _smsFailedCode = 'new_device_sms_failed';

  /// Yangi qurilma aniqlandi, LEKIN SMS ketmadi (limit 3/daq yoki shlyuz).
  /// Backend kontrakti (2026-08-09): `429` yoki `403` + shu kod.
  /// Kod ekraniga o'tish YARAMAYDI — kod yo'q, odam bo'sh ekranda kutib qoladi.
  static bool _isSmsNotSent(DioException e) {
    final status = e.response?.statusCode;
    if (status != 403 && status != 429) return false;
    final body = asMap(unwrap(e.response?.data));
    return '${body?['error'] ?? ''} ${body?['message'] ?? ''}'.contains(
      _smsFailedCode,
    );
  }

  /// Joriy (token bilan kirgan) foydalanuvchiga parol o'rnatish/almashtirish.
  Future<void> setupPassword(String password) async {
    try {
      await _client.dio.post<dynamic>(
        '/auth/setup-password',
        data: {'password': password},
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Eslatma: refresh oqimi FAQAT `ApiClient` interceptor'ida — ikki nusxa
  /// mantiq drift qilmasligi uchun bu yerda takrorlanmaydi.

  Future<List<Session>> sessions() async {
    try {
      final res = await _client.dio.get<dynamic>('/auth/sessions');
      return asList(
        unwrap(res.data),
        'sessions',
      ).map(Session.fromJson).toList();
    } on DioException catch (e) {
      // Xavfsizlik ekrani: xatoda "qurilma yo'q" ko'rsatish YOLG'ON bo'ladi —
      // odam begona seans yo'q deb xotirjam bo'ladi.
      throw ApiException.from(e);
    }
  }

  /// BOSHQA qurilmani chiqarish.
  ///
  /// `logout()` dan farqi: u SHU qurilmani yopadi va lokal tokenlarni tozalaydi.
  /// Bu esa begona sessiyani uzadi va joriy sessiyaga TEGMAYDI — telefoni
  /// yo'qolgan odam boshqa qurilmadan kirib uni chiqarib tashlashi uchun.
  Future<void> revokeSession(String deviceId) async {
    try {
      await _client.dio.delete<dynamic>('/auth/sessions/$deviceId');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Chiqish = SHU qurilma sessiyasini yopish (eski `/auth/logout` YO'Q).
  Future<void> logout() async {
    try {
      final deviceId = await DeviceInfo.id();
      await _client.dio.delete<dynamic>('/auth/sessions/$deviceId');
    } catch (_) {
      // Server javob bermasa ham lokal chiqish bajarilishi kerak.
    } finally {
      await _tokens.clear();
    }
  }

  Future<TokenResponse> _persist(Map<String, dynamic>? body) async {
    if (body == null) {
      throw ApiException(kind: ApiErrorKind.unknown);
    }
    final tokens = TokenResponse.fromJson(body);
    if (tokens.accessToken.isEmpty) {
      throw ApiException(kind: ApiErrorKind.unknown);
    }
    await _tokens.save(
      access: tokens.accessToken,
      refresh: tokens.refreshToken,
    );
    return tokens;
  }

  /// `--dart-define=MOCK_AUTH=true` rejimi — backend `/auth/*` 502 bo'lganda
  /// UI oqimini oxirigacha bosib ko'rish uchun. Tarmoqqa CHIQMAYDI.
  Future<TokenResponse> _mockLogin(String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (code != '11111') {
      throw ApiException(
        kind: ApiErrorKind.badRequest,
        statusCode: 400,
        backendMessage: 'invalid otp',
      );
    }
    const tokens = TokenResponse(
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
      isNewUser: false,
    );
    await _tokens.save(
      access: tokens.accessToken,
      refresh: tokens.refreshToken,
    );
    return tokens;
  }
}
