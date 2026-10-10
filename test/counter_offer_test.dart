import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/core/api/api_client.dart';
import 'package:yolyolakay/core/api/token_storage.dart';
import 'package:yolyolakay/data/repositories/rides_repository.dart';

/// SAVDOLASHISH — haydovchi o'z narxini qaytaradi.
///
/// Egasi 2026-08-13 da so'radi: "haydovchi qaytarib jo'natolmayapti".
/// Saytda funksiya yozilgan-u bayroq bilan o'chirilgan edi (backend
/// endpointi yo'q edi), ilovada esa UMUMAN yo'q edi.
///
/// Bu sinov YO'L va TANA to'g'riligini qo'riqlaydi: ikkalasi ham backend
/// kontraktidan (`http.CounterBookingRequest`, majburiy `new_price`).
void main() {
  // `ApiClient` har so'rovga qurilma headerlarini qo'shadi, ular esa
  // `SharedPreferences` dan o'qiladi — usiz so'rov adapterga YETIB BORMAYDI.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('to\'g\'ri yo\'lga new_price yuboradi', () async {
    RequestOptions? sent;

    final client = ApiClient(tokens: TokenStorage());
    client.dio.httpClientAdapter = _CapturingAdapter(
      (options) => sent = options,
    );

    await RidesRepository(client).counterOffer('ride-1', 'booking-2', 55000);

    expect(sent, isNotNull);
    expect(sent!.path, '/rides/ride-1/bookings/booking-2/counter');
    expect(sent!.method, 'POST');
    // Maydon nomi AYNAN `new_price` — backend boshqasini qabul qilmaydi.
    expect(sent!.data, {'new_price': 55000.0});
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
