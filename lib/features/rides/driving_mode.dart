import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/dimens.dart';
import '../../core/format.dart';
import '../../core/haptics.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';
import '../map/route_map_sheet.dart';
import '../shared/hold_to_confirm.dart';

/// «YO'LDA» REJIMI — haydovchi RULDA turib qaraydigan ekran.
///
/// 🔴 NEGA (2026-08-25 auditi): safar boshlangach haydovchi ekranida
/// o'nlab element bo'ladi — yo'lovchilar ro'yxati, belgilar, narx,
/// sozlamalar. Ruldan ko'z uzib qaraydigan odamga esa UCHTASI kerak:
/// qayerga borish, kimga qo'ng'iroq qilish, safarni yakunlash.
///
/// Uch qoida:
///  1. **Katta nishonlar.** Har tugma kamida 96 piksel: harakatlanayotgan
///     mashinada barmoq aniq tushmaydi.
///  2. **Bir qarashda o'qiladi.** Faqat keyingi manzil va vaqt — qolgani
///     yo'q. Ro'yxatni o'qish ruldan diqqatni oladi.
///  3. **Yakunlash TASODIFAN bosilmaydi.** U `HoldToConfirm` bilan:
///     bitta noto'g'ri tegish safarni tugatib qo'ymasin.
///
/// ⚠️ Bu ekran haydashni QO'LLAB-QUVVATLAMAYDI, faqat ko'rishni
/// osonlashtiradi. Navigatsiya baribir tashqi xaritada ochiladi.
class DrivingModeSheet extends StatelessWidget {
  const DrivingModeSheet({
    super.key,
    required this.ride,
    required this.onComplete,
  });

  final Ride ride;
  final Future<void> Function() onComplete;

  static Future<void> show(
    BuildContext context, {
    required Ride ride,
    required Future<void> Function() onComplete,
  }) {
    AppHaptics.select();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // To'liq ekran: yarim varaq ostidan eski ekran ko'rinib turadi va
      // «kamroq element» degan butun maqsad buziladi.
      isDismissible: true,
      showDragHandle: true,
      builder: (_) => DrivingModeSheet(ride: ride, onComplete: onComplete),
    );
  }

  /// Yo'lovchining telefoni — birinchi TASDIQLANGAN broniniki.
  ///
  /// Bittasini tanlaymiz: ruldagi odamga ro'yxat berish xavfli. Qolganlari
  /// oddiy ekranda ko'rinadi.
  String? get _firstPassengerPhone {
    for (final booking in ride.bookings) {
      final phone = booking.passenger?.phone;
      if (phone != null && phone.trim().isNotEmpty) return phone;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final phone = _firstPassengerPhone;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        0,
        AppSpace.lg,
        AppSpace.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Keyingi manzil — eng katta yozuv. Ruldan bir qarashda o'qilsin.
          Text(
            t.drivingModeTo.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            ride.destinationAddress,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (ride.departureTime != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              formatTime(ride.departureTime),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpace.xl),

          _BigAction(
            icon: Icons.navigation_outlined,
            label: t.drivingModeNavigate,
            onTap: () => showRouteMapSheet(context, ride),
          ),
          const SizedBox(height: AppSpace.md),
          _BigAction(
            icon: Icons.phone_outlined,
            label: t.drivingModeCall,
            // Telefon YO'Q bo'lsa tugma o'chiq — bosilib, hech nima
            // bo'lmasligi ruldagi odamni ikkinchi marta urinishga majbur
            // qiladi.
            onTap: phone == null
                ? null
                : () => launchUrl(Uri(scheme: 'tel', path: phone)),
          ),
          const SizedBox(height: AppSpace.xl),

          // 🔴 Yakunlash TASODIFAN bosilmasin: harakatlanayotgan mashinada
          // barmoq sirg'anadi va bitta noto'g'ri tegish safarni tugatib
          // qo'yardi (qaytarib bo'lmaydi).
          HoldToConfirm(
            label: t.completeRide,
            icon: Icons.flag_outlined,
            onConfirmed: () {
              // `HoldToConfirm` sinxron qayta chaqiruv kutadi — yakunlash
              // esa tarmoq amali. Varaqni DARHOL yopamiz: ruldagi odam
              // spinnerga qarab o'tirmasin, natijani ekran o'zi ko'rsatadi.
              Navigator.of(context).pop();
              onComplete();
            },
          ),
        ],
      ),
    );
  }
}

/// Katta nishonli tugma — harakatlanayotgan mashinada barmoq uchun.
class _BigAction extends StatelessWidget {
  const _BigAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;

    return SizedBox(
      // 96 — odatiy tugmadan deyarli ikki barobar. Ruldagi odam
      // qaramasdan ham tegadi.
      height: 96,
      child: FilledButton.tonalIcon(
        onPressed: enabled
            ? () {
                AppHaptics.notice();
                onTap!();
              }
            : null,
        icon: Icon(icon, size: 32),
        label: Text(
          label,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
