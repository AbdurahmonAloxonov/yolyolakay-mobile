import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../map/road_route.dart';
import '../map/route_line.dart';
import '../../core/format.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';
import '../map/map_tiles.dart';

/// Qidiruv natijalari XARITADA — har safar o'z JO'NASH nuqtasida.
///
/// 🔴 NEGA KERAK: bizda uchrashuv nuqtasi hal qiluvchi ahamiyatga ega.
/// Ro'yxatdagi "Chortoq" shaharning qaysi chetidan chiqishini AYTMAYDI —
/// manzil haydovchi yozgan erkin matn ("Chortoq, 3-mavze"). Xaritada esa
/// bu bir qarashda ko'rinadi va odam o'ziga qulayini tanlaydi.
///
/// Belgi MANZILGA emas, JO'NASH nuqtasiga qo'yiladi: yo'lovchi uchun muhimi
/// qayerdan chiqish, chunki manzil allaqachon u so'ragan shahar.
///
/// ⚠️ Koordinatasiz safar TASHLAB YUBORILADI (ro'yxatda esa qoladi): nol
/// nuqtaga qo'yilgan belgi xaritani okean o'rtasiga sudrab ketardi.
class ResultsMap extends ConsumerStatefulWidget {
  const ResultsMap({
    super.key,
    required this.rides,
    required this.onTapRide,
    this.selectedRideId,
    this.showAttribution = true,
  });

  final List<Ride> rides;
  final void Function(Ride ride) onTapRide;

  /// Ro'yxatda ochib turilgan safar — uning belgisi ajratib ko'rsatiladi.
  ///
  /// Busiz xaritada o'nta bir xil belgi turadi va odam qaysi birini
  /// bosganini unutadi (belgi bosilgach ro'yxat harakatlanadi, xarita esa
  /// o'sha-o'sha qoladi).
  final String? selectedRideId;

  /// OSM havolasi. Xarita to'liq ekranni egallaganda (ustidan varaq
  /// chiqadigan rejim) havola varaq ostida ko'rinmay qoladi — u holda
  /// chaqiruvchi uni O'ZI, ko'rinadigan joyga qo'yadi.
  final bool showAttribution;

  @override
  ConsumerState<ResultsMap> createState() => _ResultsMapState();
}

class _ResultsMapState extends ConsumerState<ResultsMap> {
  /*
   * TANLANGAN SAFARNING YO'LI.
   *
   * 🔴 NEGA QO'SHILDI (egasi, 2026-09-08): xaritada faqat jo'nash
   * nuqtalari turardi — o'nta nuqta, orasida hech qanday bog'liqlik
   * yo'q. Yo'lovchining eng ko'p beradigan savoli esa boshqa:
   * «MEN YO'L USTIDAN qo'shila olamanmi?». Ro'yxat ham, nuqtalar ham
   * bunga javob bermasdi.
   *
   * Endi safar tanlansa uning YO'LI chiziladi va oraliq shaharlar
   * belgilanadi — «Jizzaxdan qo'shilsa bo'ladi» degan javob
   * ko'rinadigan bo'ladi.
   *
   * ⚠️ FAQAT TANLANGANDA yuklanadi: o'nta safar yo'lini birdan
   * chizsak, xarita chigal bo'lib qoladi va har biri uchun tarmoq
   * so'rovi ketardi.
   */
  String? _routeFor;
  RoadRoute? _route;

  /*
   * ⚠️ KAMERA TANLANGAN SAFARGA MOSLASHADI.
   *
   * 🔴 Busiz oraliq shaharlar EKRANDAN TASHQARIDA qolardi: boshlang'ich
   * kamera faqat jo'nash nuqtalariga moslashadi, ular esa odatda bitta
   * shaharda (Toshkent). Ya'ni yozuv «Jizzaxdan qo'shilish mumkin»
   * deydi-yu, Jizzax ko'rinmaydi. Buni sinov ushladi.
   */
  final _map = MapController();

  @override
  void didUpdateWidget(covariant ResultsMap old) {
    super.didUpdateWidget(old);
    if (widget.selectedRideId != old.selectedRideId) _loadRoute();
  }

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Ride? get _selected {
    final id = widget.selectedRideId;
    if (id == null) return null;
    for (final r in widget.rides) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<void> _loadRoute() async {
    final ride = _selected;
    if (ride == null) {
      if (_route != null) setState(() { _route = null; _routeFor = null; });
      return;
    }
    if (_routeFor == ride.id) return;
    _routeFor = ride.id;

    /*
     * KAMERA DARHOL moslashadi — yo'l chizig'ini KUTMASDAN.
     *
     * 🔴 Ilgari u faqat marshrut yuklangach chaqirilardi, ya'ni tarmoq
     * sekin bo'lsa (yoki umuman yo'q bo'lsa — sinov muhitida shunday)
     * oraliq shahar ekrandan tashqarida qolaverardi. Yo'l chizig'i —
     * bezak, kadrni to'g'rilash esa ASOSIY ish.
     */
    _fitToRide(ride);

    final waypoints = [
      LatLng(ride.originLat, ride.originLon),
      for (final s in ride.stops) LatLng(s.lat, s.lon),
      LatLng(ride.destinationLat, ride.destinationLon),
    ];
    try {
      final route = await fetchRoadRoute(
        waypoints,
        dio: ref.read(apiClientProvider).dio,
      );
      if (mounted && _routeFor == ride.id) setState(() => _route = route);
    } catch (_) {
      // Yo'l chizilmasa xarita ishlayveradi — bu bezak emas, lekin
      // uning yo'qligi hech nimani buzmaydi.
    }
  }

  /// Tanlangan safarning BUTUN yo'li kadrga sig'sin.
  ///
  /// [now] — xarita TAYYOR ekani aniq bo'lganda (`onMapReady`):
  /// o'shanda kadr kutilmaydi. Boshqa holatda `fitCamera` xarita
  /// o'lchamga ega bo'lgunicha jimgina tashlaydi.
  void _fitToRide(Ride ride, {bool now = false}) {
    final points = <LatLng>[
      LatLng(ride.originLat, ride.originLon),
      for (final s in ride.stops) LatLng(s.lat, s.lon),
      if (ride.destinationLat != 0 || ride.destinationLon != 0)
        LatLng(ride.destinationLat, ride.destinationLon),
    ];
    // Bir xil nuqtalarda `CameraFit` cheksiz zoom hisoblab yiqiladi
    // (izohi pastda) — shuning uchun turli nuqtalar SHART.
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
            // Tepadan ko'proq — yuqoridagi izoh.
            padding: const EdgeInsets.fromLTRB(
              AppSpace.huge + AppSpace.md,
              AppSpace.huge * 2,
              AppSpace.huge + AppSpace.md,
              AppSpace.huge,
            ),
          ),
        );
      } catch (_) {
        // Xarita hali chizilmagan bo'lsa — `onMapReady` dan keyingi
        // kadrda baribir moslashadi (pastdagi izoh).
      }
    }

    if (now) {
      fit();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => fit());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final rides = widget.rides;
    final selectedRideId = widget.selectedRideId;
    final onTapRide = widget.onTapRide;
    final showAttribution = widget.showAttribution;

    final shown = [
      for (final ride in rides)
        if (ride.originLat != 0 || ride.originLon != 0) ride,
    ];
    if (shown.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Text(
            t.noMapPoints,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      );
    }

    /*
     * Kadrga sig'ishi kerak bo'lgan nuqtalar.
     *
     * 🔴 TANLANGAN safarning ORALIQ shaharlari ham shu yerda: aks
     * holda «Jizzaxdan qo'shilish mumkin» degan yozuv turadi-yu,
     * Jizzaxning o'zi kadrdan tashqarida qoladi. Ekran ochilishida
     * safar allaqachon tanlangan bo'lishi mumkin (ro'yxatdan
     * qaytganda), shuning uchun BOSHLANG'ICH kadr ham buni bilishi
     * kerak — keyingi tanlashlarni `_fitToRide` moslashtiradi.
     */
    final selectedRide = _selected;
    final points = [
      for (final ride in shown) LatLng(ride.originLat, ride.originLon),
      if (selectedRide != null) ...[
        for (final stop in selectedRide.stops) LatLng(stop.lat, stop.lon),
        if (selectedRide.destinationLat != 0 || selectedRide.destinationLon != 0)
          LatLng(selectedRide.destinationLat, selectedRide.destinationLon),
      ],
    ];

    /*
     * 🔴 BIR XIL NUQTALAR XARITANI YIQITARDI (2026-08-24, sinovda topildi):
     * `CameraFit.coordinates` nol yuzali chegarada `zoom` ni cheksiz qilib
     * hisoblaydi va ilova "Camera `zoom` must be finite" bilan tashlaydi.
     *
     * Bu FARAZIY holat emas, eng ko'p uchraydigani: shahar nomidan tanlangan
     * jo'nash nuqtasi kanonik ro'yxatdan keladi (`cities.dart`), ya'ni
     * Toshkentdan chiqadigan hamma e'lon AYNAN bir xil koordinataga ega.
     * Ikkita shunday e'lon topilsa xarita qizil ekran bilan yiqilardi.
     *
     * Shuning uchun chegara faqat HAQIQATAN turli nuqtalar bo'lganda
     * hisoblanadi; aks holda oddiy markaz + zoom.
     */
    final distinct = points
        .map((p) => '${p.latitude},${p.longitude}')
        .toSet()
        .length;

    final stops = _selected?.stops ?? const [];

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
            options: MapOptions(
              // Bitta (yoki bir xil) nuqta bo'lsa `CameraFit` chegara yasay
              // olmaydi — shu holatda oddiy markaz + zoom beriladi.
              /*
               * ⚠️ CHEKKA BELGI O'LCHAMIDAN KATTA bo'lishi shart.
               *
               * Narx belgisi 96 px keng va nuqtaning USTIDA chiziladi,
               * ya'ni chekka 48 px dan kam bo'lsa belgi ekrandan
               * qirqiladi. Tepada bundan tashqari «yo'l ustidan»
               * yozuvi turadi — u yerda yana ko'proq joy kerak.
               * Ikkalasi ham rasm chizib ko'rilganda topildi.
               */
              initialCameraFit: distinct > 1
                  ? CameraFit.coordinates(
                      coordinates: points,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.huge + AppSpace.md,
                        AppSpace.huge * 2,
                        AppSpace.huge + AppSpace.md,
                        AppSpace.huge,
                      ),
                    )
                  : null,
              initialCenter: points.first,
              initialZoom: 12,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              /*
               * ⚠️ `onMapReady` SHART: xarita o'lchamga ega bo'lgunча
               * `fitCamera` ishlamaydi (jimgina tashlaydi). Ekran
               * ochilganda safar ALLAQACHON tanlangan bo'lishi mumkin
               * — o'shanda oraliq shahar kadrdan tashqarida qolardi.
               */
              /*
               * ⚠️ `onMapReady` NING O'ZI YETMAYDI: o'sha paytda ham
               * `MapController` «FlutterMap kamida bir marta
               * chizilishi kerak» deb tashlaydi (o'lchandi). Shuning
               * uchun KEYINGI kadrda moslashtiramiz.
               */
              onMapReady: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final ride = _selected;
                  if (ride != null) _fitToRide(ride, now: true);
                });
              },
            ),
            children: [
              const MapTiles(),
              // YO'L — tanlangan safarning marshruti. Belgilardan
              // OLDIN chiziladi: chiziq belgilarni bosmasin.
              // Haqiqiy yo'l — yaxlit; kelmagan bo'lsa UZUQ taxminiy chiziq
              // (qoidasi `route_line.dart` da).
              if (_route != null)
                PolylineLayer(
                  polylines: routePolylines(
                    straight: _route!.points,
                    route: _route,
                    color: theme.colorScheme.primary,
                    width: 5,
                  ),
                ),
              // ORALIQ SHAHARLAR — «yo'l ustidan qo'shilish» nuqtalari.
              if (_selected != null && _selected!.stops.isNotEmpty)
                MarkerLayer(
                  markers: [
                    for (final stop in _selected!.stops)
                      Marker(
                        point: LatLng(stop.lat, stop.lon),
                        width: 120,
                        height: 30,
                        alignment: Alignment.topCenter,
                        child: _StopMarker(label: stop.address),
                      ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  for (final ride in shown)
                    Marker(
                      point: LatLng(ride.originLat, ride.originLon),
                      width: 96,
                      height: 34,
                      alignment: Alignment.topCenter,
                      child: _PriceMarker(
                        label: '${formatPrice(ride.pricePerSeat)} ${t.sum}',
                        selected: ride.id == selectedRideId,
                        onTap: () => onTapRide(ride),
                      ),
                    ),
                ],
              ),
            ],
              ),
              // YOZUV — belgilar nima ekanini aytadi. Usiz xaritada
              // ikkita begona nuqta turadi va odam ularni tushunmaydi.
              if (stops.isNotEmpty)
                Positioned(
                  left: AppSpace.md,
                  right: AppSpace.md,
                  top: AppSpace.md,
                  child: _AlongRouteHint(
                    text: t.joinAlongRoute(
                      stops
                          .map((s) => s.address.split(',').first.trim())
                          .join(', '),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showAttribution) const OsmAttribution(),
      ],
    );
  }
}

/// Xarita ustidagi bir qatorlik izoh.
class _AlongRouteHint extends StatelessWidget {
  const _AlongRouteHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Narx yozilgan belgi — bosilsa safar ochiladi.
///
/// Narx ATAYIN belgining O'ZIDA: xaritada o'nta bir xil nuqta orasidan
/// tanlash mumkin emas, narx esa odam qidirayotgan yagona raqam.
class _PriceMarker extends StatelessWidget {
  const _PriceMarker({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;

  /// Tanlangan belgi TO'Q rangda va kattaroq — o'nta bir xil belgi
  /// orasidan "men shuni bosgandim" ni ajratadi.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
            color: selected ? scheme.onSurface : scheme.primary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: selected ? scheme.surface : scheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// ORALIQ SHAHAR — «yo'l ustidan qo'shilish mumkin» nuqtasi.
///
/// 🔑 Narx belgisidan SHAKLI bilan farq qiladi, rangi bilan emas:
/// xaritada fon rangi har joyda boshqacha va faqat rangga tayanish
/// ishonchsiz. Bu — kichik, yumaloq va nom bilan.
class _StopMarker extends StatelessWidget {
  const _StopMarker({required this.label});

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
              // Manzil erkin matn: vergulgacha bo'lgan qism — shahar nomi.
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
