import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/home_widget_bridge.dart';
import '../data/models/ride.dart';
import '../features/rides/next_trip.dart';
import '../l10n/strings.dart';
import 'active_role.dart';
import 'providers.dart';

/// Bosh ekran vidjetini ilovadagi ma'lumot bilan tenglashtiradi.
/// Hech narsa chizmaydi.
///
/// 🔴 NEGA ALOHIDA KUZATUVCHI: vidjet ekranga bog'liq bo'lmasligi kerak.
/// Agar uni `TodayCard` ichidan yozsak, vidjet FAQAT bosh ekran ochilganda
/// yangilanardi — odam chatdan chiqib ilovani yopsa, ekranida eski safar
/// qolib ketardi.
///
/// Manba `TodayCard` bilan AYNI (`next_trip.dart`): telefon ekranida
/// bir safar, ilovada boshqasi turishi — eng jimgina yo'qotiladigan
/// ishonch.
///
/// ⚠️ Tarmoqqa O'ZI chiqmaydi: allaqachon yuklangan ro'yxatlarni
/// kuzatadi xolos (izohi `HomeWidgetBridge` da).
class HomeWidgetSync extends ConsumerStatefulWidget {
  const HomeWidgetSync({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<HomeWidgetSync> createState() => _HomeWidgetSyncState();
}

class _HomeWidgetSyncState extends ConsumerState<HomeWidgetSync> {
  @override
  void initState() {
    super.initState();
    /*
     * ⚠️ BIRINCHI YOZUV SHART. `ref.listen` faqat O'ZGARISHDA ishlaydi:
     * ro'yxat keshdan darhol kelsa hech qanday o'zgarish bo'lmaydi va
     * vidjet ilova ochilganda ham eski holicha qolardi.
     *
     * `addPostFrameCallback` — birinchi kadr chizilgandan keyin:
     * `initState` ichida provider o'qish taqiqlanmagan bo'lsa ham,
     * platforma kanali daraxt qurilishi paytida chaqirilmasin.
     */
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publish(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    // `ref.listen` — qayta chizishni QO'ZG'ATMAYDI. `watch` qo'ysak
    // butun ilova daraxti har ro'yxat yangilanganda qayta qurilardi.
    ref.listen(myRidesProvider, (_, _) => _publish(ref));
    ref.listen(myBookingsProvider, (_, _) => _publish(ref));
    ref.listen(isDriverModeProvider, (_, _) => _publish(ref));
    ref.listen(langProvider, (_, _) => _publish(ref));
    return widget.child;
  }

  void _publish(WidgetRef ref) {
    final t = AppStrings(ref.read(langProvider));
    final now = DateTime.now();
    final driverMode = ref.read(isDriverModeProvider);

    Ride? ride;
    String? note;

    if (driverMode) {
      ride = nearestDriverRide(ref.read(myRidesProvider).valueOrNull, now);
      final seats = ride?.availableSeats;
      // Haydovchiga eng kerakli raqam — nechta joy BO'SH qolgani.
      if (seats != null && seats > 0) note = t.seatsLeft(seats);
    } else {
      final booking = nearestPassengerBooking(
        ref.read(myBookingsProvider).valueOrNull,
        now,
      );
      ride = booking?.ride;
      final price = ride?.pricePerSeat;
      if (price != null && price > 0) {
        note = '${formatPrice(price)} ${t.sum}';
      }
    }

    if (ride == null) {
      HomeWidgetBridge.publishEmpty(t.widgetEmpty);
      return;
    }

    final from = ride.originAddress.split(',').first.trim();
    final to = ride.destinationAddress.split(',').first.trim();

    HomeWidgetBridge.publishTrip(
      route: '$from → $to',
      // ⚠️ SANA/VAQT, «2 soatdan keyin» EMAS: vidjet ilova ochilmasa
      // yangilanmaydi va o'zi eskiradigan yozuv YOLG'ON gapirardi
      // (izohi `HomeWidgetBridge` da).
      when: formatDateTime(ride.departureTime, t.lang),
      note: note,
    );
  }
}
