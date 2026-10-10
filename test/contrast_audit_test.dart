import 'package:flutter_test/flutter_test.dart';

import 'support/audit_screens.dart';

/// KONTRAST VA NOM AUDITI — hamma ekran, yorug' va tungi tema.
///
/// 🔴 NEGA YOZILDI (2026-09-04). O'sha kuni SAYTDA kontrast birinchi
/// marta o'lchandi va natija kutilmagan bo'ldi: nuqson chekkadagi bir
/// joyda emas, BREND RANGINING O'ZIDA edi (oq yozuvli tugmada
/// 4.18 : 1, pushti havolada 3.85 : 1 — kerak 4.5 : 1). Undan tashqari
/// profil sarlavhasidagi reyting 1.00 : 1 chiqdi — ya'ni matn zamin
/// bilan AYNAN bir xil rangda, umuman ko'rinmasdi.
///
/// Ilovada esa kontrast faqat TEMA TOKENLARI darajasida tekshirilardi
/// (`accessibility_test.dart`): «tugma rangi + yozuv rangi» juftligi.
/// Bu yetarli emas — haqiqiy ekranda matn kartaga, kartochka rangli
/// zaminga, zamin esa naqshga tushadi va yakuniy natija tokenlardan
/// boshqacha bo'ladi. Aynan shunday xato ilgari bo'lgan ham: `Ikat`
/// to'qimasi rangni o'zi quyuqlashtirib, profil sarlavhasini
/// o'qib bo'lmaydigan qilib qo'ygandi.
///
/// Shuning uchun bu yerda ekran CHIZILADI va Flutter o'zining
/// piksel darajasidagi qoidalari bilan o'lchaydi:
///
///   • `textContrastGuideline`      — har matn o'z zaminiga nisbatan
///                                    WCAG AA (4.5 : 1, yirik matn 3 : 1);
///   • `labeledTapTargetGuideline`  — bosiladigan har bir joyning NOMI
///                                    bo'lsin. Faqat ikonkali tugma
///                                    ekran o'qigichga «button» bo'lib
///                                    eshitiladi va odam nima
///                                    bosayotganini bilmaydi.
///
/// ⚠️ MATN QANDAY KO'RINISHI bu yerda O'LCHANMAYDI: audit ataylab
/// to'la (silliqlanmagan) harflar bilan chizadi, chunki Flutter'ning
/// o'lchagichi aks holda harf chetlarining ARALASHMASINI "matn rangi"
/// deb oladi va yolg'on natija beradi (batafsil hisob
/// `audit_screens.dart` dagi `_solidGlyphTheme` izohida). Kesilish —
/// `text_not_cut_test`, toshish — `ui_narrow_audit_test`.
///
/// ⚠️ KO'R NUQTA (saytdagi audit bilan bir xil): zamini SURAT yoki
/// GRADIENT bo'lgan matn o'lchanmaydi — u yerda solishtiriladigan
/// bitta rang yo'q. Naqsh ustidagi yozuvlar KO'Z bilan ko'riladi
/// (`ui_full_review.dart` rasmlari).
///
/// YANGI EKRAN QO'SHSANGIZ — `test/support/audit_screens.dart` ga
/// qo'shing, bu audit uni o'zi ko'radi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final entry in auditScreens().entries) {
    for (final dark in [false, true]) {
      final label = dark ? 'tungi' : 'yorug\'';
      testWidgets('${entry.key} · $label · kontrast', (tester) async {
        final handle = tester.ensureSemantics();
        // `solidGlyphs` — izohi `audit_screens.dart` dagi
        // `_solidGlyphTheme` da: bu audit tipografikani emas, RANGNI
        // o'lchaydi va unga silliqlanmagan harflar kerak.
        await pumpAuditScreen(
          tester,
          entry.value,
          dark: dark,
          solidGlyphs: true,
        );
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }

    testWidgets('${entry.key} · bosiladigan joyning nomi bor', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpAuditScreen(tester, entry.value);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}
