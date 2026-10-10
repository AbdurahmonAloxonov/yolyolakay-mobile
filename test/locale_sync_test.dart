import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/core/api/api_client.dart';
import 'package:yolyolakay/core/api/token_storage.dart';
import 'package:yolyolakay/data/repositories/users_repository.dart';

/// So'rovni ushlab qoladigan soxta adapter — tarmoqqa chiqmaydi.
class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString(
      jsonEncode({'data': <String, dynamic>{}}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// INTERFEYS TILI SERVERGA YETIB BORADIMI.
///
/// 🔴 NEGA (2026-08-28): server push va boshqa matnlarni foydalanuvchining
/// `locale` maydoniga qarab tanlaydi. Ilova uni HECH QACHON yubormasdi —
/// faqat push tokeniga `language` qo'shardi. Natijada yangi hisobning
/// `locale` i `ru` bo'lib qolar va tokendan OLDIN yaratilgan xabar
/// (masalan «sinov davri boshlandi») ruscha kelardi. Saytda bu allaqachon
/// bor edi — ya'ni ikki mijoz bir xil ishlamasdi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('til `PUT /users/profile` ga FAQAT `locale` bo\'lib ketadi', () async {
    final adapter = _RecordingAdapter();
    final client = ApiClient(tokens: TokenStorage());
    client.dio.httpClientAdapter = adapter;

    await UsersRepository(client).saveLocale(locale: 'uz');

    final req = adapter.captured!;
    expect(req.method, 'PUT');
    expect(req.path, '/users/profile');

    final body = req.data as Map<String, dynamic>;
    expect(body['locale'], 'uz');

    // 🔴 ISM YUBORILMASIN: bizdagi nusxa eskirgan bo'lishi mumkin (odam
    // uni boshqa qurilmada o'zgartirgan) va til almashtirish jimgina
    // eski ismni qaytarib qo'yardi. Backend 2026-08-28 dan qisman
    // yangilashni qabul qiladi — jonli o'lchandi.
    expect(
      body.containsKey('first_name'),
      isFalse,
      reason: 'ism yuborilsa eskirgan nusxa serverdagini bosib ketadi',
    );
    expect(body.containsKey('last_name'), isFalse);
  });
}
