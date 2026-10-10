import 'package:flutter/material.dart';

import '../../app/dimens.dart';
import '../../core/trust.dart';
import '../../data/models/user.dart';
import '../../l10n/strings.dart';
import '../../app/theme.dart';

/// ISHONCH NARVONI — bosqichlar ro'yxati va bitta umumiy raqam.
///
/// Sabab va qat'iy qoidalar `core/trust.dart` da. Bu yerda faqat chizish.
///
/// ⚠️ Bajarilmagan bosqich QIZIL emas, KULRANG: u ayb emas, hali
/// bosib o'tilmagan qadam. Qizil rang «bu odam xavfli» degan ma'no
/// berardi va bu bizda yo'q ma'lumot.
class TrustLadder extends StatelessWidget {
  const TrustLadder({super.key, required this.user, this.cars});

  final User user;

  /// Faqat O'Z profilida ma'lum (izohi `computeTrust` da).
  final List<Car>? cars;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final summary = computeTrust(user, cars: cars);
    if (summary.total == 0) return const SizedBox.shrink();

    final okColor = BrandColors.success;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  summary.isComplete ? Icons.verified : Icons.shield_outlined,
                  size: 20,
                  color: summary.isComplete
                      ? okColor
                      : theme.colorScheme.outline,
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    t.trustLadderTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${summary.earned}/${summary.total}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: summary.isComplete
                        ? okColor
                        : theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            for (final step in summary.shown)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: Row(
                  children: [
                    Icon(
                      summary.done.contains(step)
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 18,
                      color: summary.done.contains(step)
                          ? okColor
                          : theme.colorScheme.outlineVariant,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        _label(t, step),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: summary.done.contains(step)
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // 🔴 HALOL IZOH: ko'rsatilmagan bosqich «yiqilgan» emas —
            // biz u haqda ma'lumot olmadik. Buni aytmasak, ro'yxat
            // qisqarganda odam «nimadir yashirilyapti» deb o'ylardi.
            Text(
              t.trustLadderHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _label(AppStrings t, TrustStep step) => switch (step) {
    TrustStep.phone => t.trustStepPhone,
    TrustStep.tenure => t.trustStepTenure,
    TrustStep.reviews => t.trustStepReviews,
    TrustStep.rating => t.trustStepRating,
    TrustStep.car => t.trustStepCar,
  };
}
