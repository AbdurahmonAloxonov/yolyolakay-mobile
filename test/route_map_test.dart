import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/core/api/token_storage.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/data/models/telematics.dart';
import 'package:yolyolakay/features/map/route_map_sheet.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// MARSHRUT XARITASI varag'i.
///
/// 🔴 NEGA TEST (2026-08-30): xarita bu loyihada UMUMAN test bilan
/// qoplanmagan edi va aynan shu yerda ikkita xato yashiringan edi:
///
///  1. Egasi: «hatto haydovchi bo'lsang ham o'zing qayerdaligingni
///     ko'rib bo'lmaydi» — xaritada «mening joyim» tugmasi YO'Q edi.
///  2. Varaqni yopish DEBUG build'da xato tashlardi: neon uslub
///     yoqilmagan bo'lsa `late final` animatsiya kontrolleri hech
///     qachon yaratilmasdi va `dispose` uni AYNAN o'shanda birinchi
///     marta yaratardi — o'chirilgan elementda `TickerMode` qidirib.
void main() {
  const t = AppStrings(Lang.uz);

  Ride ride({String status = RideStatus.inProgress}) => Ride(
    id: 'r1',
    originAddress: 'Toshkent',
    destinationAddress: 'Samarqand',
    originLat: 41.2995,
    originLon: 69.2401,
    destinationLat: 39.6542,
    destinationLon: 66.9597,
    departureTime: DateTime(2026, 9, 1, 9),
    totalSeats: 4,
    availableSeats: 3,
    pricePerSeat: 100000,
    status: status,
  );

  Future<void> openMap(
    WidgetTester tester,
    Ride r, {
    NearbyDriver? driver,
    bool overrideDriver = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(TokenStorage()),
          if (overrideDriver)
            driverPositionProvider.overrideWith((ref, ride) async => driver),
        ],
        child: MaterialApp(
          locale: const Locale('uz'),
          supportedLocales: const [Locale('uz')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showRouteMapSheet(context, r),
                  child: const Text('xarita'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('xarita'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('«mening joyim» tugmasi xaritada bor', (tester) async {
    await openMap(tester, ride());

    // Tugma boshida O'CHIQ holatda: nuqta yo'q, GPS ishlamaydi.
    // Bosilmaguncha ruxsat ham so'ralmaydi.
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.byTooltip(t.myLocation), findsOneWidget);
    // Kuzatuv hali boshlanmagan — «to'xtatish» yozuvi turmasin.
    expect(find.byTooltip(t.myLocationStop), findsNothing);
  });

  testWidgets('tugma xaritaning USTIDA, ekran ichida', (tester) async {
    await openMap(tester, ride());

    final rect = tester.getRect(find.byType(FloatingActionButton));
    expect(rect.left >= 0 && rect.right <= 390, isTrue, reason: '$rect');
    expect(rect.top >= 0 && rect.bottom <= 844, isTrue, reason: '$rect');
    // Kamida 40×40: harakatlanayotgan mashinada barmoq aniq tushmaydi.
    expect(rect.width, greaterThanOrEqualTo(40));
    expect(rect.height, greaterThanOrEqualTo(40));
  });

  /// 🔴 Varaqni YOPISH xato tashlamasin — izohi fayl boshida.
  /// `takeException` bo'sh bo'lishi kerak.
  testWidgets('varaq yopilganda xato tashlamaydi', (tester) async {
    await openMap(tester, ride());
    expect(find.byType(FloatingActionButton), findsOneWidget);

    Navigator.of(tester.element(find.byType(FloatingActionButton))).pop();
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  /// Safar boshlanmagan bo'lsa ham xarita ochilaveradi (marshrutni
  /// oldindan ko'rish) — «mening joyim» esa baribir kerak.
  testWidgets('safar boshlanmagan bo\'lsa ham ochiladi', (tester) async {
    await openMap(tester, ride(status: RideStatus.active));
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  /// SAFAR HOLATI XARITADA (2026-09-08).
  ///
  /// 🔴 NEGA: xarita ochilganda marshrut ham, mashina nuqtasi ham
  /// bir xil ko'rinadi — safar boshlanganmi yoki hali kutilyaptimi,
  /// bilinmasdi. Mashina nuqtasi ikkala holatda ham o'sha joyda
  /// turadi, ya'ni undan xulosa chiqarib bo'lmaydi.
  testWidgets('xaritada safar holati ko\'rinadi', (tester) async {
    await openMap(tester, ride(status: RideStatus.inProgress));
    expect(find.text(t.rideStatus(RideStatus.inProgress)), findsOneWidget);
  });

  /// Belgi QOTIB qolmasin: boshqa holatda boshqa yozuv.
  ///
  /// ⚠️ Alohida test — bitta test ichida `openMap` ni ikki marta
  /// chaqirsak eski varaq daraxtda qolib, yangisi topilmaydi.
  testWidgets('holat belgisi safarga qarab o\'zgaradi', (tester) async {
    await openMap(tester, ride(status: RideStatus.active));
    expect(find.text(t.rideStatus(RideStatus.active)), findsOneWidget);
    expect(find.text(t.rideStatus(RideStatus.inProgress)), findsNothing);
  });

  /// 🔴 XARITA OCHILMASDI (28.09.2026): hamma nuqta BITTA joyda bo'lsa
  /// (koordinatasiz safar — ikkala uchi 0,0; yoki jo'nash = manzil)
  /// `CameraFit.coordinates` zumni CHEKSIZ hisoblaydi va varaq
  /// «Camera `zoom` must be finite» bilan yiqilardi. Natijalar va
  /// posilka xaritasida bu himoya 24.08 dan beri bor edi, shu varaqda
  /// yo'q edi — «Yo'lda» rejimidagi «Yo'nalish» tugmasi va haydovchi
  /// ekranidagi xarita ikonkasi aynan shu varaqni ochadi.
  Ride sameSpot(double lat, double lon) => Ride(
    id: 'r2',
    originAddress: 'Toshkent',
    destinationAddress: 'Toshkent',
    originLat: lat,
    originLon: lon,
    destinationLat: lat,
    destinationLon: lon,
    departureTime: DateTime(2026, 9, 1, 9),
    totalSeats: 4,
    availableSeats: 3,
    pricePerSeat: 100000,
    status: RideStatus.active,
  );

  testWidgets('jo\'nash = manzil — xarita YIQILMAYDI', (tester) async {
    await openMap(tester, sameSpot(41.2995, 69.2401));
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
  });

  testWidgets('koordinatasiz safar — xarita YIQILMAYDI', (tester) async {
    await openMap(tester, sameSpot(0, 0));
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
  });

  /// ═══ MASHINA NUQTASI TIRIKMI (17.09.2026) ═══
  ///
  /// 🔴 NEGA: nuqta ping to'xtaganda O'SHA JOYDA QOTIB QOLADI va
  /// jonli nuqtadan farq qilmaydi — xarita jim turib «hammasi joyida»
  /// deb ko'rsatardi. Saytda bu qator bor edi, ilovada yo'q edi:
  /// `NearbyDriver` serverdan kelgan `updated_at` ni O'QIMASDI.
  NearbyDriver driverAt(Duration ago) => NearbyDriver(
    driverId: 'd1',
    lat: 40.5,
    lon: 68.0,
    updatedAt: DateTime.now().subtract(ago),
  );

  testWidgets('yangi ping — «yangilandi: N daqiqa oldin»', (tester) async {
    await openMap(
      tester,
      ride(),
      driver: driverAt(const Duration(minutes: 2)),
      overrideDriver: true,
    );
    expect(find.text(t.locationUpdatedAgo(2)), findsOneWidget);
  });

  testWidgets('eskirgan ping — SABABI bilan aytiladi', (tester) async {
    await openMap(
      tester,
      ride(),
      driver: driverAt(const Duration(minutes: 25)),
      overrideDriver: true,
    );
    expect(find.text(t.locationStale(25)), findsOneWidget);
    // «Yangilandi» deb YOLG'ON aytilmasin.
    expect(find.text(t.locationUpdatedAgo(25)), findsNothing);
  });

  /// ⚠️ «Hali yubormagan» DEB AYTILMAYDI: server oxirgi pingni ~40
  /// daqiqa saqlaydi va keyin 404 beradi — nuqta yo'qligi «aloqadan
  /// chiqdi» degani ham bo'lishi mumkin.
  testWidgets('nuqta umuman yo\'q — sababi aytiladi', (tester) async {
    await openMap(tester, ride(), overrideDriver: true);
    expect(find.text(t.locationUnavailable), findsOneWidget);
  });

  /// Safar hali boshlanmagan bo'lsa ping ham kutilmaydi — qator
  /// ortiqcha tashvish bo'lardi.
  testWidgets('safar boshlanmagan — ping qatori umuman yo\'q', (tester) async {
    await openMap(
      tester,
      ride(status: RideStatus.active),
      overrideDriver: true,
    );
    expect(find.text(t.locationUnavailable), findsNothing);
  });
}
