import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/active_role.dart';
import 'package:yolyolakay/app/home_widget_sync.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/data/models/booking.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/features/rides/next_trip.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// BOSH EKRAN VIDJETI — telefon ekranidagi «yaqin safar».
///
/// 🔴 NEGA TEST KERAK: vidjetning xatosi JIM. U ilovadan tashqarida
/// yashaydi — noto'g'ri safar ko'rsatsa ham, umuman yangilanmasa ham,
/// biz buni ekranda ko'rmaymiz. Odam esa uni kuniga o'nlab marta
/// ko'radi va aynan unga ishonadi.
///
/// Ikki narsa qo'riqlanadi:
///   1. QAYSI safar tanlanishi — vidjet va `TodayCard` AYNI safarni
///      ko'rsatishi shart (manba bitta: `next_trip.dart`);
///   2. Platformaga NIMA yuborilishi — sanami yoki «2 soatdan keyin»
///      kabi o'zi eskiradigan yozuvmi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late List<MethodCall> sent;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    sent = [];
    // Platforma kanalini USHLAB QOLAMIZ: testda haqiqiy Android yo'q.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('uz.yolyolakay.mobile/settings'),
          (call) async {
            sent.add(call);
            return true;
          },
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('uz.yolyolakay.mobile/settings'),
          null,
        );
  });

  Ride rideAt(
    Duration fromNow, {
    String id = 'r-1',
    String status = 'active',
    int seats = 2,
  }) => Ride.fromJson({
    'id': id,
    'origin_address': 'Toshkent, Chilonzor tumani',
    'origin_lat': 41.2995,
    'origin_lon': 69.2401,
    'destination_address': 'Samarqand, Registon',
    'destination_lat': 39.6542,
    'destination_lon': 66.9597,
    'departure_time': DateTime.now().add(fromNow).toIso8601String(),
    'total_seats': 4,
    'available_seats': seats,
    'price_per_seat': 150000,
    'status': status,
    'driver': {'id': 'd-1', 'name': 'Aziz', 'rating': 4.9},
  });

  Booking bookingFor(Ride ride) => Booking(
    id: 'b-${ride.id}',
    rideId: ride.id,
    passengerId: 'u-1',
    seatsBooked: 1,
    status: BookingStatus.confirmed,
    totalPrice: 150000,
    ride: ride,
  );

  /// Vidjet FAQAT Android'da yoziladi, sinov esa host mashinada
  /// yuguradi va platformani «linux» deb ko'rsatadi.
  ///
  /// ⚠️ Bayroq TEST TANASI ICHIDA qaytarilishi shart: `testWidgets`
  /// test tugagach «foundation debug o'zgaruvchisi o'zgartirilgan»
  /// deb yiqiladi va `tearDown` bunga kech qoladi (birinchi urinishda
  /// aynan shunday bo'ldi).
  Future<void> onAndroid(Future<void> Function() body) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  Future<void> boot(
    WidgetTester tester, {
    required bool driverMode,
    List<Booking> bookings = const [],
    List<Ride> rides = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
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
          home: HomeWidgetSync(child: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Map<Object?, Object?> lastPayload() {
    expect(sent, isNotEmpty, reason: 'vidjetga hech nima yuborilmadi');
    expect(sent.last.method, 'updateHomeWidget');
    return sent.last.arguments as Map<Object?, Object?>;
  }

  group('Qaysi safar tanlanadi', () {
    test('eng ERTA jo\'naydigani', () {
      final now = DateTime.now();
      final soon = rideAt(const Duration(hours: 2), id: 'yaqin');
      final later = rideAt(const Duration(days: 3), id: 'uzoq');
      expect(nearestDriverRide([later, soon], now)?.id, 'yaqin');
    });

    test('bekor qilingan va tugagan safar TANLANMAYDI', () {
      final now = DateTime.now();
      final cancelled = rideAt(
        const Duration(hours: 1),
        id: 'bekor',
        status: 'cancelled',
      );
      final done = rideAt(
        const Duration(hours: 2),
        id: 'tugagan',
        status: 'completed',
      );
      final live = rideAt(const Duration(days: 1), id: 'tirik');
      expect(nearestDriverRide([cancelled, done, live], now)?.id, 'tirik');
    });

    /// 🔴 Jo'nab ketgan safar 2 soat DAVOMIDA qoladi: odam yo'lda va
    /// unga aynan o'sha paytda kerak. Undan keyin yo'qoladi.
    test('jo\'nab ketgani 2 soat qoladi, keyin yo\'qoladi', () {
      final now = DateTime.now();
      expect(tripRelevant(now.subtract(const Duration(minutes: 30)), now), isTrue);
      expect(tripRelevant(now.subtract(const Duration(hours: 3)), now), isFalse);
      expect(tripRelevant(null, now), isFalse);
    });
  });

  group('Vidjetga nima yuboriladi', () {
    testWidgets('yo\'lovchi: yo\'nalish, sana va NARX', (tester) async {
      await onAndroid(() async {
        final ride = rideAt(const Duration(days: 1));
        await boot(tester, driverMode: false, bookings: [bookingFor(ride)]);
      });

      final data = lastPayload();
      // Manzil vergulgacha qisqaradi: vidjet tor va uzun manzil
      // o'qilmaydigan mayda yozuvga aylanardi.
      expect(data['route'], 'Toshkent → Samarqand');
      expect((data['note'] as String).contains('150'), isTrue);
      expect(data['empty'], '');
    });

    testWidgets('haydovchi: narx emas, BO\'SH JOY soni', (tester) async {
      await onAndroid(() async {
        final ride = rideAt(const Duration(days: 1), seats: 3);
        await boot(tester, driverMode: true, rides: [ride]);
      });

      final data = lastPayload();
      expect(data['route'], 'Toshkent → Samarqand');
      // Haydovchiga eng kerakli raqam — nechta joy bo'sh qolgani.
      expect((data['note'] as String).contains('3'), isTrue);
    });

    /// 🔴 ENG MUHIM SINOV: vidjet ilova ochilmasa YANGILANMAYDI, ya'ni
    /// «2 soatdan keyin» kabi yozuv ertaga YOLG'ON gapiradi. Sana esa
    /// eskirsa ham rost qoladi.
    testWidgets('vaqt SANA bo\'lib ketadi, «necha soat qoldi» EMAS', (
      tester,
    ) async {
      await onAndroid(() async {
        final ride = rideAt(const Duration(hours: 3));
        await boot(tester, driverMode: false, bookings: [bookingFor(ride)]);
      });

      final when = lastPayload()['when'] as String;
      expect(when, isNotEmpty);
      // «3 soatdan keyin», «2 soat qoldi» — ertaga yolg'onga aylanadigan
      // yozuvlar. Vidjetda faqat sana/vaqt bo'lishi kerak.
      for (final banned in ['soat', 'qoldi', 'keyin', 'daqiqa']) {
        expect(
          when.toLowerCase().contains(banned.toLowerCase()),
          isFalse,
          reason: 'vidjetda o\'zi eskiradigan yozuv bo\'lmasin: "$when"',
        );
      }
    });

    testWidgets('safar yo\'q — vidjet BO\'SH qolmaydi, taklif chiqadi', (
      tester,
    ) async {
      await onAndroid(() async => boot(tester, driverMode: false));

      final data = lastPayload();
      expect(data['route'], '');
      // Bo'sh vidjet — ekrandagi o'lik to'rtburchak; odam uni birinchi
      // bo'lib olib tashlaydi.
      expect(data['empty'], AppStrings(Lang.uz).widgetEmpty);
    });

    testWidgets('eski safar vidjetga TUSHMAYDI', (tester) async {
      await onAndroid(() async {
        final old = rideAt(const Duration(hours: -5));
        await boot(tester, driverMode: false, bookings: [bookingFor(old)]);
      });

      expect(lastPayload()['route'], '');
    });
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
