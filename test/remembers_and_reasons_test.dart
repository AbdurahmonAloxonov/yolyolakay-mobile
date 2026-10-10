import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/data/models/booking.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/features/rides/ride_details_screen.dart';
import 'package:yolyolakay/features/search/search_filters.dart';
import 'package:yolyolakay/l10n/strings.dart';

import 'support/audit_screens.dart';

/// QULAYLIKNING 4 va 5-DARAJASI (2026-09-05, D bosqichi).
///
///   4 · ESLAB QOLISH   — ilova bir marta aytilgan narsani ikkinchi
///                        marta so'raydimi;
///   5 · TUSHUNARLILIK  — o'chiq tugma NEGA o'chiqligini aytadimi.
///
/// 🔴 5-daraja nega alohida test bilan qo'riqlanadi: «tugma yo'q»
/// degan shikoyat loyihada BESH marta qaytgan va to'rttasida tugma
/// BOR edi — u shunchaki o'chiq va sababsiz turardi (izohi
/// `BottomActionBar` da). Ya'ni odam uchun sababsiz o'chiq tugma =
/// buzuq ilova. Qoida bor edi, qo'riqchisi yo'q edi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('4-daraja · ilova eslab qoladi', () {
    test('qidiruv filtrlari qurilmada saqlanadi', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container
          .read(searchFiltersProvider.notifier)
          .update(const SearchFilters(noSmoking: true, hasAc: true));

      // Ilova QAYTA ochilgandek — yangi konteyner, o'sha xotira.
      final second = ProviderContainer(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(second.dispose);

      final restored = second.read(searchFiltersProvider);
      expect(
        restored.noSmoking,
        isTrue,
        reason: 'chekmaydigan odam har ochilishda qaytadan belgilaydi',
      );
      expect(restored.hasAc, isTrue);
    });

    test('🔑 NARX oralig\'i ATAYIN saqlanmaydi', () async {
      // Qulaylik xohishi ODAMNIKI, narx esa YO'NALISHNIKI: bir
      // yo'nalishda ma'noli oraliq boshqasida hamma safarni jimgina
      // yashirib qo'yadi va odam «safar yo'q ekan» deb o'ylaydi.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final first = ProviderContainer(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(first.dispose);

      first.read(searchFiltersProvider.notifier).update(
        const SearchFilters(noSmoking: true, priceMin: 50000, priceMax: 100000),
      );

      final second = ProviderContainer(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(second.dispose);

      final restored = second.read(searchFiltersProvider);
      expect(restored.noSmoking, isTrue, reason: 'qulaylik — saqlanadi');
      expect(restored.priceMin, isNull, reason: 'narx — SAQLANMAYDI');
      expect(restored.priceMax, isNull);
    });

    test('«tozalash» xotirani ham tozalaydi', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final first = ProviderContainer(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(first.dispose);

      final controller = first.read(searchFiltersProvider.notifier);
      controller.update(const SearchFilters(noPets: true));
      controller.reset();

      final second = ProviderContainer(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(second.dispose);
      expect(
        second.read(searchFiltersProvider).isEmpty,
        isTrue,
        reason: 'tozalangan filtr qayta ochilganda tirilib kelmasin',
      );
    });

    test('buzilgan yozuv qidiruvni yiqitmaydi', () async {
      // Eski versiyada boshqacha yozilgan bo'lishi mumkin — bunda
      // ilova bo'sh filtrdan boshlasin, YIQILMASIN.
      SharedPreferences.setMockInitialValues({'search_filters': 'axlat{'});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      expect(container.read(searchFiltersProvider).isEmpty, isTrue);
    });
  });

  group('5-daraja · o\'chiq tugma sababini aytadi', () {
    Ride ride({int seats = 2, String status = RideStatus.active}) => Ride(
      id: 'r1',
      originAddress: 'Toshkent',
      destinationAddress: 'Samarqand',
      originLat: 41.3,
      originLon: 69.2,
      destinationLat: 39.6,
      destinationLon: 66.9,
      // 🔴 KELAJAK bo'lishi SHART: «Joy band qilish» tugmasi endi
      // `Ride.isBookable` ga qaraydi (jo'nab ketgan safarni o'chiradi).
      // Qotirilgan sana o'tib ketsa, «hammasi joyida» testi safarni
      // «jo'nab ketgan» deb topib yolg'on yiqilardi.
      departureTime: DateTime.now().add(const Duration(days: 1)),
      totalSeats: 4,
      availableSeats: seats,
      pricePerSeat: 150000,
      status: status,
    );

    // ⚠️ «Bronlarim» BO'SH RO'YXAT qaytarsin. Serversiz muhitda u
    // xato holatida qoladi va ekran `_bookingsUnknown` deb hisoblaydi
    // — bunda sabab ATAYIN chizilmaydi (yuqorida «Qayta urinish»
    // qatori turadi). Ya'ni mock'siz test o'lchamoqchi bo'lgan
    // holatga umuman yetib bormaydi.
    final noBookings = [
      myBookingsProvider.overrideWith((_) async => const <Booking>[]),
    ];

    testWidgets('joy tugagan — sabab EKRANDA yozilgan', (tester) async {
      await pumpAuditScreen(
        tester,
        RideDetailsScreen(ride: ride(seats: 0)),
        overrides: noBookings,
      );

      final t = AppStrings(Lang.uz);
      expect(
        find.text(t.seatsSoldOut),
        findsOneWidget,
        reason:
            'tugma o\'chiq, sababi esa aytilmagan — odam uchun bu '
            '«ilova buzuq» degani (xato besh marta qaytgan)',
      );
    });

    testWidgets('safar yopilgan — sabab EKRANDA yozilgan', (tester) async {
      await pumpAuditScreen(
        tester,
        RideDetailsScreen(ride: ride(status: RideStatus.completed)),
        overrides: noBookings,
      );

      final t = AppStrings(Lang.uz);
      expect(find.text(t.bookingClosed), findsOneWidget);
    });

    testWidgets('hammasi joyida bo\'lsa — ortiqcha yozuv chiqmaydi', (
      tester,
    ) async {
      await pumpAuditScreen(
        tester,
        RideDetailsScreen(ride: ride()),
        overrides: noBookings,
      );

      final t = AppStrings(Lang.uz);
      expect(find.text(t.seatsSoldOut), findsNothing);
      expect(find.text(t.bookingClosed), findsNothing);
    });
  });
}
