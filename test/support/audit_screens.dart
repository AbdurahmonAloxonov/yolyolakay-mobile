/// AUDIT EKRANLARI — bitta ro'yxat, uchta o'lchov.
///
/// 🔴 NEGA AJRATILDI (2026-09-04): bu ro'yxat IKKI faylda so'zma-so'z
/// takrorlanardi (`ui_narrow_audit_test.dart`, `tap_target_test.dart`)
/// va ikkalasining izohida ham «yangi ekran qo'shsangiz ro'yxatga ham
/// qo'shing» deb yozilgan edi. Uchinchi o'lchov (kontrast) qo'shilishi
/// bilan bu uch nusxaga aylanardi — ya'ni yangi ekran ikkita auditga
/// tushib, uchinchisidan jimgina tushib qolishi mumkin edi.
///
/// YANGI EKRAN QO'SHSANGIZ — FAQAT shu faylga qo'shing. Uchala audit
/// ham darhol uni ko'radi.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/core/api/token_storage.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/features/auth/otp_screen.dart';
import 'package:yolyolakay/features/auth/phone_screen.dart';
import 'package:yolyolakay/features/billing/tariffs_screen.dart';
import 'package:yolyolakay/features/chat/chats_screen.dart';
import 'package:yolyolakay/features/intro/intro_screen.dart';
import 'package:yolyolakay/features/notifications/notifications_screen.dart';
import 'package:yolyolakay/features/parcels/create_parcel_screen.dart';
import 'package:yolyolakay/features/parcels/find_parcels_screen.dart';
import 'package:yolyolakay/features/parcels/my_parcels_screen.dart';
import 'package:yolyolakay/features/parcels/parcels_screen.dart';
import 'package:yolyolakay/features/profile/add_car_sheet.dart';
import 'package:yolyolakay/features/profile/cars_screen.dart';
import 'package:yolyolakay/features/profile/complete_profile_screen.dart';
import 'package:yolyolakay/features/profile/driver_verification_screen.dart';
import 'package:yolyolakay/features/profile/earnings_screen.dart';
import 'package:yolyolakay/features/profile/edit_profile_screen.dart';
import 'package:yolyolakay/features/profile/password_sheet.dart';
import 'package:yolyolakay/features/profile/profile_screen.dart';
import 'package:yolyolakay/features/profile/security_screen.dart';
import 'package:yolyolakay/features/profile/user_profile_screen.dart';
import 'package:yolyolakay/features/rides/create_ride_screen.dart';
import 'package:yolyolakay/features/rides/driver_ride_screen.dart';
import 'package:yolyolakay/features/rides/ride_details_screen.dart';
import 'package:yolyolakay/features/safety/sos_sheet.dart';
import 'package:yolyolakay/features/search/search_results_screen.dart';
import 'package:yolyolakay/features/search/search_screen.dart';
import 'package:yolyolakay/features/support/service_status_screen.dart';
import 'package:yolyolakay/features/support/support_sheet.dart';
import 'package:yolyolakay/features/trips/my_trips_screen.dart';

/// Namuna safar — auditda hamma ekran TO'LDIRILGAN holatda ochilsin.
/// Manzillar ATAYIN uzun: kesilish va toshish aynan shunda ko'rinadi.
final auditRide = Ride(
  id: 'r1',
  originAddress: 'Toshkent, Chilonzor tumani, Bunyodkor shoh ko\'chasi',
  destinationAddress: 'Samarqand, Registon maydoni yaqinida',
  originLat: 41.2995,
  originLon: 69.2401,
  destinationLat: 39.6542,
  destinationLon: 66.9597,
  departureTime: DateTime(2026, 9, 1, 9),
  totalSeats: 4,
  availableSeats: 2,
  pricePerSeat: 150000,
  status: RideStatus.active,
  isNegotiable: true,
  hasAc: true,
  hasLuggage: true,
  takesParcels: true,
  noSmoking: true,
);

/// Auditga tushadigan hamma ekran va varaq.
Map<String, Widget> auditScreens() => <String, Widget>{
  'intro': const IntroScreen(),
  'phone': const PhoneScreen(),
  'otp': const OtpScreen(phoneNumber: '+998901234567'),
  'search': const SearchScreen(),
  'search_results': const SearchResultsScreen(),
  'create_ride': const CreateRideScreen(),
  'ride_details': RideDetailsScreen(ride: auditRide),
  'driver_ride': DriverRideScreen(ride: auditRide),
  'my_trips': const MyTripsScreen(),
  'chats': const ChatsScreen(),
  'notifications': const NotificationsScreen(),
  'parcels': const ParcelsScreen(),
  'find_parcels': const Scaffold(body: FindParcelsView()),
  'my_parcels': const Scaffold(body: MyParcelsView()),
  'create_parcel': const Scaffold(body: CreateParcelView()),
  'profile': const ProfileScreen(),
  'edit_profile': const EditProfileScreen(),
  'complete_profile': const CompleteProfileScreen(),
  'cars': const CarsScreen(),
  'earnings': const EarningsScreen(),
  'security': const SecurityScreen(),
  'tariffs': const TariffsScreen(),
  'driver_verification': const DriverVerificationScreen(),
  'user_profile': const UserProfileScreen(userId: 'u2', fallbackName: 'Aziz'),
  'service_status': const ServiceStatusScreen(),
  // Varaqlar — ular ham tor ekranda ochiladi.
  'add_car_sheet': const Scaffold(body: AddCarSheet()),
  'sos_sheet': const Scaffold(body: SosSheet()),
  'support_sheet': const Scaffold(body: SupportSheet()),
  'password_sheet': const Scaffold(body: PasswordSheet()),
};

/// Ekranni auditga tayyorlab chizadi: o'lcham, til, matn kattaligi, tema.
///
/// ⚠️ `tester.takeException()` SHU YERDA chaqiriladi: test muhitida
/// server yo'q va tarmoq xatosi TABIIY — u audit natijasini
/// buzmasligi kerak.
Future<void> pumpAuditScreen(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(360, 780),
  String lang = 'uz',
  double scale = 1.0,
  bool dark = false,

  /// Qo'shimcha almashtirishlar — masalan bildirishnoma o'chiruvchisini
  /// kuzatuvchi bilan almashtirish (`push_dismiss_test`).
  List<Override> overrides = const [],

  /// RANG AUDITI UCHUN — matnni TO'LA harflar bilan chizadi.
  /// Izohi [_solidGlyphTheme] da. Faqat `contrast_audit_test` yoqadi.
  bool solidGlyphs = false,
}) async {
  SharedPreferences.setMockInitialValues({'intro_seen': true});
  final prefs = await SharedPreferences.getInstance();
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        tokenStorageProvider.overrideWithValue(TokenStorage()),
        ...overrides,
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: () {
          final theme = buildTheme(
            brightness: dark ? Brightness.dark : Brightness.light,
          );
          return solidGlyphs ? _solidGlyphTheme(theme) : theme;
        }(),
        locale: Locale(lang),
        supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
  /*
   * ⚠️ BITTA `takeException()` YETMAYDI. Ekran bir nechta provayderni
   * o'qiydi va tarmoqsiz muhitda ularning HAR BIRI xato tashlaydi.
   * Navbatda bitta xato qolsa ham test yiqiladi — holbuki server
   * yo'qligi bu yerda TABIIY va o'lchanayotgan narsa emas.
   */
  while (tester.takeException() != null) {}
}


/// RANG O'LCHOVI UCHUN — HAMMA MATNNI TO'LA HARFLAR BILAN CHIZADI.
///
/// 🔴 NEGA KERAK (10.09.2026, hisoblab tasdiqlandi).
///
/// Flutter'ning `textContrastGuideline` i matnning to'rtburchagi ichidagi
/// PIKSELLARNI sanaydi va eng ko'p uchraydigan ikki rangni "matn" va
/// "zamin" deb oladi. Haqiqiy shriftda harf chetlari silliqlangan
/// (anti-aliasing), ya'ni piksellarning katta qismi matn ham, zamin ham
/// emas — ARALASHMA. Mayda o'lchamda aralashma ko'pchilikni tashkil
/// qiladi va o'lchagich "matn rangi" o'rniga o'sha aralashmani oladi.
///
/// Buni raqam bilan ko'rsatish mumkin. `add_car_sheet` dagi yordamchi
/// yozuv rangi — `#6B6570`, zamini `#F7F5F7`:
///
///     haqiqiy nisbat                       5.20 : 1   ✅
///     o'lchagich topgani (#A4A2A5)         2.34 : 1   ❌
///     o'sha ikki rangning 50% aralashmasi  2.04 : 1
///     75% aralashmasi                      3.15 : 1
///
/// Ya'ni "yiqilgan" qiymatlar aynan aralashma chizig'ida yotadi.
/// `#6B6570` esa 04.09.2026 da qo'lda o'lchangan va 5.20 deb yozilgan
/// (izohi `theme.dart` dagi `onSurfaceVariant` ustida) — ikki hisob
/// bir-biriga mos.
///
/// 🔑 Bu audit TIPOGRAFIKANI emas, RANGNI o'lchaydi. Shuning uchun
/// unga to'la (silliqlanmagan) harflar KERAK: o'shanda o'lchagich
/// aynan biz bergan ikki rangni ko'radi. Mavjud bo'lmagan shrift oilasi
/// so'ralsa, sinov muhiti aynan shunday — to'la to'rtburchak — glif
/// beradi.
///
/// ⚠️ Ya'ni bu audit "matn qanday ko'rinadi" degan savolga javob
/// BERMAYDI. Kesilish `text_not_cut_test` da, toshish
/// `ui_narrow_audit_test` da, tipografika esa ko'z bilan
/// (`ui_full_review.dart`) tekshiriladi.
ThemeData _solidGlyphTheme(ThemeData theme) {
  const family = 'AuditSolidGlyphs';
  TextStyle? swap(TextStyle? style) => style?.copyWith(fontFamily: family);
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamily: family),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: family),
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: swap(theme.appBarTheme.titleTextStyle),
    ),
    snackBarTheme: theme.snackBarTheme.copyWith(
      contentTextStyle: swap(theme.snackBarTheme.contentTextStyle),
    ),
    chipTheme: theme.chipTheme.copyWith(
      labelStyle: swap(theme.chipTheme.labelStyle),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: theme.filledButtonTheme.style?.copyWith(
        textStyle: WidgetStatePropertyAll<TextStyle?>(
          swap(theme.filledButtonTheme.style?.textStyle?.resolve(<WidgetState>{})),
        ),
      ),
    ),
  );
}
