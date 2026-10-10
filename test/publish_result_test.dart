import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/features/rides/ride_card.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// O'Z E'LONIM KARTOCHKASI.
///
/// 🔴 Qurilmada ko'rildi (2026-08-13): safar paketi tugagach e'lon
/// yaratildi-yu FAOLLASHMADI — ya'ni qidiruvda umuman ko'rinmaydi. Lekin
/// ro'yxatdagi kartochka oddiy e'londan farq qilmasdi va haydovchi uni
/// joylandi deb o'ylab yuraverardi. Ustiga, o'z e'lonim kartochkasida
/// pastda "Haydovchi" degan qator turardi — ilova menga o'zimni tanishtirardi.
void main() {
  Ride ride({required String status}) => Ride(
    id: 'r-1',
    originLat: 41.3,
    originLon: 69.2,
    destinationLat: 39.6,
    destinationLon: 66.9,
    originAddress: 'Toshkent',
    destinationAddress: 'Buxoro',
    departureTime: DateTime(2026, 8, 20, 20, 35),
    totalSeats: 4,
    availableSeats: 3,
    pricePerSeat: 60000,
    status: status,
  );

  // `uz` Material tarjimalarida yo'q — delegatlarsiz `Localizations.localeOf`
  // inglizchaga tushib qoladi va AppStrings inglizcha matn qaytaradi.
  Widget boot(Widget child) => MaterialApp(
    locale: const Locale('uz'),
    supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );

  const t = AppStrings(Lang.uz);

  testWidgets('faollashmagan e\'lonim BELGILANADI', (tester) async {
    await tester.pumpWidget(
      boot(RideCard(ride: ride(status: 'pending'), mine: true)),
    );
    await tester.pump();

    expect(find.text(t.rideNotActive), findsOneWidget);
    // O'zimni "Haydovchi" deb tanishtirmaymiz.
    expect(find.text(t.driver), findsNothing);
  });

  testWidgets('faol e\'lonim "qidiruvda ko\'rinadi" deydi', (tester) async {
    await tester.pumpWidget(
      boot(RideCard(ride: ride(status: 'active'), mine: true)),
    );
    await tester.pump();

    expect(find.text(t.rideVisible), findsOneWidget);
  });

  testWidgets('BEGONA safarda haydovchi qatori qoladi', (tester) async {
    await tester.pumpWidget(boot(RideCard(ride: ride(status: 'active'))));
    await tester.pump();

    // Yo'lovchiga kim haydashi MUHIM — bu qator o'chib qolmasin.
    expect(find.text(t.rideVisible), findsNothing);
    expect(find.text(t.driver), findsOneWidget);
  });
}
