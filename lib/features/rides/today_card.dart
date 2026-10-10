import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/active_role.dart';
import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../data/models/booking.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';
import 'journey_view.dart';
import 'next_trip.dart';
import 'ride_hero.dart';

/// «BUGUN» — eng yaqin safar kartasi, birinchi ekranning tepasida.
///
/// 🔴 NEGA YOZILDI (2026-08-24 auditi): ilovani ochgan yo'lovchi darhol
/// BO'SH FORMANI ko'rardi. Ertaga safari bor odam ham, bir soatdan keyin
/// jo'naydigan odam ham — hammasi bir xil: shahar tanla, sana tanla, qidir.
/// Ya'ni ilova "men sen haqingda hech nima bilmayman" deb ochilardi.
///
/// Endi birinchi ekran HOLATGA qarab o'zgaradi: yaqin safar bo'lsa — u
/// tepada, qolgan hamma narsadan oldin. Bo'lmasa — karta umuman chizilmaydi
/// va ekran avvalgidek qidiruv formasi bo'lib qoladi.
///
/// QOIDA: bu karta MA'LUMOT bermasa — ko'rinmaydi. "Safaringiz yo'q" degan
/// bo'sh quti qo'yilmaydi: u har kuni ekran tepasidan joy yeb turadi va
/// hech qachon foydali bo'lmaydi.
///
/// Rol bo'yicha manba boshqa, ko'rinish bir xil:
///   • yo'lovchi — o'z broni (`myBookingsProvider`);
///   • haydovchi — o'z e'loni (`myRidesProvider`).
class TodayCard extends ConsumerStatefulWidget {
  const TodayCard({super.key});

  @override
  ConsumerState<TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends ConsumerState<TodayCard> {
  /// «Qancha qoldi» yozuvi jonli bo'lsin.
  ///
  /// 🔴 Busiz karta "3 soatdan keyin" deb ochiladi va ekran ochiq turgan
  /// vaqtda o'sha yozuv qotib qoladi — jo'nash vaqti kelib o'tsa ham.
  /// 30 soniya: daqiqa aniqligidagi yozuv uchun yetarli, batareyaga esa
  /// sezilarli emas.
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  // Tanlov mantig'i `next_trip.dart` da — bosh ekran vidjeti AYNI
  // safarni ko'rsatishi kerak va ikki nusxa bo'lsa ular ertaga
  // ajralib ketardi.

  @override
  Widget build(BuildContext context) {
    final driverMode = ref.watch(isDriverModeProvider);
    final now = DateTime.now();

    // Uzilishda ham, yuklanayotganda ham karta CHIZILMAYDI: bu ekranning
    // asosiy mazmuni emas, qo'shimcha. Skelet qo'ysak — qidiruv formasi
    // har ochilganda pastga sakrardi.
    if (driverMode) {
      final rides = ref.watch(myRidesProvider).valueOrNull;
      if (rides == null) return const SizedBox.shrink();
      final ride = nearestDriverRide(rides, now);
      if (ride == null) return const SizedBox.shrink();
      return _Card(ride: ride, seatsLine: true);
    }

    final bookings = ref.watch(myBookingsProvider).valueOrNull;
    if (bookings == null) return const SizedBox.shrink();
    final booking = nearestPassengerBooking(bookings, now);
    final ride = booking?.ride;
    if (ride == null) return const SizedBox.shrink();
    return _Card(ride: ride, booking: booking);
  }

}

class _Card extends StatelessWidget {
  const _Card({required this.ride, this.booking, this.seatsLine = false});

  final Ride ride;
  final Booking? booking;

  /// Haydovchi ko'rinishi: haydovchi qatori o'rniga BAND O'RINDIQLAR.
  /// O'z e'lonimda o'zimni haydovchi deb tanishtirish ma'nosiz.
  final bool seatsLine;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final departure = ride.departureTime;
    final departed = hasDeparted(departure);
    // Holat bilan — «Kechikmoqda» / «Yo'lda» / oddiy hisob
    // (izohi `departureStatusLabel` da).
    final countdown = departureStatusLabel(departure, ride.status, t.lang);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: PressableScale(
        onTap: () => context.push(Routes.ride, extra: ride),
        child: Card(
          // Bu karta ro'yxatning bir elementi EMAS — ekranning bosh
          // mavzusi. Aksent fon uni qolgan kartalardan ajratadi: odam
          // ekranni ochganda ko'zi shu yerga tushsin.
          color: departed
              ? scheme.surfaceContainerHighest
              : scheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      departed ? Icons.directions_car : Icons.schedule,
                      size: 18,
                      color: scheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Text(
                      t.todayCardTitle.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const Spacer(),
                    if (countdown.isNotEmpty)
                      // Hero: safar ochilganda "qancha qoldi" yozuvi
                      // JOYIDA qoladi — ekranlar bir-biriga ulanadi.
                      RideHero(
                        rideId: ride.id,
                        part: RideHeroPart.countdown,
                        child: Text(
                          countdown,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                RideHero(
                  rideId: ride.id,
                  part: RideHeroPart.journey,
                  child: JourneyLine(
                    origin: ride.originAddress,
                    destination: ride.destinationAddress,
                    originTime: formatTime(departure),
                    compact: true,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Row(
                  children: [
                    Expanded(
                      child: seatsLine
                          ? Text(
                              t.seatsBookedOf(
                                ride.totalSeats - ride.availableSeats,
                                ride.totalSeats,
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onPrimaryContainer,
                              ),
                            )
                          : DriverRow(
                              name: ride.driver?.name,
                              rating: ride.driver?.rating,
                              avatarUrl: ride.driver?.avatar,
                              seed: ride.driver?.id,
                              gender: ride.driver?.gender,
                              inlineRating: true,
                            ),
                    ),
                    if (booking != null)
                      StatusPill(
                        label: t.bookingStatus(booking!.status),
                        tone: StatusTone.forBooking(scheme, booking!.status),
                      ),
                    const SizedBox(width: AppSpace.sm),
                    Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
