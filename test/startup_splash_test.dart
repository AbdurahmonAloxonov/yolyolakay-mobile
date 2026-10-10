import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/features/shared/brand/brand_splash.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// Ochilish ekrani — brend nomi ko'rinishi SHART.
void main() {
  const t = AppStrings(Lang.uz);

  Future<void> pump(WidgetTester tester, {Brightness? brightness}) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(
            brightness: brightness ?? Brightness.light,
            useMaterial3: true,
          ),
          locale: const Locale('uz'),
          supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const BrandSplash(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('brend nomi va shior ko\'rinadi', (tester) async {
    await pump(tester);
    expect(find.text(t.appName), findsOneWidget);
    expect(find.text(t.splashTagline), findsOneWidget);
  });

  testWidgets('yuklanish belgisi bor', (tester) async {
    await pump(tester);
    // Ekranning butun ma'nosi — "ilova ishlayapti" degan ishora.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('tungi rejimda ham chiziladi', (tester) async {
    await pump(tester, brightness: Brightness.dark);
    expect(find.text(t.appName), findsOneWidget);
  });
}
