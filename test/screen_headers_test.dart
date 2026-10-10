import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/audit_screens.dart';

/// HAR EKRANNING EKRAN O'QIGICH UCHUN SARLAVHASI BO'LSIN.
///
/// 🔴 NEGA YOZILDI (2026-09-04). O'sha kuni SAYTDA o'n bir sahifada
/// `h1` umuman yo'qligi topildi va tuzatildi. Ilovaga ham o'sha savol
/// berildi — natija battarroq chiqdi: `Semantics(header: true)`
/// ILOVADA NOLTA joyda edi.
///
/// Nima demak: TalkBack yoqilgan odam ekranni faqat KETMA-KET o'qib
/// chiqishi mumkin. «Kerakli bo'limga o'tish» degan narsa yo'q —
/// profil, sozlamalar, tariflar kabi uzun ekranlarda bu butun
/// boshqaruvni yo'qotadi.
///
/// 🔑 BIR JOYDAN QAMRAB OLINDI: `SectionLabel` (o'nlab ekranda) va
/// `CollapsingScaffold`. Qolganlari — `AppBar`i yo'q ekranlar
/// (qidiruv, kirish, varaqlar, intro) qo'lda belgilandi.
///
/// ⚠️ BO'SH NOMLI SARLAVHA HAM XATO: `SliverAppBar.large` sarlavhani
/// ikki marta chizadi va Flutter `header` bayrog'ini KO'RINMAS
/// nusxaga qo'yadi. Odam «sarlavha» deb e'lon qilinganini eshitadi,
/// lekin nomini emas. Shuning uchun test nom BO'SH emasligini ham
/// tekshiradi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// `parcels` ekranining YORLIQLARI — ular hech qachon YAKKA
  /// ochilmaydi, doim «Pochta» ekrani ichida turadi va sarlavhani
  /// o'sha ekran beradi. Testda esa yakka chiziladi, shuning uchun
  /// bu yerda chetga chiqariladi.
  const insideTabs = {'find_parcels', 'my_parcels', 'create_parcel'};

  for (final entry in auditScreens().entries) {
    if (insideTabs.contains(entry.key)) continue;

    testWidgets('${entry.key}: ekran o\'qigich uchun sarlavhasi bor', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpAuditScreen(tester, entry.value);

      final labels = <String>[];
      void walk(SemanticsNode node) {
        // ⚠️ `hasFlag` va `pipelineOwner` eskirgan — yangi yo'l
        // `flagsCollection` va `SemanticsBinding`.
        if (node.flagsCollection.isHeader) labels.add(node.label.trim());
        node.visitChildren((child) {
          walk(child);
          return true;
        });
      }

      // ⚠️ `pipelineOwner` eskirgan deb belgilangan, lekin uning
      // o'rnini bosuvchi `rootPipelineOwner` widget testida semantika
      // egasini BERMAYDI (o'lchandi: `rootSemanticsNode` null bo'lib
      // qoladi va test butun ro'yxat bo'ylab yiqiladi).
      final root = tester
          .binding
          // ignore: deprecated_member_use
          .pipelineOwner
          .semanticsOwner
          ?.rootSemanticsNode;
      if (root != null) walk(root);

      expect(
        labels,
        isNotEmpty,
        reason:
            '${entry.key}: ekranda birorta sarlavha belgisi yo\'q. '
            'TalkBack bilan yuradigan odam bo\'limlar bo\'ylab sakray '
            'olmaydi — `SectionLabel` ishlating yoki sahifa sarlavhasini '
            '`Semantics(header: true)` bilan belgilang.',
      );
      expect(
        labels.where((l) => l.isNotEmpty),
        isNotEmpty,
        reason:
            '${entry.key}: sarlavha bor, lekin NOMI bo\'sh — ekran '
            'o\'qigich «sarlavha» deydi-yu, nimaligini aytmaydi.',
      );
      handle.dispose();
    });
  }
}
