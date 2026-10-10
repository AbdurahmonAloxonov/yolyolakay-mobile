import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/features/shared/yol_button.dart';

/// ASOSIY TUGMA — chiroy qulaylikni yemadimi?
///
/// 🔴 NEGA O'LCHANADI (18.09.2026): tugmaga harakat qo'shish uni
/// `Stack` ichiga solishni talab qildi, `Stack` esa bolaga BO'SH
/// constraint beradi — ya'ni tugma jimgina BUTUN ENGDAN kichrayib
/// qolishi mumkin. «Asosiy tugma butun engda» — bu loyihada qoida
/// va u TO'RT marta buzilgan (12/27/28/30-avgust).
///
/// Qolgan uchtasi ham jimgina buziladigan turdan:
/// yuklanishda yozuv yo'qolib, tugma sakrab kichrayishi; ekran
/// o'qigichga yorliqning IKKI marta o'qilishi; «harakatni kamaytir»
/// yoqilganda ham animatsiya chizilishi.
void main() {
  Widget host(Widget child, {bool reduceMotion = false}) => MaterialApp(
    theme: buildTheme(
      brightness: Brightness.light,
      style: ThemeStyle.classic,
    ),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(
        body: Center(
          child: SizedBox(width: 320, child: child),
        ),
      ),
    ),
  );

  testWidgets('tugma BUTUN ENGNI egallaydi', (tester) async {
    await tester.pumpWidget(
      host(YolButton(onPressed: () {}, label: 'Bron qilish')),
    );
    final size = tester.getSize(find.byType(YolButton));
    expect(
      size.width,
      320,
      reason: '`Stack` bolaga bo\'sh constraint bersa tugma kichrayib qoladi',
    );
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('yuklanishda YOZUV QOLADI va eni o\'zgarmaydi', (tester) async {
    await tester.pumpWidget(
      host(YolButton(onPressed: () {}, label: 'Bron qilish')),
    );
    final before = tester.getSize(find.byType(YolButton));

    await tester.pumpWidget(
      host(YolButton(onPressed: () {}, label: 'Bron qilish', busy: true)),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text('Bron qilish'),
      findsOneWidget,
      reason: 'matn spinnerga almashsa odam nimani bosganini unutadi',
    );
    expect(tester.getSize(find.byType(YolButton)), before);
  });

  testWidgets('yuklanayotgan tugma BOSILMAYDI', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(YolButton(onPressed: () => taps++, label: 'Yuborish', busy: true)),
    );
    await tester.tap(find.byType(YolButton));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('o\'chiq tugma bosilmaydi', (tester) async {
    await tester.pumpWidget(host(const YolButton(onPressed: null, label: 'X')));
    await tester.tap(find.byType(YolButton));
    await tester.pump();
    // Xato tashlanmasligi va tugma o'chiq turishi yetarli.
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('bosilsa CHAQIRILADI', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(YolButton(onPressed: () => taps++, label: 'Ha')),
    );
    await tester.tap(find.byType(YolButton));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('yorliq ekran o\'qigichga BIR marta beriladi', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(YolButton(onPressed: () {}, label: 'Bron qilish')),
    );
    expect(
      find.bySemanticsLabel('Bron qilish'),
      findsOneWidget,
      reason: 'ortiqcha `Semantics` o\'rovchisi yorliqni ikki marta o\'qitardi',
    );
    handle.dispose();
  });

  testWidgets('«harakatni kamaytir» — iz CHIZILMAYDI', (tester) async {
    await tester.pumpWidget(
      host(
        YolButton(onPressed: () {}, label: 'Bron qilish', icon: Icons.check),
        reduceMotion: true,
      ),
    );
    await tester.press(find.byType(YolButton));
    await tester.pump(const Duration(milliseconds: 100));
    // Iz `CustomPaint` bilan chiziladi — reduce-motion'da u umuman
    // qurilmasligi kerak (tugmaning o'z ichki `CustomPaint` lari bor,
    // shuning uchun aynan MASHAMIZNI qidiramiz).
    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where((p) => p.painter?.runtimeType.toString() == '_TracePainter');
    expect(painters, isEmpty);
  });

  testWidgets('uzun matn tugmadan TOSHMAYDI', (tester) async {
    await tester.pumpWidget(
      host(
        const YolButton(
          onPressed: null,
          label: 'Juda uzun yozuv — ruscha tarjimada bundan ham uzun bo\'ladi',
          icon: Icons.directions_car,
        ),
      ),
    );
    // Toshish `FlutterError` bo'lib chiqadi; `ellipsis` esa uni yutadi.
    expect(tester.takeException(), isNull);
    expect(find.byType(YolButton), findsOneWidget);
  });
}
