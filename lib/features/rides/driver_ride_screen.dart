import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/analytics.dart';
import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/haptics.dart';
import '../../core/local_flags.dart';
import '../../data/models/booking.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';
import '../map/route_map_sheet.dart';
import '../map/route_preview_map.dart';
import '../rating/rate_dialog.dart';
import '../shared/bottom_action_bar.dart';
import '../shared/state_views.dart';
import '../shared/ui.dart';
import '../safety/sos_sheet.dart';
import '../moderation/report_block_sheet.dart';
import 'driving_mode.dart';
import 'seat_map.dart';
import 'passenger_trust.dart';
import 'trip_checklist.dart';
import 'journey_view.dart';
import '../../app/dimens.dart';
import '../shared/yol_refresh.dart';
import '../shared/hold_to_confirm.dart';
import '../shared/brand/brand_panels.dart';

/// O'z safarini boshqarish (haydovchi): bronlarni qabul/rad qilish va
/// safar hayot siklini yurgizish.
///
/// Bronlar `GET /rides/my?role=driver` javobidagi `bookings[]` dan keladi —
/// alohida "safar bronlari" endpointi gateway'da yo'q, shuning uchun har
/// amaldan keyin butun ro'yxat qayta o'qiladi.
class DriverRideScreen extends ConsumerStatefulWidget {
  const DriverRideScreen({super.key, required this.ride});

  final Ride ride;

  @override
  ConsumerState<DriverRideScreen> createState() => _DriverRideScreenState();
}

class _DriverRideScreenState extends ConsumerState<DriverRideScreen> {
  late Ride _ride = widget.ride;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _syncPing();
  }

  @override
  void dispose() {
    /*
     * 🔴 EKRAN YOPILGANDA PING TO'XTAMAYDI (2026-08-30).
     *
     * Ilgari shu yerda `_ping?.stop()` turardi. Ya'ni haydovchi
     * orqaga bosib ro'yxatga chiqsa yoki chatga o'tsa, kuzatuv
     * o'lardi va yo'lovchi mashinani yo'qotardi. Xizmat endi
     * `livePingProvider` da yashaydi va uni EKRAN emas, SAFAR
     * HOLATI to'xtatadi (`_syncPing`).
     */
    super.dispose();
  }

  /// Safar holatiga qarab ping'ni yoqadi/o'chiradi.
  ///
  /// Faqat `in_progress`: e'lon "faol" bo'lishi safar boshlandi degani
  /// EMAS (u kunlar oldin e'lon qilinishi mumkin), va o'sha paytda GPS
  /// yoqib turish batareyani bekorga yeb qo'yardi.
  void _syncPing() {
    // ⚠️ `AppStrings.of(context)` EMAS: bu metod `initState` dan ham
    // chaqiriladi, `Localizations.localeOf` esa u yerda taqiqlangan
    // (inherited widget'ga bog'lanish). Til providerdan olinadi.
    final t = AppStrings(ref.read(langProvider));
    final shouldRun = _ride.status == RideStatus.inProgress;
    try {
      final ping = ref.read(livePingProvider);
      if (!shouldRun) {
        ping.stop();
        return;
      }
      ping.start(
        notificationTitle: t.livePingTitle,
        notificationText: t.livePingBody,
        notificationChannelName: t.livePingChannel,
      );
    } catch (_) {
      // 🔴 Ping — IXTIYORIY funksiya, ekran undan ustun.
      // Tarmoq qatlami mavjud bo'lmagan muhitda (masalan widget testi)
      // provider'ni o'qish tashlaydi, va usiz butun safar ekrani
      // chizilmay qolardi — haydovchi safarini boshqara olmasdi.
      // Kuzatuvning yo'qligi ekranning yo'qligidan ko'ra arzon.
    }
  }

  Future<void> _refresh() async {
    // `myRides()` endi tarmoq xatosini TASHLAYDI (ilgari bo'sh ro'yxat
    // qaytarardi). Bu yerda ekranni xato bilan almashtirmaymiz: safar
    // ma'lumoti allaqachon qo'limizda va u ko'rinib turishi kerak —
    // yangilanmagani "Qayta urinish" bilan bildiriladi.
    List<Ride> rides;
    try {
      rides = await ref.read(ridesRepositoryProvider).myRides();
    } catch (error) {
      if (mounted) showApiError(context, error, ref.read(langProvider));
      return;
    }
    for (final ride in rides) {
      if (ride.id == _ride.id) {
        if (mounted) {
          setState(() => _ride = ride);
          // Holat o'zgargan bo'lishi mumkin (boshlandi/yakunlandi).
          _syncPing();
        }
        return;
      }
    }
  }

  /// Har amal bir xil ishlaydi: bajarish -> ro'yxatni yangilash -> xabar.
  /// Amalni bajaradi va MUVAFFAQIYATLI bo'ldimi — shuni qaytaradi.
  ///
  /// 🔴 Ilgari `void` edi va xato ICHIDA yutilardi. Natijada chaqiruvchi
  /// (masalan `_activate`) xatodan keyin ham «bajarildi» degan xabar
  /// ko'rsatib turardi: ekranda bir vaqtda xato ham, muvaffaqiyat ham
  /// chiqardi. Endi chaqiruvchi natijaga qaraydi.
  Future<bool> _run(
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      await _refresh();
      ref.invalidate(myRidesProvider);
      if (!mounted) return true;
      if (successMessage != null) showMessage(context, successMessage);
      return true;
    } catch (error) {
      if (!mounted) return false;
      /*
       * PAKET TUGADI — bu yerda ham (e'lon ekranidagi «Faollashtirish»
       * tugmasi). Umumiy xato xabari foydasiz: haydovchi nima qilishini
       * bilmaydi. E'lon berish ekranida bu allaqachon shunday ishlaydi,
       * bu ikkinchi kirish nuqtasi edi va u qolib ketgandi.
       */
      if (ApiException.from(error).isQuotaExceeded) {
        ref
            .read(analyticsProvider)
            .log(
              AnalyticsEvent.paywallShown,
              payload: {'reason': 'quota_exceeded', 'from': 'driver_ride'},
            );
        showMessage(context, AppStrings.of(context).quotaExhaustedPublished);
        context.push(Routes.tariffs, extra: true);
        return false;
      }
      showApiError(context, error, ref.read(langProvider));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Yo'lovchini baholash — safar tugagach.
  ///
  /// Ism bronning o'zidan (`booking.passenger`). Kelmasa — "Yo'lovchi": ID
  /// ko'rsatishning ma'nosi yo'q, odam uni tanimaydi.
  Future<void> _rate(Booking booking) async {
    final t = AppStrings.of(context);
    final name = (booking.passenger?.name ?? '').trim();
    final rated = await showRateDialog(
      context,
      rideId: _ride.id,
      revieweeId: booking.passengerId,
      revieweeName: name.isEmpty ? t.asPassenger : name,
    );
    if (rated && mounted) setState(() {});
  }

  /// Savdolashish: haydovchi o'z narxini kiritadi.
  ///
  /// Boshlang'ich qiymat — yo'lovchi taklifi (bo'lmasa e'lon narxi): odam
  /// noldan yozmasin, taklifni ko'rib turib tuzatsin.
  Future<void> _askCounterPrice(Booking booking) async {
    final t = AppStrings.of(context);
    final controller = TextEditingController(
      text: (booking.offeredPrice ?? _ride.pricePerSeat).round().toString(),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.counterOffer),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.counterOfferHint),
            const SizedBox(height: AppSpace.md),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: t.yourPrice,
                suffixText: t.sum,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.send),
          ),
        ],
      ),
    );

    final price = double.tryParse(controller.text.trim());
    controller.dispose();
    if (confirmed != true || !mounted) return;
    if (price == null || price <= 0) {
      showMessage(context, t.priceRequired);
      return;
    }

    await _run(
      () => ref
          .read(ridesRepositoryProvider)
          .counterOffer(_ride.id, booking.id, price),
      successMessage: t.counterOfferSent,
    );
  }

  /// Bekor qilish — SABAB bilan.
  ///
  /// `cancel(reason:)` parametri repozitoriyada bor edi, lekin hech qachon
  /// uzatilmasdi (o'lik parametr). Sabab yo'lovchiga ko'rsatiladi va nizolarda
  /// asos bo'ladi, shuning uchun so'raymiz — lekin MAJBURIY emas: shoshilinch
  /// holatda bekor qilishni matn yozish to'sib qo'ymasligi kerak.
  Future<void> _confirmCancel() async {
    final t = AppStrings.of(context);
    final reason = TextEditingController();
    final started = _ride.status == RideStatus.inProgress;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.cancelRideConfirm),
            // Boshlangan safarni bekor qilish og'irroq — ogohlantiramiz.
            if (started) ...[
              const SizedBox(height: AppSpace.sm),
              Text(
                t.cancelInProgressWarning,
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpace.lg),
            TextField(
              controller: reason,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: t.cancelReasonLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            // Bosib USHLAB tasdiqlash — safarni bekor qilish qaytmaydi
            // (yo'lovchilar xabar oladi), tasodifan bosilmasin.
            HoldToConfirm(
              label: t.cancelRide,
              icon: Icons.cancel_outlined,
              onConfirmed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.close),
          ),
        ],
      ),
    );

    final text = reason.text.trim();
    reason.dispose();
    if (confirmed != true) return;
    await _run(
      () => ref
          .read(ridesRepositoryProvider)
          .cancel(_ride.id, reason: text.isEmpty ? null : text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    // KUTAYOTGANLAR TEPADA. Ilgari bronlar backend bergan tartibda turardi va
    // javob kutayotgan ariza o'nta tasdiqlangan bronning ostida qolib ketishi
    // mumkin edi — haydovchi uchun esa aynan o'sha yagona bajariladigan ish.
    final bookings = [..._ride.bookings]
      ..sort((a, b) {
        int rank(Booking x) => x.isPending ? 0 : (x.isConfirmed ? 1 : 2);
        return rank(a).compareTo(rank(b));
      });
    final pending = bookings.where((b) => b.isPending).length;
    final confirmed = bookings.where((b) => b.isConfirmed).toList();
    // Tasdiqlangan bronlardan tushadigan pul: haydovchi uchun bu safarning
    // asosiy raqami, lekin ekranda hech qayerda yo'q edi — u har bir bronni
    // ko'z bilan qo'shishi kerak edi.
    double amountOf(Booking b) =>
        b.totalPrice ?? (_ride.pricePerSeat * b.seatsBooked);
    final earning = confirmed.fold<double>(0, (sum, b) => sum + amountOf(b));

    /*
     * KASSA — kimdan olindi, qancha qoldi (egasi tanlagan band, 2026-08-25).
     *
     * 🔴 Ilovada onlayn to'lov YO'Q: pul naqd, yo'lda, qo'ldan qo'lga.
     * Ekranда faqat «kutilayotgan summa» turardi — haydovchi esa 4
     * yo'lovchidan kimdan olganini BOSHIDA saqlashi kerak edi. Bu eng
     * ko'p adashiladigan joy va u har safar takrorlanadi.
     *
     * Belgi mahalliy (`core/local_flags.dart`): backendда yozadigan joy
     * yo'q, pulni ham shu bitta odam yig'adi — ya'ni bitta qurilma yetadi.
     * Ekranda buni AYTAMIZ.
     */
    final flags = ref.watch(localFlagsProvider);
    final collected = confirmed
        .where((b) => flags.has(LocalFlags.bookingPaid(b.id)))
        .fold<double>(0, (sum, b) => sum + amountOf(b));

    return Scaffold(
      appBar: AppBar(
        bottom: const JiyakLine(),
        title: Text(t.myRideTitle),
        actions: [
          // SOS haydovchida ham — yo'lda xavf ikkala tomon uchun bir xil.
          IconButton(
            icon: Icon(
              Icons.emergency_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: t.sosTitle,
            onPressed: () => SosSheet.show(context),
          ),
        ],
      ),
      body: YolRefresh(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            // SARLAVHA: safar + holat + pul.
            //
            // Ilgari bu yerda yo'lovchiga mo'ljallangan `RideCard` turardi —
            // u ichida HAYDOVCHI ismini ko'rsatadi, ya'ni haydovchi o'z ismini
            // o'ziga ko'rsatib turardi. Holat esa AppBar burchagida kulrang
            // chip edi.
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatDateTime(_ride.departureTime, t.lang),
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        StatusPill(
                          tone: StatusTone.forRide(
                            theme.colorScheme,
                            _ride.status,
                          ),
                          label: t.rideStatus(_ride.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.lg),
                    JourneyLine(
                      origin: _ride.originAddress,
                      destination: _ride.destinationAddress,
                      stops: [for (final s in _ride.stops) s.address],
                    ),
                    const SizedBox(height: AppSpace.md),
                    Divider(height: 1, color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: AppSpace.sm),
                    // O'RINDIQ SXEMASI — haydovchida ilgari `2/4` kasr
                    // turardi. Haydovchi o'z safariga qarab «yana necha
                    // kishi sig'adi» ni bilishi kerak, kasrni bo'lish
                    // emas. Izohi `SeatMap` da.
                    SeatMap(
                      totalSeats: _ride.totalSeats,
                      availableSeats: _ride.availableSeats,
                      maxTwoBack: _ride.maxTwoBack,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.sell_outlined,
                          size: 15,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Text(
                          '${formatPrice(_ride.pricePerSeat)} ${t.sum}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const Spacer(),
                        // 🔴 "Xaritada ko'rish" ilgari SHU QATORDA edi va tor
                        // ekranda (400 px) qator 180 piksel chiqib ketardi —
                        // qurilmada bu sariq-qora chiziqli "overflow" bo'lardi.
                        // Endi tugma faqat ikonka, matni tooltipda.
                        // ⚠️ Ikonka 20 px qoladi, MAYDONI 48 px bo'ladi
                        // (o'lchandi 2026-09-04: 40 px edi). `constraints`
                        // bo'sh qoldirilsa tugma ikonka o'lchamiga
                        // qisqaradi — aynan shu bo'lgandi.
                        IconButton(
                          onPressed: () => showRouteMapSheet(context, _ride),
                          icon: const Icon(Icons.map_outlined, size: 20),
                          tooltip: t.showOnMap,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                        ),
                      ],
                    ),

                    /*
                     * XARITA TUGMA ORTIDA EMAS — 16.09.2026.
                     *
                     * 🔴 Haydovchi uchun bu yanada muhim: u yo'lni
                     * BOSHQARADI va oraliq bekatlar qayerda ekanini
                     * ko'rishi kerak. Ilgari bu faqat kichik ikonka
                     * ortida edi (ikonka qoldi — u to'liq xaritani
                     * ochadi va jonli nuqta o'sha yerda).
                     */
                    const SizedBox(height: AppSpace.md),
                    RoutePreviewMap(
                      waypoints: [
                        LatLng(_ride.originLat, _ride.originLon),
                        for (final stop in _ride.stops)
                          LatLng(stop.lat, stop.lon),
                        LatLng(_ride.destinationLat, _ride.destinationLon),
                      ],
                      height: 140,
                      label: t.showOnMap,
                      originName: _ride.originAddress,
                      destinationName: _ride.destinationAddress,
                      onTap: () => showRouteMapSheet(context, _ride),
                    ),
                  ],
                ),
              ),
            ),

            // PUL — tasdiqlangan bronlar bo'yicha.
            if (confirmed.isNotEmpty) ...[
              const SizedBox(height: AppSpace.md),
              InfoBox(
                tone: InfoTone.positive,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.md,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 20,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        '${t.confirmedLabel}: ${confirmed.length}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${formatPrice(earning)} ${t.sum}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                        // Kassa qatori FAQAT pul yig'ila boshlagach
                        // chiziladi: hech kim to'lamagan bo'lsa «0 / 300 000»
                        // hech nima qo'shmaydi, faqat shovqin qiladi.
                        if (collected > 0)
                          Text(
                            t.cashLeft(
                              '${formatPrice(earning - collected)} ${t.sum}',
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            /*
             * SAFAR OLDI RO'YXATI — haydovchi varianti (yoqilg'i,
             * zapaska, qaytim uchun maydalik). Tugagan safarda
             * ko'rsatilmaydi.
             *
             * 🔴 «BRONLAR» BO'LIMIDAN YUQORIGA KO'CHIRILDI (2026-09-02
             * ko'rigi). Ilgari u sarlavha bilan uning O'Z mazmuni
             * orasida turardi va ekranda shunday o'qilardi:
             *
             *     Bronlar 0
             *     [safar oldi ro'yxati]
             *     Hali bron yo'q
             *
             * Ya'ni bo'sh holat o'z sarlavhasidan ajralib qolib, ro'yxat
             * esa bronlarning bir qismidek ko'rinardi. Endi u safar
             * kartasidan keyin, bronlardan OLDIN turadi — u safarga
             * tegishli, bronlarga emas.
             */
            if (_ride.status != RideStatus.completed &&
                _ride.status != RideStatus.cancelled) ...[
              const SizedBox(height: AppSpace.md),
              TripChecklist(rideId: _ride.id, forDriver: true),
            ],

            const SizedBox(height: AppSpace.xl),
            Row(
              children: [
                Text(t.bookingsTitle, style: theme.textTheme.titleMedium),
                const SizedBox(width: AppSpace.sm),
                Text(
                  '${bookings.length}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const Spacer(),
                // Javob kutayotganlar soni — ish bormi yo'qmi, shundan ko'rinadi.
                // `Flexible`: uzun tarjimada (ruscha "ждут ответа") qator tor
                // ekranda chiqib ketardi.
                if (pending > 0)
                  Flexible(
                    child: StatusPill(
                      tone: StatusTone.forBooking(theme.colorScheme, 'pending'),
                      label: '$pending ${t.awaitingAnswer}',
                    ),
                  ),
              ],
            ),

            /*
             * SO'ROVLAR BO'SH JOYDAN KO'P — bu XATO EMAS, TANLOV.
             *
             * 🔴 Egasi 30.08.2026 da bron modelini tanladi: o'rin FAQAT
             * haydovchi «Qabul» bosgandan keyin band bo'ladi. Ya'ni
             * bitta o'ringa bir nechta odam so'rov yuborishi MUMKIN va
             * kimni olishni haydovchi hal qiladi.
             *
             * Busiz bu holat nosozlikka o'xshaydi: «4 o'rinlik safarimga
             * 7 ta so'rov tushdi, nima bo'lyapti?». Va oxirgi o'rin
             * ketgach «Qabul» server xatosi bilan yiqiladi — sababini
             * OLDINDAN aytmasak, odam tugmani ayblaydi.
             *
             * Raqamlar shu yerda, tugmalarning ustida turadi.
             */
            if (pending > 0) ...[
              const SizedBox(height: AppSpace.sm),
              _SeatBalance(pending: pending, free: _ride.availableSeats),
            ],

            const SizedBox(height: AppSpace.md),
            if (bookings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
                child: Text(
                  t.noBookingsYet,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              )
            else
              for (final booking in bookings) ...[
                _BookingTile(
                  booking: booking,
                  busy: _busy,
                  rideStatus: _ride.status,
                  onAccept: () => _run(
                    () => ref
                        .read(ridesRepositoryProvider)
                        .acceptBooking(_ride.id, booking.id),
                  ),
                  onReject: () => _run(
                    () => ref
                        .read(ridesRepositoryProvider)
                        .rejectBooking(_ride.id, booking.id),
                  ),
                  onNoShow: () => _run(
                    () => ref
                        .read(ridesRepositoryProvider)
                        .markNoShow(_ride.id, booking.id),
                  ),
                  onRate: () => _rate(booking),
                  onCounter: () => _askCounterPrice(booking),
                ),
                const SizedBox(height: AppSpace.sm),
              ],
          ],
        ),
      ),
      // Panel ro'yxatdan CHIZIQ bilan ajraladi — aks holda tugmalar
      // suriladigan mazmunga yopishib qoladi (izohi `BottomActionBar` da).
      bottomNavigationBar: BottomActionBar(child: _actions(t)),
    );
  }

  Widget _actions(AppStrings t) {
    // 🔴 2026-08-07 TUZATILDI: `draft` uchun hech qanday tugma yo'q edi va safar
    // BOSHI BERK KO'CHAGA tushardi. `POST /rides/` draft yaratadi; `activate`
    // qilinmasa safar qidiruvda UMUMAN ko'rinmaydi. `createAndActivate` avtomatik
    // urinadi, lekin yiqilsa (tarmoq, 502) haydovchida uni chiqarish yo'li
    // qolmasdi — e'lon abadiy ko'rinmas bo'lib qolardi va paketdan bitta safar
    // behuda ketardi. `activate()` metodi repozitoriyada bor edi, lekin UI'dan
    // hech qayerdan chaqirilmasdi.
    if (_ride.status == RideStatus.draft) {
      return Column(
        // 🔴 `mainAxisSize.min` SHART. Standart qiymat (`max`) bilan bu ustun
        // `bottomNavigationBar` uyasida BUTUN EKRAN balandligini egallab
        // olardi: tanaga (bronlar ro'yxati, marshrut, pul) joy qolmasdi va
        // ekran bo'm-bo'sh ko'rinardi — tugmalar esa sarlavha ustiga chiqib
        // ketardi. Egasi qurilmada aynan shu holatni ko'rsatdi (2026-08-13);
        // xato faqat FAOLLASHMAGAN safarda chiqadi, chunki boshqa holatlarda
        // bu yerda `Row` qaytariladi.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.activateHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          // 🔴 Ilgari ikkala tugma BITTA QATORDA edi va 360px ekranda
          // ikkalasining ham yozuvi ikki qatorga bo'linardi
          // ("Safarni bekor / qilish"). Endi asosiy amal tepada, butun enda;
          // bekor qilish — pastda, kamroq urg'u bilan. Bu tartib
          // "safar boshlandi" holatida allaqachon ishlatilgan edi.
          FilledButton(
            onPressed: _busy ? null : _activate,
            child: Text(t.activateRide),
          ),
          const SizedBox(height: AppSpace.sm),
          TextButton(
            onPressed: _busy ? null : _confirmCancel,
            child: Text(
              t.cancelRide,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      );
    }

    if (_ride.status == RideStatus.active) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(
                    () => ref.read(ridesRepositoryProvider).start(_ride.id),
                  ),
            child: Text(t.startRide),
          ),
          const SizedBox(height: AppSpace.sm),
          TextButton(
            onPressed: _busy ? null : _confirmCancel,
            child: Text(
              t.cancelRide,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      );
    }

    if (_ride.status == RideStatus.inProgress) {
      // Boshlangan safarni ham bekor qilish kerak (avariya, nosozlik). Ilgari
      // faqat "Yakunlash" bor edi va yo'lda muammo bo'lsa chiqish yo'li yo'q edi.
      // Bekor qilish kamroq urg'u bilan — asosiy amal baribir yakunlash.
      return Column(
        // 🔴 `mainAxisSize.min` SHART — `bottomNavigationBar` uyasidagi
        // ustun aks holda BUTUN EKRAN balandligini egallaydi va tana
        // bo'm-bo'sh qoladi. Aynan shu xato "faollashmagan safar"da
        // qurilmada ko'rilgan edi (2026-08-13); bu yerda ham xuddi shunday
        // edi, faqat "safar boshlangan" holatida chiqardi.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // «YO'LDA» — ruldan qaraydigan soddalashtirilgan ekran
          // (izohi `DrivingModeSheet` da). Asosiy tugmadan TEPADA:
          // safar boshlangach eng ko'p kerak bo'ladigan narsa shu.
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () => DrivingModeSheet.show(
                    context,
                    ride: _ride,
                    onComplete: () => _run(
                      () =>
                          ref.read(ridesRepositoryProvider).complete(_ride.id),
                    ),
                  ),
            icon: const Icon(Icons.explore_outlined),
            label: Text(t.drivingMode),
          ),
          const SizedBox(height: AppSpace.sm),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () => _run(
                    () => ref.read(ridesRepositoryProvider).complete(_ride.id),
                  ),
            child: Text(t.completeRide),
          ),
          const SizedBox(height: AppSpace.sm),
          TextButton(
            onPressed: _busy ? null : _confirmCancel,
            child: Text(
              t.cancelRide,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      );
    }

    // TUGAGAN safar — "amal kerak emas" degan edik, lekin aynan shu payt
    // eng qulay: haydovchi hozirgina yetib keldi va ertaga qaytadi.
    //
    // 🔴 NEGA KERAK: qaytish uchun butun formani BOSHIDAN to'ldirish kerak
    // edi (shaharlar, sana, narx, oltita belgi, mashina). Amalda ko'pchilik
    // shunchaki e'lon qilmaydi — mashina bo'sh qaytadi, yo'lovchi esa
    // "orqaga safar yo'q" deb ko'radi. Bu bitta bosish.
    if (_ride.status == RideStatus.completed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.tonalIcon(
            onPressed: () => context.push(Routes.createRide, extra: _ride),
            icon: const Icon(Icons.swap_vert),
            label: Text(t.publishReturnRide),
          ),
          const SizedBox(height: AppSpace.sm),
          // TAKRORLASH — qaytish safaridan BOSHQA ehtiyoj: ko'p haydovchi
          // har kuni AYNAN bir xil yo'nalishda yuradi.
          OutlinedButton.icon(
            onPressed: () =>
                context.push(Routes.createRide, extra: {'repeat': _ride}),
            icon: const Icon(Icons.repeat),
            label: Text(t.repeatRide),
          ),
        ],
      );
    }

    // cancelled — amal kerak emas.
    return const SizedBox.shrink();
  }

  Future<void> _activate() async {
    final t = AppStrings.of(context);
    final ok = await _run(
      () => ref.read(ridesRepositoryProvider).activate(_ride.id),
    );
    // Faqat ROSTDAN faollashgan bo'lsa xabar beramiz.
    if (ok && mounted) showMessage(context, t.activated);
  }
}

class _BookingTile extends ConsumerWidget {
  const _BookingTile({
    required this.booking,
    required this.busy,
    required this.rideStatus,
    required this.onAccept,
    required this.onReject,
    required this.onNoShow,
    required this.onRate,
    required this.onCounter,
  });

  final Booking booking;
  final bool busy;
  final String rideStatus;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onNoShow;
  final VoidCallback onRate;

  /// O'z narxini qaytarish (savdolashish).
  final VoidCallback onCounter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    // Kelmadi — faqat tasdiqlangan bronda va safar boshlangach mantiqiy.
    final canMarkNoShow =
        booking.isConfirmed &&
        (rideStatus == RideStatus.inProgress ||
            rideStatus == RideStatus.completed);

    // Baho — faqat TUGAGAN safarda, kelgan yo'lovchiga va bir marta.
    final canRate =
        booking.isConfirmed &&
        rideStatus == RideStatus.completed &&
        !ref
            .watch(ratingRepositoryProvider)
            .hasRated(booking.rideId, booking.passengerId);

    final tone = StatusTone.forBooking(theme.colorScheme, booking.status);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Holat tasmasi — yo'lovchi ro'yxatidagi kartalar bilan bir xil til.
            Container(width: 4, color: tone.bg),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // 🔴 KIM bron qilgani ko'rinmasdi: sarlavha "2 joy" edi
                        // va odamning ismi ham, reytingi ham yo'q edi. Haydovchi
                        // esa aynan shunga qarab qabul qiladi yoki rad etadi.
                        // Ma'lumot javobda bor edi, model uni o'qimasdi.
                        Expanded(
                          child: DriverRow(
                            name: booking.passenger?.name,
                            rating: booking.passenger?.rating,
                            gender: booking.passenger?.gender,
                            avatarUrl: booking.passenger?.avatar,
                            seed: booking.passenger?.id,
                            avatarRadius: 16,
                            inlineRating: true,
                          ),
                        ),
                        // Haydovchi ham yo'lovchi ustidan shikoyat qila olishi
                        // kerak (bezorilik, kelmaslik). Ilgari bu FAQAT chatdan
                        // mumkin edi.
                        if (booking.passengerId.isNotEmpty)
                          ReportBlockMenu(
                            targetUserId: booking.passengerId,
                            targetName: booking.passenger?.name,
                            rideId: booking.rideId,
                          ),
                      ],
                    ),
                    // KIMNI OLAYAPMAN — ism va reytingdan keyin darhol.
                    // Yangi akkauntda reyting yo'q, ya'ni usiz kartada
                    // odam haqida aytadigan hech narsa qolmasdi.
                    PassengerTrust(
                      userId: booking.passengerId,
                      profile: booking.passenger,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    // Holat, joy va narx — IKKINCHI qatorda.
                    //
                    // 🔴 Holat belgisi ilgari ism bilan bir qatorda edi va tor
                    // ekranda (400 px) qator chiqib ketardi: ism + reyting +
                    // "Tasdiqlangan" + shikoyat menyusi bir qatorga sig'maydi.
                    Row(
                      children: [
                        Flexible(
                          child: StatusPill(
                            tone: tone,
                            label: t.bookingStatus(booking.status),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Icon(
                          Icons.event_seat_outlined,
                          size: 15,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Text(
                          booking.isFullCarBuyout
                              ? '${booking.seatsBooked} ${t.seats}'
                              : '${booking.seatsBooked} ${t.seats}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        // Taklif qilingan narx — savdolashishda hal qiluvchi
                        // raqam, shuning uchun urg'uli.
                        if (booking.offeredPrice != null)
                          Flexible(
                            child: Text(
                              '${formatPrice(booking.offeredPrice!)} ${t.sum}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // 🔴 KELISHILGANDAN KEYIN — YO'LOVCHINING RAQAMI
                    // (egasi, 2026-08-16). Haydovchi olib ketishdan oldin
                    // "qayerdan olay" deb bog'lanishi kerak; chat bunga
                    // har doim ham yetmaydi. Tasdiqlanmagan bronda raqam
                    // KO'RSATILMAYDI — aks holda arizani rad etib ham
                    // raqamni yig'ib olish mumkin bo'lardi.
                    if (booking.isConfirmed) ...[
                      const SizedBox(height: AppSpace.sm),
                      ContactRow(
                        phone: booking.passenger?.phone,
                        label: t.contactSection,
                        callLabel: t.callButton,
                        emptyHint: t.phoneNotProvided,
                      ),

                      // KASSA — «bu odam to'ladimi?» degan savol yo'lda
                      // 4 marta takrorlanadi va boshda saqlanmaydi.
                      // Belgi mahalliy (`core/local_flags.dart`) — buni
                      // izohda OCHIQ aytamiz.
                      _PaidSwitch(bookingId: booking.id),
                    ],
                    if (booking.isPending) ...[
                      const SizedBox(height: AppSpace.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: busy ? null : onReject,
                              child: Text(t.reject),
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: FilledButton(
                              onPressed: busy ? null : onAccept,
                              child: Text(t.accept),
                            ),
                          ),
                        ],
                      ),
                      // UCHINCHI YO'L: o'z narxini qaytarish.
                      //
                      // Busiz bu savdolashish emas, "ha yoki yo'q" edi:
                      // yo'lovchi past narx taklif qilsa, haydovchi faqat rad
                      // etishi mumkin edi va oraliq narxni hech qayerda qayd
                      // eta olmasdi. Saytda bu funksiya ancha oldin yozilgan,
                      // ilovada UMUMAN yo'q edi.
                      const SizedBox(height: AppSpace.xs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: busy ? null : onCounter,
                          icon: const Icon(Icons.handshake, size: 18),
                          label: Text(t.counterOffer),
                        ),
                      ),
                    ],
                    if (canMarkNoShow) ...[
                      const SizedBox(height: AppSpace.xs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: busy ? null : onNoShow,
                          child: Text(t.noShow),
                        ),
                      ),
                    ],
                    if (canRate) ...[
                      const SizedBox(height: AppSpace.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : onRate,
                          icon: const Icon(Icons.star_border, size: 18),
                          label: Text(t.ratePassenger),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «To'ladi» belgisi — haydovchining kassasi.
///
/// 🔴 NEGA ALOHIDA VIDJET: belgi `SharedPreferences` da yashaydi va uni
/// bosganda FAQAT shu qator qayta chizilishi kerak. Butun ekranni qayta
/// qurish safar ro'yxatini, xaritani va bronlarni ham qayta chizardi.
class _PaidSwitch extends ConsumerStatefulWidget {
  const _PaidSwitch({required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<_PaidSwitch> createState() => _PaidSwitchState();
}

class _PaidSwitchState extends ConsumerState<_PaidSwitch> {
  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final flags = ref.watch(localFlagsProvider);
    final key = LocalFlags.bookingPaid(widget.bookingId);
    final paid = flags.has(key);

    return Row(
      children: [
        Icon(
          paid ? Icons.check_circle : Icons.payments_outlined,
          size: 18,
          color: paid ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(
            paid ? t.cashLocalHint : t.cashTitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
        Switch(
          value: paid,
          onChanged: (next) async {
            AppHaptics.select();
            if (next) {
              await flags.set(key);
            } else {
              await flags.clear(key);
            }
            if (mounted) setState(() {});
          },
        ),
        Text(t.cashMarkPaid, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// «7 so'rov · 4 o'rin bo'sh» — haydovchi tanlashdan OLDIN ko'radigan
/// yagona muhim raqam.
///
/// So'rov joydan ko'p bo'lsa ohang o'zgaradi: bu ogohlantirish emas,
/// TUSHUNTIRISH. Shuning uchun rang xato rangi emas.
class _SeatBalance extends StatelessWidget {
  const _SeatBalance({required this.pending, required this.free});

  final int pending;
  final int free;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final tight = pending > free;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tight ? Icons.how_to_reg_outlined : Icons.event_seat_outlined,
            size: 16,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.seatBalance(pending, free),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (tight) ...[
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    t.seatBalanceHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
