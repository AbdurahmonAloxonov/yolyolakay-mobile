import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/core/local_cache.dart';

/// PROFIL UZILISHDA — oxirgi ma'lum holat ko'rsatiladi, lekin YOLG'ON
/// aytilmaydi (`core/local_cache.dart` dagi ikki qat'iy qoida).
void main() {
  late SharedPreferences prefs;
  late LocalCache cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    cache = LocalCache(prefs);
  });

  test('bitta obyekt saqlanadi va qaytariladi', () async {
    await cache.writeMap(CacheKeys.me, {
      'id': 'u-1',
      'first_name': 'Aziz',
      'role': 'driver',
    });

    final back = cache.readMap(CacheKeys.me);
    expect(back?['first_name'], 'Aziz');
    expect(back?['role'], 'driver');
  });

  test('vaqt tamg\'asi yoziladi — «qachonligi» ekranда aytiladi', () async {
    await cache.writeMap(CacheKeys.me, const {'id': 'u-1'});
    expect(cache.cachedAt(CacheKeys.me), isNotNull);
  });

  test('kesh bo\'sh bo\'lsa null (yolg\'on profil yasalmaydi)', () {
    expect(cache.readMap(CacheKeys.me), isNull);
  });

  test('buzilgan yozuv ilovani yiqitmaydi', () async {
    await prefs.setString('cache_${CacheKeys.me}', 'bu json emas');
    expect(cache.readMap(CacheKeys.me), isNull);
  });

  /// 🔴 ENG MUHIM QOIDA: status kodli javob (401/403/500) ULANISH xatosi
  /// EMAS. Bunda keshdan ko'rsatish yolg'on bo'lardi — server bizga aniq
  /// bir narsa aytyapti.
  test('server javob bergan bo\'lsa keshdan berilmaydi', () {
    final withResponse = DioException(
      requestOptions: RequestOptions(path: '/users/me'),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/users/me'),
        statusCode: 401,
      ),
      type: DioExceptionType.badResponse,
    );
    expect(isOfflineError(withResponse), isFalse);

    final noConnection = DioException(
      requestOptions: RequestOptions(path: '/users/me'),
      type: DioExceptionType.connectionError,
    );
    expect(isOfflineError(noConnection), isTrue);
  });
}
