import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/audit_screens.dart';

/// TOR EKRAN VA KATTA MATN AUDITI — hamma ekran, bitta o'tishda.
///
/// 🔴 NEGA BU TEST BOR (2026-08-30).
///
/// Egasi to'rt marta «tugma yo'q» deb xabar qildi va har safar tugma
/// BOR edi — u shunchaki ekran chekkasidan chiqib ketgan yoki kesilgan
/// edi. Sabab har safar bir xil: `Row` ichidagi matn qisqarolmaydi va
/// qator toshadi.
///
/// 🔑 Bu xatoni HECH QANDAY oddiy vosita ko'rmaydi:
///   • `flutter analyze` gorizontal toshishni bilmaydi;
///   • reliz build'da sariq-qora chiziqlar CHIZILMAYDI — qator
///     jimgina kesiladi;
///   • odatiy widget testlar `find.text` bilan ishlaydi, u esa
///     ekrandan chiqib ketgan vidjetni ham TOPADI.
///
/// Shuning uchun bu yerda har ekran BIR NECHTA holatda ochiladi va
/// har qanday `RenderFlex overflowed` yoki ushlanmagan xato testni
/// YIQITADI:
///
///   320 px  — hali tirik eng tor Android telefonlar;
///   360 px  — eng keng tarqalgan eni;
///   uz/ru/en — ruscha matn o'zbekchadan uzun, ingliz qisqa;
///   x1.3    — ilova ruxsat beradigan eng katta matn
///             (`textScaler.clamp(1.0, 1.3)`);
///   tungi   — boshqa tema, boshqa o'lchamlar.
///
/// YANGI EKRAN QO'SHSANGIZ — `test/support/audit_screens.dart` ga
/// qo'shing. Bir qator kod, keyinchalik bir kunlik nosozlik
/// tekshiruvini tejaydi — va uchala audit ham darhol uni ko'radi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // (o'lcham, til, matn kattaligi, tungimi)
  const cases = [
    (Size(320, 568), 'uz', 1.0, false),
    (Size(320, 568), 'ru', 1.0, false),
    (Size(360, 780), 'ru', 1.0, true),
    (Size(360, 780), 'en', 1.0, false),
    // 🔴 KATTA MATN — ilova 1.3 gacha ruxsat beradi (`textScaler.clamp`),
    // lekin tizim sozlamasi 1.6 ni ham beradi.
    (Size(360, 780), 'uz', 1.3, false),
    (Size(320, 568), 'ru', 1.3, false),
  ];

  for (final entry in auditScreens().entries) {
    for (final c in cases) {
      final size = c.$1;
      final lang = c.$2;
      final scale = c.$3;
      final dark = c.$4;
      {
        testWidgets('${entry.key} · ${size.width.toInt()} · $lang · x$scale'
            '${dark ? " · tungi" : ""}', (tester) async {
          final problems = <String>[];
          final previous = FlutterError.onError;
          FlutterError.onError = (details) {
            final text = details.exceptionAsString();
            if (text.contains('overflowed')) {
              final where = details
                  .toString()
                  .split('\n')
                  .firstWhere(
                    (l) =>
                        l.contains('lib/features/') || l.contains('lib/app/'),
                    orElse: () => '(joy topilmadi)',
                  )
                  .trim();
              problems.add('${text.split('\n').first}  @ $where');
            } else if (!text.contains('UnimplementedError') &&
                !text.contains('Failed host lookup') &&
                !text.contains('HttpException') &&
                !text.contains('SocketException')) {
              final frames = details
                  .toString()
                  .split('\n')
                  .where((l) => l.contains('package:yolyolakay/'))
                  .take(3)
                  .join(' | ');
              problems.add('XATO: ${text.split('\n').first} << $frames');
            }
          };
          // 🔴 `addTearDown` EMAS. `expect()` teardown'dan OLDIN
          // ishlaydi va Flutter «test FlutterError.onError ni
          // qaytarmadi» deb assert tashlaydi — natijada test
          // fayli 2 daqiqaga OSILIB qoladi (o'lchandi).
          // Shuning uchun quyida, tekshiruvdan OLDIN qo'lda
          // tiklaymiz; bu ham zaxira sifatida qoladi.
          addTearDown(() => FlutterError.onError = previous);

          await pumpAuditScreen(
            tester,
            entry.value,
            size: size,
            lang: lang,
            scale: scale,
            dark: dark,
          );

          FlutterError.onError = previous;
          expect(
            problems.toSet(),
            isEmpty,
            reason:
                '${entry.key} ekrani ${size.width.toInt()}px · $lang · '
                'x$scale da buzilyapti',
          );
        });
      }
    }
  }
}
