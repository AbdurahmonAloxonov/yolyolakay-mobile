import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/providers.dart';
import '../../core/cities.dart';
import '../../core/format.dart';
import '../../core/local_flags.dart';
import '../../data/models/parcel.dart';
import '../../l10n/strings.dart';
import '../map/route_preview_map.dart';
import '../shared/refreshable.dart';
import '../shared/brand/suzani_icons.dart';
import '../shared/state_views.dart';
import '../shared/ui.dart';
import '../../../app/dimens.dart';
import '../shared/yol_refresh.dart';
import '../shared/skeleton.dart';
import '../shared/brand/loom_loader.dart';

/// Yuborgan posilkalarim + ularga kelgan haydovchi takliflari.
///
/// NEGA BU EKRAN ENDI BOR: `GET /parcels/my` gateway'da yo'q edi, shuning
/// uchun yuboruvchi o'z posilkasini e'lon qilgach uni BOSHQA KO'RA OLMASDI —
/// ilova ochiq uzr yozib turardi ("ro'yxatda ko'rish hozircha imkonsiz").
/// Ya'ni odam kimdir javob berganini faqat bildirishnomadan bilardi va
/// taklifni qabul qila olmasdi. 2026-08-12 swagger sverkasida yo'l paydo
/// bo'lgani aniqlandi.
class MyParcelsView extends ConsumerWidget {
  const MyParcelsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final parcels = ref.watch(myParcelsProvider);

    return parcels.when(
      // 🔴 Tortish yuklanish va xatoda ham — izohi `refreshableState` da.
      loading: () => refreshableState(
        onRefresh: () => ref.refresh(myParcelsProvider.future),
        child: const ListSkeleton(),
      ),
      error: (error, _) => refreshableState(
        onRefresh: () => ref.refresh(myParcelsProvider.future),
        child: ErrorView(
          error: error,
          onRetry: () => ref.refresh(myParcelsProvider.future),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          // 🔴 BOSHI BERK EDI (2026-09-05 qulaylik auditi): «posilkangiz
          // yo'q» deyilardi-yu, yuborish yorlig'i YONIDA turgani
          // aytilmasdi. Odam orqaga chiqib, qaytadan kirardi.
          return EmptyView(
            suzani: SuzaniIcon.parcel,
            title: t.noMyParcels,
            subtitle: t.noMyParcelsHint,
            actionLabel: t.tabSend,
            onAction: () => DefaultTabController.of(context).animateTo(0),
          );
        }
        return YolRefresh(
          onRefresh: () => ref.refresh(myParcelsProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpace.lg),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
            itemBuilder: (_, i) => _MyParcelCard(parcel: items[i]),
          ),
        );
      },
    );
  }
}

class _MyParcelCard extends ConsumerWidget {
  const _MyParcelCard({required this.parcel});

  final Parcel parcel;

  /// Bekor qilingan/yetkazilgan posilkani qayta bekor qilib bo'lmaydi —
  /// backend 400/403 berardi va odam nima uchunligini tushunmasdi.
  bool get _canCancel {
    final s = (parcel.status ?? 'pending').toLowerCase();
    return s != 'cancelled' && s != 'canceled' && s != 'delivered';
  }

  /// Posilka JO'NATUVCHI tomonda hali ochiq turibdimi.
  ///
  /// `accepted`/`picked_up` — haydovchi olgan, lekin «yetkazildi» hali
  /// yozilmagan holat. (`in_transit` — eski nom, saqlanadi.)
  bool get _awaitingDelivery =>
      (parcel.status ?? '').toLowerCase() == 'accepted' || parcel.isPickedUp;

  /// POSILKANI YOPISH — jo'natuvchi tomondan.
  ///
  /// 🔴 NEGA KERAK (egasi tanlagan band, 2026-08-25; xato 2026-08-16 da
  /// topilgan): posilka `accepted` da ABADIY qotib qolardi. Yetkazilganini
  /// yozadigan yagona chaqiruv — `/parcels/{id}/deliver` — HAYDOVCHI
  /// ekranida. Haydovchi uni bosmasa (ko'pincha shunday: posilka
  /// topshirilgan, telefon cho'ntakda), jo'natuvchining ro'yxati
  /// yopilmagan posilkalar bilan to'lib borardi va qaysi biri haqiqatan
  /// yo'lda ekani ko'rinmay qolardi.
  ///
  /// ✅ 2026-09-04: ENDI HAQIQIY ENDPOINT BOR —
  /// `POST /parcels/{id}/confirm-delivery`. Biz shuni so'ragandik va
  /// backend qo'shdi; o'lchandi: jo'natuvchi 200 oladi va holat
  /// `delivered` bo'ladi, begona odam esa 400.
  ///
  /// Ilgari bu yerda HAYDOVCHINING `deliver` chaqiruvi ishlatilardi:
  /// u jo'natuvchida deyarli har doim rad etilardi va posilka FAQAT
  /// shu qurilmada «yopilgan» bo'lib qolardi.
  ///
  /// ⚠️ Mahalliy belgi ZAXIRA sifatida QOLDIRILDI: server javob
  /// bermasa (tarmoq, eski gateway) ro'yxat baribir tozalanadi va bu
  /// EKRANDA AYTILADI — "faqat shu qurilmada". Jimgina mahalliy belgi
  /// qo'yish server bilan ikki xil gap bo'lardi, ya'ni eng yomon
  /// variant.
  Future<void> _markDelivered(BuildContext context, WidgetRef ref) async {
    final t = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.parcelMarkDelivered),
        content: Text(t.parcelMarkDeliveredConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.close),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.parcelMarkDelivered),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(parcelsRepositoryProvider).confirmDelivery(parcel.id);
      if (!context.mounted) return;
      showMessage(context, t.parcelClosedDone);
      ref.invalidate(myParcelsProvider);
    } catch (_) {
      // Server rad etdi — mahalliy belgi, OCHIQ aytilgan holda.
      await ref
          .read(localFlagsProvider)
          .set(LocalFlags.parcelDelivered(parcel.id));
      if (!context.mounted) return;
      showMessage(context, t.parcelMarkedLocally);
      ref.invalidate(myParcelsProvider);
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final t = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(t.cancelParcelConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.close),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.cancelParcel),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(parcelsRepositoryProvider).cancel(parcel.id);
      if (!context.mounted) return;
      showMessage(context, t.parcelCancelled);
      ref.invalidate(myParcelsProvider);
    } catch (error) {
      if (!context.mounted) return;
      showApiError(context, error, ref.read(langProvider));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    // Server haqiqat aytgan bo'lsa mahalliy belgi keraksiz — ikki xil gap
    // aytmaymiz (`core/local_flags.dart` dagi qoida).
    final flags = ref.watch(localFlagsProvider);
    final flagKey = LocalFlags.parcelDelivered(parcel.id);
    final serverClosed = (parcel.status ?? '').toLowerCase() == 'delivered';
    if (serverClosed && flags.has(flagKey)) unawaited(flags.clear(flagKey));
    final markedLocally = !serverClosed && flags.has(flagKey);

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
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        // Takliflar tile OCHILGANDA yuklanadi (`parcelResponsesProvider`
        // family + autoDispose): o'nta posilkaga oldindan o'nta so'rov
        // yuborish bekorga trafik va sekinlik.
        title: Row(
          children: [
            Expanded(
              child: Text('$from → $to', style: theme.textTheme.titleSmall),
            ),
            /*
             * 🔴 "N ta taklif" — JO'NATUVCHINING eng eski shikoyati.
             *
             * Ilgari haydovchi taklif berganini bilishning yagona yo'li
             * har posilkani ochib ko'rish edi: ro'yxatda hech qanday
             * belgi yo'q edi. Backend `responses_count` ni 2026-08-16
             * kechqurun qo'shdi (biz so'ragan edik) — endi taklif
             * kelgani ro'yxatning O'ZIDA ko'rinadi.
             *
             * Nol bo'lsa chizilmaydi: "0 ta taklif" hech kimga kerak emas
             * va kartani shovqinga to'ldiradi.
             */
            if ((parcel.responsesCount ?? 0) > 0) ...[
              const SizedBox(width: AppSpace.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  t.parcelOffersCount(parcel.responsesCount!),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        // Narx VA holat. Holatsiz qolganda bekor qilingan posilka faolidan
        // farq qilmasdi: odam bekor qiladi, tugma yo'qoladi, kartochka esa
        // o'sha-o'sha turadi — "bekor bo'ldimi yo'qmi" degan savol qoladi.
        subtitle: Row(
          children: [
            if (parcel.price != null)
              Text('${formatPrice(parcel.price!)} ${t.sum}'),
            if (parcel.price != null && parcel.status != null)
              const Text('  ·  '),
            if (parcel.status != null)
              Text(
                t.parcelStatus(parcel.status!),
                style: TextStyle(
                  color: _canCancel
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.error,
                ),
              ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        // IKKALASI ham kerak: `expandedCrossAxisAlignment` faqat ichki
        // Column'ga ta'sir qiladi, uni o'rab turgan Align esa standart
        // bo'yicha MARKAZDA. Faqat birinchisini bersak matn qurilmada
        // markazga tortilib qolardi (o'lchandi).
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /*
           * POSILKANING YO'LI — 16.09.2026.
           *
           * 🔴 Jo'natuvchi o'z posilkasi haqida faqat IKKI NOM va holat
           * so'zini ko'rardi ("Chortoq → Namangan · qabul qilindi").
           * Pochta qayerdan chiqib qayerga borishini xaritada ko'rish
           * imkoni umuman yo'q edi, holbuki koordinatalar backendda
           * SAQLANGAN va nuqta xaritadan tanlangan bo'lishi mumkin
           * («metro yonida») — ya'ni nom aslida to'liq manzil emas.
           *
           * ⚠️ OCHILGANDA chiziladi (`ExpansionTile.children`): yopiq
           * kartalarda xarita yuklanmaydi, ya'ni o'nta posilkali ro'yxat
           * o'nta xarita so'rovi yubormaydi.
           */
          if (parcel.originLat != 0 && parcel.destinationLat != 0) ...[
            RoutePreviewMap(
              waypoints: [
                LatLng(parcel.originLat, parcel.originLon),
                LatLng(parcel.destinationLat, parcel.destinationLon),
              ],
              height: 140,
              originName: parcel.fromAddress,
              destinationName: parcel.toAddress,
            ),
            const SizedBox(height: AppSpace.md),
          ],

          // Yuboruvchi o'zi kiritganini qayta ko'ra olsin — kartochka
          // sarlavhasida faqat yo'nalish va narx bor.
          if (parcel.size != null ||
              parcel.description != null ||
              parcel.deliverBy != null) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (parcel.size != null)
                  Chip(
                    label: Text(t.parcelSizeLabel(parcel.size!)),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                if (parcel.description != null)
                  Text(parcel.description!, style: theme.textTheme.bodySmall),
                if (parcel.deliverBy != null)
                  Text(
                    '${t.parcelDeliverBy}: ${formatDate(parcel.deliverBy, t.lang)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
          ],
          // 🔴 Bekor qilingan/yetkazilgan posilkada takliflar bo'limi ham
          // chizilardi va HAR ochilganda server so'rovi ketardi (egasi
          // qurilmada ko'rdi, 2026-08-13). Bunday posilkaga taklif kelmaydi
          // va kelganini qabul qilib ham bo'lmaydi — bo'lim ma'nosiz.
          if (_canCancel) ...[
            Text(t.parcelOffers, style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpace.sm),
            _Offers(parcelId: parcel.id, taken: parcel.isTaken),
          ],
          // YETKAZILDI DEB BELGILASH — «abadiy accepted» holatidan chiqish.
          if (_awaitingDelivery && !markedLocally) ...[
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _markDelivered(context, ref),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(t.parcelMarkDelivered),
              ),
            ),
          ],

          // Mahalliy belgi — HECH QACHON jim turmaydi.
          if (markedLocally) ...[
            const SizedBox(height: AppSpace.sm),
            InfoBox(
              tone: InfoTone.neutral,
              child: Text(
                t.parcelMarkedLocallyHint,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],

          if (_canCancel) ...[
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _cancel(context, ref),
                icon: const Icon(Icons.close, size: 18),
                label: Text(t.cancelParcel),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Offers extends ConsumerWidget {
  const _Offers({required this.parcelId, required this.taken});

  final String parcelId;

  /// Posilkaga haydovchi ALLAQACHON biriktirilganmi — `parcel.isTaken`.
  /// Taklif tugmalari shu bo'yicha yashiriladi (izohi pastda).
  final bool taken;

  Future<void> _act(
    BuildContext context,
    WidgetRef ref, {
    required String responseId,
    required bool accept,
  }) async {
    final t = AppStrings.of(context);
    final repo = ref.read(parcelsRepositoryProvider);
    try {
      if (accept) {
        await repo.acceptResponse(parcelId, responseId);
      } else {
        await repo.rejectResponse(parcelId, responseId);
      }
      if (!context.mounted) return;
      showMessage(context, accept ? t.offerAccepted : t.offerRejected);
      // Taklif qabul qilinsa posilkaning O'ZI ham o'zgaradi (haydovchi
      // biriktiriladi), shuning uchun ikkala ro'yxat ham yangilanadi.
      ref.invalidate(parcelResponsesProvider(parcelId));
      ref.invalidate(myParcelsProvider);
    } catch (error) {
      if (!context.mounted) return;
      showApiError(context, error, ref.read(langProvider));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final responses = ref.watch(parcelResponsesProvider(parcelId));

    return responses.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpace.md),
        child: Center(child: LoomLoader()),
      ),
      error: (error, _) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(parcelResponsesProvider(parcelId)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Text(
            t.noParcelOffers,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final offer in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.driverName?.trim().isNotEmpty == true
                                ? offer.driverName!
                                : '—',
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (offer.offeredPrice != null)
                            Text(
                              '${formatPrice(offer.offeredPrice!)} ${t.sum}',
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    if (offer.driverRating != null) ...[
                      const Icon(Icons.star, size: 14),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        offer.driverRating!.toStringAsFixed(1),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: AppSpace.sm),
                    ],
                    // Hal bo'lgan taklifda tugma KO'RSATILMAYDI: bosilsa
                    // backend baribir rad etardi va odam "ishlamayapti" deb
                    // o'ylardi. O'rniga holat matni turadi.
                    //
                    // 🔴 POSILKA holati ham tekshiriladi, taklifniki YETMAYDI:
                    // backend taklif qabul qilingandan keyin ham uning
                    // `status` ini `pending` da qoldiradi (o'lchandi
                    // 2026-09-04). Ya'ni posilka allaqachon haydovchining
                    // qo'lida ketayotgan bo'lsa ham «Qabul» tugmasi
                    // turaverardi va bosilganda 400 qaytarardi.
                    if (offer.isPending && !taken) ...[
                      TextButton(
                        onPressed: () => _act(
                          context,
                          ref,
                          responseId: offer.id,
                          accept: false,
                        ),
                        child: Text(t.reject),
                      ),
                      FilledButton(
                        onPressed: () => _act(
                          context,
                          ref,
                          responseId: offer.id,
                          accept: true,
                        ),
                        child: Text(t.accept),
                      ),
                    ] else
                      Text(
                        offer.status ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
