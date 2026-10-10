import 'package:flutter/material.dart';

import '../../app/dimens.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';
import '../map/map_tiles.dart';
import 'results_map.dart';

/// XARITA-BIRINCHI natijalar: xarita DOIM ko'rinadi, ro'yxat uning USTIGA
/// sudralib chiqadi.
///
/// 🔴 NEGA O'ZGARDI (2026-08-24 auditi): ilgari xarita va ro'yxat bir-birini
/// ALMASHTIRARDI. Odam ro'yxatda narxni ko'rardi, xaritaga o'tib joyni
/// ko'rardi, keyin narxni unutib yana ro'yxatga qaytardi. Ikkalasi bir vaqtda
/// kerak bo'lgan yagona savol — "menga qulay joydan chiqadigan eng arzoni
/// qaysi?" — hech qachon bitta ekranda javob olmasdi.
///
/// Endi: xarita to'liq ekran, ro'yxat pastdan uch bosqichda ochiladi
/// (ko'rinib turadi → yarim → to'liq). Xaritadagi belgi bosilsa o'sha safar
/// ro'yxatning BOSHIGA chiqadi va belgisi to'q rangga o'tadi — "men shuni
/// bosgandim" savoli qolmaydi.
///
/// ⚠️ Ro'yxat qayta TARTIBLANADI, nusxalanmaydi: tanlangan karta ikki joyda
/// turgani odamni chalkashtirardi ("ikkita bir xil safar bormi?").
class MapFirstResults extends StatefulWidget {
  const MapFirstResults({
    super.key,
    required this.rides,
    required this.itemBuilder,
    required this.onTapRide,
    this.header,
  });

  final List<Ride> rides;

  /// Kartani chizish EKRANDAN keladi: masofa, median narx va yo'l
  /// davomiyligi u yerda hisoblangan — bu vidjet ularni qayta hisoblab
  /// ikkinchi manba yaratmasligi kerak.
  final Widget Function(BuildContext context, Ride ride, bool selected)
  itemBuilder;

  final void Function(Ride ride) onTapRide;

  /// Varaqning tepasidagi qator (natija soni, median narx).
  final Widget? header;

  @override
  State<MapFirstResults> createState() => _MapFirstResultsState();
}

class _MapFirstResultsState extends State<MapFirstResults> {
  final _sheet = DraggableScrollableController();

  String? _selectedId;

  /// Uch bosqich. `_peek` da faqat tutqich va bir karta chekkasi ko'rinadi —
  /// xarita deyarli to'liq ochiq qoladi, lekin ro'yxat borligi bilinib
  /// turadi (butunlay yashirilса odam uni topa olmaydi).
  static const _peek = 0.22;
  static const _half = 0.5;
  static const _full = 0.92;

  @override
  void dispose() {
    _sheet.dispose();
    super.dispose();
  }

  void _select(Ride ride) {
    setState(() => _selectedId = ride.id);
    // Belgi bosilganda ro'yxat O'ZI ochiladi: aks holda odam belgini bosadi,
    // hech nima "o'zgarmaydi" (karta pastda, ko'rinmaydigan joyda qoladi)
    // va u ikkinchi marta bosadi.
    if (_sheet.isAttached && _sheet.size < _half) {
      _sheet.animateTo(
        _half,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Tanlangan safar BIRINCHI. Qolgan tartib (saralash) buzilmaydi.
  List<Ride> get _ordered {
    final id = _selectedId;
    if (id == null) return widget.rides;
    final index = widget.rides.indexWhere((r) => r.id == id);
    if (index <= 0) return widget.rides;
    return [widget.rides[index], ...widget.rides.where((r) => r.id != id)];
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ordered = _ordered;

    return Stack(
      children: [
        Positioned.fill(
          child: ResultsMap(
            rides: widget.rides,
            selectedRideId: _selectedId,
            onTapRide: _select,
            // Havola varaq ostida qolib ketardi — u pastda, tutqich
            // ustida ko'rsatiladi.
            showAttribution: false,
          ),
        ),
        DraggableScrollableSheet(
          controller: _sheet,
          initialChildSize: _half,
          minChildSize: _peek,
          maxChildSize: _full,
          snap: true,
          snapSizes: const [_peek, _half, _full],
          builder: (context, scrollController) => DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet),
              ),
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // Tutqich — varaqni sudrash mumkinligining yagona
                        // ko'rinadigan belgisi.
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpace.md,
                          ),
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: scheme.outlineVariant,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                          ),
                        ),
                        if (widget.header != null) widget.header!,
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.lg,
                      AppSpace.sm,
                      AppSpace.lg,
                      AppSpace.xl,
                    ),
                    sliver: SliverList.separated(
                      itemCount: ordered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpace.md),
                      itemBuilder: (context, index) {
                        final ride = ordered[index];
                        return widget.itemBuilder(
                          context,
                          ride,
                          ride.id == _selectedId,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // OSM havolasi — varaqning eng past holatidan ham TEPADA tursin,
        // aks holda litsenziya talabi bajarilmaydi (ko'rinmasa yo'q bilan
        // barobar).
        Positioned(
          left: 0,
          right: 0,
          bottom: MediaQuery.sizeOf(context).height * _peek,
          child: const IgnorePointer(child: OsmAttribution()),
        ),
        if (widget.rides.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.xl),
              child: Text(t.noMapPoints, textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }
}
