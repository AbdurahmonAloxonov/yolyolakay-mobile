import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/features/rides/ride_card.dart';

import 'support/preview_fonts.dart';

/// TUNGI HAYDASH (amber) uslubini rasmga oladi.
///
/// Kontrast «yetarlimi?» degan savolga faqat ko'z javob beradi — amber
/// past kontrastli bo'lishi ATAYIN (tunda ko'z qamashmasin), lekin
/// o'qib bo'lmaydigan darajada emas. Chegara ingichka, shuning uchun
/// rasm chiqariladi.
///
///   flutter test test/amber_preview.dart --update-goldens
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadPreviewFonts);

  testWidgets('tungi haydash uslubi', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 620));
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
      'available_seats': 2,
      'price_per_seat': 150000,
      'status': 'active',
      'driver': {'id': 'd-1', 'name': 'Aziz Karimov', 'rating': 4.9},
      'has_ac': true,
      'no_smoking': true,
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
        theme: withPreviewFont(
          buildTheme(brightness: Brightness.dark, style: ThemeStyle.amber),
        ),
        home: Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Tungi haydash')),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                RideCard(ride: ride, distanceKm: 3.2),
                const SizedBox(height: 12),
                RideCard(ride: ride, medianPrice: 200000),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {},
                  child: const Text('Bron qilish'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Safarni ochish'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Oddiy matn — tunda ko\'z qamashmasligi kerak, lekin '
                  'o\'qilishi shart.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Ikkinchi darajali matn',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../style_preview/tungi_haydash.png'),
    );
  });
}
