import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/features/search/date_strip.dart';

/// SANA LENTASI — kunlar va ularning safar soni.
///
/// 🔴 NEGA TEST: lentaning butun ma'nosi SONDA. Agar u noto'g'ri
/// ko'rsatilsa yoki bo'sh kun bosiladigan bo'lib qolsa, funksiya
/// foydadan ZARARGA aylanadi: odam songa ishonib bosadi va bo'sh
/// ekranga tushadi — ilgari ham aynan shu bo'lardi.
void main() {
  DateTime day(int plusDays) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: plusDays));
  }

  Widget boot(Map<DateTime, int> counts, {void Function(DateTime)? onPick}) =>
      ProviderScope(
        overrides: [
          ridesPerDayProvider.overrideWith((ref) async => counts),
        ],
        child: MaterialApp(
          locale: const Locale('uz'),
          supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: DateStrip(onPick: onPick ?? (_) {}),
          ),
        ),
      );

  testWidgets('ma\'lumot yo\'q — lenta UMUMAN chizilmaydi', (tester) async {
    await tester.pumpWidget(boot(const {}));
    await tester.pumpAndSettle();

    // Nol ko'rsatib "safar yo'q" deb aldashdan ko'ra hech nima
    // ko'rsatmagan yaxshi.
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('kun soni ko\'rinadi', (tester) async {
    await tester.pumpWidget(boot({day(1): 12, day(3): 3}));
    await tester.pumpAndSettle();

    expect(find.text('12'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  /// Bo'sh kunda `0` emas, chiziqcha: nol raqami "hisoblanmadi" degan
  /// taassurot beradi.
  testWidgets('bo\'sh kunda chiziqcha, nol EMAS', (tester) async {
    await tester.pumpWidget(boot({day(1): 5}));
    await tester.pumpAndSettle();

    expect(find.text('0'), findsNothing);
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('safari BOR kun bosiladi', (tester) async {
    DateTime? picked;
    await tester.pumpWidget(
      boot({day(2): 4}, onPick: (d) => picked = d),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('4'));
    await tester.pump();

    expect(picked, isNotNull);
    expect(picked!.day, day(2).day);
  });

  /// 🔴 ENG MUHIM QOIDA: son ko'rsatib turib, bosilgach bo'sh natija
  /// berish — ishonchni yo'qotadi. Bo'sh kun umuman bosilmaydi.
  testWidgets('bo\'sh kun BOSILMAYDI', (tester) async {
    DateTime? picked;
    await tester.pumpWidget(
      boot({day(1): 2}, onPick: (d) => picked = d),
    );
    await tester.pumpAndSettle();

    // Birinchi chiziqcha — bugungi kun (unda safar yo'q).
    await tester.tap(find.text('—').first);
    await tester.pump();

    expect(picked, isNull);
  });

  /// 🔴 SINOVDA TOPILGAN TOSHISH: kartochka uch qatorli edi va 62 px ga
  /// sig'masdi. Tizim shrifti kattalashtirilgan telefonda (keksalarda
  /// odatiy) bu yanada yomonlashadi. Ilova `textScaler` ni 1.3 gacha
  /// chegaralaydi — aynan o'sha chegarada tekshiramiz.
  testWidgets('katta shriftda (1.3) toshib ketmaydi', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ridesPerDayProvider.overrideWith(
            (ref) async => {day(1): 12, day(2): 7},
          ),
        ],
        child: MaterialApp(
          locale: const Locale('uz'),
          supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: Scaffold(body: DateStrip(onPick: (_) {})),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('12'), findsOneWidget);
  });
}
