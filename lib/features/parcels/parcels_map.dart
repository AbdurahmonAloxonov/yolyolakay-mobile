import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../core/cities.dart';
import '../../core/format.dart';
import '../../data/models/parcel.dart';
import '../../l10n/strings.dart';
import '../map/map_tiles.dart';
import '../map/road_route.dart';
import '../map/route_line.dart';

/// POSILKALAR XARITADA — haydovchi uchun.
///
/// 🔴 NEGA KERAK BO'LDI (16.09.2026 o'lchovi): pochta bo'limida xarita
/// UMUMAN yo'q edi, holbuki `Parcel` da to'rtta koordinata bor va qidiruv
/// `lat + lon + radius_km` bilan ishlaydi. Ya'ni haydovchi RADIUS
/// qidiruvini xaritasiz o'tkazardi: «25 km» degan raqam nimani qamrab
/// olishini ko'rmasdi, topilgan posilkalar esa oddiy ro'yxat edi.
///
/// Haydovchining haqiqiy savoli ro'yxatda javobsiz qolardi: «bu posilka
/// MENING YO'LIMGA tushadimi?» — buni faqat xarita ko'rsatadi.
///
/// Belgi OLIB KETISH nuqtasiga qo'yiladi (safar xaritasida ham shunday:
/// muhimi qayerdan olish, chunki borish manzili natijaning o'zida yozilgan).
/// Posilka tanlansa — uning YO'LI chiziladi va yetkazish nuqtasi ko'rinadi.
class ParcelsMap extends ConsumerStatefulWidget {
  const ParcelsMap({
    super.key,
    required this.parcels,
    required this.onTapParcel,
    this.center,
    this.radiusKm,
    this.selectedParcelId,
    this.showAttribution = true,
  });

  final List<Parcel> parcels;
  final void Function(Parcel parcel) onTapParcel;

  /// Qidiruv markazi — haydovchi tanlagan joy.
  final Place? center;

  /// Qidiruv radiusi. Xaritada DOIRA bo'lib chiziladi: «25 km» degan
  /// raqamning aslida qayergacha yetishi shu bilan ko'rinadi.
  final double? radiusKm;

  final String? selectedParcelId;
  final bool showAttribution;

  @override
  ConsumerState<ParcelsMap> createState() => _ParcelsMapState();
}

class _ParcelsMapState extends ConsumerState<ParcelsMap> {
  final _map = MapController();

  String? _routeFor;
  RoadRoute? _route;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void didUpdateWidget(covariant ParcelsMap old) {
    super.didUpdateWidget(old);
    if (widget.selectedParcelId != old.selectedParcelId) _loadRoute();
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  Parcel? get _selected {
    final id = widget.selectedParcelId;
    if (id == null) return null;
    for (final p in widget.parcels) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Tanlangan posilkaning yo'li. FAQAT tanlanganda yuklanadi — o'nta
  /// posilkaning yo'lini birdan chizsak xarita chigal bo'lib qoladi va
  /// har biri uchun alohida tarmoq so'rovi ketardi (`results_map` bilan
  /// bir xil qaror).
  Future<void> _loadRoute() async {
    final parcel = _selected;
    if (parcel == null) {
      if (_route != null) {
        setState(() {
          _route = null;
          _routeFor = null;
        });
      }
      return;
    }
    if (_routeFor == parcel.id) return;
    _routeFor = parcel.id;

    // Kadr DARHOL moslashadi — yo'l chizig'ini kutmasdan (izohi
    // `results_map.dart` da: chiziq bezak, kadr esa asosiy ish).
    _fitTo(parcel);

    try {
      final route = await fetchRoadRoute([
        LatLng(parcel.originLat, parcel.originLon),
        LatLng(parcel.destinationLat, parcel.destinationLon),
      ], dio: ref.read(apiClientProvider).dio);
      if (mounted && _routeFor == parcel.id) setState(() => _route = route);
    } catch (_) {
      // Yo'l chizig'i — ixtiyoriy: `apiClientProvider` ni o'qish tarmoq
      // qatlami yo'q muhitda tashlaydi va u butun xaritani chizilmay
      // qoldirardi (izohi `route_preview_map.dart` da).
    }
  }

  void _fitTo(Parcel parcel, {bool now = false}) {
    final points = <LatLng>[
      LatLng(parcel.originLat, parcel.originLon),
      LatLng(parcel.destinationLat, parcel.destinationLon),
    ];
    final distinct = points
        .map((p) => '${p.latitude},${p.longitude}')
        .toSet()
        .length;
    if (distinct < 2) return;

    void fit() {
      if (!mounted) return;
      try {
        _map.fitCamera(
          CameraFit.coordinates(
            coordinates: points,
            padding: const EdgeInsets.fromLTRB(
              AppSpace.huge,
              AppSpace.huge * 2,
              AppSpace.huge,
              AppSpace.huge,
            ),
          ),
        );
      } catch (_) {
        // Xarita hali o'lchamga ega emas — keyingi kadrda moslashadi.
      }
    }

    if (now) {
      fit();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => fit());
    }
  }

  /// Koordinatasi bor posilkalar. Nol nuqtali yozuv xaritani okean
  /// o'rtasiga sudrab ketardi (safar xaritasida ham shu qoida).
  List<Parcel> get _shown => [
    for (final p in widget.parcels)
      if (p.originLat != 0 || p.originLon != 0) p,
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shown = _shown;
    final center = widget.center;

    if (shown.isEmpty && center == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Text(
            t.noMapPoints,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.outline),
          ),
        ),
      );
    }

    final selected = _selected;
    final points = <LatLng>[
      for (final p in shown) LatLng(p.originLat, p.originLon),
      if (center != null) LatLng(center.lat, center.lon),
      if (selected != null &&
          (selected.destinationLat != 0 || selected.destinationLon != 0))
        LatLng(selected.destinationLat, selected.destinationLon),
    ];
    final distinct = points
        .map((p) => '${p.latitude},${p.longitude}')
        .toSet()
        .length;

    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCameraFit: distinct > 1
                  ? CameraFit.coordinates(
                      coordinates: points,
                      // Chekka BELGI o'lchamidan katta bo'lishi shart:
                      // narx belgisi nuqtaning ustida chiziladi va tor
                      // chekkada ekrandan qirqilardi.
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.huge,
                        AppSpace.huge * 2,
                        AppSpace.huge,
                        AppSpace.huge,
                      ),
                    )
                  : null,
              initialCenter: points.first,
              initialZoom: 11,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final parcel = _selected;
                  if (parcel != null) _fitTo(parcel, now: true);
                });
              },
            ),
            children: [
              const MapTiles(),
              // QIDIRUV DOIRASI — «radius 25 km» raqamining ko'rinishi.
              if (center != null && widget.radiusKm != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(center.lat, center.lon),
                      radius: widget.radiusKm! * 1000,
                      useRadiusInMeter: true,
                      color: scheme.primary.withValues(alpha: 0.08),
                      borderColor: scheme.primary.withValues(alpha: 0.45),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              // Haqiqiy yo'l — yaxlit; kelmagan bo'lsa UZUQ taxminiy chiziq
              // (qoidasi `route_line.dart` da).
              if (_route != null)
                PolylineLayer(
                  polylines: routePolylines(
                    straight: _route!.points,
                    route: _route,
                    color: scheme.primary,
                    width: 5,
                  ),
                ),
              // YETKAZISH nuqtasi — faqat tanlangan posilkada. Hammasini
              // birdan chizsak xaritada ikki barobar ko'p belgi bo'lardi
              // va qaysi nuqta qaysi posilkaniki ekani bilinmasdi.
              if (selected != null &&
                  (selected.destinationLat != 0 ||
                      selected.destinationLon != 0))
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        selected.destinationLat,
                        selected.destinationLon,
                      ),
                      width: 130,
                      height: 30,
                      alignment: Alignment.topCenter,
                      child: _DestMarker(
                        label: placeLabel(
                          selected.toAddress,
                          selected.destinationLat,
                          selected.destinationLon,
                        ),
                      ),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  for (final parcel in shown)
                    Marker(
                      point: LatLng(parcel.originLat, parcel.originLon),
                      width: 104,
                      height: 34,
                      alignment: Alignment.topCenter,
                      child: _ParcelMarker(
                        label: parcel.price == null
                            ? t.parcelSizeLabel(parcel.size ?? 'small')
                            : '${formatPrice(parcel.price!)} ${t.sum}',
                        selected: parcel.id == widget.selectedParcelId,
                        taken: parcel.isTaken,
                        onTap: () => widget.onTapParcel(parcel),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (widget.showAttribution) const OsmAttribution(),
      ],
    );
  }
}

/// OLIB KETISH nuqtasi — quti ikonkasi + narx.
///
/// 🔑 Safar xaritasidagi narx belgisidan SHAKLI bilan farq qiladi (ikonka
/// bor), rangi bilan emas: xaritada fon rangi har joyda boshqacha va faqat
/// rangga tayanish ishonchsiz.
class _ParcelMarker extends StatelessWidget {
  const _ParcelMarker({
    required this.label,
    required this.onTap,
    required this.selected,
    required this.taken,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  /// Olib ketilgan posilka — SO'NIQ. Ilgari ro'yxatda tugma o'chib
  /// turardi-yu, xaritada bunday farq bo'lmasa haydovchi band posilkani
  /// bosib, faqat o'shanda band ekanini bilardi.
  final bool taken;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = taken
        ? scheme.surfaceContainerHighest
        : (selected ? scheme.onSurface : scheme.primary);
    final foreground = taken
        ? scheme.outline
        : (selected ? scheme.surface : scheme.onPrimary);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.12 : 1,
        duration: const Duration(milliseconds: 160),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 13, color: foreground),
              const SizedBox(width: AppSpace.xxs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// YETKAZISH nuqtasi — nomi bilan.
class _DestMarker extends StatelessWidget {
  const _DestMarker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: scheme.secondary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        const SizedBox(width: AppSpace.xs),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(AppRadius.badge),
            ),
            child: Text(
              label.split(',').first.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
