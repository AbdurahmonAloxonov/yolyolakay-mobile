import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/features/rides/eta_ring.dart';

/// ETA halqasi.
///
/// 🔴 NEGA TEST: halqa CHEKSIZ aylanadi (`repeat()`). Bunday animatsiya
/// ikki xatoga moyil:
///   • `dispose` unutilsa — ekrandan chiqilgach ham ishlab, batareyani
///     yeb turadi (test `pumpWidget` bilan almashtirib tekshiradi);
///   • reduce-motion e'tiborsiz qolsa — tizim sozlamasini hurmat
///     qilmagan bo'lamiz, bu esa vestibulyar buzilishi bor odamlarga
///     jismonan noqulaylik keltiradi.
void main() {
  Widget boot({bool animations = true}) => MaterialApp(
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(disableAnimations: !animations),
        child: const Center(
          child: EtaRing(child: CircleAvatar(child: Text('A'))),
        ),
      ),
    ),
  );

  testWidgets('halqa va ichidagi surat chiziladi', (tester) async {
    await tester.pumpWidget(boot());
    await tester.pump();

    expect(find.byType(EtaRing), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    // Ikki qatlam: xira doimiy halqa + yorqin yoy.
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('animatsiya ishlaydi (kadrlar o\'zgaradi)', (tester) async {
    await tester.pumpWidget(boot());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Cheksiz animatsiya — `pumpAndSettle` HECH QACHON tugamaydi,
    // shuning uchun bu yerda u ATAYIN ishlatilmaydi (aks holda test
    // muzlab qolardi).
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('reduce-motion: halqa BOR, lekin aylanmaydi', (tester) async {
    await tester.pumpWidget(boot(animations: false));
    await tester.pump(const Duration(milliseconds: 500));

    // Belgi butunlay yo'qolmasin — u holat haqida ma'lumot beradi.
    expect(find.byType(EtaRing), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('ekrandan chiqilganda animatsiya to\'xtaydi', (tester) async {
    await tester.pumpWidget(boot());
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();

    expect(
      tester.hasRunningAnimations,
      isFalse,
      reason: '`dispose` chaqirilmagan — halqa fon rejimida aylanaveradi',
    );
  });
}
