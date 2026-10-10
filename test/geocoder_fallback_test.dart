import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/geocoder.dart';

/// GEOKODER ZAXIRASI — Nominatim yiqilsa manzil qidiruv O'LMASINMI?
///
/// 🔴 NEGA YOZILDI (18.09.2026): manzil kiritish butunlay Nominatim'ning
/// BEPUL jamoat serveriga bog'liq edi (soniyasiga 1 so'rov, istagan
/// paytda bloklashi mumkin). U o'lsa — safar yaratish ham, posilka
/// yuborish ham to'xtaydi. Endi backendimizdagi `GET /routing/geocode`
/// zaxira bo'lib turadi.
///
/// 🔑 SINOV AYNAN SHU HOLATNI O'LCHAYDI: zaxira faqat Nominatim
/// yiqilganda ishlaydi va uni qo'lda sinab ko'rib bo'lmaydi (Nominatim
/// bizni bloklashini kutib o'tirmaymiz). Shuning uchun tashqi manba
/// ATAYIN yiqitiladi.
///
/// ⚠️ Javob SHAKLI ham tekshiriladi: bizning backend koordinatani
/// ICHKI obyektda beradi (`coordinate:{latitude,longitude}`), Nominatim
/// esa tekis `lat`/`lon` da. Shakli xato o'qilsa zaxira «ishladi» deb
/// ko'rinib, ro'yxat JIMGINA bo'sh chiqardi.
void main() {
  /// Bizning gateway o'rniga javob beradigan qo'g'irchoq.
  Dio fakeApi({
    required dynamic geocode,
    dynamic reverse,
    bool fail = false,
  }) {
    final dio = Dio();
    dio.httpClientAdapter = _StubAdapter((path) {
      if (fail) throw DioException(requestOptions: RequestOptions(path: path));
      if (path.contains('reverse-geocode')) return reverse;
      return geocode;
    });
    return dio;
  }

  group('Zaxira geokoder', () {
    test('Nominatim yiqilsa BIZNING javob o\'qiladi', () async {
      // Jonli o'lchangan shakl (18.09.2026).
      final g = Geocoder(
        api: fakeApi(
          geocode: [
            {
              'display_name': 'Самарканд, Самаркандская область, Узбекистан',
              'coordinate': {'latitude': 39.6550017, 'longitude': 66.9756954},
            },
          ],
        ),
      );
      // Nominatim'ga chiqa olmaymiz (sinovda tarmoq yo'q) — ya'ni bu
      // AYNAN «tashqi manba yiqildi» holati.
      final rows = await g.search('Samarqand');
      expect(rows, hasLength(1));
      expect(rows.first.lat, closeTo(39.655, 0.001));
      expect(rows.first.lon, closeTo(66.9757, 0.001));
      // Nom — to'liq manzilning birinchi bo'lagi (kartaga sig'sin).
      expect(rows.first.name, 'Самарканд');
      expect(rows.first.detail, contains('Самаркандская'));
    });

    test('koordinata ICHKI obyektda — tekis lat/lon o\'qilmaydi', () {
      // Nominatim shakli bizning parser'ga berilsa `null` qaytishi kerak:
      // aks holda ikkala shakl aralashib, xato koordinata chiqardi.
      final wrong = GeoResult.fromOurs({
        'display_name': 'Samarqand',
        'lat': '39.65',
        'lon': '66.97',
      });
      expect(wrong, isNull);
    });

    test('bo\'sh yoki nuqson javob — bo\'sh ro\'yxat, xato EMAS', () async {
      final g = Geocoder(api: fakeApi(geocode: const []));
      expect(await g.search('Samarqand'), isEmpty);

      final broken = Geocoder(
        api: fakeApi(
          geocode: [
            {'display_name': 'Yo\'q joy'}, // koordinatasiz
            {'coordinate': {'latitude': 1.0, 'longitude': 2.0}}, // nomsiz
          ],
        ),
      );
      expect(await broken.search('Samarqand'), isEmpty);
    });

    test('zaxira ham yiqilsa qidiruv XATO TASHLAMAYDI', () async {
      final g = Geocoder(api: fakeApi(geocode: null, fail: true));
      expect(await g.search('Samarqand'), isEmpty);
    });

    test('zaxira YO\'Q bo\'lsa ham ishlaydi (eski xulq)', () async {
      final g = Geocoder();
      expect(await g.search('Samarqand'), isEmpty);
    });

    test('qisqa so\'rov umuman yuborilmaydi', () async {
      var called = false;
      final dio = Dio();
      dio.httpClientAdapter = _StubAdapter((_) {
        called = true;
        return const [];
      });
      final g = Geocoder(api: dio);
      expect(await g.search('Sa'), isEmpty);
      expect(called, isFalse, reason: 'ikki harfda so\'rov ketmasligi kerak');
    });

    test('teskari geokod: ma\'lum shahar YAQIN bo\'lsa tashqariga chiqmaydi',
        () async {
      var called = false;
      final dio = Dio();
      dio.httpClientAdapter = _StubAdapter((_) {
        called = true;
        return const {};
      });
      final g = Geocoder(api: dio);
      // Toshkent markazi — curated ro'yxatda bor.
      final name = await g.reverse(41.2995, 69.2401);
      expect(name, isNotNull);
      expect(
        called,
        isFalse,
        reason: 'curated ro\'yxat USTUN — izohi `geocoder.dart` da',
      );
    });
  });
}

/// Tarmoqqa chiqmaydigan adapter — javobni funksiya beradi.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.respond);

  final dynamic Function(String path) respond;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = respond(options.path);
    return ResponseBody.fromString(
      _encode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  static String _encode(dynamic body) {
    if (body == null) return 'null';
    return const JsonEncoderShim().convert(body);
  }
}

/// `dart:convert` ni sinovga olib kirmaslik uchun kichik o'rovchi.
class JsonEncoderShim {
  const JsonEncoderShim();
  String convert(dynamic value) => _json(value);

  static String _json(dynamic v) {
    if (v is String) return '"${v.replaceAll('"', r'\"')}"';
    if (v is num || v is bool) return '$v';
    if (v == null) return 'null';
    if (v is List) return '[${v.map(_json).join(',')}]';
    if (v is Map) {
      return '{${v.entries.map((e) => '${_json('${e.key}')}:${_json(e.value)}').join(',')}}';
    }
    return '"$v"';
  }
}
