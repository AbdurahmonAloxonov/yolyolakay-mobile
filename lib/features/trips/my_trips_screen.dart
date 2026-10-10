import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/active_role.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/format.dart';
import '../../data/models/booking.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';
import '../rating/rate_dialog.dart';
import 'cancel_booking_sheet.dart';
import 'offline_trip_card.dart';
import '../rides/journey_view.dart';
import '../rides/ride_card.dart';
import '../../core/local_cache.dart';
import '../shared/refreshable.dart';
import '../shared/brand/suzani_icons.dart';
import '../shared/cached_note.dart';
import '../shared/state_views.dart';
import '../shared/ui.dart';
import '../shared/notification_bell.dart';
import '../shared/settings_button.dart';
import '../../../app/dimens.dart';
import '../shared/yol_refresh.dart';
import '../shared/skeleton.dart';
import '../shared/brand/brand_panels.dart';

/// Safarlarim.
///
/// ⚠ `GET /rides/my` `role` ga qarab IKKI XIL shakl qaytaradi:
/// `driver` -> safarlar, `passenger` -> bronlar (safar detalisiz).
/// Shu sabab ikki ro'yxat bir xil karta ishlatolmaydi.
///
/// 🔴 ROL BO'YICHA (2026-08-12, egasi qurilmada ko'rdi): ilgari ekran DOIM
/// ikki tabli edi — "Yo'lovchi" va "Haydovchi". Yo'lovchi hech qachon haydovchi
/// bo'lmagan bo'lsa ham ikkinchi tab turardi va u yerda faqat bo'sh ro'yxat
/// ko'rinardi. Ya'ni odamning yarim ekrani unga tegishli bo'lmagan bo'limga
/// ketardi va "bu ilova haydovchilar uchunmi?" degan savol tug'ilardi.
///
/// Endi tab FAQAT haydovchida chiqadi. Yo'lovchida ekran bitta ro'yxat —
/// tabsiz, sarlavhasiz ortiqcha qavatsiz.
class MyTripsScreen extends ConsumerWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final isDriver = ref.watch(meProvider).valueOrNull?.user.isDriver ?? false;

    // 🔴 ROL = MAZMUN (egasi, 2026-08-13: «rolni almashtirsam faqat qidirish
    // va e'lon berish almashyapti, boshqa farq yo'q»).
    //
    // Ilgari bu ekranda IKKI yorliq turardi va rol ularga ta'sir qilmasdi —
    // ya'ni rol almashtirish shunchaki boshlang'ich yorliqni tanlardi.
    // Endi ekran faqat JORIY rolning ishini ko'rsatadi: haydovchi rejimida
    // e'lonlarim va ularga kelgan arizalar, yo'lovchi rejimida esa
    // bronlarim. Ikkinchi tomonga o'tish — sarlavhadagi almashtirgich
    // (bir bosish), saytdagi kabi.
    final driverMode = isDriver && ref.watch(isDriverModeProvider);

    return Scaffold(
      appBar: AppBar(
        bottom: const JiyakLine(),
        title: Text(driverMode ? t.myRidesTitle : t.myTripsTitle),
        actions: [
          // 🔴 DAROMAD ⚙️ OSTIDA QOLIB KETGANDI (2026-09-05 qulaylik
          // auditi): haydovchining PULI ikki qavat chuqurlikda edi —
          // profil → sozlamalar → daromad. Haydovchi eng ko'p
          // qaraydigan raqam eng uzoq joyda turardi.
          //
          // Endi u AYNAN safarlar ro'yxatining ustida: pul safardan
          // keladi, ya'ni savol shu ekranda tug'iladi.
          if (driverMode)
            IconButton(
              tooltip: t.earningsTitle,
              icon: const Icon(Icons.account_balance_wallet_outlined),
              onPressed: () => context.push(Routes.earnings),
            ),
          const NotificationBell(),
          const SettingsButton(),
        ],
      ),
      body: Column(
        children: [
          // Keshdan kelgan ma'lumot JIMGINA ko'rsatilmaydi (izohi
          // `CachedNote` da) — rol bo'yicha manba boshqa.
          CachedNote(
            cacheKey: driverMode ? CacheKeys.myRides : CacheKeys.myBookings,
          ),
          Expanded(
            child: driverMode ? const _DriverRidesTab() : const _BookingsTab(),
          ),
        ],
      ),
      // 🔴 FAB butunlay OLIB TASHLANDI (egasi, 2026-08-13: «rolni
      // almashtirsam qolgan narsalar ko'rinib turibdi»). E'lon berish —
      // HAYDOVCHINING amali va u haydovchi rejimida pastki menyuda
      // ("Yaratish") turadi. Yo'lovchi rejimida u yerda turishi rolni
      // ma'nosiz qilardi: odam yo'lovchi ro'yxatiga qarab turib, ekranning
      // o'rtasida haydovchi tugmasini ko'rardi.
    );
  }
}

/// Faol / Tugagan almashtirgichi.
///
/// 2026-08-07 da qo'shildi: ilgari faol va tugagan safarlar BITTA ro'yxatda
/// aralash turardi va tarix o'sgani sayin bugungi safarni topish qiyinlashardi.
class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.showFinished, required this.onChanged});

  final bool showFinished;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SegmentedButton<bool>(
        segments: [
          ButtonSegment(value: false, label: Text(t.tripsActive)),
          ButtonSegment(value: true, label: Text(t.tripsFinished)),
        ],
        selected: {showFinished},
        showSelectedIcon: false,
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

/// Safar tugaganmi (haydovchi ro'yxati uchun).
bool _rideFinished(Ride ride) =>
    ride.status == RideStatus.completed || ride.status == RideStatus.cancelled;

class _BookingsTab extends ConsumerStatefulWidget {
  const _BookingsTab();

  @override
  ConsumerState<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends ConsumerState<_BookingsTab> {
  bool _showFinished = false;

  /// Bronlar ro'yxatini davriy yangilash taymeri.
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    /*
     * 🔴 EKRAN O'ZI YANGILANMASDI (egasi, 2026-08-16: "agar haydovchi
     * qabul qilsa ham ilova va sayt yangilanmayapti, yo'lovchi o'zi
     * yangilamasa bilmay qoladi").
     *
     * Bron holati SERVERDA o'zgaradi — haydovchi qabul qiladi yoki narx
     * qaytaradi. Bu yerda esa ro'yxat faqat EKRAN OCHILGANDA bir marta
     * yuklanardi va boshqa hech qachon: odam soatlab "Kutilmoqda" ni
     * ko'rib o'tirardi.
     *
     * Backendda bron holati o'zgarishi bo'yicha WS hodisasi YO'Q (xat
     * 2026-08-13), push esa hali yuborilmaydi (Firebase kaliti kutilmoqda)
     * — ya'ni yagona ishonchli yo'l yengil so'rov. 20 soniya: safar
     * tafsiloti ekranidagi bilan bir xil qadam.
     */
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      ref.invalidate(myBookingsProvider);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Bron tugaganmi.
  ///
  /// Bron holatining O'ZI hamma narsani aytmaydi: tasdiqlangan bron safar
  /// yakunlangach ham `confirmed` bo'lib qolaveradi. Shuning uchun safar
  /// holatiga ham qaraymiz — `rideByIdProvider` ni bron KARTASI allaqachon
  /// o'qiydi, ya'ni bu qo'shimcha so'rov TUG'DIRMAYDI (family kesh).
  bool _finished(Booking b) {
    // Rad etilgan/bekor qilingan bron safardan QAT'I NAZAR tugagan.
    if (b.isSettled && !b.isConfirmed) return true;
    final ride = ref.watch(rideByIdProvider(b.rideId)).valueOrNull;
    return ride != null && _rideFinished(ride);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final bookings = ref.watch(myBookingsProvider);

    return bookings.when(
      // 🔴 Tortish yuklanish va xatoda ham — izohi `refreshableState` da.
      loading: () => refreshableState(
        onRefresh: () => ref.refresh(myBookingsProvider.future),
        child: const ListSkeleton(),
      ),
      error: (error, _) => refreshableState(
        onRefresh: () => ref.refresh(myBookingsProvider.future),
        child: ErrorView(
          error: error,
          onRetry: () => ref.refresh(myBookingsProvider.future),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          // Bo'sh ekrandan chiqish yo'li: ilgari bu ekran boshi berk edi —
          // "bron yo'q" deyilardi-yu, qidiruvga o'tish taklif qilinmasdi.
          return EmptyView(
            icon: Icons.event_seat_outlined,
            title: t.noBookings,
            actionLabel: t.searchButton,
            onAction: () => context.go(Routes.search),
          );
        }
        final shown = items
            .where((b) => _finished(b) == _showFinished)
            .toList();
        return Column(
          children: [
            _StatusFilter(
              showFinished: _showFinished,
              onChanged: (v) => setState(() => _showFinished = v),
            ),
            Expanded(
              child: shown.isEmpty
                  ? EmptyView(
                      icon: Icons.event_seat_outlined,
                      title: _showFinished
                          ? t.noFinishedTrips
                          : t.noActiveTrips,
                      // 🔴 BOSHI BERK EDI (2026-09-05): filtr ostida
                      // ro'yxat bo'shab qolsa odam «bronim yo'q» deb
                      // o'ylardi — aslida IKKINCHI filtrda turgan
                      // bo'lishi mumkin edi. Endi yo'l ko'rsatiladi:
                      // tugagan safarlar bo'sh bo'lsa — faoliga qayt,
                      // faoli bo'sh bo'lsa — safar qidir.
                      actionLabel: _showFinished
                          ? t.tripsActive
                          : t.searchButton,
                      onAction: () => _showFinished
                          ? setState(() => _showFinished = false)
                          : context.go(Routes.search),
                    )
                  : YolRefresh(
                      onRefresh: () => ref.refresh(myBookingsProvider.future),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpace.lg),
                        itemCount: shown.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpace.md),
                        itemBuilder: (_, index) =>
                            _BookingCard(booking: shown[index]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _BookingCard extends ConsumerWidget {
  const _BookingCard({required this.booking});

  final Booking booking;

  /// Haydovchini baholash.
  ///
  /// Bron javobida haydovchi ID'si YO'Q — safar detalidan olinadi. U ham
  /// bo'lmasa baholash umuman taklif qilinmaydi (pastdagi `canRate` shart).
  Future<void> _rate(
    BuildContext context,
    WidgetRef ref,
    Ride ride,
    String driverId,
  ) async {
    final t = AppStrings.of(context);
    await showRateDialog(
      context,
      rideId: ride.id,
      revieweeId: driverId,
      revieweeName: ride.driver?.name ?? t.driver,
    );
    ref.invalidate(myBookingsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    /*
     * 🔴 KELISHILGAN narx ustun (egasi, 2026-08-16: "narxni qabul qilsa
     * ham haydovchining belgilagan narxi ko'rsatilyapti").
     *
     * Savdolashish `offered_price` maydonini o'zgartiradi (jonli o'lchov,
     * 2026-08-13). `total_price` ni backend qayta hisoblaydimi — kontraktda
     * yozilmagan, ya'ni unga tayanib bo'lmaydi: u e'lon narxidan
     * hisoblangan eski qiymat bo'lib qolishi mumkin va odam kelishgan
     * narxi o'rniga haydovchining boshlang'ich narxini ko'radi.
     *
     * Shuning uchun taklif bo'lsa — O'SHANDAN hisoblaymiz
     * (`offered_price` BITTA O'RIN uchun), aks holda `total_price`.
     */
    final price = booking.offeredPrice != null
        ? booking.offeredPrice! * booking.seatsBooked
        : booking.totalPrice;

    // Safar detali: bronning ICHIDAGI safar + `GET /rides/{id}`.
    //
    // Holat faqat ikkinchisidan keladi, haydovchi esa bronning o'zida ham bor —
    // shuning uchun BIRLASHTIRAMIZ. Aks holda javobda `driver` kelmasa (jonli
    // kuzatilgan 2026-08-12) ism ham, baholash tugmasi ham yo'qolardi.
    //
    // Ilgari bu so'rov FAQAT tasdiqlangan bronda yuborilardi, ya'ni kutilayotgan
    // bronda marshrut umuman noma'lum edi. Endi bron qaysi holatda bo'lishidan
    // qat'i nazar safar so'raladi: odam nimani bron qilganini ko'rishi kerak.
    final ride =
        ref
            .watch(rideByIdProvider(booking.rideId))
            .valueOrNull
            ?.mergedWith(booking.ride) ??
        booking.ride;

    final driverId = ride?.driver?.id;
    final canRate =
        ride != null &&
        booking.isConfirmed &&
        ride.status == RideStatus.completed &&
        driverId != null &&
        driverId.isNotEmpty &&
        !ref.watch(ratingRepositoryProvider).hasRated(ride.id, driverId);

    /*
     * Haydovchi narxni o'zgartirdimi? (izohi `data/offer_memory.dart` da)
     *
     * 🔴 STATUSGA TAYANMAYMIZ (egasi, 2026-08-16: "haydovchi jo'natyapti,
     * lekin yo'lovchiga kelmayapti").
     *
     * Ilgari shart `status == pending_negotiation` edi. Lekin bron
     * statuslari swaggerda UMUMAN yozilmagan (`type: string`, hech qanday
     * ro'yxat yo'q) — ya'ni backend haydovchi javobidan keyin boshqa
     * qiymat qo'ysa (masalan `counter_offered`), shart bajarilmay qolardi
     * va yo'lovchi HECH NIMA ko'rmasdi. Hech qanday xato ham chiqmasdi.
     *
     * Dalil narxning O'ZIDA: bizniki bilan kelgan narx farq qilsa —
     * demak haydovchi boshqa narx aytdi. Yakunlangan holatlarda esa
     * ko'rsatilmaydi: u yerda narx allaqachon hal bo'lgan.
     */
    final settled = booking.isSettled;
    final driverCountered =
        !settled &&
        (ref
                .watch(offerMemoryProvider)
                .driverChanged(booking.id, booking.offeredPrice) ??
            false);

    /*
     * 🔴 Egasi topdi (2026-08-16): "haydovchi safarni bekor qilsa yo'lovchiga
     * xabar ham kelmaydi, bilmay ishonib qolib ketadi".
     *
     * Sabab shu yerda edi: nishon FAQAT bron holatiga qarardi. Haydovchi
     * safarni bekor qilganda bronning o'zi `confirmed` bo'lib QOLAVERADI —
     * ya'ni yo'lovchi yashil "Tasdiqlangan" yozuvini ko'rib, safar
     * bo'lishiga ishonib yuraverardi.
     *
     * Endi safar bekor qilingan bo'lsa SHU haqiqat ustun turadi.
     */
    final rideCancelled = ride?.status == RideStatus.cancelled;

    /*
     * BEKOR QILISH — endi HAQIQIY (2026-08-27).
     *
     * Ilgari bu yerda mahalliy «so'raldi» bayrog'i turardi
     * (`LocalFlags.cancelRequested`): gateway'da yo'lovchi uchun bekor
     * qilish ruchkasi yo'q edi va biz haydovchiga chat xabari yuborib,
     * bronni «so'raldi» deb belgilardik. Backend
     * `POST /rides/{id}/bookings/{booking_id}/cancel` ni ochgach, bayroq
     * ham, «kutilmoqda» qutisi ham keraksiz bo'ldi — server javobining
     * o'zi yagona haqiqat.
     */
    final canCancel =
        booking.isLive &&
        !rideCancelled &&
        ride != null &&
        ride.status != RideStatus.completed;
    final tone = rideCancelled
        ? StatusTone.forRide(scheme, RideStatus.cancelled)
        : StatusTone.forBooking(scheme, booking.status);
    // Sana: JO'NASH vaqti. Ilgari bron YARATILGAN vaqt ko'rsatilardi — odamga
    // "qachon bron qilgandim" emas, "qachon jo'nayman" kerak.
    final when = ride?.departureTime ?? booking.createdAt;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Karta ilgari BOSILMAS edi: yo'lovchi o'z bronidan safar sahifasiga
        // o'ta olmasdi (marshrut, xarita, haydovchi — hammasi berk edi).
        onTap: ride == null
            ? null
            : () => context.push(Routes.ride, extra: ride),
        // `IntrinsicHeight` SHART: `stretch` bo'lgan Row bolalarga cheksiz
        // balandlik beradi va ro'yxat ichida (ListView — vertikal cheksiz)
        // "BoxConstraints forces an infinite height" bilan yiqiladi. Test shu
        // xatoni birinchi kadrdayoq ushladi.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Chap chekkadagi rangli tasma — holatni O'QIMASDAN ajratish uchun.
              Container(width: 4, color: tone.bg),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              when == null ? '—' : formatDateTime(when, t.lang),
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          StatusPill(
                            tone: tone,
                            label: rideCancelled
                                ? t.rideCancelledTitle
                                : t.bookingStatus(booking.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.lg),

                      // MARSHRUT — bu kartada ILGARI UMUMAN YO'Q EDI. Ro'yxatda
                      // faqat "2 joy", narx va sana turardi, ya'ni qayerga
                      // ketayotganini bilish uchun har bir bronni ochish kerak edi.
                      if (ride != null)
                        JourneyLine(
                          origin: ride.originAddress,
                          destination: ride.destinationAddress,
                          stops: [for (final s in ride.stops) s.address],
                          compact: true,
                        )
                      else
                        // Safar detali kelmadi (embedded yo'q va `GET /rides/{id}`
                        // ham bermadi). Bo'sh joy qoldirmaymiz — sababini aytamiz.
                        Row(
                          children: [
                            Icon(
                              Icons.route_outlined,
                              size: 16,
                              color: scheme.outline,
                            ),
                            const SizedBox(width: AppSpace.sm),
                            Expanded(
                              child: Text(
                                t.routeUnavailable,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.outline,
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: AppSpace.md),
                      Divider(height: 1, color: scheme.outlineVariant),
                      const SizedBox(height: AppSpace.sm),

                      Row(
                        children: [
                          Expanded(
                            child: DriverRow(
                              name: ride?.driver?.name,
                              rating: ride?.driver?.rating,
                              gender: ride?.driver?.gender,
                              avatarUrl: ride?.driver?.avatar,
                              seed: ride?.driver?.id,
                              avatarRadius: 16,
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (price != null)
                                Text(
                                  '${formatPrice(price)} ${t.sum}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.primary,
                                  ),
                                ),
                              Text(
                                '${booking.seatsBooked} ${t.seats}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.outline,
                                ),
                              ),
                              // TO'LOV USULI — ilovada onlayn to'lov yo'q
                              // va bu hech qayerda yozilmagan edi. Bron
                              // tirik bo'lsagina ma'noli.
                              if (price != null && booking.isLive)
                                Text(
                                  t.cashToDriver,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.outline,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      // 🔴 HAYDOVCHI NARXNI QAYTARSA — yo'lovchi buni SHU
                      // YERDA ko'radi (egasi so'radi 2026-08-13: "haydovchi
                      // qaytarib narx jo'natsa yo'lovchini qayeriga kelishini
                      // ko'rish kerak").
                      //
                      // Ilgari narx jimgina o'zgarardi: kartochkada boshqa
                      // raqam paydo bo'lardi, xolos. Jonli o'lchov (2026-08-13)
                      // shuni ham ko'rsatdi: narxni QABUL QILISH yoki RAD
                      // ETISH yo'lovchida umuman yo'q — `accept`/`reject`
                      // faqat haydovchiga ruxsat («unauthorized: you are not
                      // the driver of this ride»). Shuning uchun bu yerda
                      // to'g'ri gap aytiladi: haydovchi tasdiqlashini kuting
                      // yoki unga yozing.
                      // Nishonning o'zi yetarli emas: odam kartani ko'rib
                      // "nega?" deb qolmasin — nima qilish kerakligini
                      // aytamiz.
                      if (rideCancelled) ...[
                        const SizedBox(height: AppSpace.md),
                        InfoBox(
                          tone: InfoTone.danger,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.rideCancelledTitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpace.xs),
                              Text(
                                t.rideCancelledHint,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (driverCountered) ...[
                        const SizedBox(height: AppSpace.md),
                        InfoBox(
                          tone: InfoTone.warning,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.driverCounterTitle(
                                  formatPrice(booking.offeredPrice ?? 0),
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpace.xs),
                              Text(
                                t.driverCounterHint,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],

                      // OFFLINE SAFAR KARTASI — aloqa yo'qolganda kerak
                      // bo'ladigan hammasi (haydovchi raqami, mashina,
                      // uchrashuv joyi). Yangi ma'lumot SO'RALMAYDI —
                      // qo'ldagi safar obyektidan quriladi, ya'ni
                      // internetsiz ham ochiladi (izohi
                      // `OfflineTripCard` da).
                      if (ride != null && booking.isLive) ...[
                        const SizedBox(height: AppSpace.sm),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                OfflineTripCard.show(context, ride: ride),
                            icon: const Icon(
                              Icons.contact_page_outlined,
                              size: 18,
                            ),
                            label: Text(t.offlineCardTitle),
                          ),
                        ),
                      ],

                      if (canCancel) ...[
                        const SizedBox(height: AppSpace.sm),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final done = await showCancelBookingSheet(
                                context,
                                booking: booking,
                              );
                              // Bekor qilingach ro'yxat QAYTA o'qiladi:
                              // bron statusi va bo'shagan o'rindiq faqat
                              // serverdan keladi.
                              if (done) ref.invalidate(myBookingsProvider);
                            },
                            icon: const Icon(
                              Icons.event_busy_outlined,
                              size: 18,
                            ),
                            label: Text(t.cancelBooking),
                          ),
                        ),
                      ],

                      if (canRate) ...[
                        const SizedBox(height: AppSpace.sm),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _rate(context, ref, ride, driverId),
                            icon: const Icon(Icons.star_border, size: 18),
                            label: Text(t.rateDriver),
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
      ),
    );
  }
}

/// Qolgan safar paketi — haydovchi tabining tepasida.
///
/// Paket tugagach e'lon berish to'siladi, lekin buni faqat "E'lon qilish"
/// bosilganda bilish kech: haydovchi butun formani to'ldirib bo'lgan bo'ladi.
/// Shuning uchun qolgan miqdor oldindan ko'rinadi.
class _QuotaBanner extends ConsumerWidget {
  const _QuotaBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final subscription = ref.watch(subscriptionProvider).valueOrNull;

    // Obuna yo'q yoki cheksiz — eslatishga hojat yo'q.
    if (subscription == null || subscription.isUnlimited) {
      return const SizedBox.shrink();
    }

    final left = subscription.ridesLeft ?? 0;
    final isEmpty = left <= 0;

    return Card(
      color: isEmpty
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: Icon(
          isEmpty ? Icons.lock_outline : Icons.confirmation_number_outlined,
          color: isEmpty ? theme.colorScheme.onErrorContainer : null,
        ),
        title: Text(
          isEmpty ? t.paywallTitle : '${t.ridesLeft}: $left',
          style: TextStyle(
            color: isEmpty ? theme.colorScheme.onErrorContainer : null,
          ),
        ),
        subtitle: isEmpty ? Text(t.paywallHint) : null,
        trailing: TextButton(
          onPressed: () => context.push(Routes.tariffs, extra: isEmpty),
          child: Text(t.tariffsTitle),
        ),
      ),
    );
  }
}

class _DriverRidesTab extends ConsumerStatefulWidget {
  const _DriverRidesTab();

  @override
  ConsumerState<_DriverRidesTab> createState() => _DriverRidesTabState();
}

class _DriverRidesTabState extends ConsumerState<_DriverRidesTab> {
  bool _showFinished = false;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final rides = ref.watch(myRidesProvider);

    return rides.when(
      loading: () => refreshableState(
        onRefresh: () => ref.refresh(myRidesProvider.future),
        child: const ListSkeleton(),
      ),
      error: (error, _) => refreshableState(
        onRefresh: () => ref.refresh(myRidesProvider.future),
        child: ErrorView(
          error: error,
          onRetry: () => ref.refresh(myRidesProvider.future),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          // Bo'sh ekran boshi berk bo'lmasin: haydovchining birinchi qadami —
          // e'lon berish. (FAB haydovchi rejimida olib tashlandi, chunki
          // pastki menyuda "Yaratish" bor; lekin bo'sh ekranda yo'l ko'rsatib
          // turish kerak.)
          return EmptyView(
            suzani: SuzaniIcon.car,
            title: t.noTrips,
            actionLabel: t.createRideTitle,
            onAction: () => context.go(Routes.search),
          );
        }
        final shown = items
            .where((r) => _rideFinished(r) == _showFinished)
            .toList();
        return Column(
          children: [
            _StatusFilter(
              showFinished: _showFinished,
              onChanged: (v) => setState(() => _showFinished = v),
            ),
            Expanded(
              child: YolRefresh(
                onRefresh: () async {
                  await Future.wait([
                    ref.refresh(myRidesProvider.future),
                    ref.refresh(subscriptionProvider.future),
                  ]);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  // Birinchi element — qolgan safar paketi (safar emas). Kvota FAQAT
                  // "Faol" bo'limida ko'rsatiladi: tarixda u ma'nosiz.
                  itemCount: shown.length + (_showFinished ? 0 : 1),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpace.md),
                  itemBuilder: (context, index) {
                    if (!_showFinished && index == 0) {
                      return const _QuotaBanner();
                    }
                    final ride = shown[index - (_showFinished ? 0 : 1)];
                    // Haydovchi o'z safarini BOSHQARISH ekranida ochadi (bronlar,
                    // start/complete) — yo'lovchining bron qilish ekranida emas.
                    return RideCard(
                      ride: ride,
                      mine: true,
                      onTap: () => context.push(Routes.driverRide, extra: ride),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
