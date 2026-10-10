import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/core/api/api_client.dart';
import 'package:yolyolakay/core/api/token_storage.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/data/repositories/rides_repository.dart';

/// «FAQAT AYOLLAR» QIDIRUVI — server tomonining ikki xususiyati.
///
/// Ikkalasi ham 08.09.2026 da JONLI o'lchangan (prod, 5 daqiqa, har
/// 60 soniyada bir so'rov):
///
///  1. Cheklovli safar parametrsiz javobga UMUMAN kirmaydi — 6 ta
///     so'rovning hech birida chiqmadi. Ya'ni parametr yuborilishi SHART.
///  2. Parametr bilan javob BEQAROR: navbatma-navbat 6 ta va 0 ta
///     bo'lib keldi (bir xil so'rov, bir xil ma'lumot).
///
/// Ikkinchisi tuzalguncha mijoz bo'sh javobda BIR marta qayta so'raydi.
/// Bu sinov aynan shu ikki xatti-harakatni qo'riqlaydi — backend
/// tuzatgach, qayta urinish olib tashlanadi va shu sinov ham o'zgaradi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  RideSearchParams params({bool womenOnly = false}) => RideSearchParams(
    originLat: 41.2995,
    originLon: 69.2401,
    destLat: 39.6542,
    destLon: 66.9597,
    womenOnly: womenOnly,
  );

  test('filtr yoqilganda gender_restriction=female yuboriladi', () async {
    final paths = <String>[];
    final client = ApiClient(tokens: TokenStorage());
    client.dio.httpClientAdapter = _ScriptedAdapter(
      onRequest: (o) => paths.add(o.uri.toString()),
      bodies: ['{"rides":[]}', '{"rides":[]}'],
    );

    await RidesRepository(client).search(params(womenOnly: true));

    expect(paths.first, contains('gender_restriction=female'));
  });

  test('filtr yoqilmagan — parametr UMUMAN yuborilmaydi', () async {
    final paths = <String>[];
    final client = ApiClient(tokens: TokenStorage());
    client.dio.httpClientAdapter = _ScriptedAdapter(
      onRequest: (o) => paths.add(o.uri.toString()),
      bodies: ['{"rides":[]}'],
    );

    await RidesRepository(client).search(params());

    expect(paths.single, isNot(contains('gender_restriction')));
  });

  test('bo\'sh javobdan keyin BIR marta qayta so\'raydi', () async {
    var calls = 0;
    final client = ApiClient(tokens: TokenStorage());
    client.dio.httpClientAdapter = _ScriptedAdapter(
      onRequest: (_) => calls++,
      // Serverning aynan o'sha xatti-harakati: avval bo'sh, keyin to'la.
      bodies: [
        '{"rides":[]}',
        '{"rides":[{"id":"r-1","origin_address":"Toshkent",'
            '"destination_address":"Samarqand","total_seats":4,'
            '"available_seats":3,"price_per_seat":150000,"status":"active",'
            '"gender_restriction":"female"}]}',
      ],
    );

    final rides = await RidesRepository(client).search(params(womenOnly: true));

    expect(calls, 2);
    expect(rides, hasLength(1));
    expect(rides.single.genderRestriction, 'female');
  });

  test('oddiy qidiruvda bo\'sh javob QAYTA so\'ralmaydi', () async {
    var calls = 0;
    final client = ApiClient(tokens: TokenStorage());
    client.dio.httpClientAdapter = _ScriptedAdapter(
      onRequest: (_) => calls++,
      bodies: ['{"rides":[]}', '{"rides":[]}'],
    );

    // Bo'sh natija bu yerda ROST javob bo'lishi mumkin — takroriy so'rov
    // shunchaki tarmoqni ikki barobar yeydi.
    await RidesRepository(client).search(params());

    expect(calls, 1);
  });
}

/// Har chaqiruvda navbatdagi tanani qaytaradi (ro'yxat tugasa — oxirgisi).
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter({required this.onRequest, required this.bodies});

  final void Function(RequestOptions) onRequest;
  final List<String> bodies;
  int _i = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onRequest(options);
    final body = bodies[_i < bodies.length ? _i : bodies.length - 1];
    _i++;
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
