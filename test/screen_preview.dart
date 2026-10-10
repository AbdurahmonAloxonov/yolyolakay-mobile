import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/data/models/billing.dart';
import 'package:yolyolakay/data/models/user.dart';
import 'package:yolyolakay/features/rides/create_ride_screen.dart';

import 'support/preview_fonts.dart';

/// HAQIQIY ekranlarni rasmga oladi — namunani emas.
///
/// `style_preview.dart` uslub TANLASH uchun edi (qo'lda yasalgan namunalar).
/// Bu esa tanlangan uslub haqiqiy ekranga qanday tushganini ko'rsatadi:
/// ilovaning o'z temasi (`buildTheme`) va o'z vidjetlari ishlatiladi.
///
///   flutter test test/screen_preview.dart --update-goldens
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

    await tester.binding.setSurfaceSize(const Size(390, 844));
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
              cars: [
                Car(
                  id: 'c-1',
                  brand: 'Chevrolet',
                  model: 'Cobalt',
                  govNumber: '01 A 123 BC',
                  moderationStatus: 'approved',
                ),
              ],
            ),
          ),
          subscriptionProvider.overrideWith(
            (ref) async =>
                const Subscription(planName: 'pro', status: 'active'),
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
          home: const CreateRideScreen(),
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
    'e\'lon berish — yorug\'',
    (t) => shoot(t, 'ekran_elon_yorug', brightness: Brightness.light),
  );
  testWidgets(
    'e\'lon berish — tungi',
    (t) => shoot(t, 'ekran_elon_tungi', brightness: Brightness.dark),
  );
}
