import 'package:flutter/material.dart';

import '../../app/dimens.dart';
import '../../core/cities.dart';
import '../../data/models/parcel.dart';
import '../../l10n/strings.dart';
import '../map/map_tiles.dart';
import 'parcel_card.dart';
import 'parcels_map.dart';

/// XARITA-BIRINCHI posilka ro'yxati (haydovchi).
///
/// Safar qidiruvidagi `MapFirstResults` bilan AYNAN bir xil odat: xarita
/// to'liq ekran, ro'yxat pastdan uch bosqichda sudralib chiqadi, xaritadagi
/// belgi bosilsa o'sha posilka ro'yxatning boshiga chiqadi. Ikkala bo'lim
/// bir xil ishlasin — haydovchi safar qidirishni allaqachon biladi.
///
/// 🔴 NEGA ALOHIDA EKRAN, TABDAGI XARITA EMAS: qidiruv formasi (shahar,
/// radius slayderi) tabning tepasida turadi va uning ostiga xarita qo'ysak,
/// xarita barmoq harakatini o'ziga olib ro'yxatni sudrab bo'lmay qolardi.
/// To'liq ekranda bunday ziddiyat yo'q.
Future<void> showParcelsMap(
  BuildContext context, {
  required List<Parcel> parcels,
  required Place? center,
  required double radiusKm,
  required Future<void> Function(Parcel parcel) onOffer,
}) {
  // `rootNavigator` — aks holda ekran pastki navigatsiya SHELLI ichida
  // ochiladi va xarita ustida "Qidirish/Safarlarim/..." tugmalari qolib
  // ketadi (izohi `pick_location_screen.dart` da).
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      builder: (_) => ParcelsMapScreen(
        parcels: parcels,
        center: center,
        radiusKm: radiusKm,
        onOffer: onOffer,
      ),
    ),
  );
}

class ParcelsMapScreen extends StatefulWidget {
  const ParcelsMapScreen({
    super.key,
    required this.parcels,
    required this.center,
    required this.radiusKm,
    required this.onOffer,
  });

  final List<Parcel> parcels;
  final Place? center;
  final double radiusKm;
  final Future<void> Function(Parcel parcel) onOffer;

  @override
  State<ParcelsMapScreen> createState() => _ParcelsMapScreenState();
}

class _ParcelsMapScreenState extends State<ParcelsMapScreen> {
  final _sheet = DraggableScrollableController();
  String? _selectedId;

  static const _peek = 0.22;
  static const _half = 0.5;
  static const _full = 0.92;

  @override
  void dispose() {
    _sheet.dispose();
    super.dispose();
  }

  void _select(Parcel parcel) {
    setState(() => _selectedId = parcel.id);
    // Belgi bosilganda ro'yxat O'ZI ochiladi: aks holda odam belgini
    // bosadi, hech nima "o'zgarmaydi" va u ikkinchi marta bosadi.
    if (_sheet.isAttached && _sheet.size < _half) {
      _sheet.animateTo(
        _half,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Tanlangan posilka BIRINCHI — qolgan tartib buzilmaydi.
  List<Parcel> get _ordered {
    final id = _selectedId;
    if (id == null) return widget.parcels;
    final index = widget.parcels.indexWhere((p) => p.id == id);
    if (index <= 0) return widget.parcels;
    return [widget.parcels[index], ...widget.parcels.where((p) => p.id != id)];
  }

  /// Taklif berilgach xarita YOPILADI.
  ///
  /// 🔑 Bu ekran ro'yxatning NUSXASINI ushlab turadi: taklif yuborilgach
  /// posilka "band" bo'ladi, lekin bu yerdagi nusxa buni bilmaydi. Qidiruv
  /// ekraniga qaytish esa uni YANGILAB ko'rsatadi (`_respond` o'zi qayta
  /// qidiradi) — ya'ni eskirgan xaritada qolib ketmaymiz.
  Future<void> _offer(Parcel parcel) async {
    final navigator = Navigator.of(context);
    await widget.onOffer(parcel);
    if (mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ordered = _ordered;

    return Scaffold(
      appBar: AppBar(title: Text(t.parcelsOnMap)),
      body: Stack(
        children: [
          Positioned.fill(
            child: ParcelsMap(
              parcels: widget.parcels,
              center: widget.center,
              radiusKm: widget.radiusKm,
              selectedParcelId: _selectedId,
              onTapParcel: _select,
              // Havola varaq ostida qolib ketardi — u pastda, tutqich
              // ustida ko'rsatiladi.
              showAttribution: false,
            ),
          ),
          DraggableScrollableSheet(
            controller: _sheet,
            initialChildSize: _peek,
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
                          // Tutqich — varaqni sudrash mumkinligining
                          // yagona ko'rinadigan belgisi.
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
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.lg,
                            ),
                            child: Text(
                              t.parcelsFound(widget.parcels.length),
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.lg,
                        AppSpace.md,
                        AppSpace.lg,
                        AppSpace.xl,
                      ),
                      sliver: SliverList.separated(
                        itemCount: ordered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpace.md),
                        itemBuilder: (context, index) {
                          final parcel = ordered[index];
                          return ParcelCard(
                            parcel: parcel,
                            onOffer: () => _offer(parcel),
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
        ],
      ),
    );
  }
}
