import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/dimens.dart';
import '../../core/format.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';
import '../shared/state_views.dart';

/// OFFLINE SAFAR KARTASI — aloqa yo'qolganda kerak bo'ladigan hammasi.
///
/// 🔴 NEGA (egasi, 2026-08-27: «antena chiqmay qolishi»): shaharlararo
/// yo'lda aloqa uziladi. Odam eng kerakli paytda — uchrashuv nuqtasida
/// turib — haydovchining raqamini, mashina davlat raqamini va uchrashuv
/// joyini topa olmaydi. Bu zerikish emas, XAVOTIR, va u zerikishdan
/// og'irroq.
///
/// 🔑 YANGI MA'LUMOT SO'RALMAYDI. Karta faqat QO'LDAGI safar obyektidan
/// quriladi — u bron ro'yxati bilan birga allaqachon keshlangan
/// (`CacheKeys.myBookings`). Ya'ni ekran tarmoqqa umuman chiqmaydi va
/// aloqa bor-yo'qligidan qat'i nazar bir xil ishlaydi.
///
/// ⚠️ TELEFON QOIDASI BUZILMAYDI: raqam faqat backend uni yuborgan
/// bo'lsa ko'rsatiladi (u tasdiqlangan bronda yuboriladi). Yo'q bo'lsa
/// SABABI yoziladi — bo'sh joy qoldirilmaydi, chunki odam «ilova
/// buzuq» deb o'ylardi.
class OfflineTripCard extends StatelessWidget {
  const OfflineTripCard({super.key, required this.ride, this.savedAt});

  final Ride ride;

  /// Ma'lumot qachon saqlangani — keshdan. Ko'rsatiladi, chunki eski
  /// ma'lumotni JIMGINA berish eng yomon variant.
  final DateTime? savedAt;

  static Future<void> show(
    BuildContext context, {
    required Ride ride,
    DateTime? savedAt,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => OfflineTripCard(ride: ride, savedAt: savedAt),
  );

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final driver = ride.driver;
    final car = ride.car;
    final phone = (driver?.phone ?? '').trim();

    final carText = [
      [car?.brand, car?.model].where((e) => (e ?? '').isNotEmpty).join(' '),
      car?.plate,
    ].where((e) => (e ?? '').trim().isNotEmpty).join(' · ');

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpace.lg,
        right: AppSpace.lg,
        top: AppSpace.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.offlineCardTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpace.xs),
          // Eng muhim va'da — birinchi qatorda.
          Row(
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 14,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  t.offlineCardWorks,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),

          _Row(
            icon: Icons.route_outlined,
            label: '${ride.originAddress} → ${ride.destinationAddress}',
            value: formatDateTime(ride.departureTime, t.lang),
          ),
          if ((driver?.name ?? '').trim().isNotEmpty)
            _Row(
              icon: Icons.person_outline,
              label: t.driver,
              value: driver!.name!,
              // Raqam — eng kerakli narsa, shuning uchun NUSXA olinadi:
              // yo'lda uni qo'lda terish qiyin.
              trailing: phone.isEmpty ? null : phone,
              onCopy: phone.isEmpty ? null : phone,
            ),
          if (phone.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 30, bottom: AppSpace.sm),
              child: Text(
                t.offlineCardNoPhone,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          if (carText.isNotEmpty)
            _Row(
              icon: Icons.directions_car_outlined,
              label: t.offlineCardCar,
              value: carText,
              onCopy: car?.plate,
            ),
          if ((ride.pickupPoint ?? '').trim().isNotEmpty)
            _Row(
              icon: Icons.place_outlined,
              label: t.offlineCardMeeting,
              value: ride.pickupPoint!.trim(),
            ),

          if (savedAt != null) ...[
            const SizedBox(height: AppSpace.md),
            Text(
              t.offlineCardSaved(formatDateTime(savedAt, t.lang)),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? trailing;

  /// Nusxa olinadigan matn — `null` bo'lsa tugma chizilmaydi.
  final String? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final copy = onCopy;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                Text(value, style: theme.textTheme.bodyMedium),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          if (copy != null && copy.trim().isNotEmpty)
            IconButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: copy.trim()));
                if (context.mounted) {
                  showMessage(context, AppStrings.of(context).copied);
                }
              },
              icon: const Icon(Icons.copy_outlined, size: 18),
              // Tooltip SHART: ekran o'quvchi uchun yagona izoh
              // (`accessibility_test` shuni tekshiradi).
              tooltip: AppStrings.of(context).copy,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
