import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/features/search/map_first_results.dart';
import 'package:yolyolakay/features/search/results_map.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// XARITA-BIRINCHI natijalar.
///
/// 🔴 NEGA TEST: butun o'zgarishning ma'nosi bitta jumlada — xarita va
/// ro'yxat BIR VAQTDA ko'rinadi. Ilgari ular bir-birini almashtirardi.
/// Agar kelajakda kimdir varaqni yana alohida ekranga chiqarsa yoki
/// xaritani `Offstage` ga o'rasa, o'zgarishning butun foydasi yo'qoladi —
/// bu test shuni ushlaydi.
void main() {
  Ride rideAt(String id, double price, {List<String> stops = const []}) =>
      Ride.fromJson({
        'stops': [
          for (final c in stops) {'address': c, 'lat': 40.1158, 'lon': 67.8422},
        ],
        'id': id,
        'origin_address': 'Toshkent',
        'origin_lat': 41.2995,
        'origin_lon': 69.2401,
        'destination_address': 'Samarqand',
        'destination_lat': 39.6542,
        'destination_lon': 66.9597,
        'departure_time': '2026-08-20T09:00:00+05:00',
        'total_seats': 4,
        'available_seats': 3,
        'price_per_seat': price,
        'status': 'active',
        'driver': {'id': 'd-1', 'name': 'Aziz', 'rating': 4.9},
      });

  // ⚠️ `ProviderScope` SHART: `ResultsMap` tanlangan safar yo'lini
  // yuklash uchun `apiClientProvider` ni o'qiydi.
  Widget boot(List<Ride> rides) => ProviderScope(
    child: MaterialApp(
      locale: const Locale('uz'),
      supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: MapFirstResults(
          rides: rides,
          onTapRide: (_) {},
          // Kartaning o'rniga oddiy matn: bu test TARTIB va BIRGA
          // ko'rinishni tekshiradi, `RideCard` ning ichini emas
          // (uning o'z testlari bor).
          itemBuilder: (context, ride, selected) =>
              Text('${ride.id}${selected ? ' *' : ''}'),
        ),
      ),
    ),
  );

  /// `ResultsMap` ni yolg'iz ko'taradi — tanlangan safar bilan.
  Widget bootMap(List<Ride> rides, {String? selectedRideId}) => ProviderScope(
    child: MaterialApp(
      locale: const Locale('uz'),
      supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: ResultsMap(
          rides: rides,
          onTapRide: (_) {},
          selectedRideId: selectedRideId,
        ),
      ),
    ),
  );

  testWidgets('xarita va ro\'yxat BIR VAQTDA ko\'rinadi', (tester) async {
    await tester.pumpWidget(
      boot([rideAt('r-1', 100000), rideAt('r-2', 90000)]),
    );
    await tester.pump();

    expect(find.byType(ResultsMap), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.text('r-1'), findsOneWidget);
    expect(find.text('r-2'), findsOneWidget);
  });

  testWidgets('tartib boshida saralangan holicha qoladi', (tester) async {
    await tester.pumpWidget(
      boot([rideAt('r-1', 100000), rideAt('r-2', 90000)]),
    );
    await tester.pump();

    // Hech narsa tanlanmagan — yulduzcha yo'q.
    expect(find.text('r-1 *'), findsNothing);
    expect(find.text('r-2 *'), findsNothing);
  });

  /// 🔴 SINOVDA TOPILGAN HAQIQIY YIQILISH (2026-08-24): shahar nomidan
  /// tanlangan jo'nash nuqtasi kanonik ro'yxatdan keladi, ya'ni Toshkentdan
  /// chiqadigan hamma e'lon AYNAN bir xil koordinatada. `CameraFit` nol
  /// yuzali chegarada `zoom` ni cheksiz hisoblab, xaritani qizil ekran
  /// bilan yiqitardi. Bu eng KO'P uchraydigan holat edi.
  testWidgets('bir xil koordinatali safarlarda xarita yiqilmaydi', (
    tester,
  ) async {
    await tester.pumpWidget(
      boot([rideAt('r-1', 100000), rideAt('r-2', 90000), rideAt('r-3', 80000)]),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(ResultsMap), findsOneWidget);
  });

  testWidgets('bo\'sh ro\'yxatda ham yiqilmaydi', (tester) async {
    await tester.pumpWidget(boot(const []));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  /// YO'L USTIDAN QO'SHILISH (2026-09-08).
  ///
  /// 🔴 NEGA TEST: butun o'zgarishning ma'nosi shu — xaritada endi
  /// nafaqat jo'nash nuqtalari, balki ORALIQ shaharlar ham ko'rinadi
  /// va yozuv ularni tushuntiradi. Belgilar yozuvsiz qolsa, odam
  /// ularni «begona nuqta» deb o'tkazib yuboradi.
  ///
  /// ⚠️ `ResultsMap` TO'G'RIDAN sinaladi: `MapFirstResults` orqali
  /// tanlash uchun xaritadagi belgini bosish kerak, u esa sinov
  /// muhitida plitkalar yuklanmagani uchun ishonchsiz.
  testWidgets('tanlangan safarning oraliq shahri xaritada YOZILADI', (
    tester,
  ) async {
    const t = AppStrings(Lang.uz);
    await tester.pumpWidget(
      bootMap([
        rideAt('r-1', 100000, stops: ['Jizzax']),
      ], selectedRideId: 'r-1'),
    );
    await tester.pump();

    expect(find.text(t.joinAlongRoute('Jizzax')), findsOneWidget);
    // Belgining o'zi ham: yozuv bor-u, nuqta yo'q bo'lsa odam qayerga
    // qarashni bilmaydi.
    expect(find.text('Jizzax'), findsOneWidget);
  });

  /// Oraliq shahari YO'Q safarda yozuv ham chiqmasin — bo'sh yozuv
  /// ekranda joy yeydi va hech nima aytmaydi.
  testWidgets('oraliq shahar bo\'lmasa yozuv chizilmaydi', (tester) async {
    await tester.pumpWidget(
      bootMap([rideAt('r-1', 100000)], selectedRideId: 'r-1'),
    );
    await tester.pump();
    expect(find.textContaining("Yo'l ustidan"), findsNothing);
  });
}
