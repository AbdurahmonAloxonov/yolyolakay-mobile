import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/core/api/api_client.dart';
import 'package:yolyolakay/core/api/token_storage.dart';
import 'package:yolyolakay/core/cities.dart';
import 'package:yolyolakay/data/repositories/parcels_repository.dart';

/// POCHTA OQIMI — haydovchi posilkani qanday oladi.
///
/// Ikki xato 2026-08-13 da jonli o'lchov bilan aniqlandi:
///
///   1. Qidiruvga KILOMETR yuborilardi, backend esa `radius` ni METRDA
///      o'qiydi. Ekranda "25 km" tursa ham serverga 25 metr ketardi va
///      haydovchi deyarli hech qachon posilka topmasdi.
///      (jonli: radius=25 va 1000 — bo'sh, 5000 — 4 ta posilka)
///
///   2. Haydovchi `POST /parcels/{id}/accept` bilan posilkani jo'natuvchidan
///      SO'RAMASDAN o'ziga biriktirib olardi. To'g'ri oqim — taklif berish:
///      jo'natuvchi takliflarni ko'radi va o'zi tanlaydi (saytda ham,
///      jo'natuvchi ekranida ham aynan shu kutiladi).
void main() {
  // `ApiClient` har so'rovga qurilma headerlarini qo'shadi (SharedPreferences).
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ({ApiClient client, List<RequestOptions> sent}) capturing() {
    final sent = <RequestOptions>[];
    final client = ApiClient(tokens: TokenStorage());
    client.dio.httpClientAdapter = _CapturingAdapter(sent.add);
    return (client: client, sent: sent);
  }

  group('qidiruv radiusi', () {
    test('kilometr METRGA aylantirib yuboriladi', () async {
      final c = capturing();
      await ParcelsRepository(c.client).search(lat: 41.3, lon: 69.2);

      final q = c.sent.single.queryParameters;
      // 25 km -> 25 000 metr. Ilgari shu yerga 25 ketardi.
      expect(q['radius'], 25000.0);
      expect(q['lat'], 41.3);
      expect(q['lon'], 69.2);
    });

    test('tanlangan radius ham metrda ketadi', () async {
      final c = capturing();
      await ParcelsRepository(
        c.client,
      ).search(lat: 41.3, lon: 69.2, radiusKm: 5);
      expect(c.sent.single.queryParameters['radius'], 5000.0);
    });

    test('`driver_id` YUBORILMAYDI — kim qidirayotgani tokendan', () async {
      final c = capturing();
      await ParcelsRepository(c.client).search(lat: 41.3, lon: 69.2);
      expect(c.sent.single.queryParameters.containsKey('driver_id'), isFalse);
    });
  });

  group('haydovchi taklifi', () {
    test('to\'g\'ri yo\'lga offered_price yuboradi', () async {
      final c = capturing();
      await ParcelsRepository(c.client).respond('p-1', 45000);

      final req = c.sent.single;
      expect(req.path, '/parcels/p-1/respond');
      expect(req.method, 'POST');
      expect(req.data, {'offered_price': 45000.0});
    });
  });

  group('nuqta nomi', () {
    test('jo\'natuvchi yozgan MATN ustun', () {
      expect(
        placeLabel('Chilonzor 9-kvartal', 41.2995, 69.2401),
        'Chilonzor 9-kvartal',
      );
    });

    test('matn bo\'lmasa koordinatadan topiladi', () {
      // Toshkent markazi — eng yaqin joy nomi qaytishi kerak.
      expect(placeLabel(null, 41.2995, 69.2401), isNot('—'));
    });

    test('bo\'sh matn matn HISOBLANMAYDI', () {
      expect(placeLabel('   ', 41.2995, 69.2401), isNot('   '));
    });
  });
}

/// So'rovni ushlab, bo'sh 200 qaytaradi.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.onRequest);

  final void Function(RequestOptions) onRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onRequest(options);
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
