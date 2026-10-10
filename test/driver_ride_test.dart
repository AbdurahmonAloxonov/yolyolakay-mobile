import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/features/rides/driver_ride_screen.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// Haydovchining o'z safari ekrani.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const t = AppStrings(Lang.uz);

  /// Ikkita bron: biri javob kutmoqda, biri tasdiqlangan. TARTIB ATAYIN
  /// "noto'g'ri" — ekran uni o'zi to'g'rilashi kerak.
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
    'available_seats': 1,
    'price_per_seat': 150000,
    'status': 'active',
    'bookings': [
      {
        'id': 'b-1',
        'ride_id': 'r-1',
        'passenger_id': 'p-1',
        'seats_booked': 2,
        'status': 'confirmed',
        'total_price': 300000,
        'passenger': {'id': 'p-1', 'name': 'Dilnoza', 'rating': 4.7},
      },
      {
        'id': 'b-2',
        'ride_id': 'r-1',
        'passenger_id': 'p-2',
        'seats_booked': 1,
        'status': 'pending',
        'offered_price': 120000,
        'passenger': {'id': 'p-2', 'name': 'Sardor'},
      },
    ],
  });

  /// FAOLLASHMAGAN (draft) safar — bronsiz. Ekrandagi tugmalar boshqa.
  final draftRide = Ride.fromJson(const {
    'id': 'r-draft',
    'origin_address': 'Toshkent',
    'origin_lat': 41.2995,
    'origin_lon': 69.2401,
    'destination_address': 'Buxoro',
    'destination_lat': 39.7681,
    'destination_lon': 64.421,
    'departure_time': '2026-08-20T20:35:00Z',
    'total_seats': 3,
    'available_seats': 3,
    'price_per_seat': 60000,
    'status': 'draft',
  });

  Future<Widget> boot({Ride? bootRide}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        locale: const Locale('uz'),
        supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: DriverRideScreen(ride: bootRide ?? ride),
      ),
    );
  }

  /// Ekran uzun: ro'yxat pastda qoladi va standart 800x600 da UMUMAN
  /// chizilmaydi (ListView faqat ko'rinadiganini quradi).
  Future<void> pumpScreen(WidgetTester tester, {Ride? bootRide}) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(await boot(bootRide: bootRide));
    await tester.pump();
  }

  /// 🔴 EGASI QURILMADA KO'RSATDI (2026-08-13): faollashmagan safar ekrani
  /// BO'M-BO'SH ochilardi — marshrut ham, bronlar ham yo'q, tugmalar esa
  /// sarlavha ustiga chiqib ketgan.
  ///
  /// Sabab: pastki paneldagi `Column` standart `mainAxisSize.max` bilan
  /// butun ekran balandligini egallab olardi va tanaga joy qolmasdi. Xato
  /// FAQAT `draft` holatida chiqardi — qolgan holatlarda u yerda `Row`
  /// qaytariladi.
  group('faollashmagan safar', () {
    testWidgets('ekran mazmuni CHIZILADI', (tester) async {
      await pumpScreen(tester, bootRide: draftRide);

      expect(find.text('Toshkent'), findsWidgets);
      expect(find.text('Buxoro'), findsWidgets);
      expect(find.text(t.activateRide), findsOneWidget);
    });

    /// 🔴 Ekran BO'M-BO'SH qolishining sababi — `bottomNavigationBar`
    /// uyasidagi ustun butun balandlikni egallashi. Uchala holatda ham
    /// (faollashmagan / faol / yo'lda) shu tuzoq bor edi.
    testWidgets('BOSHLANGAN safarda ham mazmun chiziladi', (tester) async {
      final started = Ride.fromJson(const {
        'id': 'r-started',
        'origin_address': 'Toshkent',
        'origin_lat': 41.2995,
        'origin_lon': 69.2401,
        'destination_address': 'Buxoro',
        'destination_lat': 39.7681,
        'destination_lon': 64.421,
        'departure_time': '2026-08-20T20:35:00Z',
        'total_seats': 3,
        'available_seats': 3,
        'price_per_seat': 60000,
        'status': 'in_progress',
      });
      await pumpScreen(tester, bootRide: started);

      expect(find.text('Toshkent'), findsWidgets);
      expect(find.text(t.completeRide), findsOneWidget);
    });

    testWidgets('tugmalar sarlavha ostida qoladi', (tester) async {
      await pumpScreen(tester, bootRide: draftRide);

      final appBarBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
      final buttonTop = tester
          .getTopLeft(find.widgetWithText(FilledButton, t.activateRide))
          .dy;
      expect(
        buttonTop,
        greaterThan(appBarBottom),
        reason: 'pastki panel sarlavha ustiga chiqib ketgan',
      );
    });
  });

  testWidgets('yo\'lovchi ISMI ko\'rinadi (ilgari faqat "2 joy" edi)', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Dilnoza'), findsOneWidget);
    expect(find.text('Sardor'), findsOneWidget);
    // Reyting ham — haydovchi shunga qarab qabul qiladi.
    expect(find.text('4.7'), findsOneWidget);
  });

  testWidgets('javob kutayotgan bron TEPADA turadi', (tester) async {
    await pumpScreen(tester);

    final pendingY = tester.getTopLeft(find.text('Sardor')).dy;
    final confirmedY = tester.getTopLeft(find.text('Dilnoza')).dy;
    expect(
      pendingY,
      lessThan(confirmedY),
      reason: 'haydovchining yagona bajariladigan ishi — javob berish',
    );
  });

  testWidgets('tasdiqlangan bronlardan tushadigan pul ko\'rsatiladi', (
    tester,
  ) async {
    await pumpScreen(tester);

    // 300 000 — ilgari haydovchi buni ko'z bilan qo'shishi kerak edi.
    expect(find.textContaining('300'), findsWidgets);
    expect(find.textContaining(t.confirmedLabel), findsWidgets);
  });

  testWidgets('faol safarda boshlash va bekor qilish tugmalari bor', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text(t.startRide), findsOneWidget);
    expect(find.text(t.cancelRide), findsOneWidget);
    // Kutayotgan bron uchun qabul/rad.
    expect(find.text(t.accept), findsOneWidget);
    expect(find.text(t.reject), findsOneWidget);
  });
}
