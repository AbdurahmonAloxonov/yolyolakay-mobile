import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/api/api_exception.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// SERVERNING ICHKI XATOSI ODAMGA KO'RSATILMAYDI.
///
/// 🔴 NEGA TEST (jonli, 2026-08-27): prodda `cars` jadvalida ustun
/// yetishmagani uchun backend 400 bilan XOM POSTGRES XATOSINI qaytardi va
/// u ekranga chiqib ketardi:
///
///     ERROR: column "tech_passport_front" of relation "cars"
///     does not exist (SQLSTATE 42703)
///
/// Eski filtr faqat uzunlik (120) va `{` ni tekshirardi — bu matn 86 belgi,
/// ya'ni BEMALOL o'tardi. Uch tomonlama zarar: odam tushunmaydi, bizning
/// UI orqali jadval va ustun nomlari oshkor bo'ladi, aybdor esa ilova
/// bo'lib ko'rinadi.
ApiException from400(String message) => ApiException.from(
  DioException(
    requestOptions: RequestOptions(path: '/x'),
    response: Response<dynamic>(
      requestOptions: RequestOptions(path: '/x'),
      statusCode: 400,
      data: {'error': message},
    ),
  ),
);

void main() {
  group('ichki xato YASHIRILADI', () {
    // Jonli o'lchangan HAQIQIY matnlar (27.08.2026).
    const real = [
      'ERROR: column "tech_passport_front" does not exist (SQLSTATE 42703)',
      'ERROR: column "tech_passport_front" of relation "cars" does not exist (SQLSTATE 42703)',
      'car check failed: user car error: ERROR: column "tech_passport_front" does not exist',
      "can't scan into dest[1] (col: event_date): cannot scan date (OID 1082) in binary format into *string",
    ];

    for (final msg in real) {
      test('«${msg.substring(0, 34)}…» chiqmaydi', () {
        final e = from400(msg);
        expect(e.isInternalError, isTrue);

        final shown = e.localized(Lang.uz);
        // Eng muhimi: xom matnning HECH BIR bo'lagi ekranga chiqmasin.
        expect(shown, isNot(contains('SQLSTATE')));
        expect(shown, isNot(contains('column')));
        expect(shown, isNot(contains('relation')));
        expect(shown, isNot(contains('tech_passport_front')));
        expect(shown, isNot(contains('scan')));
      });
    }

    /// 🔴 «Noto'g'ri so'rov» ham YARAMAYDI: u «siz xato kiritdingiz»
    /// degani. Server jadvalida ustun yetishmasa, odam nima kiritsa ham
    /// o'tmaydi — u formani qayta-qayta to'ldirib, o'zidan xato izlaydi.
    test('odamni AYBLAMAYDI — «sizning xatongiz emas» deyiladi', () {
      final shown = from400(real.first).localized(Lang.uz);
      expect(shown, contains('xatongiz emas'));
      expect(shown, isNot(equals("Noto'g'ri so'rov yuborildi")));
    });

    test('uchala tilda ham xom matn chiqmaydi', () {
      for (final lang in Lang.values) {
        final shown = from400(real.first).localized(lang);
        expect(shown, isNot(contains('SQLSTATE')), reason: '$lang');
        expect(shown.trim(), isNotEmpty, reason: '$lang');
      }
    });
  });

  /// ⚠️ Bu to'siq xom matnni ko'rsatish qoidasini BEKOR QILMASLIGI kerak.
  /// «Narx juda past» kabi aniq gaplar umumiy jumladan foydaliroq va ular
  /// qolishi shart (izohi `badRequest` da yozilgan).
  group('oddiy backend gaplari QOLADI', () {
    const normal = [
      'offered price is too low',
      'ride is already full',
      'booking not found for this ride',
    ];

    for (final msg in normal) {
      test('«$msg» ko\'rsatiladi', () {
        final e = from400(msg);
        expect(e.isInternalError, isFalse);
        expect(e.localized(Lang.uz), contains(msg));
      });
    }
  });

  test('bo\'sh xabar — umumiy matn, bo\'sh ekran emas', () {
    // Xabar yo'q bo'lsa ham odam BIRON gap ko'rishi kerak: bo'sh
    // snackbar «hech nima bo'lmadi» degan taassurot beradi.
    final shown = from400('').localized(Lang.uz);
    expect(shown.trim(), isNotEmpty);
    expect(shown, isNot(contains('null')));
  });
}
