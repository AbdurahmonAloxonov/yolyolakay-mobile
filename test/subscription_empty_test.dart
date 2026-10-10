import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/core/api/api_client.dart';
import 'package:yolyolakay/core/api/api_exception.dart';
import 'package:yolyolakay/core/api/token_storage.dart';
import 'package:yolyolakay/data/repositories/billing_repository.dart';

/// OBUNA YO'Q — bu XATO EMAS.
///
/// Backend xati (2026-08-14): ilgari obunasi yo'q foydalanuvchiga
/// `GET /billing/subscription` **404** qaytarardi va yangi odam tariflar
/// sahifasida qizil "Joriy tarifingizni aniqlab bo'lmadi" bannerini
/// ko'rardi. Endi backend **200 + bo'sh tana** qaytaradi.
///
/// Ikkala shakl ham qo'llab-quvvatlanishi kerak: eski javob keshda yoki
/// eski gateway'da qolishi mumkin.
///
/// 🔴 Va eng muhimi: 502/tarmoq xatosi `null` ga AYLANMASLIGI kerak —
/// aks holda uzilish "sizda tarif yo'q" bo'lib ko'rinadi va odam ikkinchi
/// marta to'lab yuborishi mumkin.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  BillingRepository repo(int status, dynamic body) {
    final client = ApiClient(tokens: TokenStorage());
    client.dio.httpClientAdapter = _StubAdapter(status, body);
    return BillingRepository(client);
  }

  test('200 + null tana -> obuna yo\'q (xato emas)', () async {
    expect(await repo(200, null).subscription(), isNull);
  });

  test('200 + bo\'sh obyekt -> obuna yo\'q', () async {
    expect(await repo(200, {}).subscription(), isNull);
  });

  test('404 -> obuna yo\'q (eski shakl)', () async {
    expect(await repo(404, {'error': 'not found'}).subscription(), isNull);
  });

  test('obuna bor -> o\'qiladi', () async {
    final sub = await repo(200, {
      'plan_name': 'pro',
      'status': 'active',
      'rides_left': 5,
    }).subscription();

    expect(sub, isNotNull);
    expect(sub!.planKey, 'pro');
    expect(sub.ridesLeft, 5);
  });

  test('502 -> XATO otiladi, "obuna yo\'q" DEB YUTILMAYDI', () async {
    await expectLater(
      repo(502, {'error': 'bad gateway'}).subscription(),
      throwsA(isA<ApiException>()),
    );
  });
}

/// Belgilangan holat va tanani qaytaradi.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.status, this.body);

  final int status;
  final dynamic body;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    body == null ? 'null' : _encode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  static String _encode(dynamic value) {
    if (value is Map) {
      final parts = value.entries.map((e) {
        final v = e.value;
        final encoded = v is String ? '"$v"' : '$v';
        return '"${e.key}":$encoded';
      });
      return '{${parts.join(',')}}';
    }
    return '$value';
  }
}
