import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/active_role.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/data/models/booking.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/features/rides/ride_hero.dart';
import 'package:yolyolakay/features/rides/today_card.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// «YAQIN SAFAR» kartasi — bosh ekranning tepasi.
///
/// 🔴 NEGA TEST: bu karta EKRAN TEPASIDA turadi, ya'ni noto'g'ri ishlasa
/// odam uni har ochilganda ko'radi. Ikki xato eng qimmatga tushadi:
///   • bo'sh/eski safarda karta CHIZILISHI — ekran tepasidan bekorga joy
///     yeydi va "safaringiz bor" deb aldaydi;
///   • jo'nab ketgan safar YO'QOLISHI — odam yo'lda, karta esa unga aynan
///     o'sha paytda kerak.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// Jo'nash vaqti HOZIRGA nisbatan beriladi: qat'iy sana yozilsa test
  /// bir kun kelib o'z-o'zidan yiqilardi.
  Ride rideAt(Duration fromNow, {String id = 'r-1', String status = 'active'}) =>
      Ride.fromJson({
        'id': id,
        'origin_address': 'Toshkent',
        'origin_lat': 41.2995,
        'origin_lon': 69.2401,
        'destination_address': 'Samarqand',
        'destination_lat': 39.6542,
        'destination_lon': 66.9597,
        'departure_time': DateTime.now().add(fromNow).toIso8601String(),
        'total_seats': 4,
        'available_seats': 2,
        'price_per_seat': 150000,
        'status': status,
        'driver': {'id': 'd-1', 'name': 'Aziz', 'rating': 4.9},
      });

  Booking bookingFor(Ride ride) => Booking(
    id: 'b-${ride.id}',
    rideId: ride.id,
    passengerId: 'u-1',
    seatsBooked: 2,
    status: BookingStatus.confirmed,
    totalPrice: 300000,
    ride: ride,
  );

  Widget boot({
    required bool driverMode,
    List<Booking> bookings = const [],
    List<Ride> rides = const [],
  }) => ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      activeRoleProvider.overrideWith(
        (ref) => _FixedRole(driverMode ? AppRole.driver : AppRole.passenger),
      ),
      myBookingsProvider.overrideWith((ref) async => bookings),
      myRidesProvider.overrideWith((ref) async => rides),
    ],
    child: const MaterialApp(
      locale: Locale('uz'),
      supportedLocales: [Locale('uz'), Locale('ru'), Locale('en')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: TodayCard()),
    ),
  );

  const t = AppStrings(Lang.uz);

  testWidgets('safar yo\'q — karta UMUMAN chizilmaydi', (tester) async {
    await tester.pumpWidget(boot(driverMode: false));
    await tester.pumpAndSettle();

    // "Safaringiz yo'q" degan bo'sh quti ham qo'yilmaydi: u har kuni
    // ekran tepasidan joy yeb turadi va hech qachon foydali bo'lmaydi.
    expect(find.text(t.todayCardTitle), findsNothing);
    expect(find.text('Toshkent'), findsNothing);
  });

  testWidgets('yaqin bron — karta ko\'rinadi', (tester) async {
    await tester.pumpWidget(
      boot(
        driverMode: false,
        bookings: [bookingFor(rideAt(const Duration(hours: 3)))],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.todayCardTitle.toUpperCase()), findsOneWidget);
    expect(find.text('Toshkent'), findsOneWidget);
    expect(find.text('Samarqand'), findsOneWidget);
  });

  /// 🔴 Odam yo'lda bo'lishi mumkin — jo'nab ketgan safar darhol
  /// yo'qolmaydi. Aynan o'sha paytda unga haydovchi ismi va safar
  /// tafsiloti kerak bo'ladi.
  testWidgets('yaqinda jo\'nab ketgan safar HALI ham ko\'rinadi', (
    tester,
  ) async {
    await tester.pumpWidget(
      boot(
        driverMode: false,
        bookings: [bookingFor(rideAt(const Duration(minutes: -30)))],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.todayCardTitle.toUpperCase()), findsOneWidget);
  });

  testWidgets('ancha oldin jo\'nab ketgan safar chizilmaydi', (tester) async {
    await tester.pumpWidget(
      boot(
        driverMode: false,
        bookings: [bookingFor(rideAt(const Duration(hours: -5)))],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.todayCardTitle.toUpperCase()), findsNothing);
  });

  testWidgets('bir nechta bron — ENG YAQINI tanlanadi', (tester) async {
    final near = rideAt(const Duration(hours: 2), id: 'r-near');
    final far = rideAt(const Duration(days: 3), id: 'r-far');
    // Ro'yxat ATAYIN teskari tartibda: karta saralashga tayanmasin.
    await tester.pumpWidget(
      boot(driverMode: false, bookings: [bookingFor(far), bookingFor(near)]),
    );
    await tester.pumpAndSettle();

    // Bitta karta — ikkitasi emas.
    expect(find.text(t.todayCardTitle.toUpperCase()), findsOneWidget);
    // Va u aynan yaqinigi: Hero teglari safar ID siga bog'langan.
    final heroes = tester
        .widgetList<RideHero>(find.byType(RideHero))
        .map((h) => h.rideId)
        .toSet();
    expect(heroes, {'r-near'});
  });

  /// Bekor qilingan e'lon "yaqin safar" emas — u umuman bo'lmaydi.
  testWidgets('haydovchi: bekor qilingan e\'lon chizilmaydi', (tester) async {
    await tester.pumpWidget(
      boot(
        driverMode: true,
        rides: [rideAt(const Duration(hours: 2), status: 'cancelled')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.todayCardTitle.toUpperCase()), findsNothing);
  });

  /// Haydovchiga o'z e'lonida "Haydovchi: Aziz" deb o'zini tanishtirish
  /// ma'nosiz — o'rniga band o'rindiqlar ko'rsatiladi.
  testWidgets('haydovchi: haydovchi qatori emas, BAND O\'RINDIQLAR', (
    tester,
  ) async {
    await tester.pumpWidget(
      boot(driverMode: true, rides: [rideAt(const Duration(hours: 2))]),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.seatsBookedOf(2, 4)), findsOneWidget);
    expect(find.text('Aziz'), findsNothing);
  });
}

class _FixedRole extends ActiveRoleNotifier {
  _FixedRole(AppRole role) : super(_NoPrefs(), role);
}

/// `ActiveRoleNotifier` prefs so'raydi, lekin sinovda saqlash kerak emas.
class _NoPrefs implements SharedPreferences {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
