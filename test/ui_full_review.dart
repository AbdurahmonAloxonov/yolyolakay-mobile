import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/core/api/token_storage.dart';
import 'package:yolyolakay/data/models/billing.dart';
import 'package:yolyolakay/data/models/booking.dart';
import 'package:yolyolakay/data/models/chat.dart';
import 'package:yolyolakay/data/models/parcel.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/data/models/user.dart';
import 'package:yolyolakay/features/billing/tariffs_screen.dart';
import 'package:yolyolakay/features/chat/chat_screen.dart';
import 'package:yolyolakay/features/chat/chats_screen.dart';
import 'package:yolyolakay/features/parcels/create_parcel_screen.dart';
import 'package:yolyolakay/features/parcels/find_parcels_screen.dart';
import 'package:yolyolakay/features/parcels/parcels_screen.dart';
import 'package:yolyolakay/features/profile/driver_verification_screen.dart';
import 'package:yolyolakay/features/notifications/notifications_screen.dart';
import 'package:yolyolakay/features/parcels/my_parcels_screen.dart';
import 'package:yolyolakay/features/auth/otp_screen.dart';
import 'package:yolyolakay/features/auth/phone_screen.dart';
import 'package:yolyolakay/features/intro/intro_screen.dart';
import 'package:yolyolakay/features/profile/cars_screen.dart';
import 'package:yolyolakay/features/profile/complete_profile_screen.dart';
import 'package:yolyolakay/features/profile/edit_profile_screen.dart';
import 'package:yolyolakay/features/profile/security_screen.dart';
import 'package:yolyolakay/features/profile/settings_screen.dart';
import 'package:yolyolakay/features/profile/user_profile_screen.dart';
import 'package:yolyolakay/features/support/service_status_screen.dart';
import 'package:yolyolakay/features/shared/brand/suzani_icons.dart';
import 'package:yolyolakay/features/shared/skeleton.dart';
import 'package:yolyolakay/features/shared/state_views.dart';
import 'package:yolyolakay/features/profile/earnings_screen.dart';
import 'package:yolyolakay/features/profile/profile_screen.dart';
import 'package:yolyolakay/features/rides/create_ride_screen.dart';
import 'package:yolyolakay/features/rides/driver_ride_screen.dart';
import 'package:yolyolakay/features/rides/ride_details_screen.dart';
import 'package:yolyolakay/features/search/search_results_screen.dart';
import 'package:yolyolakay/features/search/search_screen.dart';
import 'package:yolyolakay/features/trips/my_trips_screen.dart';

import 'support/preview_fonts.dart';

/// TO'LIQ KO'RIK — ekranlar MA'LUMOT BILAN TO'LDIRILGAN holatda.
///
/// 🔴 NEGA KERAK (egasi, 2026-09-02: «UI da buglar bor, ko'rinishlarida
/// buglar bor, tugmalar joylashuvi qo'l uchida qilingan»).
///
/// `ui_narrow_audit_test.dart` 29 ekranni tekshiradi, LEKIN ular BO'SH
/// holatda ochiladi: tarmoq yo'q, provider xatoga tushadi va ekranda
/// «qayta urinish» chiqadi. Ya'ni audit BO'SH ekranlarni o'lchayotgan
/// edi — kartalar, ro'yxatlar, narxlar, nishonlar HECH QACHON
/// chizilmagan.
///
/// Xunuk ko'rinish esa aynan TO'LDIRILGAN holatda tug'iladi: uzun ism
/// kesiladi, narx sarlavhaga tegib ketadi, nishonlar qatori toshadi.
///
///   flutter test test/ui_full_review.dart --update-goldens
///
/// Rasmlar `style_preview/review/` ga tushadi va ularni ODAM ko'radi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPreviewFonts);

  Ride mkRide({
    String id = 'r1',
    String from = 'Toshkent, Chilonzor tumani, Bunyodkor shoh ko\'chasi 12',
    String to = 'Samarqand, Registon maydoni yaqinida',
    double price = 150000,
    int seats = 2,
    String status = RideStatus.active,
  }) => Ride(
    id: id,
    originAddress: from,
    destinationAddress: to,
    originLat: 41.2995,
    originLon: 69.2401,
    destinationLat: 39.6542,
    destinationLon: 66.9597,
    departureTime: DateTime(2026, 9, 3, 9, 30),
    totalSeats: 4,
    availableSeats: seats,
    pricePerSeat: price,
    status: status,
    isNegotiable: true,
    hasAc: true,
    hasLuggage: true,
    takesParcels: true,
    noSmoking: true,
    driver: const DriverProfile(
      id: 'd1',
      name: 'Abdurahmon Rahmatullayev',
      rating: 4.8,
      phone: '+998901112233',
    ),
  );

  const me = MeResponse(
    user: User(
      id: 'u-1',
      phoneNumber: '+998900000000',
      firstName: 'Abdurahmon',
      lastName: 'Rahmatullayev',
      role: 'driver',
      rating: 4.9,
      ratingCount: 52,
    ),
    cars: [
      Car(
        id: 'c1',
        brand: 'Chevrolet',
        model: 'Cobalt',
        govNumber: '01A777AA',
        moderationStatus: 'approved',
      ),
      Car(
        id: 'c2',
        brand: 'Toyota',
        model: 'Camry 70 Hybrid',
        govNumber: '10B123CD',
        moderationStatus: 'pending',
      ),
    ],
  );

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget screen, {
    Size size = const Size(360, 780),
    String lang = 'uz',
    double scale = 1.0,
    Brightness brightness = Brightness.light,
    ThemeStyle style = ThemeStyle.classic,
    List<Override> overrides = const [],
    double? height,
  }) async {
    SharedPreferences.setMockInitialValues({'intro_seen': true});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(
      height == null ? size : Size(size.width, height),
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(TokenStorage()),
          meProvider.overrideWith((ref) async => me),
          ...overrides,
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: withPreviewFont(
            buildTheme(brightness: brightness, style: style),
          ),
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
    // ⚠️ Jonlanishlar TUGAGUNCHA kutamiz. Aks holda rasmda o'rindiqlar
    // yarim shaffof chiqadi va «ranglar chalkash» degan YOLG'ON xulosa
    // tug'iladi (02.09 da aynan shunday bo'ldi).
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../style_preview/review/$name.png'),
    );
  }

  // ── Safar tafsiloti ────────────────────────────────────────────
  testWidgets(
    'safar tafsiloti',
    (t) => shoot(t, 'safar_tafsilot', RideDetailsScreen(ride: mkRide())),
  );
  testWidgets(
    'safar tafsiloti — tungi',
    (t) => shoot(
      t,
      'safar_tafsilot_tungi',
      RideDetailsScreen(ride: mkRide()),
      brightness: Brightness.dark,
    ),
  );
  testWidgets(
    'safar tafsiloti — 320 ruscha katta',
    (t) => shoot(
      t,
      'safar_tafsilot_tor',
      RideDetailsScreen(ride: mkRide()),
      size: const Size(320, 568),
      lang: 'ru',
      scale: 1.3,
    ),
  );

  // ── Haydovchining safari ───────────────────────────────────────
  testWidgets(
    'haydovchi safari',
    (t) => shoot(t, 'haydovchi_safar', DriverRideScreen(ride: mkRide())),
  );

  // ── Mening safarlarim ──────────────────────────────────────────
  final booking = Booking(
    id: 'b1',
    rideId: 'r1',
    passengerId: 'u-1',
    seatsBooked: 2,
    status: 'confirmed',
    totalPrice: 300000,
    createdAt: DateTime(2026, 9, 1, 12),
    ride: mkRide(),
  );
  testWidgets(
    'mening safarlarim',
    (t) => shoot(
      t,
      'safarlarim',
      const MyTripsScreen(),
      overrides: [
        myRidesProvider.overrideWith(
          (ref) async => [mkRide(), mkRide(id: 'r2')],
        ),
        myBookingsProvider.overrideWith((ref) async => [booking]),
      ],
    ),
  );

  // ── Suhbatlar ──────────────────────────────────────────────────
  testWidgets(
    'suhbatlar',
    (t) => shoot(
      t,
      'suhbatlar',
      const ChatsScreen(),
      overrides: [
        conversationsProvider.overrideWith(
          (ref) async => [
            Conversation(
              rideId: 'r1',
              peerId: 'd1',
              // ⚠️ `title` — YO'NALISH, `subtitle` — ODAM ismi.
              // Ro'yxat aynan shunday o'qiydi (`chats_screen.dart`).
              title: 'Toshkent - Samarqand',
              subtitle: 'Abdurahmon Rahmatullayev',
              lastMessage: 'Yaxshi, ertaga soat 9 da Chilonzorda kutaman',
              lastAt: DateTime(2026, 9, 2, 8, 15),
              unreadCount: 3,
            ),
            Conversation(
              rideId: 'r2',
              peerId: 'd2',
              title: 'Namangan - Toshkent',
              subtitle: 'Dilnoza',
              lastMessage: 'Rahmat!',
              lastAt: DateTime(2026, 9, 1, 19, 40),
              lastIsMine: true,
            ),
          ],
        ),
      ],
    ),
  );

  // ── Bildirishnomalar ───────────────────────────────────────────
  testWidgets(
    'bildirishnomalar',
    (t) => shoot(
      t,
      'bildirishnomalar',
      const NotificationsScreen(),
      overrides: [
        notificationsProvider.overrideWith(
          (ref) async => [
            NotificationItem(
              id: 'n1',
              title: 'Bron tasdiqlandi',
              body:
                  'Abdurahmon sizning 2 o\'ringizni tasdiqladi. '
                  'Uchrashuv: Chilonzor metrosi, ertaga 09:00.',
              isRead: false,
              type: 'booking_confirmed',
              createdAt: DateTime(2026, 9, 2, 7, 30),
            ),
            NotificationItem(
              id: 'n2',
              title: 'Yangi xabar',
              body: 'Dilnoza sizga xabar yubordi',
              isRead: true,
              type: 'message',
              createdAt: DateTime(2026, 9, 1, 20, 10),
            ),
          ],
        ),
      ],
    ),
  );

  // ── Profil ─────────────────────────────────────────────────────
  testWidgets('profil', (t) => shoot(t, 'profil', const ProfileScreen()));
  // Butun bo'yi bitta rasmda — bo'limlar TARTIBINI ko'rish uchun
  // (360×780 da faqat sarlavha va birinchi karta sig'adi).
  testWidgets(
    'profil — butun bo\'yi',
    (t) => shoot(t, 'profil_butun', const ProfileScreen(), height: 2000),
  );
  testWidgets(
    'profil — tungi',
    (t) => shoot(
      t,
      'profil_tungi',
      const ProfileScreen(),
      brightness: Brightness.dark,
    ),
  );

  // ── Mashinalarim ───────────────────────────────────────────────
  testWidgets('mashinalar', (t) => shoot(t, 'mashinalar', const CarsScreen()));

  // ── Daromad ────────────────────────────────────────────────────
  testWidgets(
    'daromad',
    (t) => shoot(
      t,
      'daromad',
      const EarningsScreen(),
      overrides: [
        driverEarningsProvider.overrideWith(
          (ref) async => const DriverStatistics(
            totalEarnings: 4750000,
            totalRides: 34,
            completedRides: 31,
            cancelledRides: 3,
          ),
        ),
      ],
    ),
  );

  // ── Tariflar ───────────────────────────────────────────────────
  testWidgets(
    'tariflar',
    (t) => shoot(
      t,
      'tariflar',
      const TariffsScreen(),
      overrides: [
        billingPlansProvider.overrideWith(
          (ref) async => const [
            BillingPlan(name: 'Free Trial', price: 0, ridesQuota: 5),
            BillingPlan(name: 'Plus', price: 49000, ridesQuota: 30),
            BillingPlan(name: 'Pro', price: 99000, ridesQuota: -1),
          ],
        ),
        subscriptionProvider.overrideWith(
          (ref) async => Subscription(
            planName: 'plus',
            status: 'active',
            ridesLeft: 22,
            endDate: DateTime(2026, 9, 30),
          ),
        ),
      ],
    ),
  );

  // ── Posilkalarim ───────────────────────────────────────────────
  testWidgets(
    'posilkalarim',
    (t) => shoot(
      t,
      'posilkalarim',
      const Scaffold(body: MyParcelsView()),
      overrides: [
        myParcelsProvider.overrideWith(
          (ref) async => [
            Parcel(
              id: 'p1',
              originLat: 41.3,
              originLon: 69.2,
              destinationLat: 39.6,
              destinationLon: 66.9,
              fromAddress: 'Toshkent, Yunusobod',
              toAddress: 'Samarqand, Registon',
              price: 50000,
              status: 'pending',
              size: 'medium',
              description: 'Kichik quti, hujjatlar',
              createdAt: DateTime(2026, 9, 1, 10),
            ),
          ],
        ),
      ],
    ),
  );

  // ── Qidiruv ────────────────────────────────────────────────────
  testWidgets('qidiruv', (t) => shoot(t, 'qidiruv', const SearchScreen()));
  testWidgets(
    'qidiruv — tungi',
    (t) => shoot(
      t,
      'qidiruv_tungi',
      const SearchScreen(),
      brightness: Brightness.dark,
    ),
  );

  // ── HOLATLAR — bo'sh, yuklanish, xato ──────────────────────────
  //
  // Bular butun ilova bo'ylab ishlatiladi: bitta joyni tuzatsak, hamma
  // ekran ko'tariladi. Shuning uchun ularni ALOHIDA ko'ramiz.
  testWidgets(
    'holatlar',
    (t) => shoot(
      t,
      'holatlar',
      Scaffold(
        appBar: AppBar(title: const Text('Holatlar')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            const Text('BO\'SH'),
            SizedBox(
              height: 470,
              child: EmptyView(
                suzani: SuzaniIcon.car,
                title: 'Bu kunga safar yo\'q',
                subtitle:
                    'Ertangi kunni ko\'ring yoki yo\'nalishga obuna bo\'ling — '
                    'safar chiqsa xabar beramiz.',
                actionLabel: 'Yo\'nalishga obuna bo\'lish',
                onAction: () {},
                secondaryLabel: 'Ertangi kunni ko\'rish',
                onSecondary: () {},
              ),
            ),
            const SizedBox(height: 16),
            const Text('YUKLANMOQDA'),
            const SizedBox(height: 260, child: ListSkeleton()),
            const SizedBox(height: 16),
            const Text('XATO'),
            SizedBox(
              height: 340,
              child: ErrorView(error: Exception('tarmoq'), onRetry: () {}),
            ),
          ],
        ),
      ),
      height: 1700,
    ),
  );

  // ══════════════════════════════════════════════════════════════
  // QOLGAN EKRANLAR — 2026-09-02 da egasi so'radi: «qulay deb 100%
  // ayta olmaysan, ko'rinishini tekshirmagansan». To'g'ri edi —
  // 28 ekrandan 12 tasiga qaralgandi.
  // ══════════════════════════════════════════════════════════════

  testWidgets('intro', (t) => shoot(t, 'z_intro', const IntroScreen()));
  testWidgets(
    'intro — tungi',
    (t) => shoot(
      t,
      'z_intro_tungi',
      const IntroScreen(),
      brightness: Brightness.dark,
    ),
  );
  testWidgets('kirish', (t) => shoot(t, 'z_kirish', const PhoneScreen()));
  // 🔑 NAQSH IKKALA YORUG'LIKDA HAM TEKSHIRILADI. Relyef ranglari
  // temadan olinadi va tungida ular ALMASHADI — noto'g'ri bo'lsa
  // sahifa oq to'r bilan qoplanadi. Buni faqat KO'Z ko'radi: yorug'
  // temada hammasi joyida ko'rinaveradi.
  testWidgets(
    'kirish — tungi',
    (t) => shoot(
      t,
      'z_kirish_tungi',
      const PhoneScreen(),
      brightness: Brightness.dark,
    ),
  );
  testWidgets(
    'kod',
    (t) => shoot(t, 'z_kod', const OtpScreen(phoneNumber: '+998901234567')),
  );
  testWidgets(
    'sozlamalar',
    (t) => shoot(t, 'z_sozlamalar', const SettingsScreen(), height: 1600),
  );
  testWidgets(
    'profilni to\'ldirish',
    (t) => shoot(t, 'z_profil_toldirish', const CompleteProfileScreen()),
  );
  testWidgets(
    'profilni tahrirlash',
    (t) => shoot(t, 'z_profil_tahrir', const EditProfileScreen()),
  );
  testWidgets(
    'xavfsizlik',
    (t) => shoot(t, 'z_xavfsizlik', const SecurityScreen()),
  );
  testWidgets(
    'xizmat holati',
    (t) => shoot(t, 'z_xizmat', const ServiceStatusScreen()),
  );
  testWidgets(
    'begona profil',
    (t) => shoot(
      t,
      'z_begona_profil',
      const UserProfileScreen(userId: 'd1', fallbackName: 'Abdurahmon'),
    ),
  );

  // ── Ikkinchi to'plam ───────────────────────────────────────────
  testWidgets(
    'yozishma',
    (t) => shoot(
      t,
      'z_yozishma',
      ChatScreen(
        conversation: Conversation(
          rideId: 'r1',
          peerId: 'd1',
          title: 'Toshkent - Samarqand',
          subtitle: 'Abdurahmon Rahmatullayev',
          lastMessage: 'Yaxshi, ertaga ko\'rishamiz',
          lastAt: DateTime(2026, 9, 2, 8, 15),
        ),
      ),
    ),
  );
  testWidgets(
    'posilkalar',
    (t) => shoot(t, 'z_posilkalar', const ParcelsScreen()),
  );
  testWidgets(
    'posilka topish',
    (t) =>
        shoot(t, 'z_posilka_topish', const Scaffold(body: FindParcelsView())),
  );
  testWidgets(
    'posilka yuborish',
    (t) => shoot(
      t,
      'z_posilka_yuborish',
      const Scaffold(body: CreateParcelView()),
      height: 1200,
    ),
  );
  // ⚠️ JOY TANLASH (xarita) SINOVDA CHIZILMAYDI: `PickLocationScreen`
  // xarita keshini so'raydi va `getApplicationCacheDirectory` plagini
  // sinov muhitida yo'q (`MissingPluginException`). U YAGONA ekran
  // bo'lib, faqat QURILMADA ko'riladi — buni yodda tuting, aks holda
  // «hammasi ko'rildi» degan yolg'on tasavvur paydo bo'ladi.
  testWidgets(
    'haydovchi tekshiruvi',
    (t) => shoot(t, 'z_haydovchi_tekshiruv', const DriverVerificationScreen()),
  );

  // ── E'lon berish (haydovchi) ───────────────────────────────────
  testWidgets(
    'e\'lon berish',
    (t) => shoot(t, 'elon_berish', const CreateRideScreen(), height: 1400),
  );

  // ══════════════════════════════════════════════════════════════
  // ZO'RIQISH KO'RIGI — naqsh eng qiyin sharoitda (2026-09-03).
  //
  // 🔑 Nega kerak: naqsh qo'shilgach ekranlarda YANGI element paydo
  // bo'ldi (jiyak, muqarnas, medalyon, islimi). Ularning har biri
  // JOY egallaydi, ya'ni eng tor ekranda va eng katta matnda
  // toshish xavfi qaytadan tug'ildi. Bundan tashqari naqsh ranglari
  // temadan olinadi — ya'ni AMBER va NEON uslublarida ular umuman
  // sinalmagan edi.
  //
  // Audit testi «toshdimi» degan savolga javob beradi; bu rasmlar
  // esa «o'qiladimi, xunuk emasmi» degan savolga.
  // ══════════════════════════════════════════════════════════════
  testWidgets(
    'zo\'riqish — kirish 320 ruscha katta',
    (t) => shoot(
      t,
      'zz_kirish_320_ru',
      const PhoneScreen(),
      size: const Size(320, 568),
      lang: 'ru',
      scale: 1.3,
    ),
  );
  testWidgets(
    'zo\'riqish — bosh ekran 320 katta matn',
    (t) => shoot(
      t,
      'zz_qidiruv_320_katta',
      const SearchScreen(),
      size: const Size(320, 568),
      scale: 1.6,
      height: 1100,
    ),
  );
  testWidgets(
    'zo\'riqish — e\'lon berish 320 ruscha',
    (t) => shoot(
      t,
      'zz_elon_320_ru',
      const CreateRideScreen(),
      size: const Size(320, 568),
      lang: 'ru',
      scale: 1.3,
      height: 1900,
    ),
  );
  testWidgets(
    'zo\'riqish — sozlamalar 320 ruscha',
    (t) => shoot(
      t,
      'zz_sozlamalar_320_ru',
      const SettingsScreen(),
      size: const Size(320, 568),
      lang: 'ru',
      scale: 1.3,
      height: 2200,
    ),
  );
  // AMBER — tungi haydash uslubi. Doim qorong'i, issiq ranglar.
  testWidgets(
    'zo\'riqish — amber uslubi',
    (t) => shoot(
      t,
      'zz_amber',
      DriverRideScreen(ride: mkRide()),
      style: ThemeStyle.amber,
      brightness: Brightness.dark,
      height: 1000,
    ),
  );
  // NEON — pushti/cyan uslub. Naqsh ranglari bu yerda ham temadan.
  testWidgets(
    'zo\'riqish — neon uslubi',
    (t) => shoot(
      t,
      'zz_neon',
      const SearchScreen(),
      style: ThemeStyle.neon,
      brightness: Brightness.dark,
    ),
  );
  testWidgets(
    'zo\'riqish — neon yorug\'',
    (t) => shoot(
      t,
      'zz_neon_yorug',
      const TariffsScreen(),
      style: ThemeStyle.neon,
      height: 1200,
    ),
  );

  // Qolgan og'ir ekranlar — o'sha sharoitda (320 · ruscha · 1.3).
  testWidgets(
    'zo\'riqish — natijalar 320 ruscha',
    (t) => shoot(
      t,
      'zz_natija_320_ru',
      const SearchResultsScreen(),
      size: const Size(320, 568),
      lang: 'ru',
      scale: 1.3,
      height: 1200,
      overrides: [searchControllerProvider.overrideWith(() => _FakeSearch())],
    ),
  );
  testWidgets(
    'zo\'riqish — safarlarim 320 ruscha',
    (t) => shoot(
      t,
      'zz_safarlarim_320_ru',
      const MyTripsScreen(),
      size: const Size(320, 568),
      lang: 'ru',
      scale: 1.3,
      height: 1200,
    ),
  );
  testWidgets(
    'zo\'riqish — profil 320 ruscha',
    (t) => shoot(
      t,
      'zz_profil_320_ru',
      const ProfileScreen(),
      size: const Size(320, 568),
      lang: 'ru',
      scale: 1.3,
      height: 1600,
    ),
  );
  testWidgets(
    'zo\'riqish — tariflar 320 ruscha',
    (t) => shoot(
      t,
      'zz_tariflar_320_ru',
      const TariffsScreen(),
      size: const Size(320, 568),
      lang: 'ru',
      scale: 1.3,
      height: 1600,
    ),
  );
  testWidgets(
    'zo\'riqish — haydovchi tekshiruvi 320 ruscha',
    (t) => shoot(
      t,
      'zz_kyc_320_ru',
      const DriverVerificationScreen(),
      size: const Size(320, 568),
      lang: 'ru',
      scale: 1.3,
      height: 1400,
    ),
  );
  testWidgets(
    'zo\'riqish — haydovchi safari 320 ruscha',
    (t) => shoot(
      t,
      'zz_haydovchi_320_ru',
      DriverRideScreen(ride: mkRide()),
      size: const Size(320, 568),
      lang: 'ru',
      scale: 1.3,
      height: 1400,
    ),
  );

  // ── Qidiruv natijalari ─────────────────────────────────────────
  testWidgets(
    'qidiruv natijalari',
    (t) => shoot(
      t,
      'qidiruv_natija',
      const SearchResultsScreen(),
      overrides: [searchControllerProvider.overrideWith(() => _FakeSearch())],
    ),
  );
}

/// Natijalarni tarmoqsiz beradi — ekranni to'ldirilgan holatda ko'rish uchun.
class _FakeSearch extends RideSearchController {
  static final rides = [
    Ride(
      id: 'r1',
      originAddress: 'Toshkent, Chilonzor',
      destinationAddress: 'Samarqand, Registon',
      originLat: 41.2995,
      originLon: 69.2401,
      destinationLat: 39.6542,
      destinationLon: 66.9597,
      departureTime: DateTime.now().add(const Duration(hours: 20)),
      totalSeats: 4,
      availableSeats: 2,
      pricePerSeat: 150000,
      status: RideStatus.active,
      isNegotiable: true,
      hasAc: true,
      hasLuggage: true,
      driver: const DriverProfile(
        id: 'd1',
        name: 'Abdurahmon Rahmatullayev',
        rating: 4.8,
      ),
    ),
    Ride(
      id: 'r2',
      originAddress: 'Toshkent, Yunusobod',
      destinationAddress: 'Samarqand, Universitet xiyoboni',
      originLat: 41.35,
      originLon: 69.28,
      destinationLat: 39.65,
      destinationLon: 66.95,
      departureTime: DateTime.now().add(const Duration(days: 1, hours: 4)),
      totalSeats: 4,
      availableSeats: 3,
      pricePerSeat: 120000,
      status: RideStatus.active,
      driver: const DriverProfile(id: 'd2', name: 'Dilnoza', rating: 5.0),
    ),
  ];

  @override
  RideSearchParams? get lastParams => RideSearchParams(
    originLat: 41.2995,
    originLon: 69.2401,
    destLat: 39.6542,
    destLon: 66.9597,
    originName: 'Toshkent',
    destName: 'Samarqand',
    date: DateTime.now().add(const Duration(days: 1)),
  );

  @override
  Future<List<Ride>?> build() async => rides;
}
