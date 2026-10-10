import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/core/local_cache.dart';

/// OFFLINE KESH.
///
/// 🔴 NEGA TEST: keshning eng xavfli tomoni — u JIM ishlaydi. Noto'g'ri
/// yozilgan kesh xato bermaydi, shunchaki odamga ESKI HAQIQATNI yangi
/// deb ko'rsatadi. Ikkita qoida aynan shu sababdan qo'riqlanadi:
///
///   1. faqat ULANISH xatosida eski ma'lumot beriladi — `403`/`500` da
///      server bizga aniq bir narsa aytyapti va uni yashirish yolg'on;
///   2. `cachedAt` yozilishi shart — usiz ekranda "qachonligi" ko'rsatib
///      bo'lmaydi va kesh aldovga aylanadi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalCache cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cache = LocalCache(await SharedPreferences.getInstance());
  });

  test('yozilgan ro\'yxat qaytib o\'qiladi', () async {
    await cache.writeList('k', [
      {'id': '1', 'name': 'Toshkent'},
      {'id': '2', 'name': 'Samarqand'},
    ]);

    final read = cache.readList('k');
    expect(read, hasLength(2));
    expect(read![1]['name'], 'Samarqand');
  });

  test('vaqt belgisi yoziladi', () async {
    expect(cache.cachedAt('k'), isNull);
    await cache.writeList('k', [
      {'id': '1'},
    ]);

    final at = cache.cachedAt('k');
    expect(at, isNotNull);
    expect(DateTime.now().difference(at!).inSeconds, lessThan(5));
  });

  test('yo\'q kalit — null (yiqilmaydi)', () {
    expect(cache.readList('yoq'), isNull);
    expect(cache.cachedAt('yoq'), isNull);
  });

  test('buzuq JSON — null, tashlamaydi', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cache_k', 'bu JSON emas {{{');
    expect(cache.readList('k'), isNull);
  });

  test('tozalash', () async {
    await cache.writeList('k', [
      {'id': '1'},
    ]);
    await cache.clear('k');
    expect(cache.readList('k'), isNull);
    expect(cache.cachedAt('k'), isNull);
  });

  group('isOfflineError — keshdan ko\'rsatish SHARTI', () {
    DioException of(DioExceptionType type, {Response<dynamic>? response}) =>
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: type,
          response: response,
        );

    test('ulanish xatosi — HA', () {
      expect(isOfflineError(of(DioExceptionType.connectionError)), isTrue);
      expect(isOfflineError(of(DioExceptionType.connectionTimeout)), isTrue);
      expect(isOfflineError(of(DioExceptionType.receiveTimeout)), isTrue);
    });

    /// 🔴 ENG MUHIM: server JAVOB BERGAN bo'lsa keshdan ko'rsatilmaydi.
    /// 403 da eski ro'yxatni chiqarish — "sizda hali ham ruxsat bor" deb
    /// aldash; 500 da esa nosozlikni yashirish.
    test('server javob bergan (403/500) — YO\'Q', () {
      for (final code in [400, 403, 404, 500, 502]) {
        final response = Response<dynamic>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: code,
        );
        expect(
          isOfflineError(
            of(DioExceptionType.badResponse, response: response),
          ),
          isFalse,
          reason: '$code da kesh ISHLATILMASLIGI kerak',
        );
      }
    });

    test('bekor qilingan so\'rov — YO\'Q', () {
      expect(isOfflineError(of(DioExceptionType.cancel)), isFalse);
    });
  });
}
