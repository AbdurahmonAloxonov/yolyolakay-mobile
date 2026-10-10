import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/features/rides/trip_passport.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// SAFAR PASPORTI — ulashiladigan karta.
///
/// 🔴 NEGA TEST: bu karta ILOVADAN CHIQIB ketadi — Telegramda, Instagram'da
/// begona odamlar ko'radi. Ustidagi har bir raqam brend va'dasi bo'lib
/// qoladi. Shuning uchun eng muhim qoida kod bilan qo'riqlanadi:
/// ma'lumot yo'q bo'lsa — QATOR CHIZILMAYDI, "0 km" yoki "—" yozilmaydi.
void main() {
  const t = AppStrings(Lang.uz);

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
    'driver': {'id': 'd-1', 'name': 'AZIZ KARIMOV', 'rating': 4.9},
  });

  Widget boot({double? distanceKm, Duration? duration}) => MaterialApp(
    locale: const Locale('uz'),
    supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: buildTheme(brightness: Brightness.light),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 360,
          child: TripPassport(
            ride: ride,
            distanceKm: distanceKm,
            duration: duration,
          ),
        ),
      ),
    ),
  );

  testWidgets('yo\'nalish va sana ko\'rinadi', (tester) async {
    await tester.pumpWidget(boot());
    await tester.pumpAndSettle();

    expect(find.text('Toshkent'), findsOneWidget);
    expect(find.text('Samarqand'), findsOneWidget);
    expect(find.text(t.tripPassportTitle.toUpperCase()), findsOneWidget);
  });

  /// Ism BOSH HARFDA keladi ("AZIZ KARIMOV") — kartada u baqirayotgandek
  /// ko'rinadi, ulashilgan rasmda esa bu ayniqsa xunuk.
  testWidgets('ism odam o\'qiydigan shaklda', (tester) async {
    await tester.pumpWidget(boot());
    await tester.pumpAndSettle();

    expect(find.text('AZIZ KARIMOV'), findsNothing);
    expect(find.text('Aziz Karimov'), findsOneWidget);
  });

  testWidgets('masofa va vaqt bo\'lsa — ko\'rsatiladi', (tester) async {
    await tester.pumpWidget(
      boot(distanceKm: 280, duration: const Duration(hours: 4)),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.tripPassportDistance.toUpperCase()), findsOneWidget);
    expect(find.text(t.tripPassportTime.toUpperCase()), findsOneWidget);
  });

  /// 🔴 ENG MUHIM QOIDA. Karta ilovadan chiqib ketadi — "0 km" yoki "—"
  /// yozilgan rasm brendni ishonchsiz qiladi. Ma'lumot yo'q bo'lsa qator
  /// UMUMAN bo'lmaydi.
  testWidgets('masofa/vaqt YO\'Q bo\'lsa — qator umuman chizilmaydi', (
    tester,
  ) async {
    await tester.pumpWidget(boot());
    await tester.pumpAndSettle();

    expect(find.text(t.tripPassportDistance.toUpperCase()), findsNothing);
    expect(find.text(t.tripPassportTime.toUpperCase()), findsNothing);
    expect(find.textContaining('0 km'), findsNothing);
    expect(find.text('—'), findsNothing);
  });

  testWidgets('faqat masofa bo\'lsa — faqat u chiqadi', (tester) async {
    await tester.pumpWidget(boot(distanceKm: 280));
    await tester.pumpAndSettle();

    expect(find.text(t.tripPassportDistance.toUpperCase()), findsOneWidget);
    expect(find.text(t.tripPassportTime.toUpperCase()), findsNothing);
  });
}
