import 'package:yolyolakay/features/shared/screen_title.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../data/models/chat.dart';
import '../../core/analytics.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/geo.dart';
import '../../core/place_links.dart';
import '../../core/calendar_export.dart';
import '../../core/format.dart';
import '../../core/haptics.dart';
import 'arrival_notice.dart';
import 'ride_poster.dart';
import 'ride_share.dart';
import 'trip_checklist.dart';
import 'seat_map.dart';
import '../profile/reviews_section.dart';
import '../shared/yol_refresh.dart';
import 'road_companion_card.dart';
import 'co_passengers.dart';
import '../../data/models/booking.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';
import '../map/route_map_sheet.dart';
import '../map/route_preview_map.dart';
import '../shared/bottom_action_bar.dart';
import '../shared/state_views.dart';
import '../shared/ui.dart';
import '../safety/sos_sheet.dart';
import '../moderation/report_block_sheet.dart';
import 'eta_ring.dart';
import 'journey_view.dart';
import 'ride_hero.dart';
import 'trip_passport.dart';
import 'ride_card.dart';
import '../../app/dimens.dart';
import '../../core/money_input.dart';
import '../shared/brand/brand_panels.dart';

/// Safar tafsiloti + bron qilish.
///
/// Ro'yxatdan kelgan [ride] darhol ko'rsatiladi (bo'sh ekran bo'lmasin),
/// keyin `GET /rides/{id}` bilan yangilanadi — u gateway'da hali bo'lmasligi
/// mumkin, bunda ro'yxatdagi ma'lumot qoladi.
class RideDetailsScreen extends ConsumerStatefulWidget {
  const RideDetailsScreen({super.key, required this.ride});

  final Ride ride;

  @override
  ConsumerState<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends ConsumerState<RideDetailsScreen> {
  late Ride _ride = widget.ride;
  int _seats = 1;
  bool _booking = false;
  Booking? _result;

  /// Yo'lovchi taklif qilayotgan narx (bir joy uchun). Boshlang'ich qiymat —
  /// haydovchi narxi, ya'ni "roziman".
  late double _offeredPrice = widget.ride.pricePerSeat;

  /// Narx maydoni — «+/−» qadam o'rniga (egasi, 2026-08-16).
  late final _priceController = TextEditingController(
    text: formatMoneyInput(widget.ride.pricePerSeat),
  );

  /// Butun salonni sotib olish.
  bool _buyout = false;

  /// Safar holatini davriy yangilash taymeri.
  Timer? _pollTimer;

  /// Oxirgi ko'rilgan bron holati — haydovchi javob berganini PAYQASH uchun.
  ///
  /// Nega kerak: holat polling orqali jimgina almashadi. Yo'lovchi ekranga
  /// tikilib o'tirsa ham "Kutilmoqda" -> "Qabul qilindi" o'tishini sezmasligi
  /// mumkin, holbuki bu butun oqimdagi eng kutilgan lahza. Vebda ham xuddi
  /// shunday xabar qo'shildi (2026-08-10).
  ///
  /// Push kelguncha (backendda ochiq) bu yagona xabar berish yo'li.
  /// `BookingStatus` — enum emas, String konstantalar sinfi.
  String? _lastSeenStatus;

  /// Oxirgi ko'rilgan SAFAR holati — haydovchi safarni bekor qilganini
  /// payqash uchun. Bron holati bunda o'zgarmaydi (`confirmed` bo'lib
  /// qolaveradi), shuning uchun alohida kuzatiladi.
  String? _lastSeenRideStatus;

  @override
  void initState() {
    super.initState();

    /*
     * 🔴 HAMMA `ref` CHAQIRUVI BIRINCHI KADRDAN KEYIN (2026-08-30 auditi).
     *
     * Ilgari `ref.read(...)` to'g'ridan-to'g'ri `initState` ichida
     * chaqirilardi va Flutter har safar safar ekrani ochilganda xato
     * yozardi:
     *
     *   dependOnInheritedWidgetOfExactType<UncontrolledProviderScope>()
     *   was called before _RideDetailsScreenState.initState() completed
     *
     * Sabab: Riverpod konteynerni `InheritedWidget` orqali topadi, bu
     * esa `initState` tugagunga qadar TAQIQLANGAN. Reliz build'da
     * tekshiruv o'chiq — shuning uchun u jimgina o'tib ketgan, lekin
     * debug'da har ochishda qizil xato chiqardi va Sentry'ga ham
     * tushardi.
     */
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // SO'NGGI KO'RILGANLAR — odam safarni ochib, «o'ylab ko'raman» deb
      // chiqsa uni qayta topa olsin (izohi `RecentRidesController` da).
      ref.read(recentRidesProvider.notifier).remember(_ride);
      _applySearchSeats();
      // Qidiruv -> ochish -> bron zanjiri: odam qayerda to'xtab qolishini
      // faqat uchalasi birga ko'rsatadi.
      ref
          .read(analyticsProvider)
          .log(
            AnalyticsEvent.rideOpened,
            payload: {'negotiable': widget.ride.isNegotiable},
          );
      _refresh();
    });

    /*
     * 🔴 Nima buzilgan edi (CEO 2026-08-04): haydovchi safarni boshlaganda va
     * hatto yakunlaganda ham yo'lovchida holat "faol" bo'lib qotib qolardi —
     * ekran faqat OCHILGANDA bir marta yangilanardi va boshqa hech qachon.
     * Backendda holat o'zgarishi bo'yicha WS hodisasi YO'Q (xatda so'radik),
     * shuning uchun yagona yo'l — yengil so'rov.
     *
     * 20 soniya: yetarlicha tez va yukni oshirmaydi. Safar tugagach taymer
     * O'ZI to'xtaydi (`_refresh` ichida) — bekorga so'rov ketmaydi.
     */
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
  }

  /// Qidiruvda nechta joy so'ralgan bo'lsa, bron oynasi ham shuncha
  /// bilan ochilsin.
  void _applySearchSeats() {
    /*
     * 🔴 Egasi topdi (2026-08-16): "2 yo'lovchiga" deb qidirsam, qidiruv
     * to'g'ri ishlaydi — lekin ichiga kirsam bron oynasi 1 joyga qaytib
     * ketadi: narx 1 kishiga hisoblanadi va haydovchiga ham 1 kishilik
     * so'rov ketadi. Odam buni sezmasligi mumkin va safarga ikkitasi
     * borib qoladi.
     *
     * Sabab: `_seats` qattiq 1 edi, qidiruvdagi `min_seats` esa faqat
     * SERVERGA ketardi va ekranga qaytmasdi. Endi qidiruv nechta joy
     * so'ragan bo'lsa, bron oynasi ham o'shancha bilan ochiladi.
     *
     * Bo'sh joy yetmasa mavjudiga QISQARTIRAMIZ (3 ta so'ralgan, 2 tasi
     * bo'sh) — aks holda tugma bosilishi bilan backend rad etardi.
     */
    final requested = ref
        .read(searchControllerProvider.notifier)
        .lastParams
        ?.minSeats;
    if (requested != null && requested > 1) {
      // Yuqori chegara "+" tugmasinikidek (`maxSeats`) — aks holda hisoblagich
      // tugma ruxsat bermaydigan qiymatdan boshlanardi.
      setState(
        () =>
            _seats = requested.clamp(1, widget.ride.availableSeats.clamp(1, 4)),
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _priceController.dispose();
    super.dispose();
  }

  /// ⚠ Backend semantikasi: `offered_price` YUBORILISHINING O'ZI savdolashish
  /// (`pending_negotiation`) deb qabul qilinadi. Yo'lovchi e'lon narxiga to'liq
  /// rozi bo'lsa maydon UMUMAN yuborilmasligi kerak (`pending`), aks holda
  /// haydovchi hech qanday savdo bo'lmagan bronni ham "kelishilyapti" deb
  /// ko'radi va ortiqcha tasdiqlash qadami paydo bo'ladi.
  double? get _priceToSend {
    if (!_ride.isNegotiable) return null;
    if (_offeredPrice == _ride.pricePerSeat) return null;
    return _offeredPrice;
  }

  /// Safarni telefon kalendariga qo'shish (`.ics`).
  Future<void> _addToCalendar() async {
    final t = AppStrings.of(context);
    final start = _ride.departureTime;
    if (start == null) return;

    final route = [
      _ride.originAddress.trim(),
      _ride.destinationAddress.trim(),
    ].where((p) => p.isNotEmpty).join(' → ');

    try {
      await shareIcs(
        fileName: 'yolyolakay-${_ride.id}',
        content: buildIcs(
          uid: _ride.id,
          start: start,
          title: route.isEmpty ? t.appName : '${t.appName}: $route',
          description: rideShareUrl(_ride.id, t.lang),
          location: _ride.pickupPoint ?? _ride.originAddress,
        ),
      );
    } catch (_) {
      // Ulashish bekor qilinsa yoki xato — jimgina o'tamiz.
    }
  }

  Future<void> _refresh() async {
    /*
     * 🔴 BRONNI HAM YANGILAYMIZ (egasi, 2026-08-16: "haydovchi qabul
     * qilsa ham yangilanmayapti").
     *
     * Ilgari bu yerda faqat SAFAR qayta o'qilardi. Bron holati esa
     * `myBookingsProvider` da va u faqat ekran birinchi ochilganda
     * yuklanardi — ya'ni haydovchi qabul qilsa ham yoki narx qaytarsa
     * ham, bu ekranda "Kutilmoqda" abadiy turaverardi. Hatto pastdagi
     * `_noticeStatusChange` ham hech qachon ishlamasdi: solishtiradigan
     * yangi holat kelmasdi.
     */
    ref.invalidate(myBookingsProvider);

    final fresh = await ref.read(ridesRepositoryProvider).byId(widget.ride.id);
    if (fresh == null || !mounted) return;
    // Yangisini eskining USTIGA qo'ymaymiz, BIRLASHTIRAMIZ: `GET /rides/{id}`
    // javobida haydovchi bo'lmasligi mumkin, o'shanda kartochkadagi ism
    // 30 soniyalik yangilashdan keyin "Haydovchi" ga aylanib qolardi.
    setState(() => _ride = fresh.mergedWith(_ride));
    _noticeRideCancelled(fresh.status);
    if (fresh.status == RideStatus.cancelled) _cancelReminders();
    // Tugagan/bekor qilingan safarda kuzatishning ma'nosi yo'q.
    if (fresh.status == RideStatus.completed ||
        fresh.status == RideStatus.cancelled) {
      _pollTimer?.cancel();
    }
  }

  Future<void> _book() async {
    setState(() => _booking = true);
    try {
      final booking = await ref
          .read(ridesRepositoryProvider)
          .book(
            _ride.id,
            BookRideRequest(
              seats: _buyout ? _ride.availableSeats.clamp(1, 8) : _seats,
              offeredPrice: _priceToSend,
              isFullCarBuyout: _buyout,
            ),
          );
      if (!mounted) return;
      // O'z taklifimizni eslab qolamiz: haydovchi narxni qaytarganda
      // "bu meniki emas, haydovchiniki" deb ayta olish uchun
      // (izohi `data/offer_memory.dart` da).
      final myOffer = _priceToSend;
      if (myOffer != null && booking.id.isNotEmpty) {
        await ref.read(offerMemoryProvider).remember(booking.id, myOffer);
      }
      if (!mounted) return;
      setState(() => _result = booking);
      ref
          .read(analyticsProvider)
          .log(
            AnalyticsEvent.bookingCreated,
            payload: {
              'seats': _buyout ? _ride.availableSeats : _seats,
              'buyout': _buyout,
              // Narx taklif qilindimi — savdolashish qanchalik ishlatilishini
              // ko'rsatadi.
              'negotiated': _priceToSend != null,
            },
          );
      ref.invalidate(myBookingsProvider);
      showMessage(context, AppStrings.of(context).booked);
    } catch (error) {
      if (!mounted) return;
      showApiError(context, error, ref.read(langProvider));
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  /// Shu safar uchun MAVJUD bron.
  ///
  /// 🔴 Ilgari faqat `_result` (lokal state) tekshirilardi: odam bron qilib,
  /// ekrandan chiqib qaytsa `_result` yana `null` bo'lardi va "Bron qilish"
  /// tugmasi qayta faol turardi — IKKI MARTA bron qilish mumkin edi.
  ///
  /// Endi server ro'yxatidan ham qaraymiz. `myBookingsProvider` baribir
  /// "Safarlarim" ekranida yuklanadi, ya'ni qo'shimcha so'rov emas.
  /// Bronlar ro'yxati HALI NOMA'LUM (yuklanyapti yoki yiqildi).
  ///
  /// 🔴 Bu holatda bron tugmasi OCHIQ QOLMASLIGI kerak: `_existingBooking`
  /// bo'sh ro'yxatda `null` qaytaradi, ya'ni ekran "sizda bron yo'q" deb
  /// hisoblaydi va odam IKKINCHI marta bron qilib yuborishi mumkin — yuqoridagi
  /// izohda tuzatilgan deb yozilgan xatoning aynan o'zi, faqat boshqa yo'ldan.
  /// Vebda ham shunday qo'riqchi bor (`myBookingsFetched`).
  bool get _bookingsUnknown {
    if (_result != null) return false; // o'z bronimiz allaqachon qo'limizda
    final async = ref.watch(myBookingsProvider);
    return async.isLoading || async.hasError;
  }

  Booking? get _existingBooking {
    if (_result != null) return _result;
    final bookings =
        ref.watch(myBookingsProvider).valueOrNull ?? const <Booking>[];
    for (final b in bookings) {
      // Rad etilgan bron qayta bron qilishga TO'SQINLIK QILMAYDI — odam
      // boshqa narx bilan yana urinishi mumkin.
      if (b.rideId == _ride.id && b.status != BookingStatus.rejected) return b;
    }
    return null;
  }

  /// Bron holati o'zgarganini tekshiradi va bir marta xabar ko'rsatadi.
  /// Ekran birinchi ochilganda xabar CHIQMAYDI (avvalgi holat noma'lum).
  void _noticeStatusChange(Booking? booking) {
    final now = booking?.status;
    final before = _lastSeenStatus;
    _lastSeenStatus = now;
    if (before == null || now == null || before == now || !mounted) return;

    final t = AppStrings.of(context);
    // ⚠️ Qabul qilingan status `confirmed` (accepted EMAS) — booking.dart izohi.
    if (now == BookingStatus.confirmed) {
      // Ko'tariluvchi uch zarba — telefon cho'ntakda bo'lsa ham javob
      // IJOBIY ekani bilinadi (izohi `AppHaptics.confirmed` da).
      AppHaptics.confirmed();
      showMessage(context, t.driverAcceptedRequest);
      // Bron tasdiqlangan payt — eslatma qo'yish uchun eng to'g'ri
      // lahza: vaqt ma'lum va odam safarga rozi bo'ldi.
      _scheduleReminders();
    } else if (now == BookingStatus.rejected) {
      AppHaptics.cancelled();
      showMessage(context, t.driverDeclinedRequest);
      _cancelReminders();
    }
  }

  /// Bosib o'tilgan yo'l ulushi (`0`..`1`) yoki `null`.
  ///
  /// Faqat safar YO'LDA bo'lganda hisoblanadi. Boshlanmagan safarda
  /// «nol foiz» ko'rsatish ham noto'g'ri bo'lardi — chiziq umuman
  /// to'lmasligi kerak.
  double? _journeyProgress() {
    if (_ride.status != RideStatus.inProgress) return null;

    final total = ref.watch(rideRouteProvider(_ride)).valueOrNull?.duration;
    final left = ref.watch(rideEtaProvider(_ride)).valueOrNull?.duration;
    if (total == null || left == null) return null;
    if (total.inSeconds <= 0) return null;

    // Qolgan vaqt to'liqdan KO'P bo'lishi mumkin (tirbandlik) — bunda
    // ulush nolga tushadi, manfiy emas.
    final done = 1 - left.inSeconds / total.inSeconds;
    return done.clamp(0.0, 1.0);
  }

  /// Safar eslatmalarini QURILMADA rejalashtiradi (izohi `TripReminders` da).
  ///
  /// Serverga bog'liq emas: push yuborilmasa ham ishlaydi.
  void _scheduleReminders() {
    final start = _ride.departureTime;
    if (start == null) return;
    final t = AppStrings.of(context);
    final route = [
      _ride.originAddress.trim(),
      _ride.destinationAddress.trim(),
    ].where((p) => p.isNotEmpty).join(' → ');

    // `unawaited` emas, oddiy chaqiruv: natija kutilmaydi va xato
    // xizmatning ichida yutiladi.
    ref
        .read(tripRemindersProvider)
        .schedule(
          rideId: _ride.id,
          departure: start,
          route: route,
          beforeTitle: t.reminderBeforeTitle,
          beforeBody: t.reminderBeforeBody,
          rateTitle: t.reminderRateTitle,
          rateBody: t.reminderRateBody,
        );
  }

  void _cancelReminders() {
    ref.read(tripRemindersProvider).cancel(_ride.id);
  }

  /// Haydovchi safarni BEKOR QILDI — ekran ochiq turgan odamga darhol
  /// aytamiz.
  ///
  /// 🔴 Egasi (2026-08-16): "haydovchi safarni bekor qilsa yo'lovchiga xabar
  /// ham kelmaydi, bilmay ishonib qolib ketadi". Holat jimgina almashardi:
  /// sahifada bir nishon o'zgarardi, xolos. Bron holati esa `confirmed`
  /// bo'lib qolgani uchun ro'yxatda hech nima o'zgarmasdi.
  ///
  /// ⚠️ Bu FAQAT ekran ochiq bo'lgan holatni yopadi. Ilova yopiq bo'lsa
  /// xabar push bilan kelishi kerak — u backend tomonda
  /// (BACKEND_XAT_PUSH_2026-08-16, 4-trigger).
  void _noticeRideCancelled(String status) {
    final before = _lastSeenRideStatus;
    _lastSeenRideStatus = status;
    if (before == null || before == status || !mounted) return;
    if (status != RideStatus.cancelled) return;
    showMessage(context, AppStrings.of(context).rideCancelledTitle);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    // Haydovchi javob berdimi — build paytida tekshiramiz (bron allaqachon
    // shu yerda kuzatilyapti, ya'ni qo'shimcha so'rov ketmaydi). Xabar
    // kadr chizilgandan KEYIN ko'rsatiladi.
    final currentBooking = _existingBooking;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _noticeStatusChange(currentBooking),
    );
    final maxSeats = _ride.availableSeats.clamp(1, 4);
    final total = _ride.pricePerSeat * _seats;

    // Mashina: odatda safar javobining o'zida keladi. Kelmasa `vehicle_id`
    // bo'yicha alohida so'raymiz — javob bo'lmasa qator umuman chizilmaydi.
    final car =
        _ride.car ??
        ((_ride.vehicleId ?? '').isEmpty
            ? null
            : ref.watch(vehicleByIdProvider(_ride.vehicleId!)).valueOrNull);

    return Scaffold(
      appBar: AppBar(
        bottom: const JiyakLine(),
        title: ScreenTitle(t.rideDetails),
        // SOS safar ekranida — aynan yo'lda kerak bo'ladi. Qizil rang bilan,
        // lekin AppBar'da: tasodifan bosilmasin deb pastga yashirilmadi.
        actions: [
          // ULASHISH — safar Telegramga tayyor matn bo'lib ketadi.
          // SOS'dan OLDIN emas, KEYIN turishi kerak edi-yu, lekin SOS
          // qizil va o'ngda — u yerda odat bo'yicha eng kam bosiladigan
          // amal turadi. Ulashish esa kundalik, shuning uchun chapda.
          // ULASHISH — oddiy matn (tez) yoki BRENDLI PLAKAT (ko'zga
          // tashlanadi). Ikkalasi ham kerak: chatda matn qulay, guruhda
          // esa rasm ishlaydi (izohi `RidePoster` da).
          PopupMenuButton<int>(
            icon: const Icon(Icons.ios_share),
            tooltip: t.shareRide,
            itemBuilder: (menuContext) => [
              PopupMenuItem(value: 0, child: Text(t.shareRide)),
              PopupMenuItem(
                value: 1,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(t.sharePoster),
                  subtitle: Text(t.sharePosterHint),
                ),
              ),
            ],
            onSelected: (value) => value == 0
                ? shareRide(context, _ride)
                : showRidePoster(context, _ride),
          ),
          IconButton(
            icon: Icon(
              Icons.emergency_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: t.sosTitle,
            onPressed: () => SosSheet.show(context),
          ),
          // Shikoyat/bloklash — ilgari FAQAT chatdan mumkin edi, chat esa faqat
          // TASDIQLANGAN bron uchun ochiladi. Ya'ni bezori haydovchi ustidan
          // shikoyat qilish uchun avval uning safarini bron qilish kerak edi.
          // Google Play talabi nuqtai nazaridan ham zaif.
          if ((_ride.driver?.id ?? '').isNotEmpty)
            ReportBlockMenu(
              targetUserId: _ride.driver!.id!,
              targetName: _ride.driver?.name,
              rideId: _ride.id,
            ),
        ],
      ),
      /*
       * TORTIB-YANGILASH — qo'l tormozi (egasi, 2026-08-28).
       *
       * 🔴 NEGA KERAK: safar ma'lumoti o'z-o'zidan ham yangilanadi
       * (`_pollTimer`), lekin odamda QO'LDA yangilash yo'li yo'q edi.
       * Aynan bu ekranda savol eng o'tkir: «safar hali ham bormi, joy
       * qoldimi, haydovchi qayerda». Avtomatik yangilanishni KUTIB
       * o'tirish — ishonchsizlik hissi beradi, garchi ma'lumot to'g'ri
       * bo'lsa ham.
       *
       * ⚠️ Avtomatik yangilash OLIB TASHLANMADI: ikkalasi birga
       * ishlaydi. Qo'l tormozi dvigatel tormozini almashtirmaydi.
       *
       * `_refresh()` allaqachon bor edi — faqat uni chaqiradigan
       * HARAKAT yo'q edi.
       */
      body: YolRefresh(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            // BRONINGIZ — eng tepada.
            //
            // Ilgari bron holati faqat pastdagi panelda, "So'rov yuborildi"
            // yozuvi ostida turardi. Ekranga qaytgan odamning birinchi savoli
            // esa aynan shu: "haydovchi javob berdimi?" — buning uchun u pastga
            // aylantirishi kerak edi. Endi javob birinchi qatorda.
            if (currentBooking != null) ...[
              _BookingBanner(booking: currentBooking),
              _BookingProgress(
                bookingStatus: currentBooking.status,
                rideStatus: _ride.status,
              ),
              const SizedBox(height: AppSpace.md),
              // Uchrashuv payti kerak bo'ladigan hamma narsa — FAQAT bron
              // tasdiqlangach: undan oldin uchrashuv hali yo'q.
              if (currentBooking.isConfirmed) ...[
                // Uchrashuv nuqtasi koordinatasi: 1) haydovchi xaritada
                // qo'ygan ANIQ nuqta (`pickup_lat/lon`); 2) bo'lmasa —
                // matndan geokod (izohi `pickupCoordProvider` da);
                // 3) u ham topilmasa — boshlanish shahri.
                //
                // 🔴 28.09.2026 gacha birinchi qadam YO'Q edi: server aniq
                // nuqtani qaytarsa ham ilova uni tashlab, matnni qayta
                // geokod qilardi — «Chorsu metro, 3-chiqish» geokoderda
                // butun Chorsuga yoki umuman topilmay shahar markaziga
                // tushardi.
                Builder(
                  builder: (context) {
                    final exact = _ride.hasPickupCoord;
                    final coord = exact
                        ? null
                        : ref
                              .watch(
                                pickupCoordProvider(_ride.pickupPoint ?? ''),
                              )
                              .valueOrNull;
                    return _PickupCard(
                      car: car,
                      pickupPoint: _ride.pickupPoint,
                      lat: exact
                          ? _ride.pickupLat!
                          : coord?.lat ?? _ride.originLat,
                      lon: exact
                          ? _ride.pickupLon!
                          : coord?.lon ?? _ride.originLon,
                    );
                  },
                ),
                const SizedBox(height: AppSpace.sm),
                // KALENDAR — ilova ichidagi eslatmadan KUCHLIROQ: u
                // ilovadan tashqarida yashaydi, boshqa qurilmalarga
                // sinxronlanadi va ilova o'chirilsa ham qoladi.
                if (_ride.departureTime != null)
                  OutlinedButton.icon(
                    onPressed: () => _addToCalendar(),
                    icon: const Icon(Icons.event_available_outlined, size: 18),
                    label: Text(t.addToCalendar),
                  ),
                // XAVFSIZLIK: SOS hodisadan KEYIN ishlaydi, bu esa oldini
                // oladi — yaqinlari kim bilan va qanaqa mashinada
                // ketayotganini oldindan biladi.
                OutlinedButton.icon(
                  onPressed: () => shareTripWatch(context, ref, _ride),
                  icon: const Icon(Icons.shield_outlined, size: 18),
                  label: Text(t.watchTripAction),
                ),
                const SizedBox(height: AppSpace.md),
                // «Qachon yetamiz?» — safar BOSHLANGANDA. Yuklanayotgani
                // yoki xatosi ko'rsatilmaydi: bu qo'shimcha ma'lumot,
                // uning yiqilishi ekranni buzmasligi kerak.
                ref
                    .watch(rideEtaProvider(_ride))
                    .maybeWhen(
                      data: (eta) {
                        final duration = eta?.duration;
                        if (duration == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.md),
                          child: InfoBox(
                            child: Row(
                              children: [
                                // HALQA — haydovchi surati atrofida aylanadi.
                                // Ilgari bu yerda oddiy soat ikonkasi turardi
                                // va butun qator ekrandagi boshqa o'nta qator
                                // orasida yo'qolib ketardi. Ayni paytda safar
                                // boshlangach yo'lovchini QIZIQTIRADIGAN
                                // yagona narsa shu (izohi `EtaRing` da).
                                EtaRing(
                                  size: 64,
                                  child: PersonAvatar(
                                    url: _ride.driver?.avatar,
                                    radius: 26,
                                    gender: _ride.driver?.gender,
                                    seed: _ride.driver?.id,
                                  ),
                                ),
                                const SizedBox(width: AppSpace.md),
                                Expanded(
                                  // «Taxminan» ATAYIN: raqam haydovchining
                                  // oxirgi ping'iga tayanadi va u ilovani
                                  // yopsa eskiradi.
                                  child: Text(
                                    t.etaApprox(
                                      formatDuration(duration, t.lang),
                                    ),
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
              ],
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SANA + NARX bir qatorda.
                    //
                    // 🔴 Narx bu ekranda UMUMAN ko'rinmasdi: u faqat pastdagi
                    // bron blokida bor edi, bron qilingandan keyin esa o'sha
                    // blok holat tugmasiga almashadi. Ya'ni bron qilgan odam
                    // o'zi qancha to'lashini bu yerda ko'ra olmasdi
                    // (qurilmada ko'rilgan, 2026-08-12).
                    Row(
                      // 🔴 BIR BAZA CHIZIG'IDA (2026-09-03 ko'rigi).
                      //
                      // `start` bilan ikkala ustunning USTI tenglashardi,
                      // lekin sana 16 px, narx esa 20 px — ya'ni harflar
                      // turli balandlikda «suzib» turardi va qator
                      // qiyshiq ko'rinardi. Odam ustni emas, HARFLAR
                      // TURGAN CHIZIQNI ko'radi.
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatDateTime(_ride.departureTime, t.lang),
                                style: theme.textTheme.titleMedium,
                              ),
                              // Bu ekranda aniq vaqt QOLADI (kartadan farqli),
                              // "qancha qoldi" esa uning ostiga qo'shiladi:
                              // odam ulgurishini shu yerda hal qiladi.
                              // MANZILDAGI OB-HAVO — safar kunida. Odam nima
                              // kiyishini va yo'l qanday bo'lishini shu yerda
                              // biladi (hozir buni boshqa ilovadan qaraydi).
                              ref
                                  .watch(rideWeatherProvider(_ride))
                                  .maybeWhen(
                                    data: (w) => w == null
                                        ? const SizedBox.shrink()
                                        : Padding(
                                            padding: const EdgeInsets.only(
                                              top: AppSpace.xs,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  w.icon,
                                                  size: 15,
                                                  color:
                                                      theme.colorScheme.outline,
                                                ),
                                                const SizedBox(
                                                  width: AppSpace.xs,
                                                ),
                                                Text(
                                                  '${_ride.destinationAddress}: ${w.tempLabel}',
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .outline,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                    orElse: () => const SizedBox.shrink(),
                                  ),
                              // Holat bilan: «Jo'nab ketdi» yozuvi safar
                              // boshlanmagan bo'lsa yolg'on edi
                              // (izohi `departureStatusLabel` da).
                              if (departureStatusLabel(
                                _ride.departureTime,
                                _ride.status,
                                t.lang,
                              ).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpace.sm,
                                  ),
                                  /*
                                   * 🔴 HOLAT — MATN EMAS, NISHON
                                   * (2026-09-03 ko'rigi).
                                   *
                                   * «Kechikmoqda — 4 soat 2 daqiqa»
                                   * yozuvi PUSHTI matn edi va yonidagi
                                   * PUSHTI narx bilan yonma-yon turardi:
                                   * bitta bo'lakda ikkita pushti,
                                   * ikkalasi ham «eng muhim» deb
                                   * baqirardi. Ustiga uzun matn ikki
                                   * qatorga sinib, chap ustunni
                                   * cho'zib yuborardi va qator
                                   * yamoq-yamoq ko'rinardi.
                                   *
                                   * Endi u NISHON — ro'yxatdagi
                                   * «N joy qoldi» bilan bir xil shakl
                                   * va rangda. Nishon o'zini «holat»
                                   * deb tanitadi, narx bilan
                                   * raqobatlashmaydi, va bir butun
                                   * bo'lak sifatida ko'chadi.
                                   *
                                   * Oddiy holatda (kechikish yo'q) u
                                   * avvalgidek sokin yozuv bo'lib
                                   * qoladi: nishon faqat E'TIBOR
                                   * talab qilganda paydo bo'ladi.
                                   */
                                  child:
                                      departureNeedsAttention(
                                        _ride.departureTime,
                                        _ride.status,
                                      )
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpace.sm,
                                            vertical: AppSpace.xxs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme
                                                .errorContainer,
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.pill,
                                            ),
                                          ),
                                          child: Text(
                                            departureStatusLabel(
                                              _ride.departureTime,
                                              _ride.status,
                                              t.lang,
                                            ),
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: theme
                                                      .colorScheme
                                                      .onErrorContainer,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          departureStatusLabel(
                                            _ride.departureTime,
                                            _ride.status,
                                            t.lang,
                                          ),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        // 🔴 `Flexible` + `FittedBox` (2026-08-30 auditi):
                        // katta matn rejimida (1.3 baravar) narx ustuni
                        // qatordan 42 pikselgacha toshib ketardi. Narxni
                        // KESIB BO'LMAYDI — shuning uchun u ellips bilan
                        // qisqarmaydi, balki kerak bo'lsa KICHRAYADI.
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Narx BELGILAB NUSXALANADI (egasi 2026-08-20).
                              // Bu tafsilot ekrani — bosiladigan karta emas, shuning
                              // uchun matn tanlash bosishni buzmaydi.
                              // `RideHero`: ro'yxatdagi narx SHU YERGA uchib
                              // keladi va kattalashadi. Teg bir xil bo'lgani
                              // uchun boshqa hech nima kerak emas.
                              RideHero(
                                rideId: _ride.id,
                                part: RideHeroPart.price,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: SelectableText(
                                    '${formatPrice(_ride.pricePerSeat)} ${t.sum}',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                t.perSeat,
                                textAlign: TextAlign.end,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.lg),
                    // Marshrut — qidiruv kartasidagi bilan BIR XIL chiziq.
                    // Ilgari bu yerda uchta bir-biriga ulanmagan ikonkali qator
                    // turardi (`trip_origin`, `more_vert`, `place`) va oraliq
                    // shaharlar "uch nuqta" belgisi bilan chiziladi edi — qaysi
                    // biri jo'nash, qaysi biri manzil ekani ko'rinmasdi.
                    RideHero(
                      rideId: _ride.id,
                      part: RideHeroPart.journey,
                      child: JourneyLine(
                        origin: _ride.originAddress,
                        destination: _ride.destinationAddress,
                        stops: [for (final s in _ride.stops) s.address],
                        /*
                       * JONLI YO'L TASMASI — bosib o'tilgan qism to'ladi.
                       *
                       * 🔴 Safar boshlangach yo'lovchi KO'R bo'lib qolardi:
                       * ETA raqami bor edi-yu, marshrut chizig'i safar
                       * boshlanishidan oldin ham, o'rtasida ham AYNAN bir
                       * xil ko'rinardi.
                       *
                       * ⚠️ QIYMAT TO'QIB CHIQARILMAYDI — u faqat IKKI ROST
                       * raqamdan: yo'lning to'liq davomiyligi
                       * (`/routing/route`) va qolgan vaqt
                       * (`/telematics/eta`). Biri yo'q bo'lsa `null` va
                       * chiziq avvalgidek bir xil qoladi.
                       */
                        progress: _journeyProgress(),
                      ),
                    ),
                    // 🔴 MASOFA VA YO'L VAQTI serverda allaqachon bor edi
                    // (`GET /routing/route`), lekin ilova uni so'ramasdi:
                    // yo'lovchi safar necha kilometr va necha soatligini
                    // bilmasdan bron qilardi (2026-08-14).
                    //
                    // Kelmasa hech narsa chizilmaydi — bu ikkinchi darajali
                    // ma'lumot, uning yo'qligi ekranni buzmasligi kerak.
                    ref
                        .watch(rideRouteProvider(_ride))
                        .maybeWhen(
                          data: (route) => route == null
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpace.md,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.route_outlined,
                                        size: 16,
                                        color: theme.colorScheme.outline,
                                      ),
                                      const SizedBox(width: AppSpace.sm),
                                      Expanded(
                                        child: Text(
                                          '${route.distanceKm.round()} ${t.kmAway} · ${formatDuration(route.duration, t.lang)}',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                    if (_ride.pickupPoint != null) ...[
                      const Divider(height: 24),
                      _Row(
                        icon: Icons.pin_drop_outlined,
                        text: '${t.pickupPoint}: ${_ride.pickupPoint}',
                      ),
                    ],
                    const SizedBox(height: AppSpace.md),

                    /*
                     * XARITA ENDI TUGMA ORTIDA EMAS — 16.09.2026
                     * (egasi: «karta to'liq ishlatilsin»).
                     *
                     * 🔴 Bu yerda «Xaritada ko'rish» degan IKKINCHI
                     * DARAJALI havola turardi — ataylab so'niq, e'tibor
                     * tortmasin deb. Natijada yo'nalish deyarli hech
                     * qachon ochilmasdi: yo'lovchi ikkita shahar nomini
                     * o'qib, uchrashuv nuqtasi qayerdaligini bilmasdan
                     * bron qilardi. Holbuki bizda manzil — haydovchi
                     * yozgan erkin matn («Chortoq, 3-mavze»).
                     *
                     * Endi yo'l DARHOL ko'rinadi, bosilsa to'liq xarita
                     * ochiladi (jonli nuqta, navigator — hammasi
                     * o'sha yerda). Ko'rik TINCH: u barmoq harakatini
                     * o'ziga olmaydi va ekran surilishini buzmaydi.
                     */
                    RoutePreviewMap(
                      waypoints: [
                        LatLng(_ride.originLat, _ride.originLon),
                        for (final stop in _ride.stops)
                          LatLng(stop.lat, stop.lon),
                        LatLng(_ride.destinationLat, _ride.destinationLon),
                      ],
                      height: 150,
                      label: t.showOnMap,
                      originName: _ride.originAddress,
                      destinationName: _ride.destinationAddress,
                      onTap: () => showRouteMapSheet(context, _ride),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.md),

            // HAYDOVCHI + HOLAT + BO'SH JOY — bitta kartada.
            //
            // Ilgari haydovchi kartochkasi FAQAT ma'lumot kelganda chizilardi,
            // holat esa alohida chip bo'lib bo'm-bo'sh maydonda osilib turardi.
            // Yo'lovchi uchun eng muhim savol — "kim bilan ketyapman" — ba'zan
            // umuman javobsiz qolardi. Endi blok DOIM bor: ism bo'lmasa
            // "Haydovchi" deb turadi, lekin joyi va tuzilishi o'zgarmaydi.
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    DriverRow(
                      name: _ride.driver?.name,
                      rating: _ride.driver?.rating,
                      gender: _ride.driver?.gender,
                      avatarUrl: _ride.driver?.avatar,
                      seed: _ride.driver?.id,
                      avatarRadius: 22,
                      // Haydovchi endi O'LIK NUQTA emas: bosilsa profili
                      // ochiladi (reyting, qachondan beri platformada).
                      onTap: (_ride.driver?.id ?? '').isEmpty
                          ? null
                          : () => context.push(
                              Routes.userProfile,
                              extra: <String, String?>{
                                'id': _ride.driver!.id!,
                                'name': _ride.driver?.name,
                              },
                            ),
                      // Safar holati shu yerda — alohida osilib turgan chip emas.
                      trailing: StatusPill(
                        tone: StatusTone.forRide(
                          theme.colorScheme,
                          _ride.status,
                        ),
                        label: t.rideStatus(_ride.status),
                      ),
                    ),

                    /*
                   * YO'L HAMROHI — «hozir qayerdan o'tyapmiz».
                   *
                   * FAQAT safar YO'LDA bo'lganda va haydovchining oxirgi
                   * ma'lum joyi bo'lganda. Karta tarmoqqa so'rov
                   * QILMAYDI — joylar ham, matnlar ham qurilmada
                   * (izohi `core/road_facts.dart` da): shaharlararo
                   * yo'lda aynan zerikish paytida internet yo'q.
                   */
                    if (_ride.status == RideStatus.inProgress) ...[
                      () {
                        final pos = ref
                            .watch(driverPositionProvider(_ride))
                            .valueOrNull;
                        if (pos == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpace.md),
                          child: RoadCompanionCard(lat: pos.lat, lon: pos.lon),
                        );
                      }(),
                    ],

                    // HAYDOVCHI HAQIDA SHARHLAR — qaror AYNAN shu yerda
                    // qabul qilinadi, profilga o'tishni kutib bo'lmaydi.
                    //
                    // ⚠️ Atigi IKKITA: karta allaqachon zich va qolgani
                    // profilda (haydovchi qatori bosilsa ochiladi).
                    if ((_ride.driver?.id ?? '').isNotEmpty) ...[
                      const SizedBox(height: AppSpace.md),
                      ReviewsSection(userId: _ride.driver!.id!, limit: 2),
                    ],
                    /*
                   * SAFAR PASPORTI — FAQAT tugagan safarda.
                   *
                   * 🔴 Safar tugaydi va IZSIZ yo'qoladi: odam eslab
                   * qoladigan, do'stiga ko'rsatadigan hech narsa
                   * qolmaydi. Karta faqat ROST ma'lumotdan quriladi
                   * (izohi `TripPassport` da) — masofa/vaqt kelmasa
                   * o'sha qator umuman chizilmaydi.
                   */
                    if (_ride.status == RideStatus.completed) ...[
                      const SizedBox(height: AppSpace.md),
                      () {
                        final route = ref
                            .watch(rideRouteProvider(_ride))
                            .valueOrNull;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TripPassport(
                              ride: _ride,
                              distanceKm: route == null
                                  ? null
                                  : route.distanceMeters / 1000,
                              duration: route?.duration,
                            ),
                            const SizedBox(height: AppSpace.sm),
                            OutlinedButton.icon(
                              onPressed: () => TripPassport.share(context),
                              icon: const Icon(Icons.ios_share, size: 18),
                              label: Text(t.tripPassportShare),
                            ),
                          ],
                        );
                      }(),
                    ],
                    // O'RINDIQ SXEMASI — "3 joy" raqami ikki xil o'qilardi
                    // (mashinada uchta joy bormi yoki uchtasi BO'SHMI?).
                    // Sxemada savol qolmaydi. Izohi `SeatMap` da.
                    const SizedBox(height: AppSpace.md),
                    SeatMap(
                      totalSeats: _ride.totalSeats,
                      availableSeats: _ride.availableSeats,
                      maxTwoBack: _ride.maxTwoBack,
                      // Tanlash FAQAT bron qilinmagan va butun mashina
                      // sotib olinmagan holatda: qolgan holatlarda son
                      // odamning ixtiyorida emas.
                      selected: _existingBooking == null && !_buyout
                          ? _seats
                          : 0,
                      maxSelectable: _existingBooking == null && !_buyout
                          ? _ride.availableSeats.clamp(1, 4)
                          : 0,
                      onSelect: _existingBooking == null && !_buyout
                          ? (n) => setState(() => _seats = n.clamp(1, 4))
                          : null,
                    ),
                    // MASHINA — ilovada UMUMAN ko'rinmasdi (saytda bor edi).
                    // Odam qanaqa mashina kelishini va raqamini bilishi kerak:
                    // uchrashuv nuqtasida uni shu bilan taniydi.
                    if (car != null) ...[
                      const SizedBox(height: AppSpace.md),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 18,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: Text(
                              [
                                car.title,
                                if ((car.color ?? '').isNotEmpty) car.color!,
                                if (car.year != null) '${car.year}',
                              ].where((p) => p.isNotEmpty).join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          if ((car.plate ?? '').isNotEmpty) ...[
                            const SizedBox(width: AppSpace.sm),
                            // Raqam — "avtomobil raqami" ko'rinishida: aynan shu
                            // matnni odam ko'chada solishtiradi.
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.sm,
                                vertical: AppSpace.xs,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.badge,
                                ),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Text(
                                car.plate!,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    // HAMROHLAR — boshqa tasdiqlangan yo'lovchilar,
                    // telefonsiz. Manba: safar javobining O'ZIDAGI
                    // `passengers[]` — mehmonga ham ko'rinadi
                    // (14.09.2026, izohi `CoPassengers` da).
                    const SizedBox(height: AppSpace.md),
                    CoPassengers(
                      passengers: _ride.passengers,
                      selfUserId: ref.watch(meProvider).valueOrNull?.user.id,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    // 🔴 `Row` EMAS, `Wrap` (2026-08-30 auditi): «2 bo'sh
                    // o'rin» va «Narx kelishiladi» katta matn rejimida
                    // bitta qatorga sig'masdi — 208 pikselgacha toshish.
                    // `Wrap` ularni ikkinchi qatorga tushiradi.
                    Wrap(
                      spacing: AppSpace.lg,
                      runSpacing: AppSpace.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_seat_outlined,
                              size: 15,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Text(
                              '${_ride.availableSeats} ${t.freeSeats}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        if (_ride.isNegotiable)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.forum_outlined,
                                size: 15,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(width: AppSpace.xs),
                              Text(
                                t.negotiable,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            /*
             * «FAQAT AYOLLAR» — QULAYLIK EMAS, BRON SHARTI.
             *
             * Shuning uchun u chiplar orasida emas, alohida va bron
             * tugmasidan OLDIN turadi: odam shartni bron qilishdan
             * oldin ko'rishi kerak, keyin emas.
             */
            if (_ride.genderRestriction == 'female') ...[
              const SizedBox(height: AppSpace.md),
              Container(
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.female,
                      size: 20,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        t.womenOnlyHint,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (rideBadges(_ride, t, includeGender: false).isNotEmpty) ...[
              const SizedBox(height: AppSpace.xl),
              SectionLabel(t.comfortTitle),
              const SizedBox(height: AppSpace.sm),
              // Sarlavhasiz, katta oraliqli chiplar ro'yxati "nosozlik ro'yxati"
              // kabi ko'rinardi. Endi bo'lim nomi bor va oraliq ixchamroq.
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final badge in rideBadges(
                    _ride,
                    t,
                    includeGender: false,
                  ))
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(badge.label),
                      avatar: RideBadgeIcon(
                        badge,
                        size: 18,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                ],
              ),
            ],

            /*
           * SAFAR OLDI RO'YXATI — FAQAT bron qilingan va hali
           * boshlanmagan safarda (izohi `TripChecklist` da).
           *
           * Bron qilinmagan safarда ro'yxat ma'nosiz: odam hali
           * ketishini ham hal qilmagan. Tugagan safarда esa u
           * shunchaki eski axlat bo'lardi.
           */
            if (_existingBooking != null &&
                _ride.status != RideStatus.completed &&
                _ride.status != RideStatus.cancelled) ...[
              const SizedBox(height: AppSpace.xl),
              TripChecklist(rideId: _ride.id, forDriver: false),
            ],

            /*
             * BRON FORMASI — SURILADIGAN QISMDA (2026-08-30).
             *
             * 🔴 Nima buzilgan edi: narx taklifi, joy hisoblagichi va
             * «butun salon» belgisi PASTKI PANELDA turardi. Panel
             * ekranning yarmini egallab, safar ma'lumotlari (marshrut,
             * haydovchi, o'rindiqlar) bir chiziqqa siqilib qolardi —
             * rasmda ochiq ko'rindi. Katta matn rejimida esa panel
             * shu qadar o'sardiki, «Bron qilish» tugmasi ekran ostiga
             * tushib ketardi.
             *
             * Endi FORMA suriladi, PANELDA esa faqat ikki narsa
             * qoladi: yakuniy summa va tugma. Loyihaning umumiy
             * qoidasi ham shu — «asosiy tugma suriladigan qism ichida
             * turmasin, qolgani esa surilsin».
             */
            if (_existingBooking == null) ...[
              const SizedBox(height: AppSpace.xl),
              if (_ride.isNegotiable) _priceOffer(t, theme),
              /*
                 * 🔴 BITTA QATOR EMAS, IKKITA (2026-08-30 auditi).
                 *
                 * Ilgari bu «Yo'lovchilar — [−] 2 [+] — 300 000 so'm»
                 * bitta `Row` edi va SIG'MASDI: 360 pikselli ekranda
                 * o'ngdan 144 piksel toshardi (320 px da 184, ruscha
                 * matnda ham xuddi shunday). Ya'ni NARX ekrandan
                 * chiqib ketgan — yo'lovchi qancha to'lashini
                 * ko'rmasdan bron qilardi. Bu ilovaning eng muhim
                 * ekrani.
                 *
                 * Ikki qator hech qachon toshmaydi: yorliq
                 * `Expanded` ichida qisqaradi, narx esa o'z qatorida
                 * to'liq turadi.
                 */
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.passengers,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: t.seatDecrease,
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _buyout || _seats <= 1
                        ? null
                        : () => setState(() => _seats--),
                  ),
                  Text('$_seats', style: theme.textTheme.titleMedium),
                  IconButton(
                    tooltip: t.seatIncrease,
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _buyout || _seats >= maxSeats
                        ? null
                        : () => setState(() => _seats++),
                  ),
                ],
              ),
              if (_ride.availableSeats > 1)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  value: _buyout,
                  // `Expanded`: uzun sarlavha ikonkani ekrandan
                  // chiqarib yubormasin (audit: 64 pikselgacha
                  // toshish).
                  title: Row(
                    children: [
                      const Icon(Icons.directions_car_filled, size: 18),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(child: Text(t.buyoutTitle)),
                    ],
                  ),
                  subtitle: Text(
                    t.buyoutHint,
                    style: theme.textTheme.bodySmall,
                  ),
                  onChanged: (value) =>
                      setState(() => _buyout = value ?? false),
                ),
            ],

            // «YETIB KELDIM» — safar oldidagi «Safarimni kuzat» xabarining
            // JAVOBI (izohi `ArrivalNotice` da). Faqat bron qilgan odamда:
            // begona safarда «yetib keldingiz» degan gap ma'nosiz.
            if (_existingBooking != null) ArrivalNotice(ride: _ride),
          ],
        ),
      ),
      // Chat uchun haydovchi ID'si. Backend uni ikki joyda beradi
      // (`driver_id` yoki ichma-ich `driver.id`) — ikkalasini ham qaraymiz.
      /*
       * PASTKI PANEL — IKKI NARSA, BOSHQA HECH NIMA (2026-08-30).
       *
       * 🔴 Ilgari bu yerda butun bron formasi turardi: narx taklifi,
       * joy hisoblagichi, «butun salon» belgisi va tugma. Panel
       * ekranning YARMINI egallab, safar ma'lumotlariga bir chiziqcha
       * joy qolardi; katta matn rejimida esa u toshib, tugmani
       * ekrandan tushirib yuborardi (auditda 136 piksel).
       *
       * Endi forma suriladigan qismда, panelda esa faqat qaror uchun
       * kerak bo'lgani: YAKUNIY SUMMA va TUGMA. Panel har doim past va
       * tugma har doim ko'rinadi.
       */
      // Panel suriladigan mazmundan CHIZIQ bilan ajraladi — tor ekranda
      // xato yozuvi va tugma bir-biriga yopishib qolardi (izohi
      // `BottomActionBar` da).
      bottomNavigationBar: BottomActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_existingBooking == null) ...[
              // NARX — alohida qatorda va URG'ULI. Odam bron
              // tugmasini bosishdan oldin ko'radigan oxirgi raqam.
              /*
               * JAMI — QAROR LAHZASI (2026-09-02, «YO'L» dizayn tili).
               *
               * 🔴 Ilgari yorliq ham, summa ham deyarli bir xil
               * og'irlikda edi (`bodyMedium` va `titleMedium`) — ya'ni
               * ekranning eng muhim raqami ro'yxatdagi oddiy qatordan
               * farq qilmasdi. Odam tugmani bosishdan oldin oxirgi
               * marta AYNAN shu raqamga qaraydi.
               *
               * Endi summa eng katta o'lchamda, yorliq esa shivirlaydi.
               *
               * ⚠️ SUMMA PUSHTI EMAS: pushti tugmaning o'zida. Ikkalasi
               * ham brend rangida bo'lsa, ko'z qayerga qarashni bilmaydi.
               */
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      t.priceTotal,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  // ⚠️ `FittedBox`: katta matn rejimida summa qatordan
                  // toshib ketmasin — narxni kesib bo'lmaydi, u faqat
                  // kichrayishi mumkin.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${formatPrice(total)} ${t.sum}',
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              // Tugma nega o'chiq — ochiq aytamiz. Sababsiz o'chgan tugma
              // "ilova buzuq" degan taassurot qoldiradi.
              if (ref.watch(myBookingsProvider).hasError) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.of(context).bookingsUnavailable,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(myBookingsProvider),
                      child: Text(AppStrings.of(context).retry),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
              ],
              // 🔴 O'CHIQ TUGMA SABABINI AYTSIN (2026-09-05, qulaylik
              // auditining 5-darajasi). Tugma to'rt xil holatda o'chib
              // qolardi — joy tugagan, safar yopilgan, yuklanmoqda,
              // bronlarim noma'lum — va HECH BIRIDA sababi ekranga
              // chiqmasdi. Odam uchun sababsiz o'chiq tugma =
              // «ilova buzuq». Bu shikoyat loyihada besh marta
              // qaytgan (izohi `BottomActionBar` da).
              //
              // Yuklanish va «bronlarim noma'lum» holatlari o'z
              // belgisini allaqachon ko'rsatadi (aylana va yuqoridagi
              // «Qayta urinish» qatori), shuning uchun bu yerda
              // safarning O'ZIGA tegishli ikki sabab yoziladi.
              if (!_booking && !_bookingsUnknown)
                if (_ride.availableSeats == 0 || !_ride.isBookable()) ...[
                  InfoBox(
                    tone: InfoTone.neutral,
                    child: Text(
                      _ride.availableSeats == 0
                          ? t.seatsSoldOut
                          : t.bookingClosed,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
              FilledButton(
                // Safar tugagan/bekor qilingan YOKI jo'nab ketgan (3 soatlik
                // oynadan o'tgan) bo'lsa bron qilib bo'lmaydi. Ilgari tugma
                // faqat `isActive` ga qarardi — jo'nab ketgan safar backendда
                // `active` qolgani uchun tugma faol turar, bosilganda backend
                // 409 qaytarar, foydalanuvchi SABABSIZ xato ko'rardi
                // (izohi `Ride.isBookable` da).
                onPressed:
                    _booking ||
                        _ride.availableSeats == 0 ||
                        !_ride.isBookable() ||
                        // Bronlarim noma'lum bo'lsa bron qilmaymiz — dublikat xavfi.
                        _bookingsUnknown
                    ? null
                    : _book,
                child: _booking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_priceToSend != null ? t.sendOffer : t.bookButton),
              ),
            ] else ...[
              InfoBox(
                tone: InfoTone.positive,
                child: Column(
                  children: [
                    Text(t.booked, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      t.bookingStatus(_existingBooking!.status),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // 🔴 Bron tasdiqlangach yo'lovchining keyingi tabiiy ishi —
              // haydovchi bilan gaplashish (qayerdan olib ketasiz, necha
              // daqiqada chiqaman...). Bu ekranda unga yo'l YO'Q edi: odam
              // "Suhbatlar" ga borib, ro'yxatdan haydovchini o'zi topishi
              // kerak edi. Chat faqat TASDIQLANGAN bronda ochiladi
              // (mahsulot qoidasi) — shuning uchun shart ham shu.
              // 🔴 KELISHILGANDAN KEYIN — TELEFON (egasi, 2026-08-16:
              // "kelishuvga erishganlar bir-birining nomerini
              // topolmayapti"). Uchrashish joyini aniqlashda chat har
              // doim ham yetarli emas: internet bo'lmasligi, odam
              // ilovani ochmasligi mumkin.
              //
              // Raqam FAQAT tasdiqlangan bronda ko'rinadi — tasdiqdan
              // oldin ko'rsatilsa har qanday odam e'lon egasining
              // raqamini yig'ib olishi mumkin bo'lardi.
              if (_existingBooking!.isConfirmed) ...[
                const SizedBox(height: AppSpace.md),
                ContactRow(
                  phone: _ride.driver?.phone,
                  label: t.contactSection,
                  callLabel: t.callButton,
                  emptyHint: t.phoneNotProvided,
                ),
              ],
              if (_existingBooking!.isConfirmed &&
                  (_ride.driver?.id ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                OutlinedButton.icon(
                  onPressed: () => context.push(
                    Routes.chat,
                    extra: Conversation(
                      rideId: _ride.id,
                      peerId: _ride.driver!.id!,
                      title:
                          '${_ride.originAddress} → ${_ride.destinationAddress}',
                      subtitle: _ride.driver?.name,
                    ),
                  ),
                  icon: const Icon(Icons.forum_outlined),
                  label: Text(t.messageDriver),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Narx taklifi — faqat haydovchi "kelishiladi" deb belgilagan safarda.
  ///
  /// Qadam 5 000 so'm; e'lon narxidan pastga ham, yuqoriga ham siljitish
  /// mumkin (yo'lovchi tezroq olinish uchun ko'proq taklif qilishi ham odatiy).
  Widget _priceOffer(AppStrings t, ThemeData theme) {
    final base = _ride.pricePerSeat;
    final isSame = _offeredPrice == base;

    /*
     * 🔴 «+ / −» TUGMALARI OLIB TASHLANDI (egasi, 2026-08-16: "5 minglik
     * +/- larni olib tashlab saytdagidek narxni yoza oladigan bo'lib
     * chiqsin").
     *
     * Nega qadam yomon edi: 5 000 so'mlik qadam bilan 47 000 ni yozib
     * bo'lmaydi — odam eng yaqin qiymatga rozi bo'lishga majbur edi.
     * Savdolashishning butun ma'nosi esa ANIQ raqamda. Saytda maydon
     * allaqachon shunday.
     */
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: InfoBox(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.handshake, size: 18),
                const SizedBox(width: AppSpace.sm),
                // `Flexible`: «Sizning taklifingiz» uzun tilda
                // maydonni ekrandan surib chiqarardi (audit: 45 px).
                Flexible(
                  child: Text(
                    t.yourOffer,
                    style: theme.textTheme.bodyMedium,
                    // ⚠️ Ikki qator: 320 px da yozuvga 113 px qolardi,
                    // kerak esa 114 — bir piksel yetmagani uchun
                    // «Sizning taklifingi…» bo'lib kesilardi
                    // (o'lchandi 2026-09-04).
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [ThousandsInputFormatter()],
                    textAlign: TextAlign.end,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      suffixText: t.sum,
                    ),
                    onChanged: (value) {
                      // Faqat raqam: odam probel yoki harf yozsa ham
                      // narx buzilmasin.
                      final digits = value.replaceAll(RegExp('[^0-9]'), '');
                      setState(
                        () => _offeredPrice = double.tryParse(digits) ?? 0,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              isSame ? t.agreeWithPrice : t.offerDiffersHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSame
                    ? theme.colorScheme.outline
                    : theme.colorScheme.primary,
              ),
            ),
            if (!isSame)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() {
                    _offeredPrice = base;
                    _priceController.text = formatMoneyInput(base);
                  }),
                  child: Text(t.resetOffer),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Sizning broningiz" — holat rangi bilan.
///
/// Yo'lovchi uchun bu ekrandagi eng muhim ma'lumot: haydovchi qabul qildimi,
/// rad etdimi yoki narx hali kelishilyaptimi.
class _BookingBanner extends StatelessWidget {
  const _BookingBanner({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final tone = StatusTone.forBooking(theme.colorScheme, booking.status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(tone.icon, size: 20, color: tone.fg),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.bookingStatus(booking.status),
                  style: theme.textTheme.titleSmall?.copyWith(color: tone.fg),
                ),
                Text(
                  '${booking.seatsBooked} ${t.seats}',
                  style: theme.textTheme.bodySmall?.copyWith(color: tone.fg),
                ),
              ],
            ),
          ),
          if ((booking.totalPrice ?? booking.offeredPrice) != null)
            Text(
              '${formatPrice(booking.totalPrice ?? booking.offeredPrice!)} ${t.sum}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: tone.fg,
              ),
            ),
        ],
      ),
    );
  }
}

/// Ikonkali bitta qator — endi faqat "olib ketish nuqtasi" uchun ishlatiladi
/// (marshrutning o'zi `JourneyLine` bilan chiziladi).
class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: AppSpace.md),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

/// Bron BOSQICHLARI — "endi nima bo'ladi?" degan savolga javob.
///
/// 🔴 NEGA KERAK: holat bitta nishon edi ("Tasdiqlangan"). Odam uni ko'rib
/// keyingi qadamni BILMASDI: haydovchi qo'ng'iroq qiladimi, safar boshlanishini
/// kim belgilaydi, "tugadi" qachon bo'ladi. Bosqichlar butun yo'lni bir
/// qarashda ko'rsatadi va hozir qayerdaligini belgilaydi.
///
/// Bosqichlar HAQIQIY holatlardan olinadi, o'ylab topilmaydi:
///   so'rov (`pending`) → tasdiq (`confirmed`) → yo'lda (safar `in_progress`)
///   → tugadi (safar `completed`).
///
/// ⚠️ Rad etilgan / kelmagan / bekor qilingan bronda CHIZILMAYDI: u yo'l
/// tugamagan, uzilgan — bosqich chizig'i esa "davom etyapti" degan yolg'on
/// taassurot berardi. Bunday holatda yuqoridagi nishon o'zi yetarli.
class _BookingProgress extends StatelessWidget {
  const _BookingProgress({
    required this.bookingStatus,
    required this.rideStatus,
  });

  final String bookingStatus;
  final String rideStatus;

  /// Hozirgi bosqich (0..3), yoki `null` — chizilmaydi.
  int? get _step {
    if (bookingStatus == 'rejected' ||
        bookingStatus == 'no_show' ||
        rideStatus == RideStatus.cancelled) {
      return null;
    }
    if (rideStatus == RideStatus.completed) return 3;
    if (rideStatus == RideStatus.inProgress) return 2;
    if (bookingStatus == 'confirmed') return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final current = _step;
    if (current == null) return const SizedBox.shrink();

    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final labels = [
      t.stepRequested,
      t.stepConfirmed,
      t.stepOnTheWay,
      t.stepDone,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  color: i <= current
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  i < current
                      ? Icons.check_circle
                      : i == current
                      ? Icons.radio_button_checked
                      : Icons.circle_outlined,
                  size: 18,
                  color: i <= current
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
                const SizedBox(height: AppSpace.xs),
                // Kenglik CHEGARALANGAN: tor telefonda to'rtta yozuv
                // qatorni toshirib yuborardi.
                SizedBox(
                  width: 62,
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: i == current
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: i <= current
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// KUTIB OLISH KARTASI — uchrashuv payti kerak bo'ladigan hamma narsa.
///
/// 🔴 NEGA KERAK: bekatda bir vaqtda bir necha "Farg'onaga" chiqadigan
/// mashina turadi. Yo'lovchi o'zinikini DAVLAT RAQAMIDAN topadi — lekin
/// bizda raqam boshqa ma'lumot orasida, oddiy matn qatorida turardi va
/// ko'zga tashlanmasdi. inDrive/Yandex'da u ekranning yarmini egallaydi,
/// chunki aynan shu payt boshqa hech nima kerak emas.
///
/// Karta FAQAT bron TASDIQLANGANDA chiqadi: tasdiqlanmagan bronda uchrashuv
/// hali yo'q va bu ma'lumot faqat ekranni to'ldirardi.
///
/// ⚠️ Mashina FOTOSI ATAYIN yo'q: backend media 404 beradi (xat
/// 2026-08-20), ya'ni rasm baribir ochilmaydi. Bo'sh joy qoldirgandan
/// ko'ra umuman ko'rsatmagan yaxshi.
class _PickupCard extends StatefulWidget {
  const _PickupCard({
    required this.car,
    required this.pickupPoint,
    required this.lat,
    required this.lon,
  });

  /// Mashina — ekranda ALLAQACHON hal qilingan (`ride.car`, bo'lmasa
  /// `vehicleByIdProvider`). Bu yerda qayta so'ramaymiz: `ride.car` ko'pincha
  /// bo'sh keladi va karta jimgina yo'qolib qolardi.
  final RideVehicle? car;
  final String? pickupPoint;

  /// Jo'nash nuqtasi — navigator va "sizdan qancha uzoq" uchun.
  final double lat;
  final double lon;

  @override
  State<_PickupCard> createState() => _PickupCardState();
}

class _PickupCardState extends State<_PickupCard> {
  /// Uchrashuv nuqtasigacha masofa (km) — foydalanuvchi joylashuvidan.
  ///
  /// 🔴 Ruxsat SO'RALMAYDI: bu qo'shimcha ma'lumot, uning uchun tizim
  /// oynasini chiqarish haddan tashqari. Ruxsat allaqachon berilgan
  /// bo'lsa (xaritadan joy tanlaganda so'ralgan) — ko'rsatamiz, aks
  /// holda qator umuman chizilmaydi.
  double? _distanceKm;

  @override
  void initState() {
    super.initState();
    _measure();
  }

  Future<void> _measure() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      setState(() {
        _distanceKm = distanceKm(
          fromLat: position.latitude,
          fromLon: position.longitude,
          toLat: widget.lat,
          toLon: widget.lon,
        );
      });
    } catch (_) {
      // Joylashuv olinmadi — masofa shunchaki ko'rsatilmaydi.
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final car = widget.car;
    final plate = (car?.plate ?? '').trim();
    final title = (car?.title ?? '').trim();
    final pickup = widget.pickupPoint?.trim() ?? '';

    // Hech qanday ma'lumot bo'lmasa karta CHIZILMAYDI: bo'sh ramka
    // "ilova buzuq" degandek ko'rinadi.
    if (plate.isEmpty && title.isEmpty && pickup.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.pickupTitle.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: theme.colorScheme.onPrimaryContainer.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
            if (plate.isNotEmpty) ...[
              const SizedBox(height: AppSpace.sm),
              // Raqam KATTA va BELGILANADIGAN: odam uni uzoqdan o'qiydi
              // yoki nusxalab yaqiniga yuboradi.
              SelectableText(
                plate.toUpperCase(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
            if (title.isNotEmpty)
              Text(
                [
                  title,
                  if ((car?.color ?? '').isNotEmpty) car!.color!,
                ].join(' · '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            if (pickup.isNotEmpty) ...[
              const SizedBox(height: AppSpace.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.my_location,
                    size: 18,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      pickup,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // "Sizdan qancha uzoq" — joylashuv ruxsati bo'lsa.
            if (_distanceKm != null) ...[
              const SizedBox(height: AppSpace.xs),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Text(
                  t.awayFromYou(formatDistance(_distanceKm!)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.75,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpace.md),
            // NAVIGATOR — odam nuqtani ko'rib emas, YETIB BORISHI kerak.
            // Muayyan ilova emas, `geo:` (izohi `openInMaps` da).
            OutlinedButton.icon(
              onPressed: () async {
                final opened = await openInMaps(
                  lat: widget.lat,
                  lon: widget.lon,
                  label: pickup.isEmpty ? null : pickup,
                );
                if (!opened && context.mounted) {
                  showMessage(context, t.mapsNotOpened);
                }
              },
              icon: const Icon(Icons.directions_outlined, size: 18),
              label: Text(t.openInMaps),
            ),
          ],
        ),
      ),
    );
  }
}
