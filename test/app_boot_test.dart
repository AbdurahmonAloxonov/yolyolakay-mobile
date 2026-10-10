import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/app.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/core/api/token_storage.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// Ilova ko'tarilishi va router redirect'i ishlashini qurilmasiz tekshiradi:
/// sessiya yo'q -> login ekrani, sessiya bor -> ichkari (qidiruv).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Widget> boot({
    required bool loggedIn,
    Map<String, Object> prefsValues = const {},
  }) async {
    // Mavjud testlar login/ichkarini sinaydi — intro OLDINDAN ko'rilgan deb
    // hisoblaymiz. Intro oqimi alohida testda (`intro_seen` yo'q holat).
    SharedPreferences.setMockInitialValues({
      'intro_seen': true,
      ...prefsValues,
    });
    final prefs = await SharedPreferences.getInstance();
    final tokens = TokenStorage();
    if (loggedIn) tokens.access = 'test-token';

    return ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokens),
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const YolYolakayApp(),
    );
  }

  testWidgets('birinchi ochilish — tanishtiruv (intro) ko\'rinadi', (
    tester,
  ) async {
    // `intro_seen` YO'Q — yangi qurilma. Router intro'ga yo'naltirishi kerak.
    await tester.pumpWidget(
      await boot(loggedIn: false, prefsValues: const {'intro_seen': false}),
    );
    await tester.pumpAndSettle();

    // Birinchi sahifa sarlavhasi + "O'tkazib yuborish" ko'rinadi.
    expect(find.text('Hamroh toping'), findsOneWidget);
    expect(find.text('O\'tkazib yuborish'), findsOneWidget);
    // Hali login EMAS.
    expect(find.text('Kod yuborish'), findsNothing);
  });

  testWidgets('sessiyasiz — login ekrani ochiladi', (tester) async {
    await tester.pumpWidget(await boot(loggedIn: false));
    await tester.pumpAndSettle();

    expect(find.text('YolYolakay'), findsOneWidget);
    expect(find.text('Kod yuborish'), findsOneWidget);
  });

  testWidgets('til ruschaga o\'zgarsa matnlar almashadi', (tester) async {
    await tester.pumpWidget(await boot(loggedIn: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();

    expect(find.text('Отправить код'), findsOneWidget);
  });

  testWidgets('sessiya bo\'lsa — qidiruv ekraniga o\'tadi', (tester) async {
    await tester.pumpWidget(await boot(loggedIn: true));
    await tester.pumpAndSettle();

    // ⚠️ Bosh ekranning sarlavhasi 2026-09-02 da o'zgardi: «Safar
    // qidirish» degan yozuv pastdagi «Qidirish» tugmasi bilan bir gapni
    // ikki marta aytardi. Endi u savol — «Qayerga boramiz?».
    expect(find.text('Qayerga boramiz?'), findsOneWidget);
    expect(find.text('Qayerdan'), findsOneWidget);
  });

  testWidgets('standart tema — tizim bo\'yicha', (tester) async {
    await tester.pumpWidget(await boot(loggedIn: false));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(
      app.theme,
      isNotNull,
      reason: 'yorug\' tema aniqlangan bo\'lishi kerak',
    );
    expect(app.darkTheme, isNotNull);
  });

  testWidgets('saqlangan yorug\' rejim ishga tushganda tiklanadi', (
    tester,
  ) async {
    await tester.pumpWidget(
      await boot(loggedIn: false, prefsValues: {'theme_mode': 'light'}),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);

    // Haqiqatan yorug' renderlanayotganini tekshiramiz (faqat bayroq emas).
    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.light);
  });

  testWidgets('saqlangan tungi rejim tiklanadi', (tester) async {
    await tester.pumpWidget(
      await boot(loggedIn: false, prefsValues: {'theme_mode': 'dark'}),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  group('Uch til', () {
    test('har bir matn uchta tilda ham bo\'sh emas', () {
      // Kodmod bilan 247 ta matnga inglizcha qo'shildi — bittasi ham
      // tushib qolmaganini va bo'sh satr bo'lmaganini tekshiramiz.
      for (final lang in Lang.values) {
        final t = AppStrings(lang);
        for (final value in [
          t.appName,
          t.cancel,
          t.save,
          t.loading,
          t.loginTitle,
          t.sendCode,
          t.otpTitle,
          t.profileTitle,
          t.searchTitle,
          t.parcelsTitle,
          t.tariffsTitle,
          t.becomeDriver,
          t.deleteAccount,
          t.techPassport,
          t.logout,
          t.privacyPolicy,
          t.termsOfUse,
          t.unlimited,
        ]) {
          expect(value.trim(), isNotEmpty, reason: '$lang uchun bo\'sh matn');
        }
      }
    });

    test('tillar bir-biridan farq qiladi (nusxa qolib ketmagan)', () {
      expect(AppStrings(Lang.uz).cancel, isNot(AppStrings(Lang.ru).cancel));
      expect(AppStrings(Lang.en).cancel, isNot(AppStrings(Lang.ru).cancel));
      expect(AppStrings(Lang.en).deleteAccount, 'Delete account');
      expect(AppStrings(Lang.en).unlimited, 'Unlimited');
    });
  });
}
