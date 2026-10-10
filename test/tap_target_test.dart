import 'package:flutter_test/flutter_test.dart';

import 'support/audit_screens.dart';

/// BARMOQ NISHONI AUDITI — bosiladigan hamma narsa 48 px dan kichik emas.
///
/// 🔴 NEGA YOZILDI (2026-09-04). O'sha kuni SAYTDA o'lchov o'tkazildi va
/// o'n bir joyda bosiladigan element 16–34 px chiqdi: «Hammasini o'qilgan
/// qilish» 16 px, «Panelga qaytish» 20 px, «Orqaga» 28 px, shahar
/// tanlash ro'yxatining qatorlari 34 px. Ularning hammasi KO'ZGA
/// normal ko'rinardi — chunki YOZUV normal, bosiladigan MAYDON esa
/// yozuvdan kichik.
///
/// Ilovada bunday o'lchov umuman o'tkazilmagandi. Bu test uni
/// Flutter'ning o'z qoidasi bilan bajaradi
/// (`androidTapTargetGuideline` — 48×48 dp).
///
/// 🔑 Nega aynan test: bu xatoni `flutter analyze` ham, ko'z ham
/// ko'rmaydi. U faqat barmoq bilan bilinadi — va odam «tugma
/// ishlamayapti» deb yozadi, aslida tugma bosilgan-u, qo'shnisi
/// bosilgan.
///
/// YANGI EKRAN QO'SHSANGIZ — `test/support/audit_screens.dart` ga
/// qo'shing, uchala audit ham o'sha ro'yxatdan foydalanadi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final entry in auditScreens().entries) {
    testWidgets('${entry.key} · barmoq nishonlari 48 px', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpAuditScreen(tester, entry.value);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  }
}
