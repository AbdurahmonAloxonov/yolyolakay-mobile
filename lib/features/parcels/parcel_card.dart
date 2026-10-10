import 'package:flutter/material.dart';

import '../../app/dimens.dart';
import '../../core/cities.dart';
import '../../core/format.dart';
import '../../data/models/parcel.dart';
import '../../l10n/strings.dart';
import '../rides/journey_view.dart';

/// POSILKA KARTOCHKASI — qidiruvda, xaritada va «olib ketayotganlarim»da
/// bir xil ko'rinadi.
///
/// 🔴 NEGA ALOHIDA FAYLGA CHIQDI (16.09.2026): karta ilgari
/// `find_parcels_screen.dart` ichida yashiringan (`_ParcelCard`) edi.
/// Posilkalar XARITADA ham ko'rsatiladigan bo'lgach, o'sha kartani
/// xarita ustidagi varaqda ham chizish kerak bo'ldi — aks holda
/// xaritada boshqacha ko'rinishdagi ikkinchi karta paydo bo'lardi va
/// «bu bir xil posilkami?» degan savol tug'ilardi.
class ParcelCard extends StatelessWidget {
  const ParcelCard({
    super.key,
    required this.parcel,
    this.onOffer,
    this.onPickup,
    this.onDeliver,
  });

  final Parcel parcel;

  /// `null` — bu men allaqachon olib ketayotgan posilka, tugma kerak emas.
  final VoidCallback? onOffer;

  /// Haydovchi amallari — faqat "Olib ketayotganlarim" ro'yxatida.
  final VoidCallback? onPickup;
  final VoidCallback? onDeliver;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    // ✅ Backend 2026-08-07 dan manzil MATNINI saqlaydi (`from_address`) —
    // ya'ni jo'natuvchi yozgan nom ko'rinadi. Koordinatadan shahar topish
    // zaxira bo'lib qoladi: undan oldin yaratilgan posilkalarda matn yo'q.
    final from = placeLabel(
      parcel.fromAddress,
      parcel.originLat,
      parcel.originLon,
    );
    final to = placeLabel(
      parcel.toAddress,
      parcel.destinationLat,
      parcel.destinationLon,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 20),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text('$from → $to', style: theme.textTheme.titleSmall),
                ),
              ],
            ),
            // NIMA tashiyotgani — haydovchi uchun narxdan kam emas. Ilgari
            // kartochkada faqat yo'nalish va narx turardi, ya'ni odam
            // hujjatmi yoki chamadonmi bilmay "olib ketaman" bosardi.
            if (parcel.size != null || parcel.description != null) ...[
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  if (parcel.size != null) ...[
                    Chip(
                      label: Text(t.parcelSizeLabel(parcel.size!)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: AppSpace.sm),
                  ],
                  if (parcel.description != null)
                    Expanded(
                      child: Text(
                        parcel.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ],
            if (parcel.deliverBy != null) ...[
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  const Icon(Icons.event_outlined, size: 14),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    '${t.parcelDeliverBy}: ${formatDate(parcel.deliverBy, t.lang)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            if (parcel.price != null) ...[
              const SizedBox(height: AppSpace.sm),
              Text(
                '${formatPrice(parcel.price!)} ${t.sum}',
                style: theme.textTheme.titleMedium,
              ),
            ],
            // Jo'natuvchi ismi — backend bergan bo'lsa (xat 2026-08-14).
            // Kelmasa qator umuman chizilmaydi: bo'sh "—" savol tug'diradi.
            if ((parcel.senderName ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: AppSpace.sm),
              DriverRow(
                name: parcel.senderName,
                rating: parcel.senderRating,
                seed: parcel.senderId,
                avatarRadius: 14,
                inlineRating: true,
              ),
            ],
            if (parcel.receiverPhone != null) ...[
              const SizedBox(height: AppSpace.xs),
              Text(
                '${t.receiverPhone}: ${parcel.receiverPhone}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (onOffer != null) ...[
              const SizedBox(height: AppSpace.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: parcel.isTaken ? null : onOffer,
                  child: Text(parcel.isTaken ? t.parcelTaken : t.offerParcel),
                ),
              ),
            ],
            if (onPickup != null || onDeliver != null) ...[
              const SizedBox(height: AppSpace.md),
              _CarryActions(
                parcel: parcel,
                onPickup: onPickup,
                onDeliver: onDeliver,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Posilka amallari qatori.
class _CarryActions extends StatelessWidget {
  const _CarryActions({
    required this.parcel,
    required this.onPickup,
    required this.onDeliver,
  });

  final Parcel parcel;
  final VoidCallback? onPickup;
  final VoidCallback? onDeliver;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return Row(
      children: [
        if (onPickup != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPickup,
              icon: const Icon(Icons.inventory_2_outlined, size: 18),
              label: Text(t.parcelPickup),
            ),
          ),
        if (onPickup != null && onDeliver != null)
          const SizedBox(width: AppSpace.sm),
        if (onDeliver != null)
          Expanded(
            child: FilledButton.icon(
              onPressed: onDeliver,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(t.parcelDeliver),
            ),
          ),
      ],
    );
  }
}
