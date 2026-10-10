import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import 'map_tiles.dart';
import 'road_route.dart';
import 'route_decor.dart';
import 'route_line.dart';

/// TINCH MARSHRUT KO'RINISHI — karta ichida turadigan kichik xarita.
///
/// 🔴 NEGA KERAK BO'LDI (egasi, 16.09.2026: «karta to'liq ishlatilsin»).
/// Ilovada xarita BOR edi, lekin u HAR DOIM tugma ortida yashiringan:
/// safar detalida «Xaritada ko'rish» bosilsa varaq ochilardi, posilkada
/// esa umuman yo'q edi. Ya'ni odam yo'nalishni ko'rish uchun QAROR
/// qilishi kerak edi — «xaritani ochishga arziydimi?». Yandex Go'da
/// bunday savol yo'q: xarita ekranning O'ZI, u yerda turadi.
///
/// Bu vidjet o'rtadagi yo'l: xarita DOIM ko'rinadi, lekin kichik va
/// TINCH — u bilan o'ynab bo'lmaydi (`InteractiveFlag.none`), chunki
/// karta ichidagi surilaydigan xarita ro'yxatni sudrab ketardi. Bosilsa
/// [onTap] to'liq xaritani ochadi.
///
/// ⚠️ PLITKA NARXI: har ko'rinish ~4–8 plitka so'raydi. Shuning uchun u
/// RO'YXAT ELEMENTIGA QO'YILMAYDI (o'nta karta = o'nta xarita), faqat
/// BITTA narsa ko'rsatilayotgan ekranda: safar detali, posilka detali,
/// posilka yaratish ko'rigi.
class RoutePreviewMap extends ConsumerStatefulWidget {
  const RoutePreviewMap({
    super.key,
    required this.waypoints,
    this.height = 160,
    this.onTap,
    this.label,
    this.originName,
    this.destinationName,
  });

  /// Uchlarning nomi (manzil matni — qisqartiriladi). Berilsa uchlar
  /// yorliq bilan chiziladi (izohi `route_decor.dart` da).
  final String? originName;
  final String? destinationName;

  /// Jo'nash → (oraliq bekatlar) → manzil. Ikkitadan kam bo'lsa vidjet
  /// hech narsa chizmaydi (`SizedBox.shrink`).
  final List<LatLng> waypoints;

  final double height;

  /// Bosilganda — odatda to'liq xarita varag'i. `null` bo'lsa xarita
  /// bosilmaydigan rasm bo'lib qoladi.
  final VoidCallback? onTap;

  /// Xarita ustidagi kichik yozuv («Xaritada ko'rish»). Bosish mumkin
  /// ekanini KO'RSATADI — `onTap` bor-u yozuv yo'q bo'lsa, xarita oddiy
  /// rasmdek ko'rinadi va hech kim bosmaydi.
  final String? label;

  @override
  ConsumerState<RoutePreviewMap> createState() => _RoutePreviewMapState();
}

class _RoutePreviewMapState extends ConsumerState<RoutePreviewMap> {
  // Keshda bo'lsa birinchi kadrdayoq haqiqiy yo'l (izohi `road_route.dart`).
  late RoadRoute? _route = cachedRoadRoute(widget.waypoints);

  /*
   * 🔴 KADR YO'LNI KO'RMASDI (28.09.2026, egasi qurilmasida ko'rildi:
   * Samarqand → Buxoro). Kamera faqat SHAHAR nuqtalariga moslanardi,
   * haqiqiy yo'l esa ulardan chetga — Qashqadaryo tomonga — egilib
   * o'tadi va kartaning pastki chetida KESILIB qolardi. Endi yo'l kelishi
   * bilan kadr yo'lning butun chizig'iga qayta moslanadi.
   */
  final MapController _map = MapController();
  bool _mapReady = false;

  List<LatLng> get _frame => [
    ...widget.waypoints,
    if (_route?.isRealRoad ?? false) ..._route!.points,
  ];

  bool get _named => widget.originName != null || widget.destinationName != null;

  // Nom yorlig'i nuqtaning USTIDA va markazlashgan — yondagi va tepadagi
  // shahar nomi kartaning chetidan chiqib ketmasin (28.09.2026, rasmda
  // «Samarqand» yarmi kesilgani ko'rildi).
  EdgeInsets get _padding => EdgeInsets.fromLTRB(
    _named ? AppSpace.xl + 44 : AppSpace.xl,
    _named ? AppSpace.xl + 24 : AppSpace.xl,
    _named ? AppSpace.xl + 44 : AppSpace.xl,
    // 🔴 PASTDA YOZUV UCHUN JOY (28.09.2026, rasmda ko'rildi):
    // «Xaritada ko'rish» chipi chap-pastki burchakda turadi va
    // janubi-g'arbdagi manzil (Toshkent → Samarqand) AYNAN uning
    // ostiga tushib, ko'rinmay qolardi.
    widget.label == null ? AppSpace.xl : AppSpace.xl + 44,
  );

  void _refit() {
    if (!_mapReady || !mounted) return;
    try {
      _map.fitCamera(
        CameraFit.coordinates(coordinates: _frame, padding: _padding),
      );
    } catch (_) {
      // Kadr — bezak: moslab bo'lmasa eski kadr qoladi.
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RoutePreviewMap old) {
    super.didUpdateWidget(old);
    if (!_sameWaypoints(old.waypoints, widget.waypoints)) {
      _route = cachedRoadRoute(widget.waypoints);
      _load();
      // Yangi yo'nalish — kadr ham yangi (`initialCameraFit` faqat bir marta).
      WidgetsBinding.instance.addPostFrameCallback((_) => _refit());
    }
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  static bool _sameWaypoints(List<LatLng> a, List<LatLng> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].latitude != b[i].latitude || a[i].longitude != b[i].longitude) {
        return false;
      }
    }
    return true;
  }

  Future<void> _load() async {
    if (widget.waypoints.length < 2) return;
    try {
      final route = await fetchRoadRoute(
        widget.waypoints,
        dio: ref.read(apiClientProvider).dio,
      );
      if (!mounted) return;
      setState(() => _route = route);
      if (route.isRealRoad) _refit();
    } catch (_) {
      /*
       * 🔴 YO'L CHIZIG'I — IXTIYORIY, EKRAN UNDAN USTUN (16.09.2026,
       * sinov tutdi).
       *
       * `fetchRoadRoute` ning O'ZI hech qachon tashlamaydi, lekin
       * `apiClientProvider` ni O'QISH tashlashi mumkin: tarmoq qatlami
       * mavjud bo'lmagan muhitda (widget sinovi) u
       * «main.dart da override qilinadi» deb yiqiladi. Ilgari bu
       * sezilmasdi — xarita faqat varaqda edi. Endi u safar detali va
       * haydovchi ekranining ICHIDA, ya'ni bu istisno BUTUN EKRANNI
       * chizilmay qoldirardi.
       *
       * Chiziqsiz xarita ishlayveradi: to'g'ri chiziq baribir chiziladi.
       */
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.waypoints;
    if (points.length < 2) return const SizedBox.shrink();

    // Bir xil (yoki nol) koordinatalarda `CameraFit` cheksiz zoom hisoblab
    // ilovani yiqitadi — izohi `results_map.dart` da batafsil.
    final distinct = points
        .map((p) => '${p.latitude},${p.longitude}')
        .toSet()
        .length;
    if (distinct < 2) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final map = FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCameraFit: CameraFit.coordinates(
          coordinates: _frame,
          padding: _padding,
        ),
        onMapReady: () => _mapReady = true,
        // TINCH: surish, kattalashtirish — hammasi o'chiq. Xarita
        // ro'yxat/forma ichida turadi va barmoq harakatini o'ziga olsa,
        // odam sahifani sura olmay qoladi.
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        const MapTiles(),
        // Haqiqiy yo'l — yaxlit; kelguncha UZUQ taxminiy chiziq
        // (qoidasi `route_line.dart` da).
        PolylineLayer(
          polylines: routePolylines(
            straight: points,
            route: _route,
            color: scheme.primary,
          ),
        ),
        MarkerLayer(
          markers: [
            // Oraliq bekatlar — oddiy kichik nuqta; uchlar pastda,
            // bekatlar ustida chiziladi.
            for (var i = 1; i < points.length - 1; i++)
              Marker(
                point: points[i],
                width: 16,
                height: 16,
                child: _Dot(color: scheme.outline, small: true),
              ),
            // Boshi va oxiri — nom yorlig'i bilan (safar kartasidagi
            // nuqtalar bilan bir xil ranglar, `journey_view.dart`).
            routeEndMarker(
              point: points.first,
              name: widget.originName,
              color: scheme.primary,
              compact: true,
            ),
            routeEndMarker(
              point: points.last,
              name: widget.destinationName,
              color: scheme.secondary,
              compact: true,
            ),
          ],
        ),
      ],
    );

    final child = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            map,
            // OSM litsenziyasi (ODbL) attributsiyani TALAB qiladi — kichik
            // ko'rinishda ham. Olib tashlanmasin.
            Positioned(
              right: AppSpace.xs,
              bottom: AppSpace.xxs,
              child: const MapAttributionBadge(),
            ),
            if (widget.label != null)
              Positioned(
                left: AppSpace.sm,
                bottom: AppSpace.sm,
                child: MapOpenChip(text: widget.label!),
              ),
          ],
        ),
      ),
    );

    if (widget.onTap == null) return child;

    /*
     * 🔴 EKRAN O'QIGICH UCHUN NOM SHART (16.09.2026, qo'riqchi sinov
     * tutdi: «Tappable widgets should have a semantic label»).
     *
     * Xarita — rasm; TalkBack uning ichidan o'qiydigan hech nima topa
     * olmaydi va ko'zi ojiz odam uchun bu «nomsiz tugma» bo'lib qolardi.
     * Ichki tafsilotlar (plitka, chiziq, nuqta) esa `ExcludeSemantics`
     * bilan yashiriladi: aks holda o'qigich o'nlab ma'nosiz tugunni
     * sanab chiqardi.
     */
    return Semantics(
      button: true,
      label: widget.label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: child,
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, this.small = false});

  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 9.0 : 14.0;
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}

/// «Xaritada ko'rish» yozuvi — xarita bosiladigan ekanini bildiradi.
class MapOpenChip extends StatelessWidget {
  const MapOpenChip({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.open_in_full, size: 14, color: scheme.onSurface),
          const SizedBox(width: AppSpace.xs),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
