import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../core/format.dart';
import '../../data/models/rating.dart';
import '../../l10n/strings.dart';
import '../shared/ui.dart';
import '../../app/theme.dart';

/// SHARHLAR RO'YXATI — odam haqida boshqalar nima yozgani.
///
/// 🔴 NEGA ENDI BOR: 27-avgustgacha kontraktda faqat `POST /rating` bor
/// edi. Ya'ni biz safardan keyin izoh SO'RAYDIK, odam yozadi — va u
/// gap hech qayerda ko'rinmasdi. Ikki tomonlama zarar: yozgan odam
/// keyingi safar yozmaydi, o'qiydigan odam esa «4.9» raqami ortida nima
/// turganini bilmaydi. Backend so'rovimizdan keyin `GET /rating` ni ochdi.
///
/// 🔑 STANDART `with_comment=true` — MATNLI sharhlar. Bo'sh baholar
/// ro'yxatni suyultiradi: odam bu yerga raqamni emas, GAPNI o'qigani
/// keladi. Umumiy son va o'rtacha esa reyting qatorida turadi.
///
/// ⚠️ Ro'yxat YUKLANMASA hech nima chizilmaydi. Profilning qolgan qismi
/// (ism, reyting, mashina) ishlaydi — sharhlar uzilishi tufayli butun
/// ekranni xato holatiga o'tkazish nomutanosib bo'lardi.
class ReviewsSection extends ConsumerWidget {
  const ReviewsSection({super.key, required this.userId, this.limit = 3});

  final String userId;

  /// Profilda ko'rsatiladigan soni — qolgani «Yana N ta» bilan ochiladi.
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.isEmpty) return const SizedBox.shrink();

    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(userFeedbackProvider(userId));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpace.lg),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      // Uzilishda JIM qolamiz — izohi sinf ustida.
      error: (_, _) => const SizedBox.shrink(),
      data: (list) {
        final items = list.items.where((e) => e.hasComment).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  t.reviewsTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (list.total > 0) ...[
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    '${list.total}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpace.sm),

            if (items.isEmpty)
              Text(
                t.reviewsEmpty,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              )
            else ...[
              for (final r in items.take(limit)) ...[
                _ReviewTile(item: r),
                if (r != items.take(limit).last)
                  const SizedBox(height: AppSpace.sm),
              ],
              if (items.length > limit) ...[
                const SizedBox(height: AppSpace.xs),
                TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => _AllReviewsSheet(items: items),
                  ),
                  child: Text(t.reviewsMore(items.length - limit)),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _AllReviewsSheet extends StatelessWidget {
  const _AllReviewsSheet({required this.items});

  final List<FeedbackItem> items;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Text(
              t.reviewsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                0,
                AppSpace.lg,
                AppSpace.lg,
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
              itemBuilder: (_, i) => _ReviewTile(item: items[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.item});

  final FeedbackItem item;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PersonAvatar(
          url: item.reviewerAvatar,
          radius: 16,
          // Rasm yo'q bo'lsa suzani muhri chiziladi — ism bo'lmasa ham
          // ID dan noyob belgi chiqadi.
          seed: item.reviewerName ?? item.reviewerId,
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      // Ism bo'lmasligi mumkin — o'shanda ham sharh
                      // ko'rsatiladi, faqat muallifsiz.
                      (item.reviewerName ?? '').trim().isEmpty
                          ? t.reviewAuthorUnknown
                          : item.reviewerName!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Yulduzlar SON bilan emas, BELGI bilan: qatorda
                  // "5/5" dan ko'ra tezroq o'qiladi.
                  for (var i = 1; i <= 5; i++)
                    Icon(
                      i <= item.score ? Icons.star : Icons.star_border,
                      size: 13,
                      color: i <= item.score
                          ? BrandColors.star
                          : theme.colorScheme.outlineVariant,
                    ),
                ],
              ),
              if (item.hasComment) ...[
                const SizedBox(height: AppSpace.xs),
                Text(item.comment!.trim(), style: theme.textTheme.bodySmall),
              ],
              if (item.createdAt != null) ...[
                const SizedBox(height: AppSpace.xs),
                Text(
                  formatDate(item.createdAt, t.lang),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
