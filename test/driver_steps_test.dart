import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/features/profile/driver_verification_screen.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// HAYDOVCHI BO'LISH — «nega keyingisiga o'tish yo'q».
///
/// 🔴 NEGA TEST (egasi, qurilmada 2026-08-27): «Keyingi» tugmasi BOR va u
/// suriladigan qismdan TASHQARIDA, ya'ni ekrandan chiqib ketmaydi. Lekin
/// surat yuklanmagan bo'lsa u O'CHIQ turadi va SABABINI aytmaydi.
/// Yuklash xatosi esa snackbar bo'lib bir lahzada yo'qoladi. Natijada
/// odam «tugma yo'q» deb o'ylaydi — u yerda turgan bo'lsa ham.
void main() {
  const t = AppStrings(Lang.uz);

  Future<void> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          locale: Locale('uz'),
          supportedLocales: [Locale('uz')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: DriverVerificationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('«Keyingi» tugmasi BOR va ko\'rinadi', (tester) async {
    await pump(tester);
    expect(find.text(t.next), findsOneWidget);
  });

  /// 🔴 ENG MUHIMI: tugma o'chiq bo'lsa NEGA ekani yozilib turishi kerak.
  /// Aks holda odam «keyingisi yo'q» deb o'ylaydi va oqimni tashlab
  /// ketadi — aynan shu bo'lgan.
  testWidgets('tugma o\'chiq bo\'lsa SABABI yozilgan', (tester) async {
    await pump(tester);

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text(t.next),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull, reason: 'surat yo\'q — o\'chiq bo\'lsin');
    expect(find.text(t.stepNeedSelfie), findsOneWidget);
  });

  /// Tugma suriladigan ro'yxat ICHIDA turmasligi kerak — aks holda uzun
  /// qadamda u pastga tushib ketadi va topilmaydi. Loyihada bu xatoning
  /// tarixi bor («asosiy tugma ro'yxat oxirida turmasin»).
  testWidgets('tugma ro\'yxat ichida EMAS — doim ko\'rinadi', (tester) async {
    await pump(tester);
    final listView = find.byType(ListView);
    expect(listView, findsOneWidget);
    expect(
      find.descendant(of: listView, matching: find.text(t.next)),
      findsNothing,
    );
  });

  testWidgets('tor ekranda ham qator toshmaydi', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          locale: Locale('uz'),
          supportedLocales: [Locale('uz')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: DriverVerificationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(t.next), findsOneWidget);
  });
}
