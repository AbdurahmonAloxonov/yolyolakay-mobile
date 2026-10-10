import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/active_role.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/data/models/booking.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/data/models/user.dart';
import 'package:yolyolakay/features/trips/my_trips_screen.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// "Safarlarim" ekrani — rolga qarab.
///
/// 🔴 Egasi qurilmada ko'rdi (2026-08-12): yo'lovchiga ham HAYDOVCHI tabi
/// ko'rinardi. U yerda hech qachon hech narsa bo'lmaydi — odamning yarim
/// ekrani unga tegishli bo'lmagan bo'limga ketardi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  MeResponse me({required bool driver}) => MeResponse(
    user: User(
      id: 'u-1',
      phoneNumber: '+998900000000',
      firstName: 'Test',
      role: driver ? 'driver' : 'passenger',
    ),
    cars: const [],
  );

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
    'available_seats': 2,
    'price_per_seat': 150000,
    'status': 'active',
    'driver': {'id': 'd-1', 'name': 'Aziz', 'rating': 4.9},
  });

  final booking = Booking(
    id: 'b-1',
    rideId: 'r-1',
    passengerId: 'u-1',
    seatsBooked: 2,
    status: BookingStatus.confirmed,
    totalPrice: 300000,
    ride: ride,
  );

  /// [driverMode] — haydovchi HOZIR qaysi rejimda: ekran shunga qarab
  /// kerakli yorliqdan ochiladi.
  Widget boot({
    required bool driver,
    List<Booking> bookings = const [],
    bool driverMode = true,
  }) => ProviderScope(
    overrides: [
      // Savdolashish kartochkasi "o'z taklifim" xotirasini o'qiydi
      // (`OfferMemory`) va u `SharedPreferences` ga tayanadi.
      sharedPrefsProvider.overrideWithValue(prefs),
      // Rol `SharedPreferences` da saqlanadi; sinovda uni bevosita
      // beramiz — shunda prefs kerak bo'lmaydi.
      activeRoleProvider.overrideWith(
        (ref) => _FixedRole(driverMode ? AppRole.driver : AppRole.passenger),
      ),
      meProvider.overrideWith((ref) async => me(driver: driver)),
      myBookingsProvider.overrideWith((ref) async => bookings),
      myRidesProvider.overrideWith((ref) async => const <Ride>[]),
      rideByIdProvider.overrideWith((ref, id) async => null),
    ],
    child: const MaterialApp(
      locale: Locale('uz'),
      // Ilovadagi bilan bir xil: `uz` Material tarjimalarida yo'q, shuning
      // uchun delegatlarsiz `Localizations.localeOf` inglizchaga tushib
      // qolardi va AppStrings ham inglizcha matn qaytarardi.
      supportedLocales: [Locale('uz'), Locale('ru'), Locale('en')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MyTripsScreen(),
    ),
  );

  testWidgets('yo\'lovchida HAYDOVCHI tabi umuman yo\'q', (tester) async {
    await tester.pumpWidget(boot(driver: false));
    await tester.pumpAndSettle();

    const t = AppStrings(Lang.uz);
    expect(find.text(t.myTripsTitle), findsOneWidget);
    // Tab ham, "safar yaratish" tugmasi ham chiqmasligi kerak.
    expect(find.byType(TabBar), findsNothing);
    expect(find.text(t.asDriver), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  /// 🔴 ROL = MAZMUN (egasi, 2026-08-13: «rolni almashtirsam faqat qidirish
  /// va e'lon berish almashyapti, boshqa farq yo'q»).
  ///
  /// Ilgari bu ekranda ikki yorliq turardi va rol faqat qaysi biri ochilishini
  /// hal qilardi — ya'ni haydovchi rejimida ham yo'lovchi ro'yxati bir bosish
  /// naridagina turardi. Endi ekran FAQAT joriy rolning ishini ko'rsatadi.
  testWidgets('haydovchi rejimi — E\'LONLARIM, yorliqlar YO\'Q', (
    tester,
  ) async {
    await tester.pumpWidget(boot(driver: true));
    await tester.pumpAndSettle();

    const t = AppStrings(Lang.uz);
    expect(find.byType(TabBar), findsNothing);
    expect(find.text(t.myRidesTitle), findsOneWidget);
    // Yo'lovchi ro'yxati bu rejimda umuman chizilmaydi.
    expect(find.text(t.myTripsTitle), findsNothing);
  });

  testWidgets('yo\'lovchi rejimi — BRONLARIM', (tester) async {
    await tester.pumpWidget(boot(driver: true, driverMode: false));
    await tester.pumpAndSettle();

    const t = AppStrings(Lang.uz);
    expect(find.byType(TabBar), findsNothing);
    expect(find.text(t.myTripsTitle), findsOneWidget);
  });

  /// 🔴 BRONNI BEKOR QILISH — yo'lovchi tomonidan.
  ///
  /// 2026-08-25 da gateway'da bunday ruchka YO'Q edi, shuning uchun biz
  /// ATAYIN "so'rov" yasagandik: haydovchiga chat xabari + mahalliy
  /// «so'raldi» bayrog'i. 2026-08-27 da backend
  /// `POST /rides/{id}/bookings/{booking_id}/cancel` ni ochdi — endi
  /// bekor qilish haqiqiy va bayroq yo'q.
  group('bronni bekor qilish', () {
    testWidgets('tirik bronda tugma BOR', (tester) async {
      await tester.pumpWidget(
        boot(driver: false, driverMode: false, bookings: [booking]),
      );
      await tester.pumpAndSettle();

      const t = AppStrings(Lang.uz);
      expect(find.text(t.cancelBooking), findsOneWidget);
    });

    /// 🔴 Varaq OQIBATNI aytishi shart. Ilgari bu quti «bu faqat so'rov,
    /// o'rindiq band turadi» derdi — endi teskarisi rost va matn ham
    /// teskari bo'lishi kerak. Agar kimdir eski matnni qoldirib ketsa,
    /// odam bronim qoldi deb o'ylab yuraverardi.
    testWidgets('varaq nechta o\'rindiq bo\'shashini aytadi', (tester) async {
      await tester.pumpWidget(
        boot(driver: false, driverMode: false, bookings: [booking]),
      );
      await tester.pumpAndSettle();

      const t = AppStrings(Lang.uz);
      await tester.tap(find.text(t.cancelBooking));
      await tester.pumpAndSettle();

      expect(find.text(t.cancelBookingTitle), findsOneWidget);
      expect(
        find.text(t.cancelBookingExplain(booking.seatsBooked)),
        findsOneWidget,
      );
      // Ikki tugma ham ATAYIN ochiq nomlangan.
      expect(find.text(t.cancelBookingConfirm), findsOneWidget);
      expect(find.text(t.cancelBookingKeep), findsOneWidget);
    });

    testWidgets('rad etilgan bronda tugma YO\'Q', (tester) async {
      final rejected = Booking(
        id: 'b-2',
        rideId: 'r-1',
        passengerId: 'u-1',
        seatsBooked: 1,
        status: BookingStatus.rejected,
        ride: ride,
      );
      await tester.pumpWidget(
        boot(driver: false, driverMode: false, bookings: [rejected]),
      );
      await tester.pumpAndSettle();

      const t = AppStrings(Lang.uz);
      expect(find.text(t.cancelBooking), findsNothing);
    });
  });

  /// 🔴 Egasi tanladi (2026-08-13, "inDrive/Yandex uslubi"): rejim ikki
  /// alohida dunyo va almashtirgich BITTA joyda — profilda. Ilgari u
  /// sarlavhalarda ham turardi; ikki joyda turgan almashtirgich rejim
  /// tushunchasini suyultiradi.
  testWidgets('sarlavhada rejim almashtirgichi YO\'Q', (tester) async {
    await tester.pumpWidget(boot(driver: true));
    await tester.pumpAndSettle();

    expect(find.byType(ActionChip), findsNothing);
  });

  /// 🔴 Bitta safarga IKKI bron bo'lishi mumkin (biri tasdiqlangan, biri
  /// savdolashishda). Qurilmada ro'yxatda bittasi ko'rinmadi — bu ilova
  /// mantig'imi yoki ma'lumotmi, shu sinov hal qiladi.
  testWidgets('bitta safarga ikki bron — IKKALASI ham ro\'yxatda', (
    tester,
  ) async {
    final two = [
      const Booking(
        id: 'b-confirmed',
        rideId: 'r-1',
        passengerId: 'p-1',
        seatsBooked: 1,
        status: 'confirmed',
        totalPrice: 40000,
      ),
      const Booking(
        id: 'b-negotiation',
        rideId: 'r-1',
        passengerId: 'p-1',
        seatsBooked: 1,
        status: 'pending_negotiation',
        offeredPrice: 45000,
      ),
    ];
    await tester.pumpWidget(boot(driver: false, bookings: two));
    await tester.pumpAndSettle();

    const t = AppStrings(Lang.uz);
    expect(find.text(t.bookingStatus('confirmed')), findsOneWidget);
    expect(find.text(t.bookingStatus('pending_negotiation')), findsOneWidget);
  });

  testWidgets('bron kartasida MARSHRUT ko\'rinadi', (tester) async {
    // Ilgari kartada faqat "2 joy", narx va bron sanasi turardi — qayerga
    // ketayotganini bilish uchun har bir bronni ochish kerak edi.
    await tester.pumpWidget(boot(driver: false, bookings: [booking]));
    await tester.pumpAndSettle();

    expect(find.text('Toshkent'), findsOneWidget);
    expect(find.text('Samarqand'), findsOneWidget);
    // Haydovchi ismi bronning ichidagi safardan olinadi.
    expect(find.text('Aziz'), findsOneWidget);
    // Holat matn bilan ham ko'rinadi (rang bilan birga).
    expect(
      find.text(const AppStrings(Lang.uz).bookingStatus('confirmed')),
      findsOneWidget,
    );
  });
}

/// Sinov uchun o'zgarmas rol.
class _FixedRole extends ActiveRoleNotifier {
  _FixedRole(AppRole role) : super(_NoPrefs(), role);
}

/// `ActiveRoleNotifier` prefs so'raydi, lekin sinovda saqlash kerak emas.
class _NoPrefs implements SharedPreferences {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
