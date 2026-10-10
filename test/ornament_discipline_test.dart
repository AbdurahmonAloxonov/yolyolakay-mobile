import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/features/shared/brand/atlas.dart';
import 'package:yolyolakay/features/shared/brand/brand_panels.dart';
import 'package:yolyolakay/features/shared/brand/ornament.dart';

import 'support/audit_screens.dart';

/// NAQSH NIZOMI — HAR ELEMENT O'Z JOYIDA VA O'Z SONIDA.
///
/// 🔴 NEGA YOZILDI (10.09.2026). Egasi ilovaga qarab «hunuk bo'lib
/// qolgan» dedi. Sabab naqshning o'zida emas, TARTIBSIZLIGIDA edi:
/// atlas ipi `AppBar.bottom` da ham, `BottomActionBar` ichida ham
/// turardi va bitta ekranda IKKI MARTA chiqib, ekranni tasma-tasma
/// qilib kesardi. Buni qo'lda, safar tafsiloti ekranining suratiga
/// qarab topdik — hech qanday test tutmagan edi.
///
/// 🔑 NEGA BU TEST NAQSHNI CHEKLAMAYDI, HIMOYA QILADI: naqsh —
/// ilovaning o'zligi va u QOLISHI kerak. Uni shovqinga aylantiradigan
/// narsa takrorlanish. Tartibsiz ishlatilgan naqsh birinchi navbatda
/// naqshning O'ZIGA zarar qiladi.
///
/// ⚠️ ATLAS IPINING IKKI ROLI BOR — bu test yozilayotganda aniqlandi
/// va nizom shunga ko'ra aniqlashtirildi:
///
///   1. SAHIFA TIKUVI — `JiyakLine`, sarlavha panelining ostida.
///      Ilovaning imzosi, har ekranda BITTA.
///   2. BUYUM JIYAGI — o'zi yopiq buyumning (hujjat kartasi, plakat,
///      safar pasporti, bo'sh holat nishoni) ichidagi ip. U BUYUMGA
///      tegishli, sahifaga emas — masalan tarif kartasi «xabar emas,
///      HUJJAT» bo'lishi uchun pastida jiyak turadi.
///
/// Shuning uchun test yalang'och `AtlasEdge` ni qidiradi: agar ip
/// biror `Card` yoki nishon ichida bo'lmasa — u ikkinchi sahifa
/// tikuvi degani va bu xato.
///
/// ⚠️ Yangi ekran qo'shsangiz `test/support/audit_screens.dart` ga
/// qo'shing — bu test uni o'zi ko'radi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final entry in auditScreens().entries) {
    testWidgets('${entry.key} · naqsh nizomi', (tester) async {
      await pumpAuditScreen(tester, entry.value);
      // Tarmoq yo'qligi tabiiy — test muhitida server yo'q.
      tester.takeException();

      final broken = <String>[];

      // ── 1. SAHIFA TIKUVI: bittadan ko'p bo'lmasin ──────────────
      final seams = find.byType(JiyakLine).evaluate().length;
      if (seams > 1) {
        broken.add(
          'sahifa tikuvi (JiyakLine) $seams marta — ruxsat 1. '
          'Ip ilovaning YAGONA imzosi: faqat sarlavha paneli ostida.',
        );
      }

      // ── 2. YALANG'OCH IP: buyum ichida bo'lmagan `AtlasEdge` ───
      //
      // `JiyakLine` o'z ichida bitta `AtlasEdge` chizadi — u sanalmaydi.
      // Qolganlari biror BUYUM ichida bo'lishi kerak: `Card` (tarif
      // hujjati, safar pasporti), `PeshtoqMedallion` (bo'sh holat
      // nishoni) yoki `OrnamentHeader` (peshtoq).
      for (final edge in find.byType(AtlasEdge).evaluate()) {
        final inSeam = find
            .ancestor(of: find.byWidget(edge.widget), matching: find.byType(JiyakLine))
            .evaluate()
            .isNotEmpty;
        if (inSeam) continue;

        final inObject = [
          find.byType(Card),
          find.byType(PeshtoqMedallion),
          find.byType(OrnamentHeader),
        ].any(
          (m) => find
              .ancestor(of: find.byWidget(edge.widget), matching: m)
              .evaluate()
              .isNotEmpty,
        );
        if (!inObject) {
          broken.add(
            'yalang\'och atlas ipi — u biror buyum (Card / nishon / '
            'peshtoq) ichida emas, ya\'ni IKKINCHI sahifa tikuvi '
            'bo\'lib turibdi.',
          );
        }
      }

      // ── 3. ZAMIN NAQSHI ────────────────────────────────────────
      //
      // Ikkitagacha ruxsat: to'q peshtoq zamini va yorug' tanadagi
      // ganch — bular BIR MOTIV, ikki xil zaminda (`GanchPattern` —
      // `GirihPattern` ning nomli konstruktori). Uchinchisi esa
      // allaqachon shovqin.
      final girih = find.byType(GirihPattern).evaluate().length;
      if (girih > 2) {
        broken.add('girih $girih marta — ruxsat 2 (to\'q zamin + yorug\' zamin)');
      }

      // ── 4. YAKKA ELEMENTLAR ────────────────────────────────────
      for (final (name, n) in [
        ('palak rozetkasi', find.byType(PalakRosette).evaluate().length),
        ('muqarnas', find.byType(MuqarnasBand).evaluate().length),
      ]) {
        if (n > 1) broken.add('$name $n marta — ruxsat 1');
      }

      expect(
        broken,
        isEmpty,
        reason:
            '«${entry.key}» ekranida naqsh nizomi buzilgan:\n'
            '  ${broken.join('\n  ')}\n'
            'Nizom `lib/features/shared/brand/ornament.dart` boshida.',
      );
    });
  }
}
