import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';
import '../rides/ride_card.dart';
import '../shared/ui.dart';
import 'search_filters.dart';
import '../../app/dimens.dart';

/// Natijalar tepasidagi boshqaruv — BITTA qator: "Filtrlar" tugmasi + saralash.
///
/// 🔴 Nima buzuq edi (egasi qurilmada ko'rdi, 2026-08-12): filtrlar tepada
/// YOYILIB yotardi — 44 px chiplar qatori (o'nta chip, gorizontal siljiydigan)
/// va uning ostida yana 40 px saralash qatori. Ya'ni ekranning yuqori uchdan
/// biri hali hech qanday safar ko'rsatmasdan band bo'lardi, natijalar esa
/// pastga siljib ketardi. Ustiga-ustak gorizontal siljiydigan chiplar orasida
/// nima borligini bilish uchun ularni surib chiqish kerak edi.
///
/// Endi: bitta 44 px qator. Filtrlar pastdan chiqadigan varaqda, tugmada esa
/// nechta filtr yoqilgani raqam bilan turadi — yopiq bo'lsa ham holat ko'rinadi.
class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final filters = ref.watch(searchFiltersProvider);
    final sort = ref.watch(searchSortProvider);

    /*
     * «Faqat ayollar» filtri QAYTARILDI (egasi, 2026-09-08) — lekin
     * BOSHQA shaklda.
     *
     * 13.08.2026 da u shuning uchun olib tashlangandi: filtr faqat ayol
     * foydalanuvchida ko'rinardi va «erkaklar ham uni qidira olsin»
     * degan e'tiroz bor edi. Endi filtr HAMMAGA ochiq va hech kimdan
     * hech narsani yashirmaydi — yoqilmasa ro'yxat o'zgarmaydi.
     *
     * 🔑 Belgining ma'nosi ham boshqa: u haydovchining JINSI emas,
     * SALON haqidagi e'loni («men bu safarga faqat ayol yo'lovchi
     * olaman»). Erkak haydovchi ham qo'ya oladi.
     */
    final active = filters.activeCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      child: Row(
        children: [
          // Filtrlar tugmasi — yoqilganlar soni bilan.
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _openSheet(context, ref),
              icon: const Icon(Icons.tune, size: 18),
              label: Text(
                active == 0 ? t.filters : '${t.filters} · $active',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: active == 0
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.primary,
                side: BorderSide(
                  color: active == 0
                      ? theme.colorScheme.outlineVariant
                      : theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          // Saralash — menyu. Ilgari uchta chip alohida qator egallardi.
          Expanded(
            child: PopupMenuButton<SearchSort>(
              initialValue: sort,
              onSelected: (value) =>
                  ref.read(searchSortProvider.notifier).state = value,
              itemBuilder: (context) => [
                for (final option in SearchSort.values)
                  PopupMenuItem(
                    value: option,
                    child: Text(_sortLabel(t, option)),
                  ),
              ],
              child: InputDecorator(
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.swap_vert,
                      size: 18,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        _sortLabel(t, sort),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _sortLabel(AppStrings t, SearchSort sort) => switch (sort) {
    SearchSort.distance => t.sortDistance,
    SearchSort.time => t.sortTime,
    SearchSort.price => t.sortPrice,
  };

  void _openSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      // `useSafeArea` SHART (Android 15+ / targetSdk 36): tizim
      // "edge-to-edge" ni MAJBURIY qiladi va opt-out endi ishlamaydi.
      // Usiz varaqning eng pastki tugmasi imo-ishora paneli ostida
      // qolib, bosib bo'lmaydigan bo'lardi.
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _FilterSheet(),
    );
  }
}

/// Filtrlar varag'i.
///
/// Chiplar o'rniga BELGILI qatorlar: chipda "yoqilgan"ni faqat rang bildiradi,
/// qatorda esa tumbler ochiq turadi va nima yoqilgani bir qarashda ko'rinadi.
class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  /// Narx maydonlari — oyna yopilganda QO'LLANADI, har bosishda emas.
  ///
  /// 🔴 NEGA SHUNDAY: narx SERVER filtri, ya'ni har o'zgarishda qayta
  /// so'rov ketardi. Odam "50000" yozguncha beshta so'rov yuborilardi va
  /// oradagi natijalar chalg'itardi. Shuning uchun qiymat "Ko'rsatish"
  /// bosilganda bir marta yuboriladi.
  late final _min = TextEditingController(
    text: _initial(ref.read(searchFiltersProvider).priceMin),
  );
  late final _max = TextEditingController(
    text: _initial(ref.read(searchFiltersProvider).priceMax),
  );

  static String _initial(double? v) => v == null ? '' : v.round().toString();

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) {
    final digits = c.text.replaceAll(RegExp('[^0-9]'), '');
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }

  /// Oynani yopish: narx serverga yuboriladi va qidiruv qayta yugurtiriladi.
  Future<void> _apply() async {
    final min = _parse(_min);
    final max = _parse(_max);
    ref
        .read(searchFiltersProvider.notifier)
        .update(
          ref
              .read(searchFiltersProvider)
              .copyWith(
                priceMin: min,
                priceMax: max,
                clearPrice: min == null && max == null,
              ),
        );
    Navigator.of(context).pop();
    await ref
        .read(searchControllerProvider.notifier)
        .applyPrice(min: min, max: max);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final filters = ref.watch(searchFiltersProvider);
    final controller = ref.read(searchFiltersProvider.notifier);

    /*
     * 🔴 TUGMA PASTGA QADALGAN (2026-08-16). Narx maydonlari qo'shilgach
     * varaq uzaydi va "Ko'rsatish" ro'yxat oxirida, ekrandan tashqarida
     * qolib ketdi — odam filtrni tanlab, uni qo'llay olmasdi.
     *
     * Loyihadagi qoida (2026-08-13, e'lon formasi bilan bir xil): asosiy
     * tugma AYLANTIRILADIGAN ro'yxat oxirida turmasin. Endi faqat filtrlar
     * aylanadi, tugma esa doim ko'rinib turadi.
     *
     * Balandlik ekranning 85% i bilan cheklangan: qisqa ro'yxatda varaq
     * mazmun bo'yicha kichik qoladi, uzunida esa ekranni to'ldirib
     * yubormaydi.
     */
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                    child: Row(
                      children: [
                        Text(t.filters, style: theme.textTheme.titleLarge),
                        const Spacer(),
                        if (!filters.isEmpty)
                          TextButton(
                            onPressed: controller.reset,
                            child: Text(t.resetFilters),
                          ),
                      ],
                    ),
                  ),

                  // XAVFSIZLIK — qulayliklardan OLDIN: bu «konditsioner
                  // bormi» darajasidagi tanlov emas, odam safarga
                  // chiqish-chiqmaslikni shunga qarab hal qiladi.
                  _Toggle(
                    icon: Icons.female,
                    label: t.womenOnlyFilter,
                    subtitle: t.womenOnlyHint,
                    value: filters.womenOnly,
                    onChanged: (v) {
                      controller.update(filters.copyWith(womenOnly: v));
                      // SERVER filtri — darhol qayta so'rov (izohi
                      // `RideSearchController.setWomenOnly` da).
                      // Varaq qanday yopilishidan qat'i nazar holat
                      // to'g'ri bo'lsin uchun `_apply` kutilmaydi.
                      unawaited(
                        ref
                            .read(searchControllerProvider.notifier)
                            .setWomenOnly(v),
                      );
                    },
                  ),
                  const Divider(height: 8),

                  _Toggle(
                    icon: Icons.local_shipping,
                    label: t.parcelFilter,
                    value: filters.takesParcels,
                    onChanged: (v) =>
                        controller.update(filters.copyWith(takesParcels: v)),
                  ),
                  _Toggle(
                    icon: Icons.smoke_free,
                    label: t.noSmoking,
                    value: filters.noSmoking,
                    onChanged: (v) =>
                        controller.update(filters.copyWith(noSmoking: v)),
                  ),
                  _Toggle(
                    icon: Icons.pets,
                    prohibited: true,
                    label: t.noPets,
                    value: filters.noPets,
                    onChanged: (v) =>
                        controller.update(filters.copyWith(noPets: v)),
                  ),
                  _Toggle(
                    icon: Icons.ac_unit,
                    label: t.hasAc,
                    value: filters.hasAc,
                    onChanged: (v) =>
                        controller.update(filters.copyWith(hasAc: v)),
                  ),
                  _Toggle(
                    icon: Icons.luggage,
                    label: t.hasLuggage,
                    value: filters.hasLuggage,
                    onChanged: (v) =>
                        controller.update(filters.copyWith(hasLuggage: v)),
                  ),
                  _Toggle(
                    icon: Icons.airline_seat_recline_normal,
                    label: t.maxTwoBack,
                    value: filters.maxTwoBack,
                    onChanged: (v) =>
                        controller.update(filters.copyWith(maxTwoBack: v)),
                  ),
                  _Toggle(
                    icon: Icons.handshake,
                    label: t.negotiable,
                    value: filters.negotiable,
                    onChanged: (v) =>
                        controller.update(filters.copyWith(negotiable: v)),
                  ),

                  const Divider(height: 24),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Text(
                      t.drivingStyle,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                  // NARX ORALIG'I — server filtri (saytdagi bilan bir xil).
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.md,
                      AppSpace.md,
                      AppSpace.md,
                      AppSpace.sm,
                    ),
                    child: SectionLabel(t.priceRange),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _min,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: t.priceFrom,
                              suffixText: t.sum,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: TextField(
                            controller: _max,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: t.priceTo,
                              suffixText: t.sum,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),

                  // Haydash uslubi — bittasini tanlash. Chiplar bu yerda o'rinli:
                  // uchtasi bir qatorga sig'adi va tanlov o'zaro istisno.
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.md,
                    ),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final speed in DrivingSpeed.values)
                          ChoiceChip(
                            label: Text(switch (speed) {
                              DrivingSpeed.calm => t.speedCalm,
                              DrivingSpeed.normal => t.speedNormal,
                              DrivingSpeed.fast => t.speedFast,
                            }),
                            selected: filters.drivingSpeed == speed,
                            showCheckmark: false,
                            onSelected: (selected) => controller.update(
                              selected
                                  ? filters.copyWith(drivingSpeed: speed)
                                  : filters.copyWith(clearDrivingSpeed: true),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Doim ko'rinadigan tugma.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.sm,
                AppSpace.md,
                AppSpace.md,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _apply,
                  child: Text(t.showResults),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.prohibited = false,
    this.subtitle,
  });

  final IconData icon;

  /// "Mumkin emas" belgisi — ikonka ustidan chiziq (`RideBadgeIcon`).
  final bool prohibited;
  final String label;

  /// Ixtiyoriy izoh — belgi nimani anglatishini aytadi. Faqat ma'nosi
  /// nomidan ko'rinmaydigan filtrlarda (hozircha «Faqat ayollar»).
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      dense: true,
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle!),
      // ⚠️ `isThreeLine` EMAS: matn shkalasi kattalashsa izoh ikki
      // qatorga chiqadi va qat'iy balandlik uni kesib qo'yardi.
      secondary: RideBadgeIcon(
        RideBadge(icon, label, prohibited: prohibited),
        size: 22,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Yoqilgan filtrlar — birma-bir olib tashlanadigan chiplar.
///
/// 🔴 NEGA FAQAT BO'SH NATIJADA: filtr chiplari ilgari natijalar TEPASIDA
/// doim turardi va egasi ularni 2026-08-12 da olib tashlatgan — ekranning
/// yuqori uchdan biri hali bitta ham safar ko'rsatmasdan band bo'lardi
/// (izohi `FilterBar` da). Bu qaror kuchida qoladi.
///
/// Lekin natija BO'SH chiqqanda holat teskari: ekranda bo'sh joy ko'p va
/// odamning yagona savoli — "nega hech nima yo'q?". "Hammasini tozalash"
/// bor edi-yu, u BUTUN tanlovni yo'q qiladi; ko'pincha esa bitta filtr
/// ortiqcha bo'ladi. Shu yerda chiplar javob ham, yechim ham bo'ladi.
///
/// Saytda bu chiplar doim ko'rinadi — u yerda ekran keng va joy muammosi
/// yo'q. Paritet ATAYIN buzilgan: cheklov boshqa.
class ActiveFilterChips extends ConsumerWidget {
  const ActiveFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final filters = ref.watch(searchFiltersProvider);
    final controller = ref.read(searchFiltersProvider.notifier);
    if (filters.isEmpty) return const SizedBox.shrink();

    final chips = <Widget>[];
    void add({
      required bool on,
      required IconData icon,
      required String label,
      required SearchFilters cleared,
    }) {
      if (!on) return;
      chips.add(
        InputChip(
          avatar: Icon(icon, size: 16),
          label: Text(label),
          onDeleted: () => controller.update(cleared),
        ),
      );
    }

    // «Faqat ayollar» — SERVER filtri, shuning uchun chipni olib
    // tashlash qidiruvni ham qayta yugurtiradi (`add` yordamchisi
    // faqat mahalliy holatni o'zgartiradi).
    if (filters.womenOnly) {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.female, size: 16),
          label: Text(t.womenOnlyFilter),
          onDeleted: () {
            controller.update(filters.copyWith(womenOnly: false));
            unawaited(
              ref.read(searchControllerProvider.notifier).setWomenOnly(false),
            );
          },
        ),
      );
    }

    add(
      on: filters.noSmoking,
      icon: Icons.smoke_free,
      label: t.noSmoking,
      cleared: filters.copyWith(noSmoking: false),
    );
    add(
      on: filters.noPets,
      icon: Icons.pets,
      label: t.noPets,
      cleared: filters.copyWith(noPets: false),
    );
    add(
      on: filters.hasAc,
      icon: Icons.ac_unit,
      label: t.hasAc,
      cleared: filters.copyWith(hasAc: false),
    );
    add(
      on: filters.hasLuggage,
      icon: Icons.luggage,
      label: t.hasLuggage,
      cleared: filters.copyWith(hasLuggage: false),
    );
    add(
      on: filters.maxTwoBack,
      icon: Icons.airline_seat_recline_normal,
      label: t.maxTwoBack,
      cleared: filters.copyWith(maxTwoBack: false),
    );
    add(
      on: filters.takesParcels,
      icon: Icons.local_shipping,
      label: t.takesParcels,
      cleared: filters.copyWith(takesParcels: false),
    );
    add(
      on: filters.negotiable,
      icon: Icons.handshake,
      label: t.negotiable,
      cleared: filters.copyWith(negotiable: false),
    );
    add(
      on: filters.drivingSpeed != null,
      icon: Icons.speed,
      label: switch (filters.drivingSpeed) {
        DrivingSpeed.calm => t.speedCalm,
        DrivingSpeed.normal => t.speedNormal,
        DrivingSpeed.fast => t.speedFast,
        null => '',
      },
      cleared: filters.copyWith(clearDrivingSpeed: true),
    );
    add(
      on: filters.priceMin != null || filters.priceMax != null,
      icon: Icons.payments_outlined,
      label: [
        if (filters.priceMin != null)
          '${formatPrice(filters.priceMin!)} ${t.priceFrom}',
        if (filters.priceMax != null)
          '${formatPrice(filters.priceMax!)} ${t.priceTo}',
      ].join(' · '),
      cleared: filters.copyWith(clearPrice: true),
    );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpace.sm,
      runSpacing: AppSpace.xs,
      children: chips,
    );
  }
}
