import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/features/rides/eta_ring.dart';
import 'package:yolyolakay/features/rides/seat_map.dart';
import 'package:yolyolakay/features/rides/trip_passport.dart';
import 'package:yolyolakay/features/search/date_strip.dart';

/// «KATTA MATN» REJIMI — 1.6 chegarasida layout butun qolishi.
///
/// 🔴 NEGA (2026-08-25): ilova ilgari shriftni 1.3 da CHEKLARDI va butun
/// layout aynan shu chegarada tekshirilgan edi. «Kattaroq matn» tugmasi
/// chegarani 1.6 ga ko'tardi — ya'ni men ilovani ilgari HECH QACHON
/// sinalmagan holatga qo'ydim.
///
/// Bu ayniqsa xavfli, chunki tugmani aynan ko'zi xira odam yoqadi: unga
/// «kattaroq matn» va'da qilamiz, u esa toshib ketgan, o'qib bo'lmaydigan
/// ekran oladi. Yolg'on va'dadan ko'ra chegarani past qo'ygan yaxshi
/// bo'lardi — shuning uchun va'da kod bilan qo'riqlanadi.
///
/// SHU SESSIYADA qo'shilgan vidjetlar sinaladi; eskilari
/// `layout_narrow_test.dart` da allaqachon 1.6 da tekshiriladi.
void main() {
  Ride ride() => Ride.fromJson(const {
    'id': 'r-1',
    'origin_address': 'Toshkent, Yunusobod tumani',
    'origin_lat': 41.2995,
    'origin_lon': 69.2401,
    'destination_address': 'Qoraqalpog\'iston, Nukus shahri',
    'destination_lat': 42.4600,
    'destination_lon': 59.6100,
    'departure_time': '2026-08-20T09:00:00+05:00',
    'total_seats': 4,
    'available_seats': 3,
    'price_per_seat': 150000,
    'status': 'completed',
    'driver': {'id': 'd-1', 'name': 'ABDURAHMON MUXAMMADALIYEV', 'rating': 4.9},
  });

  /// Eng yomon holat: TOR ekran (320dp) + eng katta ruxsat etilgan shrift.
  Widget wrap(Widget child, {List<Override> overrides = const []}) =>
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          locale: const Locale('uz'),
          supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildTheme(brightness: Brightness.light),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 720),
              textScaler: TextScaler.linear(1.6),
            ),
            child: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        ),
      );

  DateTime day(int plus) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: plus));
  }

  testWidgets('sana lentasi 1.6 da toshmaydi', (tester) async {
    await tester.pumpWidget(
      wrap(
        DateStrip(onPick: (_) {}),
        overrides: [
          ridesPerDayProvider.overrideWith(
            (ref) async => {day(1): 12, day(2): 3},
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('o\'rindiq sxemasi 1.6 da toshmaydi', (tester) async {
    await tester.pumpWidget(
      wrap(const SeatMap(totalSeats: 8, availableSeats: 6)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('safar pasporti 1.6 da toshmaydi', (tester) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 320,
          child: TripPassport(
            ride: ride(),
            distanceKm: 1281,
            duration: const Duration(hours: 14, minutes: 35),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('ETA halqasi 1.6 da toshmaydi', (tester) async {
    await tester.pumpWidget(
      wrap(const EtaRing(child: CircleAvatar(child: Text('A')))),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
