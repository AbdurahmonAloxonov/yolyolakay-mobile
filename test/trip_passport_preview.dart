import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/features/rides/trip_passport.dart';

import 'support/preview_fonts.dart';

/// Safar pasportini rasmga oladi — ko'z bilan tekshirish uchun.
///
/// Bu karta ILOVADAN CHIQIB ketadi (Telegram, Instagram), ya'ni uni
/// begona odamlar ko'radi. "Sig'dimi?" degan savolga faqat ko'z javob
/// beradi, shuning uchun bu yerda tasdiq yo'q — rasm chiqariladi.
///
///   flutter test test/trip_passport_preview.dart --update-goldens
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadPreviewFonts);

  testWidgets('safar pasporti', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 560));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final ride = Ride.fromJson(const {
      'id': 'r-1',
      'origin_address': 'Toshkent',
      'origin_lat': 41.2995,
      'origin_lon': 69.2401,
      'destination_address': 'Samarqand',
      'destination_lat': 39.6542,
      'destination_lon': 66.9597,
      'departure_time': '2026-08-20T09:00:00+05:00',
      'total_seats': 4,
      'available_seats': 0,
      'price_per_seat': 150000,
      'status': 'completed',
      'driver': {'id': 'd-42', 'name': 'AZIZ KARIMOV', 'rating': 4.9},
    });

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('uz'),
        supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildTheme(brightness: Brightness.light),
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: SizedBox(
              width: 400,
              child: TripPassport(
                ride: ride,
                distanceKm: 281,
                duration: const Duration(hours: 4, minutes: 10),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../style_preview/safar_pasporti.png'),
    );
  });
}
