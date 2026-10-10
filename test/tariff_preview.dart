import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/data/models/billing.dart';
import 'package:yolyolakay/data/models/user.dart';
import 'package:yolyolakay/features/billing/tariffs_screen.dart';

import 'support/preview_fonts.dart';

/// Tarif ekranining rasmi — kartani ko'z bilan baholash uchun.
///
///   flutter test test/tariff_preview.dart --update-goldens
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPreviewFonts);

  Future<void> shoot(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          meProvider.overrideWith(
            (ref) async => const MeResponse(
              user: User(
                id: 'u-1',
                phoneNumber: '+998900000000',
                firstName: 'Aziz',
                role: 'driver',
              ),
              cars: [],
            ),
          ),
          subscriptionProvider.overrideWith((ref) async => null),
          billingPlansProvider.overrideWith(
            (ref) async => const [
              BillingPlan(name: 'Free Trial', price: 0, ridesQuota: 3),
              BillingPlan(name: 'Plus', price: 30000, ridesQuota: 15),
              BillingPlan(
                name: 'Pro',
                price: 60000,
                ridesQuota: 40,
                parcelsQuota: 5,
              ),
              BillingPlan(
                name: 'Premium',
                price: 100000,
                ridesQuota: -1,
                parcelsQuota: -1,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: withPreviewFont(buildTheme(brightness: brightness)),
          locale: const Locale('uz'),
          supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const TariffsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../style_preview/$name.png'),
    );
  }

  testWidgets(
    'tariflar — yorug\'',
    (t) => shoot(t, 'tarif_yorug', brightness: Brightness.light),
  );
  testWidgets(
    'tariflar — tungi',
    (t) => shoot(t, 'tarif_tungi', brightness: Brightness.dark),
  );

  /// Kartani bosganda ochiladigan tafsilot oynasi.
  testWidgets('tarif tafsiloti', (tester) async {
    await shoot(tester, 'tarif_yorug_tmp', brightness: Brightness.light);
    // "Pro" kartasini bosamiz — eng foydali tarif.
    await tester.tap(find.text('Pro'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../style_preview/tarif_tafsilot.png'),
    );
  });
}
