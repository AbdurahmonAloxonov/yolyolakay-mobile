import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';
import '../shared/refreshable.dart';
import '../../../app/dimens.dart';
import '../shared/skeleton.dart';
import '../shared/brand/brand_panels.dart';
import '../../app/theme.dart';
import '../shared/brand/atlas.dart';
import '../shared/brand/ornament.dart';

/// Haydovchi daromadi — `GET /rides/earnings`.
///
/// ⚠️ IKKI OGOHLANTIRISH ekranda OCHIQ yozilgan, chunki ikkalasi ham
/// foydalanuvchini chalg'itishi mumkin:
///
/// 1. Raqamlar BUTUN ishlash davri uchun — backendda oy/hafta bo'linishi YO'Q.
///    Busiz odam "bu oy shuncha ishladim" deb o'ylaydi.
/// 2. Naqd pul yo'lovchi bilan TO'G'RIDAN-TO'G'RI hisob-kitob qilinadi —
///    bu raqam bizda turgan pul EMAS, faqat statistika.
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final earnings = ref.watch(driverEarningsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.earningsTitle), bottom: const JiyakLine()),
      // 🔴 TORTISH YUKLANISH VA XATODA HAM (2026-09-04) — izohi
      // `YolRefreshable` da.
      body: YolRefreshable<DriverStatistics>(
        value: earnings,
        onRefresh: () => ref.refresh(driverEarningsProvider.future),
        loading: const ListSkeleton(),
        builder: (stats) => ListView(
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            _EarningsHero(stats: stats),
            const SizedBox(height: AppSpace.md),
            Card(
              child: Column(
                children: [
                  _StatRow(
                    icon: Icons.directions_car_outlined,
                    label: t.totalRides,
                    value: _num(stats.totalRides),
                  ),
                  const Divider(height: 1, indent: 56),
                  _StatRow(
                    icon: Icons.check_circle_outline,
                    label: t.completedRides,
                    value: _num(stats.completedRides),
                  ),
                  const Divider(height: 1, indent: 56),
                  _StatRow(
                    icon: Icons.cancel_outlined,
                    label: t.cancelledRides,
                    value: _num(stats.cancelledRides),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              t.earningsNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `null` -> "—", 0 EMAS: "ma'lumot yo'q" va "nol" farqlanishi kerak.
  static String _num(int? value) => value?.toString() ?? '—';
}

class _EarningsHero extends StatelessWidget {
  const _EarningsHero({required this.stats});

  final DriverStatistics stats;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    /*
     * DAROMAD KARTASI — HUJJAT (2026-09-03 ko'rigi).
     *
     * 🔴 Ilgari u och pushti edi. Ilovada endi «hujjat» tili bor:
     * obuna kartasi va safar pasporti to'q zaminda, girih naqshi
     * bilan va pastida atlas jiyagi. Daromad — haydovchining pul
     * hisoboti, ya'ni aynan o'sha oiladan. Och pushti quti esa
     * boshqa hech nimaga o'xshamas, «xabar» bo'lib turardi.
     */
    final ground = heroSurface(theme);
    final ink = onHeroSurface(theme);

    return Card(
      color: ground,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: GirihPattern(
              cell: 76,
              color: ink.withValues(alpha: 0.10),
              cut: ground,
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AtlasEdge(height: 4, scale: 0.55),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xl,
              AppSpace.xl,
              AppSpace.xl,
              AppSpace.xl + 4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.totalEarnings,
                  style: theme.textTheme.bodyMedium?.copyWith(color: ink),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  stats.totalEarnings == null
                      ? '—'
                      : '${formatPrice(stats.totalEarnings!)} ${t.sum}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                // Davr YO'Qligi ochiq aytiladi — "bu oy" deb o'ylanmasin.
                Text(
                  t.allTimePeriod,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ink.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    trailing: Text(
      value,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    ),
  );
}
