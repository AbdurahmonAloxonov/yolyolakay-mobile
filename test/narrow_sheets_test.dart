import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/features/search/city_picker.dart';
import 'package:yolyolakay/features/search/filter_bar.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// TOR EKRAN QO'RIQCHISI — VARAQLAR uchun.
///
/// 🔴 NEGA YOZILDI (2026-08-26): `layout_narrow_test.dart` kartalarni
/// tekshiradi, VARAQLAR esa uning ostiga tushmagan edi. Auditda shahar
/// tanlash varag'ida 360 dp da **197 px toshish** topildi: "Faqat
/// tumanlar" chipi va "Xaritadan tanlash" tugmasi bir qatorga sig'masdi
/// va tugma ekran chetidan chiqib ketardi — ya'ni uni BOSIB BO'LMASDI.
///
/// Sabab naqshi: `Row` ichida ikkita TARJIMA qilinadigan matn va orada
/// `Spacer()`. Joy tugaganда `Spacer` nolga siqiladi, matn esa
/// qisqarmaydi. Ruscha matn o'zbekchadan uzunroq — ya'ni xato avval
/// ruscha interfeysda chiqadi.
///
/// Bu yerda eng yomon holat olinadi: eng tor telefon (320 dp) VA tizim
/// shrifti 1.6. Flutter toshishni xato deb beradi, sinov yiqiladi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpNarrow(
    WidgetTester tester,
    Widget child, {
    required Locale locale,
    double textScale = 1.0,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          locale: locale,
          supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, inner) => MediaQuery.withClampedTextScaling(
            minScaleFactor: textScale,
            maxScaleFactor: textScale,
            child: inner!,
          ),
          home: child,
        ),
      ),
    );
  }

  /// Har uch tilda: ruscha matn odatda eng uzun, ya'ni xato avval u yerda
  /// chiqadi. Ingliz ham tekshiriladi — u ba'zan undan ham uzun.
  for (final locale in const [Locale('uz'), Locale('ru'), Locale('en')]) {
    testWidgets('shahar tanlash varag\'i tor ekranда sig\'adi (${locale.languageCode})', (
      tester,
    ) async {
      await pumpNarrow(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showPlacePicker(context),
                child: const Text('och'),
              ),
            ),
          ),
        ),
        locale: locale,
      );

      await tester.tap(find.text('och'));
      await tester.pumpAndSettle();
      // Toshish bo'lsa Flutter xato beradi va sinov shu yerda yiqiladi.
      expect(find.byType(FilterChip), findsOneWidget);
    });
  }

  testWidgets('shahar tanlash varag\'i KATTA matnda ham sig\'adi', (
    tester,
  ) async {
    await pumpNarrow(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showPlacePicker(context),
              child: const Text('och'),
            ),
          ),
        ),
      ),
      locale: const Locale('ru'),
      textScale: 1.6,
    );

    await tester.tap(find.text('och'));
    await tester.pumpAndSettle();
    expect(find.byType(FilterChip), findsOneWidget);
  });

  for (final locale in const [Locale('uz'), Locale('ru'), Locale('en')]) {
    testWidgets('filtrlar varag\'i tor ekranда sig\'adi (${locale.languageCode})', (
      tester,
    ) async {
      await pumpNarrow(
        tester,
        const Scaffold(body: SafeArea(child: FilterBar())),
        locale: locale,
      );
      await tester.pumpAndSettle();

      final t = AppStrings(switch (locale.languageCode) {
        'ru' => Lang.ru,
        'en' => Lang.en,
        _ => Lang.uz,
      });
      await tester.tap(find.text(t.filters).first);
      await tester.pumpAndSettle();
    });
  }
}
