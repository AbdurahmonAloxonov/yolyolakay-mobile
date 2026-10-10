import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/dimens.dart';
import '../../app/router.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';
import '../rides/journey_view.dart';

/// SUHBAT KONTEKSTI — chat qaysi safar haqida ekani.
///
/// 🔴 NEGA YOZILDI (2026-08-24 auditi): chatda safar haqida faqat BITTA
/// qator bor edi — "Toshkent → Samarqand". Yozishmadagi savollarning
/// ko'pi esa aynan tafsilotga tegishli: "soat nechada?", "narx qancha
/// edi?", "necha joy oldingiz?". Odam javob berish uchun chatdan CHIQIB,
/// safarni topib, qaytib kirishi kerak edi — va qaytganda nima yozmoqchi
/// bo'lganini unutardi.
///
/// QOIDA: yopiq holatda BITTA qator. Chat — xabarlar joyi, kontekst esa
/// kerak bo'lganda ochiladi. Doim ochiq tursa u ekranning uchdan birini
/// yeb, yozishmani pastga surib qo'yardi.
///
/// Safar topilmasa vidjet umuman chizilmaydi (suhbat safarsiz ham bo'ladi —
/// odam bo'yicha chat, izohi `chat-odam-boyicha` xotirasida).
class TripContextCard extends StatefulWidget {
  const TripContextCard({super.key, required this.ride});

  final Ride ride;

  @override
  State<TripContextCard> createState() => _TripContextCardState();
}

class _TripContextCardState extends State<TripContextCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ride = widget.ride;

    // Yopiq qatorning mazmuni — chatda eng ko'p so'raladigan uchta narsa.
    final summary = [
      if (departureStatusLabel(
        ride.departureTime,
        ride.status,
        t.lang,
      ).isNotEmpty)
        departureStatusLabel(ride.departureTime, ride.status, t.lang)
      else if (ride.departureTime != null)
        formatDateTime(ride.departureTime, t.lang),
      '${ride.availableSeats} ${t.seats}',
      '${formatPrice(ride.pricePerSeat)} ${t.sum}',
    ].join('  ·  ');

    return Material(
      color: scheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: AppMotion.on(context)
                        ? const Duration(milliseconds: 180)
                        : Duration.zero,
                    child: Icon(
                      Icons.expand_more,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                0,
                AppSpace.lg,
                AppSpace.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Marshrut — ilovaning boshqa joylaridagi BILAN BIR XIL
                  // chiziq (`JourneyLine`), shu jumladan oraliq shaharlar.
                  JourneyLine(
                    origin: ride.originAddress,
                    destination: ride.destinationAddress,
                    stops: [for (final s in ride.stops) s.address],
                    originTime: formatTime(ride.departureTime),
                    compact: true,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => context.push(Routes.ride, extra: ride),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(t.openRide),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _open
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: AppMotion.on(context)
                ? const Duration(milliseconds: 200)
                : Duration.zero,
          ),
          Divider(height: 1, color: scheme.outlineVariant),
        ],
      ),
    );
  }
}
