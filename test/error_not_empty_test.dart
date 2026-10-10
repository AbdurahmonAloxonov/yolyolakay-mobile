import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/api/api_client.dart';
import 'package:yolyolakay/core/api/token_storage.dart';
import 'package:yolyolakay/core/api/api_exception.dart';
import 'package:yolyolakay/data/repositories/auth_repository.dart';
import 'package:yolyolakay/data/repositories/notifications_repository.dart';
import 'package:yolyolakay/data/repositories/rides_repository.dart';

/// UZILISH — "MA'LUMOT YO'Q" DEGANI EMAS.
///
/// 🔴 Egasi qurilmada topdi (2026-08-13): server o'chganda "Safarlarim"
/// ekrani "Hali bron yo'q" deb ko'rsatardi. Sabab — repozitoriy tarmoq
/// xatosini yutib, bo'sh ro'yxat qaytarardi; ekrandagi xato holati esa
/// hech qachon ishga tushmasdi (o'lik kod).
///
/// Oqibati jiddiy: broni bor yo'lovchi uni yo'qolgan deb o'ylaydi va qayta
/// bron qiladi; haydovchi esa e'loni yo'q deb ikkinchisini joylaydi.
///
/// Shu sabab bu ro'yxatdagi HAR BIR chaqiruv xatoni yuqoriga UZATISHI shart.
void main() {
  _cloudflareTests();

  /// Har so'rovga tarmoq xatosi qaytaradigan mijoz — server o'chgan holat.
  ///
  /// Haqiqiy `ApiClient` quriladi (interceptorlari bilan), faqat tarmoq
  /// qatlami almashtiriladi: shunda sinov haqiqiy yo'ldan o'tadi.
  ApiClient failingClient() {
    final client = ApiClient(tokens: TokenStorage());
    client.dio.httpClientAdapter = _AlwaysFailsAdapter();
    return client;
  }

  group('tarmoq xatosi bo\'sh ro\'yxatga aylanmaydi', () {
    test('bronlarim', () async {
      final repo = RidesRepository(failingClient());
      await expectLater(repo.myBookings(), throwsA(isA<ApiException>()));
    });

    test('safarlarim (haydovchi)', () async {
      final repo = RidesRepository(failingClient());
      await expectLater(repo.myRides(), throwsA(isA<ApiException>()));
    });

    test('kirilgan qurilmalar', () async {
      final repo = AuthRepository(failingClient(), TokenStorage());
      await expectLater(repo.sessions(), throwsA(isA<ApiException>()));
    });

    test('bildirishnomalar', () async {
      final repo = NotificationsRepository(failingClient());
      await expectLater(repo.list(), throwsA(isA<ApiException>()));
    });

    test('yozishma tarixi', () async {
      final repo = NotificationsRepository(failingClient());
      await expectLater(
        repo.history(myId: 'a', peerId: 'b'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

/// Har qanday so'rovga ulanish xatosi beradi — server o'chgan holat.
class _AlwaysFailsAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'server o\'chiq',
    );
  }
}

/// Cloudflare kodlari (520-530) — "bizning server o'chiq" degani.
///
/// 🔴 Telefonda ko'rildi (2026-08-13): server 530 qaytarardi va ilova
/// "Tizimda xatolik yuz berdi" degan tushunarsiz matnni ko'rsatardi.
void _cloudflareTests() {
  ApiException fromStatus(int status) => ApiException.from(
    DioException(
      requestOptions: RequestOptions(path: '/x'),
      response: Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: status,
      ),
    ),
  );

  group('server o\'chganda tushunarli matn', () {
    test('530 va qo\'shnilari "server javob bermayapti" deb tanaladi', () {
      for (final status in [502, 503, 504, 520, 521, 522, 523, 524, 530]) {
        expect(
          fromStatus(status).kind,
          ApiErrorKind.serverUnavailable,
          reason: '$status',
        );
      }
    });

    test('boshqa 5xx umumiy xato bo\'lib qoladi', () {
      expect(fromStatus(500).kind, ApiErrorKind.server);
    });
  });
}
