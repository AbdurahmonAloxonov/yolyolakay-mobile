import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/core/api/api_client.dart';
import 'package:yolyolakay/core/api/api_exception.dart';
import 'package:yolyolakay/core/api/token_storage.dart';
import 'package:yolyolakay/data/repositories/auth_repository.dart';

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
      jsonEncode({
        'data': {'access_token': 'a', 'refresh_token': 'r'},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Berilgan status/tanani qaytaradi — xato oqimlarini tekshirish uchun.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.status, this.body);

  final int status;
  final Map<String, dynamic> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('verify-otp device_fingerprint ni TANADA ham yuboradi', () async {
    final adapter = _RecordingAdapter();
    final client = ApiClient(tokens: TokenStorage());
    client.dio.httpClientAdapter = adapter;

    await AuthRepository(
      client,
      TokenStorage(),
    ).verifyOtp('+998990000000', '11111');

    final body = adapter.captured!.data as Map<String, dynamic>;

    // ⚠ Backendning ikki avlodi ikki xil joyni kutadi: monolit tanadagi
    // `device_fingerprint` ni MAJBURIY deb biladi (`400 invalid payload`),
    // deploy qilingan gateway esa headerdan oladi. Ikkalasi ham bo'lishi shart.
    expect(body['device_fingerprint'], isNotEmpty);
    expect(body['phone_number'], '+998990000000');
    expect(body['code'], '11111');
    expect(adapter.captured!.headers['X-Device-ID'], isNotNull);
    expect(adapter.captured!.headers['X-OS-Type'], isNotNull);

    // Bir xil qurilma — header va tanadagi qiymat AJRALMASLIGI kerak,
    // aks holda sessiyalar ro'yxatida ikkita yozuv paydo bo'lardi.
    expect(
      body['device_fingerprint'],
      adapter.captured!.headers['X-Device-ID'],
    );
  });

  test('parol bilan kirish ham device_fingerprint yuboradi', () async {
    final adapter = _RecordingAdapter();
    final client = ApiClient(tokens: TokenStorage());
    client.dio.httpClientAdapter = adapter;

    await AuthRepository(
      client,
      TokenStorage(),
    ).loginWithPassword('+998990000000', 'parol123');

    final body = adapter.captured!.data as Map<String, dynamic>;
    expect(body['device_fingerprint'], isNotEmpty);
    expect(body['password'], 'parol123');
  });

  // 🔴 Backend hisoboti 2026-08-09: `send-otp` qurilma headersiz ketardi va shu
  // sabab har kirish "yangi qurilma" bo'lib ko'rinardi. Header endi
  // `ApiClient` interceptor'ida — HAR so'rovda. Bu test o'sha regressiyani qo'riqlaydi.
  test('send-otp ham X-Device-ID yuboradi', () async {
    final adapter = _RecordingAdapter();
    final client = ApiClient(tokens: TokenStorage());
    client.dio.httpClientAdapter = adapter;

    await AuthRepository(client, TokenStorage()).sendOtp('+998990000000');

    expect(adapter.captured!.path, contains('/auth/send-otp'));
    expect(adapter.captured!.headers['X-Device-ID'], isNotNull);
    expect(adapter.captured!.headers['X-OS-Type'], isNotNull);
  });

  test('login 403 new_device — xato emas, NewDeviceException', () async {
    final client = ApiClient(tokens: TokenStorage());
    client.dio.httpClientAdapter = _StubAdapter(403, {
      'error': 'new_device',
      'message': 'Новое устройство. СМС-код успешно отправлен.',
    });

    await expectLater(
      AuthRepository(
        client,
        TokenStorage(),
      ).loginWithPassword('+998990000000', 'parol123'),
      throwsA(isA<NewDeviceException>()),
    );
  });

  // Swaggerda `/auth/login` uchun 403 javobi erkin `map[string]string`, aniq
  // `new_device` kaliti u yerda YO'Q (faqat backend xatida aytilgan) — kalit
  // o'zgarsa ham foydalanuvchi yolg'on "parol noto'g'ri" xatosiga tushmasin.
  test('403 matn bo\'yicha ham new_device deb tanilади', () async {
    final client = ApiClient(tokens: TokenStorage());
    client.dio.httpClientAdapter = _StubAdapter(403, {
      'error': 'forbidden',
      'message': 'New device detected, OTP required',
    });

    await expectLater(
      AuthRepository(
        client,
        TokenStorage(),
      ).loginWithPassword('+998990000000', 'parol123'),
      throwsA(isA<NewDeviceException>()),
    );
  });

  // 🔴 Tuzoq: `new_device_sms_failed` ham `new_device` bilan boshlanadi. Matn
  // bo'yicha zaxira tekshiruv uni "kod yuborildi" deb qabul qilsa, odam
  // KELMAYDIGAN kodni kutib qolardi — aynan biz oldini olmoqchi bo'lgan holat.
  test('new_device_sms_failed new_device deb QABUL QILINMAYDI', () async {
    for (final status in [403, 429]) {
      final client = ApiClient(tokens: TokenStorage());
      client.dio.httpClientAdapter = _StubAdapter(status, {
        'error': 'new_device_sms_failed',
        'message': 'СМС-код не отправлен',
      });

      await expectLater(
        AuthRepository(
          client,
          TokenStorage(),
        ).loginWithPassword('+998990000000', 'parol123'),
        throwsA(
          isA<SmsNotSentException>().having(
            (e) => e is NewDeviceException,
            'NewDevice emas',
            isFalse,
          ),
        ),
        reason: 'status $status',
      );
    }
  });

  test('423 — hisob bloklangan, alohida tur', () async {
    final client = ApiClient(tokens: TokenStorage());
    client.dio.httpClientAdapter = _StubAdapter(423, {
      'error': 'account locked',
    });

    await expectLater(
      AuthRepository(
        client,
        TokenStorage(),
      ).loginWithPassword('+998990000000', 'parol123'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.kind,
          'kind',
          ApiErrorKind.accountLocked,
        ),
      ),
    );
  });

  test('boshqa 403 new_device deb talqin qilinmaydi', () async {
    final client = ApiClient(tokens: TokenStorage());
    client.dio.httpClientAdapter = _StubAdapter(403, {
      'error': 'account blocked',
    });

    await expectLater(
      AuthRepository(
        client,
        TokenStorage(),
      ).loginWithPassword('+998990000000', 'parol123'),
      throwsA(
        isA<ApiException>().having(
          (e) => e is NewDeviceException,
          'NewDeviceException emas',
          isFalse,
        ),
      ),
    );
  });
}
