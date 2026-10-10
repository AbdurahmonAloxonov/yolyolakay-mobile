import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/features/rides/journey_view.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// Marshrut chizig'i uchta ekranda ishlatiladi, shuning uchun uning
/// cheklovlarga chidashi alohida tekshiriladi: ro'yxat ichida (vertikal
/// cheksiz) va tor ekranda.
void main() {
  Widget wrap(Widget child, {double width = 360}) => MaterialApp(
    locale: const Locale('uz'),
    supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: SizedBox(
        width: width,
        // ListView ATAYIN: aynan shu yerda "infinite height" xatolari
        // chiqadi, oddiy Column'da esa hech narsa ko'rinmaydi.
        child: ListView(children: [child]),
      ),
    ),
  );

  testWidgets('jo\'nash, oraliq shaharlar va manzil — hammasi chiziladi', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const JourneyLine(
          origin: 'Toshkent',
          destination: 'Buxoro',
          stops: ['Jizzax', 'Samarqand'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Toshkent'), findsOneWidget);
    expect(find.text('Jizzax'), findsOneWidget);
    expect(find.text('Samarqand'), findsOneWidget);
    expect(find.text('Buxoro'), findsOneWidget);
  });

  testWidgets('uzun manzil tor ekranda ham yiqilmaydi', (tester) async {
    await tester.pumpWidget(
      wrap(
        const JourneyLine(
          origin:
              'Toshkent shahri, Yunusobod tumani, Amir Temur shoh ko\'chasi 108',
          destination: 'Samarqand viloyati, Urgut tumani, Chorbog\' mahallasi',
        ),
        width: 240,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('haydovchi ismi kelmasa blok yo\'qolmaydi', (tester) async {
    await tester.pumpWidget(wrap(const DriverRow(name: null)));
    await tester.pumpAndSettle();

    // Ism o'rniga "Haydovchi" turadi — bo'sh joy emas.
    expect(find.text(const AppStrings(Lang.uz).driver), findsOneWidget);
  });

  testWidgets('reyting 0 bo\'lsa "0.0" chiqmaydi', (tester) async {
    await tester.pumpWidget(wrap(const DriverRow(name: 'Aziz', rating: 0)));
    await tester.pumpAndSettle();

    expect(find.text('Aziz'), findsOneWidget);
    expect(find.text('0.0'), findsNothing);
  });

  /// 🔴 Backend ismlarni BOSH HARFDA yuboradi ("MUXAMMAD RAXMATILLAYEV").
  /// Chatda biz uni tuzatardik, safar ekranlarida esa u baqirib turardi va
  /// kengroq bo'lgani uchun ertaroq kesilardi (qurilmada ko'rildi
  /// 2026-08-13).
  testWidgets('haydovchi ismi BAQIRMAYDI', (tester) async {
    await tester.pumpWidget(
      wrap(const DriverRow(name: 'MUXAMMAD RAXMATILLAYEV', rating: 5)),
    );
    await tester.pump();

    expect(find.text('Muxammad Raxmatillayev'), findsOneWidget);
    expect(find.text('MUXAMMAD RAXMATILLAYEV'), findsNothing);
  });

  testWidgets('odam o\'zi yozgan ismga TEGILMAYDI', (tester) async {
    await tester.pumpWidget(wrap(const DriverRow(name: 'Aziz', rating: 5)));
    await tester.pump();

    expect(find.text('Aziz'), findsOneWidget);
  });

  /// 🔴 Egasi (2026-08-14): jins bo'yicha CHEKLOV olib tashlandi, lekin
  /// yo'lovchi kim bilan ketayotganini bilishi kerak — jins MA'LUMOT
  /// sifatida qoladi (avatar ikonkasida, ortiqcha yozuvsiz).
  testWidgets('jins ikonkasi haydovchiga qarab o\'zgaradi', (tester) async {
    await tester.pumpWidget(
      wrap(const DriverRow(name: 'Aziz', gender: 'male')),
    );
    await tester.pump();
    expect(find.byIcon(Icons.man), findsOneWidget);

    await tester.pumpWidget(
      wrap(const DriverRow(name: 'Dilnoza', gender: 'female')),
    );
    await tester.pump();
    expect(find.byIcon(Icons.woman), findsOneWidget);
  });

  testWidgets('jins noma\'lum bo\'lsa oddiy ikonka', (tester) async {
    await tester.pumpWidget(wrap(const DriverRow(name: 'Aziz')));
    await tester.pump();
    expect(find.byIcon(Icons.person), findsOneWidget);
  });
}
