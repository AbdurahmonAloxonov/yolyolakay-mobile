import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:dio/dio.dart';

import '../env.dart';
import '../format.dart';
import 'device.dart';
import 'token_storage.dart';

/// Gateway javobi ba'zan `{success, data}` qobig'ida, ba'zan yassi keladi —
/// ikkalasini bitta shaklga keltiramiz.
dynamic unwrap(dynamic body) {
  if (body is Map && body.containsKey('data') && body['data'] != null) {
    return body['data'];
  }
  return body;
}

/// `unwrap` natijasini xavfsiz Map'ga keltirish (kutilmagan shaklda null).
Map<String, dynamic>? asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

/// Ro'yxat javoblari uchun: `[...]` ham, `{"rides": null}` ham keladi
/// (jonli kuzatilgan — bo'sh natijada kalit `null`).
List<Map<String, dynamic>> asList(dynamic value, String key) {
  final dynamic raw = value is List ? value : asMap(value)?[key];
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
}

/// JWT `exp` claim'i — kutubxonasiz, yaroqsiz token uchun `null`.
///
/// 🔴 `base64Url` EMAS, qo'lda: JWT to'ldirish belgisisiz (`=`) keladi va
/// Dart'ning `base64.decode` i bunday satrda `FormatException` tashlaydi.
/// `-`/`_` ni almashtirib, uzunlikni 4 ga to'ldiramiz.
///
/// Sinovdan o'tkazish uchun TOP-LEVEL: bu yerdagi xato jimgina "token hech
/// qachon eskirmaydi" degan xulosaga olib keladi va faqat 15 daqiqadan keyin,
/// jonli qurilmada bilinadi.
DateTime? jwtExpiry(String token) {
  try {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    payload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
    final json = jsonDecode(utf8.decode(base64.decode(payload)));
    final exp = json is Map ? json['exp'] : null;
    if (exp is! int) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
  } catch (_) {
    return null;
  }
}

/// Yagona HTTP klient — barcha domen repozitoriylari shu orqali chiqadi.
///
/// Vazifalari:
///  1. har so'rovga `Authorization: Bearer` qo'yish;
///  2. 401 da bitta refresh (parallel so'rovlar shu bittasini kutadi) va so'rovni qaytarish;
///  3. refresh 400/401/403 bersa — qattiq chiqish; 5xx/tarmoq bersa — sessiyani
///     SAQLAB 10 soniya kutish (server tiklanayotgan bo'lishi mumkin, loop bo'lmasin).
class ApiClient {
  ApiClient({required this.tokens}) {
    final base = BaseOptions(
      baseUrl: Env.apiRoot,
      connectTimeout: Env.connectTimeout,
      receiveTimeout: Env.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
      // 4xx/5xx ni o'zimiz ushlaymiz.
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    );
    dio = Dio(base);
    _plain = Dio(base); // interceptorsiz — refresh uchun
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  final TokenStorage tokens;
  late final Dio dio;
  late final Dio _plain;

  /// Internet holati — SO'ROV BACKENDGA YETDIMI bo'yicha (paket EMAS).
  ///
  /// 🔴 NEGA shunday (egasi, 2026-08-20): `connectivity_plus` "Wi-Fi ulangan"
  /// deydi-yu, backend 502 bo'lsa yoki Wi-Fi'da internet bo'lmasa bilmaydi.
  /// Bu yerda esa haqiqat: so'rov javob oldimi. Ulanish xatosi (SocketExcept.
  /// /timeout) = internet YO'Q; status kodli javob (hatto 500) = internet BOR.
  /// `ValueNotifier` ATAYIN (Riverpod emas): interceptor `ref`siz ishlaydi,
  /// banner esa `ValueListenableBuilder` bilan tinglaydi.
  final ValueNotifier<bool> connected = ValueNotifier<bool>(true);

  /// Offline holatда tiklanishни kuzatuvchi taymer.
  ///
  /// 🔴 NEGA KERAK: `connected` FAQAT muvaffaqiyatли javobда `true` bo'ladi.
  /// Ya'ni internet uzilib, keyin tiklansa-yu, foydalanuvchi yangi so'rov
  /// qilmasa (ekran passiv tursa), banner ABADIY qolib ketardi. Bu taymer
  /// offline paytда har birnecha soniyada yengil "ping" yuboradi — javob
  /// kelsa `_onResponse` `connected`ni o'zi `true` qiladi va taymer to'xtaydi.
  Timer? _recoveryTimer;

  /// Sessiya butunlay yaroqsiz bo'lganda chaqiriladi (router login'ga oladi).
  void Function()? onSessionExpired;

  /// Muddati shu vaqtdan kam qolgan token OLDINDAN yangilanadi.
  static const _refreshSkew = Duration(seconds: 60);

  Completer<String?>? _refreshing;
  DateTime? _cooldownUntil;

  bool get _inCooldown =>
      _cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!);

  /// Har so'rovga: `Authorization` + qurilma headerlari.
  ///
  /// Qurilma headerlari ilgari faqat `login`/`verify-otp` ga qo'lda qo'yilardi,
  /// `send-otp` esa ularsiz ketardi — backend qurilmani AYNAN o'sha bosqichda ham
  /// bog'laydi, ya'ni har kirish "yangi qurilma" bo'lib ko'rinardi (2026-08-09).
  /// Endi manba bitta: shu interceptor.
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    var token = tokens.access;

    /*
     * MUDDATI TUGAYOTGAN TOKEN BILAN SO'ROV YUBORMAYMIZ.
     *
     * 🔴 `access_token` umri jonli o'lchovda atigi 15 DAQIQA (2026-08-24).
     * Ilgari yangilash faqat 401 KELGANDAN KEYIN boshlanardi: ilova fondan
     * qaytganda bir vaqtda o'nlab so'rov ketardi va hammasi 401 olardi.
     * Har bunday to'lqin — yangilash uchun qo'shimcha imkoniyat, refresh
     * token esa AYLANADI (eskisi darhol o'ladi), ya'ni har ortiqcha urinish
     * sessiyani yo'qotish xavfi.
     *
     * Endi muddat tugashiga bir daqiqadan kam qolsa, so'rov ketishidan OLDIN
     * yangilanadi — bitta `_refreshing` completer'i hammasini birlashtiradi.
     *
     * `/auth/` yo'llari chetlab o'tiladi: login/OTP tokensiz ishlaydi.
     */
    final isAuthCall = options.path.contains('/auth/');
    if (!isAuthCall && token != null && _expiresSoon(token) && !_inCooldown) {
      token = await _refreshAccessToken() ?? token;
    }

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers.addAll(await DeviceInfo.headers());
    handler.next(options);
  }

  /// Token muddati [_refreshSkew] dan kam qoldimi.
  ///
  /// Muddatni o'qib bo'lmasa `false` — noma'lum tokenni "tugagan" deb
  /// hisoblab har so'rovda yangilash so'ramaymiz.
  static bool _expiresSoon(String token) {
    final exp = jwtExpiry(token);
    if (exp == null) return false;
    return exp.difference(DateTime.now()) < _refreshSkew;
  }



  /// Javobdagi HTML kodlarini ochadi (`Farg&#39;ona` -> `Farg'ona`).
  ///
  /// Nega SHU YERDA: backend saqlagan har qanday matn kodlangan qaytadi va
  /// uni har ekranda alohida ochish esdan chiqadi (ilgari faqat chatda
  /// ochilardi). Batafsil izoh — `format.dart` dagi `deepUnescape`.
  ///
  /// Faqat JSON (Map/List) tegiladi: fayl yuklash javoblari (`bytes`)
  /// o'zgarishsiz o'tadi.
  /// Offline aniqlanганда davriy "ping" boshlaydi (izoh `connected` da).
  void _startRecoveryProbe() {
    if (_recoveryTimer != null) return; // allaqachon ishlayapti
    _recoveryTimer = Timer.periodic(const Duration(seconds: 4), (_) => _probe());
  }

  /// Yengil so'rov: javob kelса (2xx YOKI status kodli xato) internet bor
  /// deb belgilaymiz. FAQAT ulanish xatosi (yetib bormaslik) offline.
  /// `_plain` — interceptorsiz, aks holda 401 refresh zanjiri ishga tushardi.
  Future<void> _probe() async {
    try {
      await _plain.get<dynamic>(
        '/notifications/vapid-key',
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      connected.value = true;
    } on DioException catch (e) {
      if (e.response != null) connected.value = true; // server javob berdi
      // aks holda hali offline — taymer keyingi urinishни qiladi
    } catch (_) {
      // e'tiborsiz
    }
    if (connected.value) {
      _recoveryTimer?.cancel();
      _recoveryTimer = null;
    }
  }

  void _onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    connected.value = true; // javob keldi — internet bor
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
    final data = response.data;
    if (data is Map || data is List) {
      response.data = deepUnescape(data);
    }
    handler.next(response);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    // Ulanish xatosi (so'rov backendga UMUMAN yetmadi) = internet yo'q.
    // Status kodli javob (hatto 5xx) = internet bor, server javob berdi.
    const offlineTypes = {
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    };
    if (error.response == null && offlineTypes.contains(error.type)) {
      connected.value = false;
      _startRecoveryProbe();
    } else if (error.response != null) {
      // Server JAVOB BERDI (hatto 4xx/5xx) — internet bor, banner yo'qolsin.
      connected.value = true;
      _recoveryTimer?.cancel();
      _recoveryTimer = null;
    }

    final request = error.requestOptions;
    final isUnauthorized = error.response?.statusCode == 401;
    final alreadyRetried = request.extra['_retry'] == true;
    final isRefreshCall = request.path.contains('/auth/refresh');

    if (!isUnauthorized || alreadyRetried || isRefreshCall || _inCooldown) {
      return handler.next(error);
    }

    final token = await _refreshAccessToken();
    if (token == null) return handler.next(error);

    request.extra['_retry'] = true;
    request.headers['Authorization'] = 'Bearer $token';
    try {
      handler.resolve(await dio.fetch(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Bir vaqtda faqat BITTA refresh — qolgan so'rovlar shu future'ni kutadi.
  Future<String?> _refreshAccessToken() {
    final inFlight = _refreshing;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<String?>();
    _refreshing = completer;
    _performRefresh().then((token) {
      _refreshing = null;
      completer.complete(token);
    });
    return completer.future;
  }

  Future<String?> _performRefresh() async {
    final refreshToken = tokens.refresh;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _hardLogout();
      return null;
    }

    try {
      // `_plain` interceptorsiz — qurilma headerlarini bu yerda O'ZIMIZ qo'yamiz:
      // refresh sessiyaga bog'langan, sessiya esa `device_id` bilan ochilgan.
      final res = await _plain.post<dynamic>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(headers: await DeviceInfo.headers()),
      );
      final body = asMap(unwrap(res.data));
      final access = body?['access_token'] as String?;
      if (access == null || access.isEmpty) {
        throw StateError('refresh javobida access_token yo\'q');
      }
      await tokens.save(
        access: access,
        refresh: (body?['refresh_token'] as String?) ?? refreshToken,
      );
      return access;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 400 || status == 401 || status == 403) {
        /*
         * 🔴 DARHOL CHIQARIB YUBORMAYMIZ (2026-08-27, egasi: «yangilanishdan
         * keyin hammani loginga tepvoryapti»).
         *
         * O'LCHANDI: backend refresh tokenni AYLANTIRADI va eskisi
         * DARHOL o'ladi — imtiyoz oynasi YO'Q:
         *     A bilan yangilash  -> 200 (yangi B)
         *     A ni qayta ishlatish -> 401 «invalid or expired session»
         *
         * Ya'ni bizda qo'lda turgan token allaqachon almashtirilgan
         * bo'lishi mumkin: boshqa oqim ulgurgan yoki oldingi urinish
         * javobi kelib, biz uni O'QIB ULGURMAGANMIZ. Bu «sessiya o'ldi»
         * degani EMAS, «kechikdik» degani.
         *
         * Shuning uchun saqlangan tokenni QAYTA o'qiymiz: u biz
         * yuborganidan farq qilsa — bir marta shuning bilan urinamiz.
         * Saytda bu himoya 2026-08-24 dan beri bor edi, ilovada esa
         * TUSHIB QOLGAN edi.
         */
        final latest = tokens.refresh;
        if (latest != null && latest.isNotEmpty && latest != refreshToken) {
          try {
            final res2 = await _plain.post<dynamic>(
              '/auth/refresh',
              data: {'refresh_token': latest},
            );
            final body2 = asMap(unwrap(res2.data));
            final access2 = body2?['access_token'] as String?;
            if (access2 != null && access2.isNotEmpty) {
              await tokens.save(
                access: access2,
                refresh: (body2?['refresh_token'] as String?) ?? latest,
              );
              return access2;
            }
          } catch (_) {
            /* ikkinchi urinish ham yiqildi — sessiya rostdan o'lgan */
          }
        }
        await _hardLogout();
      } else {
        // Tarmoq/5xx — token hali yaroqli bo'lishi mumkin, sessiyani saqlaymiz.
        _cooldownUntil = DateTime.now().add(const Duration(seconds: 10));
      }
      return null;
    } catch (_) {
      /*
       * 🔴 KUTILMAGAN XATODA CHIQARMAYMIZ (2026-08-27).
       *
       * Ilgari bu yerda ham `_hardLogout()` turardi. Ya'ni javob shakli
       * biz kutganidan farq qilsa (masalan backend maydonni o'rab
       * yuborsa) yoki JSON tahlili yiqilsa — HAMMA foydalanuvchi
       * loginga uchardi. Bu server xatosi uchun eng og'ir jazо edi.
       *
       * Token bunday holatda YAROQLI bo'lishi mumkin, shuning uchun
       * sessiya saqlanadi va biroz kutamiz (tarmoq xatosi bilan bir xil
       * muomala).
       */
      _cooldownUntil = DateTime.now().add(const Duration(seconds: 10));
      return null;
    }
  }

  Future<void> _hardLogout() async {
    await tokens.clear();
    onSessionExpired?.call();
  }
}
