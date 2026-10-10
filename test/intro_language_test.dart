import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/features/intro/intro_screen.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// INTRO — til tanlash.
///
/// 🔴 NEGA TEST: bu ilovaning ENG BIRINCHI ekrani va til tanlovi shu
/// yerda bo'lmasa, ruszabon odam o'zbekcha ekranni ko'rib ketadi —
/// u tilni qayerdan almashtirishni bilmaydi. Tugma yo'qolib qolsa
/// hech qanday xato chiqmaydi, faqat odamlar ketaveradi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget boot() => ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: Consumer(
      builder: (context, ref, _) => MaterialApp(
        locale: ref.watch(localeProvider),
        supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const IntroScreen(),
      ),
    ),
  );

  testWidgets('birinchi ekranda uchala til KO\'RINADI', (tester) async {
    await tester.pumpWidget(boot());
    await tester.pumpAndSettle();

    // Ochiluvchi ro'yxat emas — uchtasi ham darhol ko'rinishi kerak.
    expect(find.text('UZ'), findsOneWidget);
    expect(find.text('RU'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
  });

  testWidgets('til bosilsa interfeys DARHOL o\'zgaradi', (tester) async {
    await tester.pumpWidget(boot());
    await tester.pumpAndSettle();

    const uz = AppStrings(Lang.uz);
    const ru = AppStrings(Lang.ru);
    expect(find.text(uz.introSkip), findsOneWidget);

    await tester.tap(find.text('RU'));
    await tester.pumpAndSettle();

    expect(find.text(ru.introSkip), findsOneWidget);
    expect(find.text(uz.introSkip), findsNothing);
  });

  testWidgets('tanlangan til SAQLANADI', (tester) async {
    await tester.pumpWidget(boot());
    await tester.pumpAndSettle();

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    // Qayta ochilganda o'sha til qaytadi — aks holda odam har safar
    // qaytadan tanlashi kerak bo'lardi.
    expect(prefs.getString('locale'), 'en');
  });
}
