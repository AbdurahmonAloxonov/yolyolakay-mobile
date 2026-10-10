import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/features/shared/collapsing_scaffold.dart';

/// Yig'iladigan sarlavha.
///
/// 🔴 NEGA TEST: `NestedScrollView` ichida tana o'z skrollini yo'qotib
/// qo'yishi mumkin — u holda ro'yxat UMUMAN surilmaydi. Bu ekranni
/// butunlay ishlamas qiladi, lekin `analyze` hech nima demaydi.
void main() {
  Widget boot({int items = 40}) => MaterialApp(
    theme: buildTheme(brightness: Brightness.light),
    home: CollapsingScaffold(
      title: 'Suhbatlar',
      actions: const [Icon(Icons.more_vert)],
      body: ListView.builder(
        itemCount: items,
        itemBuilder: (context, i) => ListTile(title: Text('qator $i')),
      ),
    ),
  );

  testWidgets('sarlavha va tana chiziladi', (tester) async {
    await tester.pumpWidget(boot());
    await tester.pumpAndSettle();

    // `SliverAppBar.large` sarlavhani IKKI marta chizadi (yig'ilgan va
    // yoyilgan holat o'rtasida silliq o'tish uchun) — bu Material 3 ning
    // odatiy xatti-harakati, xato emas.
    expect(find.text('Suhbatlar'), findsNWidgets(2));
    expect(find.text('qator 0'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });

  testWidgets('avval SARLAVHA yig\'iladi, keyin ro\'yxat suriladi', (
    tester,
  ) async {
    await tester.pumpWidget(boot());
    await tester.pumpAndSettle();

    final firstRowTop = tester.getTopLeft(find.text('qator 0')).dy;

    // Kichik surish: `NestedScrollView` uni AVVAL sarlavhaga beradi —
    // ro'yxat hali joyida qoladi, lekin tepaga siljiydi.
    await tester.drag(find.text('qator 2'), const Offset(0, -60));
    await tester.pumpAndSettle();

    expect(
      find.text('qator 0'),
      findsOneWidget,
      reason: 'kichik surishda ro\'yxat hali surilmasligi kerak edi',
    );
    expect(
      tester.getTopLeft(find.text('qator 0')).dy,
      lessThan(firstRowTop),
      reason: 'sarlavha yig\'ilmadi — joy bo\'shamadi',
    );

    // Katta surish: endi ro'yxatning O'ZI suriladi. Bu ham tekshiriladi,
    // chunki `NestedScrollView` ichida tana skrollini yo'qotib qo'yishi
    // mumkin — o'shanda ekran butunlay ishlamas bo'lardi.
    await tester.drag(find.text('qator 2'), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('qator 0'), findsNothing);
  });

  /// Yig'ilgandan keyin ham sarlavha KO'RINIB turishi kerak — u butunlay
  /// yo'qolsa odam qaysi bo'limda ekanini yo'qotadi.
  testWidgets('yig\'ilgach ham sarlavha ko\'rinadi', (tester) async {
    await tester.pumpWidget(boot());
    await tester.pumpAndSettle();

    await tester.drag(find.text('qator 3'), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Suhbatlar'), findsWidgets);
  });
}
