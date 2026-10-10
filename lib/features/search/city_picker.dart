import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/cities.dart';
import '../../core/geocoder.dart';
import '../../l10n/strings.dart';
import '../map/pick_location_screen.dart';
import '../../app/dimens.dart';

/// Joy tanlash — shaharlar va tumanlar, filtr bilan.
///
/// Qidiruv `searchPlaces` orqali: apostrof, ruscha kirill va o'zbekcha kelishik
/// qo'shimchalari hisobga olinadi ("toshkentdan", "чиланзар", "Farg'ona" →
/// hammasi topiladi).
///
/// Ichki ro'yxatda hech nima topilmasa geokoderga (Nominatim) murojaat
/// qilinadi — mahalla, ko'cha yoki orientir nomi kiritilgan bo'lishi mumkin.
/// Xaritadan nuqta tanlash ham shu yerdan ochiladi.
///
/// Bekor qilinsa `null` qaytadi.
/// [initialQuery] — qidiruv maydoniga oldindan yoziladigan matn.
///
/// 🔴 NEGA KERAK (2026-08-25): ovoz bilan aytilgan shahar tanilmasa, ilgari
/// FAQAT xabar chiqardi va matn hech qayerga tushmasdi — odam aytdi, ilova
/// eshitdi va... hech nima qilmadi. Endi eshitilgani ro'yxat filtriga
/// qo'yiladi: nutq yarim tanilgan bo'lsa ham odam ro'yxatdan bir tegishda
/// tanlaydi.
Future<Place?> showPlacePicker(
  BuildContext context, {
  Place? exclude,
  String? initialQuery,
}) {
  return showModalBottomSheet<Place>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        _PlacePickerSheet(exclude: exclude, initialQuery: initialQuery),
  );
}

class _PlacePickerSheet extends ConsumerStatefulWidget {
  const _PlacePickerSheet({this.exclude, this.initialQuery});

  final Place? exclude;
  final String? initialQuery;

  @override
  ConsumerState<_PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends ConsumerState<_PlacePickerSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialQuery ?? '',
  );
  late String _query = widget.initialQuery ?? '';
  bool _districtsOnly = false;

  @override
  void initState() {
    super.initState();
    final prefilled = widget.initialQuery?.trim() ?? '';
    if (prefilled.isEmpty) return;
    // Kursor matn OXIRIDA — odam eshitilganini tuzatadi, boshidan yozmaydi.
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    // Ichki ro'yxatda topilmasa geokoderga ham murojaat qilinsin: aytilgani
    // mahalla yoki orientir nomi bo'lishi mumkin.
    if (prefilled.length >= 3) {
      _debounce = Timer(
        const Duration(milliseconds: 300),
        () => _geoSearch(_query),
      );
    }
  }

  Timer? _debounce;
  List<GeoResult> _geoResults = const [];
  bool _geoLoading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
      _geoResults = const [];
    });

    // Geokoder tashqi xizmat: har harfga so'rov yubormaymiz va faqat ichki
    // ro'yxat bo'sh qolganda chaqiramiz (Nominatim qoidasi — 1 so'rov/soniya).
    _debounce?.cancel();
    if (value.trim().length < 3) return;
    _debounce = Timer(
      const Duration(milliseconds: 600),
      () => _geoSearch(value),
    );
  }

  Future<void> _geoSearch(String value) async {
    if (searchPlaces(value, limit: 1).isNotEmpty) return;

    setState(() => _geoLoading = true);
    final results = await ref.read(geocoderProvider).search(value);
    if (!mounted || value != _query) return;
    setState(() {
      _geoResults = results;
      _geoLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    var places = searchPlaces(
      _query,
      limit: 200,
    ).where((p) => p.name != widget.exclude?.name).toList();
    if (_districtsOnly) {
      places = places.where((p) => p.isDistrict).toList();
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // ⚠️ Tutqich bu yerda CHIZILMAYDI: temada `showDragHandle: true`
          // (izohi `theme.dart` da). Qo'lda chizilgani bilan varaq
          // tepasida IKKITA tutqich turardi (28.09.2026, qurilmada).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _controller,
              // Matn oldindan qo'yilgan bo'lsa kursor OXIRIDA tursin: odam
              // aytilganini tuzatadi, boshidan qayta yozmaydi.
              autofocus: true,
              decoration: InputDecoration(
                hintText: t.searchPlaceHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: t.clearSearch,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                        },
                      ),
              ),
              onChanged: _onQueryChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            /*
             * 🔴 TOR EKRANDA QATOR TOSHIB KETARDI (2026-08-26, sinovда
             * o'lchandi: 360 dp da 197 px toshish).
             *
             * Ilgari bu yerda `Spacer()` turardi va ikkala bola ham O'Z
             * tabiiy kengligini olardi. "Faqat tumanlar" + "Xaritadan
             * tanlash" — ikkalasi ham TARJIMA qilinadigan matn, ruschada
             * esa ular uzunroq. Joy tugaganda `Spacer` NOLGA siqiladi,
             * matn esa qisqarmaydi — natijada "Xaritadan tanlash" tugmasi
             * ekran chetidan chiqib ketardi va uni bosib bo'lmasdi.
             *
             * 🔴 `Flexible` + ellipsis ham YECHIM EMAS edi (28.09.2026,
             * qurilmada, 385 dp): «Xaritadan tanl…» — tugma o'z nomini
             * aytmay qolardi. Endi `Wrap`: joy yetmasa tugma KEYINGI
             * QATORGA tushadi, matn esa hech qachon kesilmaydi.
             */
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpace.sm,
              children: [
                FilterChip(
                  label: Text(t.districtsOnly),
                  selected: _districtsOnly,
                  showCheckmark: false,
                  onSelected: (value) =>
                      setState(() => _districtsOnly = value),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final place = await showLocationPicker(context);
                    if (place != null && context.mounted) {
                      Navigator.of(context).pop(place);
                    }
                  },
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(t.pickOnMap),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Expanded(
            child: places.isEmpty
                ? _geoSection(t, theme, scrollController)
                : ListView.builder(
                    controller: scrollController,
                    itemCount: places.length,
                    itemBuilder: (context, index) {
                      final place = places[index];

                      // Ro'yxatda ~200 joy bor. Qidiruvsiz ochilganda avval
                      // shaharlar, keyin tumanlar keladi — chegarani belgilab
                      // qo'ymasak foydalanuvchi tumanlar ham borligini
                      // umuman bilmaydi.
                      final showHeader =
                          index == 0 ||
                          places[index - 1].isDistrict != place.isDistrict;

                      final tile = ListTile(
                        leading: Icon(
                          place.isDistrict
                              ? Icons.home_work_outlined
                              : Icons.location_city_outlined,
                          color: place.isDistrict
                              ? theme.colorScheme.outline
                              : theme.colorScheme.primary,
                        ),
                        title: Text(place.name),
                        // 🔴 Viloyat nomi shahar nomi bilan BIR XIL bo'lsa
                        // ostki yozuv chiqarilmaydi: "Samarqand / Samarqand"
                        // va "Buxoro / Buxoro" bo'lib turardi (egasi
                        // qurilmada ko'rdi, 2026-08-13). Ma'lumot bermaydigan
                        // qator qatorni uzaytiradi va ro'yxatga kamroq shahar
                        // sig'adi. Toshkent ("Toshkent shahri") kabi haqiqiy
                        // farqi bor joylarda yozuv qoladi.
                        subtitle: place.isDistrict
                            ? Text('${t.districtLabel} · ${place.region}')
                            : (place.region.trim().toLowerCase() ==
                                      place.name.trim().toLowerCase()
                                  ? null
                                  : Text(place.region)),
                        onTap: () => Navigator.of(context).pop(place),
                      );

                      if (!showHeader) return tile;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              index == 0 ? 4 : 16,
                              16,
                              4,
                            ),
                            child: Text(
                              place.isDistrict
                                  ? t.districtsSection
                                  : t.citiesSection,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          tile,
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Ichki ro'yxat bo'sh — geokoder natijalari yoki tushuntirish matni.
  Widget _geoSection(
    AppStrings t,
    ThemeData theme,
    ScrollController scrollController,
  ) {
    if (_geoLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpace.lg),
            Text(t.searchingOnMap, style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    if (_geoResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Text(
            t.placeNotFound,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      );
    }

    return ListView(
      controller: scrollController,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            t.mapResults,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
        for (final result in _geoResults)
          ListTile(
            leading: Icon(
              Icons.place_outlined,
              color: theme.colorScheme.tertiary,
            ),
            title: Text(result.name),
            subtitle: Text(
              result.detail ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => Navigator.of(context).pop(result.toPlace()),
          ),
      ],
    );
  }
}
