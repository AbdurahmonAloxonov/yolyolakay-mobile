import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/api/api_exception.dart';
import 'package:yolyolakay/data/repositories/rides_repository.dart';

/// PAKET TUGADI → TARIFLAR OCHILSIN.
///
/// 🔴 Bu yo'l 09.09.2026 gacha HECH QACHON ishga tushmagan: backend kvotani
/// sanamasdi va `POST /rides/{id}/activate` doim 200 berardi. O'sha kuni
/// sanay boshladi (`402 {"error":"payment required: insufficient ride
/// limits"}` — jonli o'lchandi) va ikkita jimgina yolg'on ochildi:
///
///   1. `isQuotaExceeded` HOLAT KODIni yetarli deb hisoblamasdi — inglizcha
///      matnda `quota`/`limit` so'zini ham talab qilardi. Backend jumlani
///      o'zgartirgan kuni paywall jimgina o'chib qolardi.
///   2. `isRetryable` faqat 400 ni istisno qilardi — ya'ni 402 da ham
///      «Qayta urinish» tugmasi chiqardi. U hech qachon ishlamaydi.
///
/// Shu ikkalasi shu yerda qotiriladi. (Tariflar ekraniga o'tishning o'zi
/// ekranda bir qator — u test bilan qoplanmagan, bu ATAYIN yozib qo'yildi.)
void main() {
  ApiException http(int code, {ApiErrorKind? kind, String? message}) =>
      ApiException(
        kind: kind ?? ApiErrorKind.unknown,
        statusCode: code,
        backendMessage: message,
      );

  group('ApiException.isQuotaExceeded', () {
    test('402 ning O\'ZI yetarli — matn talab qilinmaydi', () {
      // Backend matnsiz 402 qaytarsa ham paywall ochilishi SHART.
      expect(http(402).isQuotaExceeded, isTrue);
    });

    test('402 — jonli o\'lchangan HAQIQIY xabar bilan', () {
      expect(
        http(402, message: 'payment required: insufficient ride limits')
            .isQuotaExceeded,
        isTrue,
      );
    });

    test('402 — backend jumlani O\'ZGARTIRSA ham ishlaydi', () {
      // Aynan shu holat ilgari paywallni jimgina o'chirardi.
      expect(
        http(402, message: 'obuna muddati tugagan').isQuotaExceeded,
        isTrue,
      );
    });

    test('403 uchun matn tekshiruvi QOLADI', () {
      // 403 ko'p narsani bildiradi (masalan begona safarga tegish) —
      // hammasini paywall deb hisoblash noto'g'ri bo'lardi.
      expect(
        http(403, kind: ApiErrorKind.forbidden, message: 'ride limit reached')
            .isQuotaExceeded,
        isTrue,
      );
      expect(
        http(403, kind: ApiErrorKind.forbidden, message: 'not your ride')
            .isQuotaExceeded,
        isFalse,
      );
    });

    test('mashina tasdiqlanmagani (400) paywall EMAS', () {
      expect(
        http(
          400,
          kind: ApiErrorKind.badRequest,
          message: 'cannot activate ride: driver does not have an approved car',
        ).isQuotaExceeded,
        isFalse,
      );
    });
  });

  group('PublishResult — ekran qaysi yo\'lni tanlaydi', () {
    PublishResult res(ApiException? e) =>
        PublishResult(rideId: 'r-1', activated: false, error: e);

    test('paket tugagan: paywall YO\'LI, qayta urinish YO\'Q', () {
      final r = res(
        http(402, message: 'payment required: insufficient ride limits'),
      );
      expect(r.isQuotaExceeded, isTrue);
      expect(
        r.isRetryable,
        isFalse,
        reason:
            '402 da «Qayta urinish» tugmasi chiqsa, u hech qachon ishlamaydi '
            'va haydovchini aldaydi.',
      );
    });

    test('mashina tasdiqlanmagan: paywall EMAS', () {
      final r = res(
        http(
          400,
          kind: ApiErrorKind.badRequest,
          message: 'driver does not have an approved car',
        ),
      );
      expect(r.isQuotaExceeded, isFalse);
      expect(r.isRetryable, isFalse);
    });

    test('tarmoq uzilishi: qayta urinish MA\'NOLI, paywall emas', () {
      final r = res(ApiException(kind: ApiErrorKind.network));
      expect(r.isQuotaExceeded, isFalse);
      expect(r.isRetryable, isTrue);
    });

    test('faollashgan e\'londa xato ham, paywall ham yo\'q', () {
      const r = PublishResult(rideId: 'r-1', activated: true);
      expect(r.isQuotaExceeded, isFalse);
    });
  });
}
