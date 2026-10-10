import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/cities.dart';
import '../../data/models/parcel.dart';
import '../../l10n/strings.dart';
import '../search/city_picker.dart';
import 'parcel_card.dart';
import 'parcels_map_screen.dart';
import '../shared/yol_refresh.dart';
import '../shared/brand/suzani_icons.dart';
import '../shared/state_views.dart';
import '../../../app/dimens.dart';
import '../shared/refreshable.dart';
import '../shared/skeleton.dart';
import '../shared/city_field.dart';

/// Yaqin-atrofdagi posilkalarni topish (haydovchi).
///
/// Backend qidiruvi FAQAT bitta nuqta + radiusni biladi (yo'nalish emas):
/// haydovchi qayerdan olib ketishini tanlaydi, borish manzili natijalarda
/// ko'rinadi. Shuning uchun "qayerga" maydoni umuman yo'q — bo'lsa,
/// foydalanuvchi filtr ishlayapti deb o'ylagan bo'lardi.
class FindParcelsView extends ConsumerStatefulWidget {
  const FindParcelsView({super.key});

  @override
  ConsumerState<FindParcelsView> createState() => _FindParcelsViewState();
}

class _FindParcelsViewState extends ConsumerState<FindParcelsView> {
  Place? _near;
  double _radiusKm = 25;

  List<Parcel>? _results;
  Object? _error;
  bool _loading = false;

  Future<void> _search() async {
    final t = AppStrings.of(context);
    final near = _near;
    if (near == null) {
      showMessage(context, t.selectCity);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final parcels = await ref
          .read(parcelsRepositoryProvider)
          .search(lat: near.lat, lon: near.lon, radiusKm: _radiusKm);
      if (mounted) setState(() => _results = parcels);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Haydovchi TAKLIF beradi — posilkani o'ziga biriktirib olmaydi.
  ///
  /// 🔴 Ilgari bu tugma `POST /parcels/{id}/accept` ni chaqirardi: haydovchi
  /// jo'natuvchidan so'ramasdan posilkani olib qo'yardi va narx muhokamasi
  /// umuman bo'lmasdi. Jo'natuvchi ekranida esa "haydovchi takliflari"
  /// ro'yxati turardi va u DOIM bo'sh bo'lardi — chunki ilovadagi haydovchi
  /// taklif yaratmasdi. Saytda oqim to'g'ri edi, ikkala mijoz bir-biriga zid
  /// ishlardi.
  Future<void> _respond(Parcel parcel) async {
    final t = AppStrings.of(context);
    final price = await _askPrice(parcel);
    if (price == null) return;

    try {
      await ref.read(parcelsRepositoryProvider).respond(parcel.id, price);
      if (!mounted) return;
      showMessage(context, t.offerSent);
      await _search();
    } catch (error) {
      if (!mounted) return;
      showApiError(context, error, t.lang);
    }
  }

  /// Taklif narxi. Boshlang'ich qiymat — jo'natuvchi aytgan narx: ko'pincha
  /// haydovchi shunga rozi bo'ladi va hech narsa yozmasdan tasdiqlaydi.
  Future<double?> _askPrice(Parcel parcel) async {
    final t = AppStrings.of(context);
    final controller = TextEditingController(
      text: parcel.price == null ? '' : parcel.price!.round().toString(),
    );

    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.offerParcelTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(suffixText: t.sum),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              t.offerParcelHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        // 🔴 Ikki tugma bitta qatorga sig'masdi va "Yopish" TEPADA, o'ngga
        // qisilib, "Taklif berish" esa pastda alohida turardi — oyna
        // buzuqdek ko'rinardi (qurilmada ko'rildi 2026-08-13).
        // `actionsOverflowDirection` bilan tartib aniq: asosiy amal
        // TEPADA va ikkalasi ham butun enda.
        actionsOverflowDirection: VerticalDirection.up,
        actionsOverflowButtonSpacing: AppSpace.sm,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.close),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value == null || value <= 0) return;
              Navigator.pop(context, value);
            },
            child: Text(t.offerParcel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    // "Olib ketayotganlarim" endi ALOHIDA yorliq (`CarryingParcelsView`):
    // qidiruv ekranining tepasida turganda u har qidiruvda ko'zga tashlanib,
    // asosiy ishni pastga surib yuborardi.
    /*
     * 🔴 TORTIB-YANGILASH (egasi, 2026-09-04: «har bir joyda bo'lishi
     * kerak»). Bu ekran forma ko'rinsa ham, pastida SERVERDAN kelgan
     * posilkalar ro'yxati turadi — u eskiradi.
     *
     * Tortish oxirgi qidiruvni QAYTA yuboradi: filtrlar (shahar,
     * radius) o'z joyida qoladi, faqat natija yangilanadi.
     */
    return YolRefresh(
      onRefresh: _search,
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          // 🔴 SHAHAR MAYDONI ILOVANING IMZOSIGA ZID EDI (2026-09-03).
          //
          // Bu yerda «nishonga olish» ikonkasi (`my_location`) turardi,
          // qolgan hamma joyda esa shahar NUQTA bilan ko'rsatiladi.
          // `CityField` aynan shu nusxalanishni to'xtatish uchun
          // yaratilgan edi, lekin bu ekran o'sha paytda o'tkazib
          // yuborilgan.
          Card(
            child: CityField(
              label: t.parcelsNear,
              city: _near,
              dot: theme.colorScheme.primary,
              onTap: () async {
                final place = await showPlacePicker(context);
                if (place != null) setState(() => _near = place);
              },
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            '${t.radius}: ${_radiusKm.round()} ${t.kmAway}',
            style: theme.textTheme.bodyMedium,
          ),
          Slider(
            value: _radiusKm,
            min: 5,
            max: 100,
            divisions: 19,
            label: '${_radiusKm.round()}',
            onChanged: (value) => setState(() => _radiusKm = value),
          ),
          const SizedBox(height: AppSpace.sm),
          FilledButton(
            onPressed: _loading ? null : _search,
            child: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.searchButton),
          ),
          const SizedBox(height: AppSpace.xl),

          /*
           * XARITADA KO'RISH — 16.09.2026.
           *
           * 🔴 Ro'yxat haydovchining ASOSIY savoliga javob bermasdi:
           * «bu posilka mening yo'limga tushadimi?». Ro'yxatda "Chortoq →
           * Namangan" degan ikki nom turadi, ular esa yo'l ustidami yoki
           * chekkadami — bilinmaydi. Radius slayderi ham ko'r edi: "25 km"
           * qayergacha yetishini odam tasavvur qilishi kerak edi.
           *
           * Tugma FAQAT natija bo'lganda chiqadi: bo'sh xarita ochish
           * odamni aldaydi.
           */
          if ((_results ?? const []).isNotEmpty) ...[
            OutlinedButton.icon(
              onPressed: () => showParcelsMap(
                context,
                parcels: _results!,
                center: _near,
                radiusKm: _radiusKm,
                onOffer: _respond,
              ),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(t.parcelsOnMap),
            ),
            const SizedBox(height: AppSpace.lg),
          ],

          if (_error != null)
            ErrorView(error: _error!, onRetry: _search)
          else if (_results != null && _results!.isEmpty)
            // qulaylik: chiqish yo'li SHART EMAS — qidiruv formasi
            // AYNAN shu ekranda, bo'sh natijaning ustida turibdi.
            EmptyView(
              suzani: SuzaniIcon.parcel,
              title: t.noParcels,
              subtitle: t.noParcelsHint,
            )
          else
            for (final parcel in _results ?? const <Parcel>[]) ...[
              ParcelCard(parcel: parcel, onOffer: () => _respond(parcel)),
              const SizedBox(height: AppSpace.md),
            ],
        ],
      ),
    );
  }
}

/// Haydovchi OLIB KETAYOTGAN posilkalar — "Pochta" bo'limining ikkinchi
/// yorlig'i.
///
/// Ilgari bunday ro'yxat umuman yo'q edi: taklif qabul qilingach posilka
/// haydovchi ekranidan yo'qolardi va u nima olib ketayotganini eslab
/// qolishi kerak edi.
class CarryingParcelsView extends ConsumerWidget {
  const CarryingParcelsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final carrying = ref.watch(carryingParcelsProvider);

    // Tortib-yangilash YUKLANISH va XATO holatida ham (izohi
    // `YolRefreshable` da).
    return YolRefreshable<List<Parcel>>(
      value: carrying,
      onRefresh: () => ref.refresh(carryingParcelsProvider.future),
      loading: const ListSkeleton(),
      builder: (parcels) {
        if (parcels.isEmpty) {
          // 🔴 BOSHI BERK EDI (2026-09-05): haydovchi hech qanday yuk
          // olmagan bo'lsa, yuk TOPADIGAN yorliq yonida turardi va u
          // haqda hech narsa aytilmasdi.
          return EmptyView(
            suzani: SuzaniIcon.parcel,
            title: t.noCarryingParcels,
            subtitle: t.noCarryingParcelsHint,
            actionLabel: t.tabFind,
            onAction: () => DefaultTabController.of(context).animateTo(0),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpace.lg),
          itemCount: parcels.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
          itemBuilder: (_, i) => _CarryingCard(parcel: parcels[i]),
        );
      },
    );
  }
}

/// Haydovchi olib ketayotgan posilka — amallari bilan.
///
/// 🔴 NEGA ALOHIDA WIDGET: amallar so'rov yuboradi va natijaga qarab
/// ro'yxatni yangilaydi, ya'ni holat kerak. Karta esa oddiy va holatsiz
/// qolishi kerak — u qidiruvda ham ishlatiladi.
class _CarryingCard extends ConsumerStatefulWidget {
  const _CarryingCard({required this.parcel});

  final Parcel parcel;

  @override
  ConsumerState<_CarryingCard> createState() => _CarryingCardState();
}

class _CarryingCardState extends ConsumerState<_CarryingCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String doneMessage) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(carryingParcelsProvider);
      if (mounted) showMessage(context, doneMessage);
    } catch (error) {
      if (mounted) showApiError(context, error, ref.read(langProvider));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final repo = ref.read(parcelsRepositoryProvider);

    // `accepted` -> "Oldim", `picked_up` -> "Yetkazdim". Yakunlangan
    // posilkada tugma umuman chizilmaydi.
    //
    // 🔴 Holat nomi `in_transit` deb yozilgandi, backend esa `picked_up`
    // beradi (o'lchandi 2026-09-04) — ya'ni «Yetkazdim» HECH QACHON
    // chiqmasdi, «Oldim» esa olingandan keyin ham turaverardi.
    final canPickup =
        !_busy && !widget.parcel.isPickedUp && !widget.parcel.isDelivered;
    final canDeliver = !_busy && widget.parcel.isPickedUp;

    return ParcelCard(
      parcel: widget.parcel,
      onPickup: canPickup
          ? () =>
                _run(() => repo.pickup(widget.parcel.id), t.parcelPickedUpDone)
          : null,
      onDeliver: canDeliver
          ? () => _run(
              () => repo.deliver(widget.parcel.id),
              t.parcelDeliveredDone,
            )
          : null,
    );
  }
}
