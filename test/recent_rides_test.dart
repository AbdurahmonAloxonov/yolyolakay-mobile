import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/data/models/ride.dart';

/// SO'NGGI KO'RILGAN SAFARLAR.
///
/// 🔴 NEGA TEST: ro'yxat DISKDA yashaydi va faqat ko'rsatish uchun
/// saqlangan TOR nusxadan tiklanadi. Ikki xato jimgina yuzaga chiqadi:
///   • takror yozuv — bitta safar ro'yxatni to'ldirib yuboradi;
///   • saqlangan maydonlar `Ride.fromJson` bilan mos kelmasligi —
///     kartochka bo'sh ("—") bo'lib chiziladi va hech qanday xato
///     bermaydi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Ride ride(String id, {String from = 'Toshkent'}) => Ride.fromJson({
    'id': id,
    'origin_address': from,
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
    'driver': {'id': 'd-1', 'name': 'Aziz', 'rating': 4.9},
  });

  late ProviderContainer container;

  Future<ProviderContainer> boot() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    );
  }

  setUp(() async {
    container = await boot();
  });

  tearDown(() => container.dispose());

  test('ko\'rilgan safar ro\'yxatga tushadi', () async {
    await container.read(recentRidesProvider.notifier).remember(ride('r-1'));
    expect(container.read(recentRidesProvider).map((r) => r.id), ['r-1']);
  });

  /// Saqlangan nusxa `Ride.fromJson` bilan MOS bo'lishi shart — aks holda
  /// kartochka bo'sh chiziladi va hech qanday xato chiqmaydi.
  test('saqlangan maydonlar qaytib o\'qiladi', () async {
    await container
        .read(recentRidesProvider.notifier)
        .remember(ride('r-1', from: 'Farg\'ona'));

    final saved = container.read(recentRidesProvider).single;
    expect(saved.originAddress, 'Farg\'ona');
    expect(saved.destinationAddress, 'Samarqand');
    expect(saved.pricePerSeat, 150000);
    expect(saved.availableSeats, 2);
    expect(saved.driver?.name, 'Aziz');
    expect(saved.departureTime, isNotNull);
  });

  test('takror safar TEPAGA ko\'chadi, ikkilanmaydi', () async {
    final notifier = container.read(recentRidesProvider.notifier);
    await notifier.remember(ride('r-1'));
    await notifier.remember(ride('r-2'));
    await notifier.remember(ride('r-1'));

    expect(container.read(recentRidesProvider).map((r) => r.id), [
      'r-1',
      'r-2',
    ]);
  });

  test('beshtadan oshmaydi', () async {
    final notifier = container.read(recentRidesProvider.notifier);
    for (var i = 1; i <= 8; i++) {
      await notifier.remember(ride('r-$i'));
    }
    expect(container.read(recentRidesProvider), hasLength(5));
    // Eng oxirgi ko'rilgani birinchi.
    expect(container.read(recentRidesProvider).first.id, 'r-8');
  });

  test('ilova qayta ochilganda ro\'yxat qoladi', () async {
    await container.read(recentRidesProvider.notifier).remember(ride('r-1'));
    container.dispose();

    // Yangi konteyner — o'sha `SharedPreferences` bilan.
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    );
    expect(container.read(recentRidesProvider).map((r) => r.id), ['r-1']);
  });

  test('tozalash', () async {
    final notifier = container.read(recentRidesProvider.notifier);
    await notifier.remember(ride('r-1'));
    await notifier.clear();
    expect(container.read(recentRidesProvider), isEmpty);
  });
}
