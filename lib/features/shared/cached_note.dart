import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../core/format.dart';
import '../../l10n/strings.dart';

/// «OXIRGI YANGILANISH» — ekrandagi ma'lumot KESHDAN kelganini aytadi.
///
/// 🔴 NEGA SHART (offline kesh qoidasining ikkinchi yarmi): eski ma'lumotni
/// JIMGINA ko'rsatish — aldash. Odam «2 joy bo'sh» degan yozuvni ko'rib
/// bron qilishga urinadi, aslida esa u soat oldingi holat. Kesh faqat
/// «qachon olingani» aytilgandagina foydali bo'ladi.
///
/// FAQAT uzilishda ko'rinadi: internet bor bo'lsa ma'lumot yangi va bu
/// qator ekrandan bekorga joy yeb turadi.
///
/// Holat manbai — `ApiClient.connected` (`ConnectionBanner` bilan bir xil):
/// u so'rov backendga YETDIMI degan haqiqatga tayanadi, `connectivity_plus`
/// ning "Wi-Fi ulangan" degan taxminiga emas.
class CachedNote extends ConsumerWidget {
  const CachedNote({super.key, required this.cacheKey});

  /// `CacheKeys` dagi kalit.
  final String cacheKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final at = ref.watch(localCacheProvider).cachedAt(cacheKey);
    if (at == null) return const SizedBox.shrink();

    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: ref.watch(apiClientProvider).connected,
      builder: (context, isOnline, _) {
        if (isOnline) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.sm,
            AppSpace.lg,
            0,
          ),
          child: Row(
            children: [
              Icon(Icons.history, size: 14, color: theme.colorScheme.outline),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  t.cachedAt(formatTime(at)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
