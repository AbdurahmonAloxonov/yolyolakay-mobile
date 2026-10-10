import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/active_role.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/data/models/booking.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/features/rides/ride_card.dart';
import 'package:yolyolakay/features/rides/seat_map.dart';
import 'package:yolyolakay/features/rides/today_card.dart';
import 'package:yolyolakay/features/rides/journey_view.dart';
import 'package:yolyolakay/features/search/date_strip.dart';
import 'package:yolyolakay/features/shared/brand/suzani_icons.dart';

import 'support/preview_fonts.dart';

/// PLAY DO'KONI UCHUN SKRINSHOTLAR.
///
/// 🔴 NEGA YOZILDI (2026-08-25): `store/screenshots/` dagi rasmlar
/// 12-AVGUSTDAN. Ularda suzani ikonkalari ham, «Yaqin safar» kartasi
/// ham, sana lentasi ham YO'Q — do'kon sahifasi endi mavjud bo'lmagan
/// ilovani ko'rsatyapti.
///
/// Do'kon sahifasi = O'RNATISH KONVERSIYASI: odam avval skrinshotni
/// ko'radi, keyin o'rnatadi.
///
/// ⚠️ TO'LIQ EKRANLAR EMAS, TERILGAN KOMPOZITSIYALAR. Sabab halol:
/// haqiqiy ekranlar o'nlab providerga bog'langan va sinov muhitida
/// ularning yarmi bo'sh chiqadi (xarita plitkalari yuklanmaydi, media
/// 404). Bunday rasm ilovani YOMONROQ ko'rsatardi. Bu yerda esa
/// AYNAN O'SHA vidjetlar, faqat ma'lumot qo'lda berilgan — ya'ni
/// odam ilovada ko'radigan narsa.
///
/// Yangilash:
///   flutter test test/store_screenshots.dart --update-goldens
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadPreviewFonts);

  Ride ride({
    required String from,
    required String to,
    required double price,
    int seats = 2,
    String id = 'r-1',
    String status = 'active',
    // 🔴 Do'kon rasmida uchta bir xil qator «yasama» bo'lib ko'rinadi:
    // bir xil ism, bir xil vaqt, bir xil masofa. Haqiqiy ro'yxat
    // hech qachon bunday bo'lmaydi.
    String driver = 'Aziz Karimov',
    double rating = 4.9,
    Duration after = const Duration(hours: 3),
  }) => Ride.fromJson({
    'id': id,
    'origin_address': from,
    'origin_lat': 41.2995,
    'origin_lon': 69.2401,
    'destination_address': to,
    'destination_lat': 39.6542,
    'destination_lon': 66.9597,
    'departure_time': DateTime.now().add(after).toIso8601String(),
    'total_seats': 4,
    'available_seats': seats,
    'price_per_seat': price,
    'status': status,
    'driver': {'id': 'd-$id', 'name': driver, 'rating': rating},
    'has_ac': true,
    'no_smoking': true,
  });

  /// Do'kon o'lchami — mavjud rasmlar bilan bir xil (1204x2408).
  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget Function(BuildContext context) body, {
    List<Override> overrides = const [],
  }) async {
    tester.view.devicePixelRatio = 3.0871794871794872;
    tester.view.physicalSize = const Size(1204, 2408);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: withPreviewFont(buildTheme(brightness: Brightness.light)),
          locale: const Locale('uz'),
          supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(builder: body),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../store/screenshots/$name.png'),
    );
  }

  /// Pastki menyu — suzani ikonkalari HAR skrinshotda ko'rinsin: ular
  /// ilovaning eng tanib olinadigan qismi.
  Widget nav(int index) => NavigationBar(
    selectedIndex: index,
    destinations: const [
      NavigationDestination(
        icon: SuzaniIconWidget(SuzaniIcon.search),
        selectedIcon: SuzaniIconWidget(SuzaniIcon.search, filled: true),
        label: 'Qidirish',
      ),
      NavigationDestination(
        icon: SuzaniIconWidget(SuzaniIcon.car),
        selectedIcon: SuzaniIconWidget(SuzaniIcon.car, filled: true),
        label: 'Safarlarim',
      ),
      NavigationDestination(
        icon: SuzaniIconWidget(SuzaniIcon.parcel),
        selectedIcon: SuzaniIconWidget(SuzaniIcon.parcel, filled: true),
        label: 'Pochta',
      ),
      NavigationDestination(
        icon: SuzaniIconWidget(SuzaniIcon.chat),
        selectedIcon: SuzaniIconWidget(SuzaniIcon.chat, filled: true),
        label: 'Suhbatlar',
      ),
      NavigationDestination(
        icon: SuzaniIconWidget(SuzaniIcon.person),
        selectedIcon: SuzaniIconWidget(SuzaniIcon.person, filled: true),
        label: 'Profil',
      ),
    ],
  );

  DateTime day(int plus) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: plus));
  }

  // ══ 1. Yaqin safar — bosh ekranning yangi qiyofasi ══════════════════
  testWidgets('01 — yaqin safar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final booked = ride(from: 'Toshkent', to: 'Samarqand', price: 150000);

    await shoot(
      tester,
      '01-yaqin-safar',
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        activeRoleProvider.overrideWith(
          (ref) => _FixedRole(prefs, AppRole.passenger),
        ),
        myRidesProvider.overrideWith((ref) async => const <Ride>[]),
        myBookingsProvider.overrideWith(
          (ref) async => [
            Booking(
              id: 'b-1',
              rideId: booked.id,
              passengerId: 'u-1',
              seatsBooked: 2,
              status: BookingStatus.confirmed,
              ride: booked,
            ),
          ],
        ),
      ],
      (context) => Scaffold(
        appBar: AppBar(title: const Text('Safar qidirish')),
        bottomNavigationBar: nav(0),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const TodayCard(),
            const SizedBox(height: 8),
            Text(
              'OXIRGI YO\'NALISHLAR',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: const [
                Chip(label: Text('Toshkent → Samarqand')),
                Chip(label: Text('Toshkent → Farg\'ona')),
              ],
            ),
            const SizedBox(height: 20),
            // QIDIRUV FORMASI — ekranning asosiy qismi. Usiz kadrning
            // yarmi oq bo'sh joy bo'lib qolardi (ko'z bilan ko'rildi).
            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.trip_origin),
                    title: Text('Toshkent'),
                    subtitle: Text('Qayerdan'),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.place_outlined),
                    title: Text('Samarqand'),
                    subtitle: Text('Qayerga'),
                  ),
                  const Divider(height: 1),
                  Row(
                    children: const [
                      Expanded(
                        child: ListTile(
                          leading: Icon(Icons.calendar_today_outlined),
                          title: Text('9-sentabr'),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          leading: Icon(Icons.person_outline),
                          title: Text('1 yo\'lovchi'),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.search),
                        label: const Text('Qidirish'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  });

  // ══ 2. Sana lentasi + natijalar ═════════════════════════════════════
  testWidgets('02 — natijalar', (tester) async {
    await shoot(
      tester,
      '02-natijalar',
      overrides: [
        ridesPerDayProvider.overrideWith(
          (ref) async => {day(0): 4, day(1): 12, day(2): 3, day(4): 7},
        ),
      ],
      (context) => Scaffold(
        appBar: AppBar(title: const Text('Topilgan safarlar')),
        bottomNavigationBar: nav(0),
        body: Column(
          children: [
            const SizedBox(height: 8),
            DateStrip(onPick: (_) {}),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  RideCard(
                    ride: ride(
                      from: 'Toshkent',
                      to: 'Samarqand',
                      price: 130000,
                      driver: 'Aziz Karimov',
                      after: const Duration(hours: 3, minutes: 10),
                    ),
                    distanceKm: 1.2,
                    medianPrice: 160000,
                  ),
                  const SizedBox(height: 12),
                  RideCard(
                    ride: ride(
                      from: 'Toshkent',
                      to: 'Samarqand',
                      price: 160000,
                      seats: 1,
                      id: 'r-2',
                      driver: 'Dilnoza Rahimova',
                      rating: 5.0,
                      after: const Duration(hours: 5, minutes: 40),
                    ),
                    distanceKm: 4.8,
                  ),
                  const SizedBox(height: 12),
                  RideCard(
                    ride: ride(
                      from: 'Toshkent',
                      to: 'Samarqand',
                      price: 180000,
                      seats: 3,
                      id: 'r-3',
                      driver: 'Sherzod Umarov',
                      rating: 4.7,
                      after: const Duration(hours: 8, minutes: 15),
                    ),
                    distanceKm: 9.1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  });

  // ══ 3. Safar tafsiloti — o'rindiq sxemasi va marshrut ═══════════════
  testWidgets('03 — safar tafsiloti', (tester) async {
    await shoot(tester, '03-safar', (context) {
      final theme = Theme.of(context);
      return Scaffold(
        appBar: AppBar(title: const Text('Safar')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Bugun 14:30',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          '150 000 so\'m',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const JourneyLine(
                      origin: 'Toshkent, Chilonzor',
                      destination: 'Samarqand, Registon',
                      stops: ['Jizzax'],
                      originTime: '14:30',
                    ),
                    const SizedBox(height: 16),
                    const SeatMap(totalSeats: 4, availableSeats: 2),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.directions_car_outlined),
                title: const Text('Chevrolet Cobalt'),
                subtitle: const Text('01 A 123 BC · oq'),
              ),
            ),
            const SizedBox(height: 12),
            // Haydovchi va qulayliklar — ekranning qolgan qismi. Usiz
            // kadr pastida oq bo'shliq qolardi (ko'z bilan ko'rildi).
            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text('Aziz Karimov'),
                    subtitle: Text('★ 4.9 · 27 ta safar'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: const [
                        Chip(
                          avatar: Icon(Icons.ac_unit, size: 18),
                          label: Text('Konditsioner'),
                        ),
                        Chip(
                          avatar: Icon(Icons.smoke_free, size: 18),
                          label: Text('Chekilmaydi'),
                        ),
                        Chip(
                          avatar: Icon(Icons.luggage, size: 18),
                          label: Text('Yuk joyi'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () {},
              child: const Text('Bron qilish'),
            ),
          ),
        ),
      );
    });
  });

  // ══ 4. Tungi haydash uslubi ═════════════════════════════════════════
  testWidgets('04 — tungi haydash', (tester) async {
    tester.view.devicePixelRatio = 3.0871794871794872;
    tester.view.physicalSize = const Size(1204, 2408);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: withPreviewFont(
          buildTheme(brightness: Brightness.dark, style: ThemeStyle.amber),
        ),
        locale: const Locale('uz'),
        supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          appBar: AppBar(title: const Text('Tungi haydash')),
          bottomNavigationBar: nav(1),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              RideCard(
                ride: ride(
                  from: 'Namangan',
                  to: 'Toshkent',
                  price: 120000,
                  driver: 'Otabek Yo\'ldoshev',
                  rating: 4.8,
                  after: const Duration(hours: 2, minutes: 20),
                ),
                distanceKm: 2.4,
              ),
              const SizedBox(height: 12),
              RideCard(
                ride: ride(
                  from: 'Namangan',
                  to: 'Toshkent',
                  price: 140000,
                  seats: 1,
                  id: 'r-2',
                  driver: 'Nodira Qosimova',
                  rating: 4.9,
                  after: const Duration(hours: 6, minutes: 5),
                ),
              ),
              const SizedBox(height: 12),
              // Uchinchi karta — kadr pastida qora bo'shliq qolmasin
              // (ikkitasi bilan ekran yarim bo'sh chiqardi).
              RideCard(
                ride: ride(
                  from: 'Namangan',
                  to: 'Toshkent',
                  price: 110000,
                  seats: 3,
                  id: 'r-3',
                  driver: 'Bekzod Ismoilov',
                  rating: 4.6,
                  after: const Duration(hours: 9, minutes: 30),
                ),
                distanceKm: 6.7,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../store/screenshots/04-tungi.png'),
    );
  });
  // ══ 5. «Faqat ayollar» filtri ═══════════════════════════════════════
  //
  // 🔴 NEGA DO'KONGA CHIQADI (2026-09-08): bu bizning Telegram
  // guruhlaridan ham, shahar taksilaridan ham farqimiz. Skrinshotda
  // ko'rinmasa, u haqda hech kim bilmaydi.
  testWidgets('05 — faqat ayollar filtri', (tester) async {
    await shoot(tester, '05-ayollar', (context) {
      final theme = Theme.of(context);
      Widget row(
        IconData icon,
        String label, {
        String? sub,
        bool value = false,
      }) => SwitchListTile(
        value: value,
        onChanged: (_) {},
        dense: true,
        title: Text(label),
        subtitle: sub == null ? null : Text(sub),
        secondary: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      );

      return Scaffold(
        appBar: AppBar(title: const Text('Filtrlar')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          children: [
            row(
              Icons.female,
              'Faqat ayollar',
              sub: 'Haydovchi bu safarga faqat ayol yo\'lovchi oladi',
              value: true,
            ),
            const Divider(height: 8),
            row(Icons.local_shipping, 'Pochta'),
            row(Icons.smoke_free, 'Chekilmaydi', value: true),
            row(Icons.pets, 'Hayvonsiz'),
            row(Icons.ac_unit, 'Konditsioner', value: true),
            row(Icons.luggage, 'Yuk joyi'),
            row(Icons.airline_seat_recline_normal, 'Orqada 2 kishi'),
            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Narx oralig\'i',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: '100 000'),
                      decoration: const InputDecoration(labelText: 'dan'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: '200 000'),
                      decoration: const InputDecoration(labelText: 'gacha'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton(
                onPressed: () {},
                child: const Text('Ko\'rsatish'),
              ),
            ),
          ],
        ),
        bottomNavigationBar: nav(0),
      );
    });
  });

  // ══ 6. Posilka — holat zanjiri ══════════════════════════════════════
  testWidgets('06 — posilka', (tester) async {
    await shoot(tester, '06-posilka', (context) {
      final theme = Theme.of(context);
      Widget step(IconData icon, String title, String when, bool done) =>
          ListTile(
            leading: Icon(
              icon,
              color: done
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
            title: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: done ? FontWeight.w800 : FontWeight.w500,
                color: done
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.outline,
              ),
            ),
            subtitle: when.isEmpty ? null : Text(when),
          );

      return Scaffold(
        appBar: AppBar(title: const Text('Posilka')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Hujjatlar',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          '40 000 so\'m',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const JourneyLine(
                      origin: 'Toshkent, Chilonzor',
                      destination: 'Buxoro, Markaz',
                      originTime: '09:00',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  step(Icons.inventory_2_outlined, 'Qabul qilindi', 'Bugun 09:12', true),
                  step(Icons.local_shipping_outlined, 'Yo\'lga chiqdi', 'Bugun 10:40', true),
                  step(Icons.check_circle_outline, 'Yetkazildi', '', false),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Aziz Karimov'),
                subtitle: const Text('Chevrolet Cobalt · 01 A 123 BC'),
                trailing: const Icon(Icons.chat_bubble_outline),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Oluvchi', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.call_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('+998 90 123 45 67'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Icon(Icons.scale_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Hujjatlar solingan konvert · 0.5 kg'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: nav(2),
      );
    });
  });
}


class _FixedRole extends ActiveRoleNotifier {
  _FixedRole(super.prefs, super.role);
}
