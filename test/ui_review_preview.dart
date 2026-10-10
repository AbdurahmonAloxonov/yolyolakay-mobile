import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/core/api/token_storage.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/core/drafts.dart';
import 'package:yolyolakay/features/auth/phone_screen.dart';
import 'package:yolyolakay/features/profile/driver_verification_screen.dart';
import 'package:yolyolakay/features/intro/intro_screen.dart';
import 'package:yolyolakay/features/rides/ride_details_screen.dart';

import 'support/preview_fonts.dart';

/// EKRANLARNI KO'Z BILAN KO'RISH uchun rasm yasagich (tekshirgich EMAS).
///
///   flutter test test/ui_review_preview.dart --update-goldens
///
/// Nega kerak: o'lchov «toshdimi yoki yo'q» degan savolga javob beradi,
/// lekin «chiroylimi, o'qiladimi, muvozanatlimi» degan savolga bermaydi.
/// Rasmlar `style_preview/` ga tushadi va ularni odam ko'radi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPreviewFonts);

  final ride = Ride(
    id: 'r1',
    originAddress: 'Toshkent, Chilonzor',
    destinationAddress: 'Samarqand, Registon',
    originLat: 41.2995,
    originLon: 69.2401,
    destinationLat: 39.6542,
    destinationLon: 66.9597,
    departureTime: DateTime(2026, 9, 1, 9),
    totalSeats: 4,
    availableSeats: 2,
    pricePerSeat: 150000,
    status: RideStatus.active,
    isNegotiable: true,
    hasAc: true,
    hasLuggage: true,
  );

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget screen, {
    Size size = const Size(360, 780),
    String lang = 'uz',
    double scale = 1.0,
    Brightness brightness = Brightness.light,
    Map<String, Object> extraPrefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues({'intro_seen': true, ...extraPrefs});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(TokenStorage()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: withPreviewFont(buildTheme(brightness: brightness)),
          locale: Locale(lang),
          supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../style_preview/$name.png'),
    );
  }

  testWidgets(
    'kirish — uz',
    (t) => shoot(t, 'ui_kirish_uz', const PhoneScreen()),
  );
  testWidgets(
    'kirish — ru, tor',
    (t) => shoot(
      t,
      'ui_kirish_ru_tor',
      const PhoneScreen(),
      size: const Size(320, 568),
      lang: 'ru',
    ),
  );
  testWidgets(
    'intro — uz',
    (t) => shoot(t, 'ui_intro_uz', const IntroScreen()),
  );
  testWidgets(
    'safar tafsiloti — uz',
    (t) => shoot(t, 'ui_safar_uz', RideDetailsScreen(ride: ride)),
  );
  testWidgets(
    'safar tafsiloti — katta matn',
    (t) =>
        shoot(t, 'ui_safar_katta', RideDetailsScreen(ride: ride), scale: 1.3),
  );

  // ══════════════════════════════════════════════════════════════
  // HAYDOVCHI BO'LISH — egasi TO'RT MARTA «keyingisi tugmasi yo'q»
  // dedi. O'lchov tugma joyidaligini aytadi, lekin egasi buni KO'RISHI
  // kerak. Rasmlar SURATLAR YUKLANGAN holatda olinadi — toshish
  // aynan shunda paydo bo'lardi (bo'sh formada «Almashtirish/O'chirish»
  // qatori umuman chizilmaydi).
  // ══════════════════════════════════════════════════════════════
  final filled = <String, Object>{
    'draft_${Drafts.driverVerification}': jsonEncode({
      'step': 0,
      'selfie': 'https://x/s.jpg',
      'license_front': 'https://x/lf.jpg',
      'license_back': 'https://x/lb.jpg',
      'tech_front': 'https://x/tf.jpg',
      'tech_back': 'https://x/tb.jpg',
      'car_front': 'https://x/cf.jpg',
      'car_back': 'https://x/cb.jpg',
      'car_side': 'https://x/cs.jpg',
      'brand': 'Chevrolet',
      'model': 'Cobalt',
      'gov_number': '01A777AA',
    }),
  };

  Map<String, Object> filledAt(int step) => {
    'draft_${Drafts.driverVerification}': jsonEncode({
      ...jsonDecode(filled.values.first as String) as Map<String, dynamic>,
      'step': step,
    }),
  };

  // Surat yuklangandan KEYINGI holat — aynan egasi aytgan lahza.
  testWidgets(
    'haydovchi — surat yuklangan, 1-qadam',
    (t) => shoot(
      t,
      'ui_haydovchi_surat_uz',
      const DriverVerificationScreen(),
      extraPrefs: filledAt(0),
    ),
  );

  // Eng og'ir holat: eng tor ekran + ruscha (uzun matn) + katta shrift.
  testWidgets(
    'haydovchi — 320px, ruscha, katta matn',
    (t) => shoot(
      t,
      'ui_haydovchi_tor_ru_katta',
      const DriverVerificationScreen(),
      size: const Size(320, 568),
      lang: 'ru',
      scale: 1.3,
      extraPrefs: filledAt(0),
    ),
  );

  // Oxirgi qadam — «Ko'rib chiqishga yuborish» aynan shu yerda
  // 94 piksel ekrandan tashqarida chizilardi.
  testWidgets(
    'haydovchi — oxirgi qadam, 320px ruscha',
    (t) => shoot(
      t,
      'ui_haydovchi_yuborish_tor_ru',
      const DriverVerificationScreen(),
      size: const Size(320, 568),
      lang: 'ru',
      extraPrefs: filledAt(5),
    ),
  );
}
