import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/api/api_exception.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// SESSIYA OSONGINA O'LMASLIGI KERAK.
///
/// 🔴 NEGA TEST (egasi, 2026-08-27: «deploy va ilovada yangilanishdan
/// keyin loginga tepvoryapti hammani»):
///
/// O'LCHANDI — backend refresh tokenni AYLANTIRADI va eskisi DARHOL
/// o'ladi, imtiyoz oynasi YO'Q:
///     A bilan yangilash    -> 200 (yangi B beriladi)
///     A ni qayta ishlatish -> 401 «invalid or expired session»
///
/// Zanjir: yangilash so'rovi ketadi -> server A ni o'ldirib B beradi ->
/// deploy/yangilanish jarayonni SHU PAYT to'xtatadi -> mijozda hamon A
/// qoladi -> keyingi ochilishda 401 -> LOGIN.
///
/// Shuning uchun 401 «sessiya o'ldi» degani EMAS. Bu yerdagi sinovlar
/// mijoz o'z tomonidan qanchalik chidamli ekanini qotiradi.
void main() {
  ApiException from(int? status) => ApiException.from(
    DioException(
      requestOptions: RequestOptions(path: '/auth/refresh'),
      response: status == null
          ? null
          : Response<dynamic>(
              requestOptions: RequestOptions(path: '/auth/refresh'),
              statusCode: status,
              data: {'error': 'invalid or expired session'},
            ),
    ),
  );

  /// 🔴 Tarmoq yoki server xatosi HECH QACHON sessiyani o'ldirmasin:
  /// token yaroqli bo'lishi mumkin, biz shunchaki serverga yeta olmadik.
  test('tarmoq/5xx — bu SESSIYA o\'limi emas', () {
    for (final s in [null, 500, 502, 503, 504]) {
      final e = from(s);
      expect(
        e.kind == ApiErrorKind.unauthorized,
        isFalse,
        reason: 'status=$s sessiyani o\'ldirmasin',
      );
    }
  });

  test('401 — sessiya turi sifatida tanilady', () {
    expect(from(401).kind, ApiErrorKind.unauthorized);
  });

  /// 401 matni odamga TUSHUNARLI bo'lsin: «invalid or expired session»
  /// degan inglizcha xom gap emas.
  test('401 xabari xom matn EMAS', () {
    final shown = from(401).localized(Lang.uz);
    expect(shown, isNot(contains('invalid or expired')));
    expect(shown.trim(), isNotEmpty);
  });
}
