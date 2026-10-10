import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:yolyolakay/features/profile/cars_screen.dart';
import 'package:yolyolakay/features/profile/complete_profile_screen.dart';
import 'package:yolyolakay/features/profile/driver_verification_screen.dart';
import 'package:yolyolakay/features/profile/earnings_screen.dart';
import 'package:yolyolakay/features/profile/edit_profile_screen.dart';
import 'package:yolyolakay/features/profile/profile_screen.dart';
import 'package:yolyolakay/features/profile/security_screen.dart';
import 'package:yolyolakay/features/profile/add_car_sheet.dart';
import 'package:yolyolakay/features/profile/password_sheet.dart';
import 'package:yolyolakay/features/profile/user_profile_screen.dart';
import 'package:yolyolakay/features/safety/sos_sheet.dart';
import 'package:yolyolakay/features/support/support_sheet.dart';
import 'package:yolyolakay/features/rides/create_ride_screen.dart';
import 'package:yolyolakay/features/rides/driver_ride_screen.dart';
import 'package:yolyolakay/features/rides/ride_details_screen.dart';
import 'package:yolyolakay/features/search/search_results_screen.dart';
import 'package:yolyolakay/features/search/search_screen.dart';
import 'package:yolyolakay/features/support/service_status_screen.dart';
import 'package:yolyolakay/features/trips/my_trips_screen.dart';

import 'support/preview_fonts.dart';

/// KESILGAN MATN QO'RIQCHISI — yorliq o'z nomini ayta olsin.
///
/// 🔴 NEGA YOZILDI (2026-09-04). O'sha kuni saytda barmoq nishonlari
/// o'lchandi va o'n bir joyda muammo topildi; keyin AYNAN shu usul
/// ilovaga qo'llanganda boshqa turdagi xato chiqdi — MATN KESILISHI:
///
///     «Опубликовать поездку»     288 / 302 px   (sarlavha)
///     «Редактировать профиль»    288 / 321 px   (sarlavha)
///     «2 из 4 свободно»          118 / 127 px   (bo'sh joy SONI)
///     «O'tkazib yuborish»        104 / 110 px   (birinchi ekran)
///     «Shahar yoki tumanni…»     170 / 196 px   (nima qilish kerakligi)
///     «Например: документы…»     187 / 289 px   (forma maslahati)
///
/// 🔑 Bu xatoni TOSHISH auditi (`ui_narrow_audit_test`) TUTMAYDI:
/// `ellipsis` toshishni yutadi, ya'ni hech qanday «overflow» xabari
/// bo'lmaydi. Ekran «to'g'ri» ko'rinadi — shunchaki yozuvlar
/// tugallanmagan.
///
/// ⚠️ HAQIQIY SHRIFT SHART: shriftsiz sinov muhitida har harf bir
/// kvadrat enida chiziladi va o'lchov mutlaqo yolg'on bo'ladi.
///
/// MA'LUMOT kesilishi (manzil, ism) MUMKIN — ular pastdagi ro'yxatda.
/// Yangi yorliq kesilsa, test yiqiladi va sabab aniq ko'rinadi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPreviewFonts);

  final ride = Ride(
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

  final screens = <String, Widget>{
    'intro': const IntroScreen(),
    'phone': const PhoneScreen(),
    'otp': const OtpScreen(phoneNumber: '+998901234567'),
    'search': const SearchScreen(),
    'search_results': const SearchResultsScreen(),
    'create_ride': const CreateRideScreen(),
    'ride_details': RideDetailsScreen(ride: ride),
    'driver_ride': DriverRideScreen(ride: ride),
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

  /// MA'LUMOT — yorliq emas. Bularning kesilishi TABIIY: manzil yoki
  /// ism har xil uzunlikda bo'ladi va uni qisqartirishdan boshqa iloj
  /// yo'q. Ro'yxatga QO'SHISHDAN OLDIN o'ylang: bu haqiqatan
  /// foydalanuvchi kiritgan qiymatmi, yoki biz yozgan yorliqmi?
  const dataTexts = <String>[
    'Toshkent, Chilonzor tumani, Bunyodkor shoh ko\'chasi',
    'Samarqand, Registon maydoni yaqinida',
  ];

  for (final entry in screens.entries) {
    for (final c in [
      (const Size(320, 900), 'uz', 1.0),
      (const Size(320, 900), 'ru', 1.3),
      (const Size(360, 900), 'ru', 1.0),
    ]) {
      testWidgets('${entry.key} · ${c.$1.width.toInt()} · ${c.$2} · x${c.$3}', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({'intro_seen': true});
        final prefs = await SharedPreferences.getInstance();
        await tester.binding.setSurfaceSize(c.$1);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPrefsProvider.overrideWithValue(prefs),
              tokenStorageProvider.overrideWithValue(TokenStorage()),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildTheme(brightness: Brightness.light),
              locale: Locale(c.$2),
              supportedLocales: const [
                Locale('uz'),
                Locale('ru'),
                Locale('en'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(c.$3)),
                child: child!,
              ),
              home: entry.value,
            ),
          ),
        );
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 120));
        }
        // Tarmoq yo'qligi tabiiy — test muhitida server yo'q.
        tester.takeException();

        final cut = <String>[];
        void walk(RenderObject o) {
          if (o is RenderParagraph && o.didExceedMaxLines) {
            final text = o.text.toPlainText().trim();
            if (text.isNotEmpty && !dataTexts.contains(text)) {
              cut.add(
                '"$text" — ${o.size.width.toStringAsFixed(0)} px berilgan, '
                '${o.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(0)} px kerak',
              );
            }
          }
          o.visitChildren(walk);
        }

        walk(tester.binding.rootElement!.renderObject!);

        expect(
          cut.toSet(),
          isEmpty,
          reason:
              '${entry.key} ekranida yozuv kesilyapti — yorliq o\'z nomini '
              'ayta olmayapti',
        );
      });
    }
  }
}
