import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/features/shared/yol_refresh.dart';

/// SURISH FIZIKASI — «slide qilishda qotish» (egasi, 2026-08-26).
///
/// 🔴 SABAB: `YolRefresh` ichidagi `ScrollConfiguration` da
/// `const AlwaysScrollableScrollPhysics()` PARENT'SIZ berilgan edi. Bu sinf
/// atigi ikki narsani override qiladi, qolgani `ScrollPhysics` bazasiga
/// tushadi, baza esa hammasini `parent` ga uzatadi — parent null bo'lsa
/// `createBallisticSimulation` NULL qaytaradi, ya'ni INERSIYA YO'Q:
/// barmoq uzilishi bilan ro'yxat o'sha joyda to'xtaydi.
///
/// `YolRefresh` 12 ta ekranda ishlatiladi (tariflar, safarlarim, qidiruv
/// natijalari, suhbatlar, bildirishnomalar, posilkalar, daromad...), ya'ni
/// bu bitta qator butun ilovaning "his"ini buzgan edi.
void main() {
  /// Uzun ro'yxat — flingga joy bo'lsin.
  Widget boot(ScrollController controller) => MaterialApp(
    home: Scaffold(
      body: YolRefresh(
        onRefresh: () async {},
        child: ListView.builder(
          controller: controller,
          itemCount: 200,
          itemBuilder: (_, i) => SizedBox(height: 60, child: Text('$i')),
        ),
      ),
    ),
  );

  testWidgets('barmoq uzilgach ro\'yxat INERSIYA bilan davom etadi', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(boot(controller));

    await tester.fling(find.byType(ListView), const Offset(0, -300), 1200);
    // Fling tugadi, barmoq uzildi — lekin ballistik faza endi boshlanadi.
    await tester.pump();
    final afterLift = controller.offset;

    // Ballistik fazani bir necha kadr aylantiramiz.
    await tester.pump(const Duration(milliseconds: 200));
    final afterCoast = controller.offset;

    expect(
      afterCoast,
      greaterThan(afterLift),
      reason:
          'Barmoq uzilgandan keyin ro\'yxat to\'xtab qoldi — inersiya yo\'q. '
          'Sabab odatda `AlwaysScrollableScrollPhysics` ga parent '
          'berilmagani bo\'ladi.',
    );

    await tester.pumpAndSettle();
  });

  testWidgets('ro\'yxat oxiridan nariga surilib ketmaydi', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(boot(controller));

    // Ro'yxat oxiridan NARIGA tortamiz: chekka ushlab turilmasa barmoq
    // qayerga sursa, o'sha yerga surilib ketaveradi.
    await tester.drag(find.byType(ListView), const Offset(0, -20000));
    await tester.pumpAndSettle();

    expect(
      controller.offset,
      lessThanOrEqualTo(controller.position.maxScrollExtent),
      reason:
          'Chekka ushlab turilmadi — `applyBoundaryConditions` bazadan '
          'kelyapti (0.0 qaytaradi), ya\'ni parent yo\'q.',
    );
  });

  testWidgets('qisqa ro\'yxat ham tortiladi (asosiy maqsad buzilmasin)', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: YolRefresh(
            onRefresh: () async {},
            child: ListView(
              controller: controller,
              children: const [SizedBox(height: 40, child: Text('bitta'))],
            ),
          ),
        ),
      ),
    );

    expect(
      controller.position.physics.shouldAcceptUserOffset(controller.position),
      isTrue,
      reason: 'Ekranга sig\'adigan ro\'yxat ham tortib-yangilanishi kerak',
    );
  });
}
