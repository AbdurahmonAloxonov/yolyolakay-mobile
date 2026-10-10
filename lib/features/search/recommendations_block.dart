import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/cities.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';
import '../../../app/dimens.dart';

/// «Siz uchun» — `GET /rides/recommendations`.
///
/// 🔴 Ruchka SAFAR emas, YO'NALISH STATISTIKASI qaytaradi. Web'da bu 2026-08-07
/// gacha noto'g'ri tushunilgan edi va blok HECH QACHON chizilmasdi. Shuning
/// uchun bu yerda darrov to'g'ri shakl: yo'nalish kartochkasi, bosilganda
/// qidiruv to'ldiriladi.
///
/// `from`/`to` — backend bergan MATN. Uni `resolvePlace` koordinataga aylantiradi
/// (u yozilishiga befarq: apostrof, kirill, lotin). Yechilmasa kartochka
/// UMUMAN ko'rsatilmaydi — bosilganda hech nima qilmaydigan tugma yomonroq.
class RecommendationsBlock extends ConsumerWidget {
  const RecommendationsBlock({super.key, required this.onPick});

  /// Yo'nalish tanlanganda: qidiruvni to'ldirib ishga tushirish.
  /// `from` null bo'lishi mumkin (yangi shahar tavsiyasida faqat manzil bor).
  final void Function(Place? from, Place to) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final data = ref.watch(recommendationsProvider).valueOrNull;
    if (data == null || data.isEmpty) return const SizedBox.shrink();

    // Bir yo'nalish ikki guruhda takrorlanmasin (shaxsiy tavsiya ustun).
    final seen = <String>{};
    List<_Item> take(List<RecommendedRoute> routes) {
      final result = <_Item>[];
      for (final route in routes) {
        final key = '${route.from.toLowerCase()}>${route.to.toLowerCase()}';
        if (!seen.add(key)) continue;
        final from = resolvePlace(route.from);
        final to = resolvePlace(route.to);
        if (from == null || to == null) continue; // yechilmasa ko'rsatmaymiz
        result.add(
          _Item(
            label: '${route.from} → ${route.to}',
            from: from,
            to: to,
            count: route.tripsCount,
          ),
        );
        if (result.length >= 4) break;
      }
      return result;
    }

    final mine = take(data.byYourRoutes);
    final popular = take(data.popular);

    final cities = <_Item>[];
    for (final city in data.newDirections) {
      final place = resolvePlace(city.city);
      if (place == null) continue;
      cities.add(_Item(label: city.city, from: null, to: place));
      if (cities.length >= 6) break;
    }

    if (mine.isEmpty && popular.isEmpty && cities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpace.xl),
        Text(
          t.forYou.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: AppSpace.sm),
        if (mine.isNotEmpty)
          _Group(title: t.basedOnYourTrips, items: mine, onPick: onPick),
        if (popular.isNotEmpty)
          _Group(title: t.popularRoutes, items: popular, onPick: onPick),
        if (cities.isNotEmpty)
          _Group(title: t.newDirections, items: cities, onPick: onPick),
      ],
    );
  }
}

class _Item {
  const _Item({
    required this.label,
    required this.from,
    required this.to,
    this.count,
  });
  final String label;
  final Place? from;
  final Place to;
  final int? count;
}

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.items,
    required this.onPick,
  });

  final String title;
  final List<_Item> items;
  final void Function(Place? from, Place to) onPick;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                ActionChip(
                  avatar: const Icon(Icons.explore_outlined, size: 18),
                  label: Text(
                    item.count == null
                        ? item.label
                        : '${item.label} · ${item.count} ${t.tripsCountSuffix}',
                  ),
                  onPressed: () => onPick(item.from, item.to),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
