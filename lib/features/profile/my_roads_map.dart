import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';
import '../map/map_tiles.dart';
import '../map/road_route.dart';
import '../map/route_line.dart';
import '../map/route_preview_map.dart';
import '../shared/ui.dart';

/// «YO'LLARIM» — bosib o'tilgan yo'nalishlar bitta xaritada.
///
/// 🔴 NEGA KERAK BO'LDI (egasi, 16.09.2026: «karta to'liq ishlatilsin»).
/// Profilda odam haqida reyting va sharhlar bor edi, lekin u QAYERLARDA
/// bo'lgani — platformadagi eng shaxsiy narsa — hech qayerda ko'rinmasdi.
///
/// 🔑 MA'LUMOT HAQIQIY (loyiha qoidasi: «o'lchama, ishonma»). `MemoryCard`
/// da yozilgan edi: «backendda safar kilometri yoki shahar soni uchun
/// ishonchli endpoint YO'Q, shuning uchun soxta "1000 km" yozilmaydi».
/// Bu yerda hech nima o'ylab topilmaydi: har chiziq — `GET /rides/my` yoki
/// `GET /bookings/my` dan kelgan HAQIQIY safarning jo'nash va borish
/// koordinatasi. Km ham, CO2 ham yozilmaydi — faqat SAFARLAR SONI, u esa
/// oddiy sanoq.
///
/// ✅ CHIZIQ ENDI YO'L BO'YLAB (28.09.2026, egasi: «to'g'ri chiziqlarmi,
/// rasvo»). Ilgari ataylab to'g'ri edi — «ellik safar = ellik so'rov» deb.
/// O'lchov bu qo'rquvni rad etdi: test akkauntdagi 49 safar atigi 3 ta
/// TURLI yo'nalish. Yo'nalishlar birlashtiriladi va har biri BIR MARTA
/// so'raladi (kesh `road_route.dart` da); ko'p yurilgan yo'l QALINROQ.
/// Eng ko'p yurilgan [_maxRoads] tasidan tashqarisi so'ralmaydi.
class MyRoadsMap extends ConsumerWidget {
  const MyRoadsMap({
    super.key,
    this.height = 200,
    this.driverId,
    this.title,
    this.fullscreen = false,
  });

  /// To'liq ekran ko'rinishi — surish va kattalashtirish OCHIQ.
  ///
  /// 🔴 NEGA (28.09.2026, egasi qurilmada: «karta ochilmayapti»). Profildagi
  /// karta qotirib qo'yilgan edi (`InteractiveFlag.none` — ro'yxat
  /// surilishi buzilmasin deb) va bosilganda HECH NARSA bo'lmasdi.
  /// Odam uni bosib, «ochilmayapti» deb o'ylardi. Endi kichik karta
  /// ham tinch qoladi, lekin bosilsa shu to'liq ko'rinish ochiladi —
  /// safar detalidagi kichik karta bilan bir xil qoida.
  final bool fullscreen;

  final double height;

  /// Bo'lim sarlavhasi (`SectionLabel`) — xarita bilan BIRGA chiziladi va
  /// safar bo'lmasa u bilan birga yo'qoladi. Tashqarida qo'yilsa, bo'sh
  /// profilda sarlavha yolg'iz osilib qolardi.
  final String? title;

  /// BEGONA HAYDOVCHINING yo'llari (uning ochiq profili).
  ///
  /// 🔴 Berilmasa — O'Z yo'llarim (ikkala rol bo'yicha). Berilsa —
  /// faqat shu haydovchining ochiq safarlari: `GET /users/{id}/rides`
  /// (16.09.2026 da backend ochdi; mehmonga ham 200, PII yo'q —
  /// prodda o'lchandi).
  ///
  /// 🔑 Nega BITTA vidjet: ko'rinish aynan bir xil bo'lishi kerak.
  /// Ikkita nusxa yasasak, ertaga biri o'zgarib ikkinchisi qolib
  /// ketardi — loyihaning eski kasali.
  final String? driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final id = driverId;
    final myRides = id == null
        ? (ref.watch(myRidesProvider).valueOrNull ?? const <Ride>[])
        : (ref.watch(driverRidesProvider(id)).valueOrNull ?? const <Ride>[]);
    // Begona haydovchida bronlar O'QILMAYDI: ular meniki emas va
    // serverdan ham kelmaydi.
    final myBookings = id == null
        ? ref.watch(myBookingsProvider).valueOrNull
        : null;

    /*
     * IKKALA ROL ham hisobga olinadi: odam bir safarda haydovchi,
     * boshqasida yo'lovchi bo'lishi mumkin va «yo'llarim» ikkalasini
     * ham bildiradi. Yo'lovchilik safari bronning ICHIDAN keladi
     * (`BookingResponse.ride`).
     */
    final rides = <String, Ride>{for (final r in myRides) r.id: r};
    for (final booking in myBookings ?? const []) {
      final ride = booking.ride;
      if (ride != null) rides.putIfAbsent(ride.id, () => ride);
    }

    // Koordinatasiz safar TASHLAB YUBORILADI: nol nuqtaga chizilgan
    // chiziq xaritani okean o'rtasiga sudrab ketardi.
    final legs = <List<LatLng>>[];
    for (final ride in rides.values) {
      if (ride.originLat == 0 && ride.originLon == 0) continue;
      if (ride.destinationLat == 0 && ride.destinationLon == 0) continue;
      legs.add([
        LatLng(ride.originLat, ride.originLon),
        for (final stop in ride.stops) LatLng(stop.lat, stop.lon),
        LatLng(ride.destinationLat, ride.destinationLon),
      ]);
    }

    // Safar bo'lmasa karta UMUMAN chizilmaydi — bo'sh xarita «buzilgan»
    // ko'rinardi va yangi foydalanuvchini bekorga xafa qilardi.
    if (legs.isEmpty) return const SizedBox.shrink();

    // Bir xil yo'nalish BITTA chiziq — nechta safar bo'lsa, shuncha qalin.
    final counts = <String, int>{};
    final unique = <String, List<LatLng>>{};
    for (final leg in legs) {
      final key = leg
          .map(
            (p) =>
                '${p.latitude.toStringAsFixed(4)},'
                '${p.longitude.toStringAsFixed(4)}',
          )
          .join('|');
      unique.putIfAbsent(key, () => leg);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final roads = unique.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final shownLegs = [
      for (final k in roads.take(_maxRoads))
        (points: unique[k]!, trips: counts[k]!),
    ];

    final points = [for (final leg in legs) ...leg];
    final distinct = points
        .map((p) => '${p.latitude},${p.longitude}')
        .toSet()
        .length;
    if (distinct < 2) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          const SizedBox(height: AppSpace.lg),
          SectionLabel(title!),
          const SizedBox(height: AppSpace.sm),
        ],
        _tappable(
          context,
          label: t.showOnMap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCameraFit: CameraFit.coordinates(
                        coordinates: points,
                        padding: const EdgeInsets.all(AppSpace.xl),
                      ),
                      // Kichik karta TINCH: profil ro'yxati ichida turadi va
                      // barmoq harakatini o'ziga olsa, sahifa surilmay
                      // qolardi. To'liq ko'rinishda esa — erkin.
                      interactionOptions: InteractionOptions(
                        flags: fullscreen
                            ? InteractiveFlag.all & ~InteractiveFlag.rotate
                            : InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      const MapTiles(),
                      _RoadsLayer(legs: shownLegs, color: scheme.primary),
                      MarkerLayer(
                        markers: [
                          for (final leg in legs) ...[
                            _cityDot(scheme, leg.first),
                            _cityDot(scheme, leg.last),
                          ],
                        ],
                      ),
                    ],
                  ),
                  // OSM litsenziyasi (ODbL) attributsiyani TALAB qiladi.
                  Positioned(
                    right: AppSpace.xs,
                    bottom: AppSpace.xxs,
                    child: const MapAttributionBadge(),
                  ),
                  if (!fullscreen)
                    Positioned(
                      left: AppSpace.sm,
                      bottom: AppSpace.sm,
                      child: MapOpenChip(text: t.showOnMap),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          t.myRoadsCount(legs.length),
          style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
        ),
      ],
    );
  }

  /// Kichik karta bosilsa — to'liq ekran. Ekran o'qigich uchun nomli tugma
  /// (qoidasi `RoutePreviewMap` da).
  Widget _tappable(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    if (fullscreen) return child;
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: Text(title ?? AppStrings.of(context).sectionMyRoads),
                ),
                body: LayoutBuilder(
                  builder: (context, box) => Padding(
                    padding: const EdgeInsets.all(AppSpace.md),
                    child: MyRoadsMap(
                      driverId: driverId,
                      fullscreen: true,
                      // Pastdagi «N ta safar» yozuvi uchun joy qoldiriladi.
                      height: box.maxHeight - AppSpace.md * 2 - 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Shundan ortiq turli yo'nalish so'ralmaydi — kamdan-kam odamda
  /// bo'ladi, bo'lsa ham eng kam yurilganlari chizilmay qoladi.
  static const _maxRoads = 12;

  static Marker _cityDot(ColorScheme scheme, LatLng point) => Marker(
    point: point,
    width: 10,
    height: 10,
    child: Container(
      decoration: BoxDecoration(
        color: scheme.secondary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    ),
  );
}

/// Yo'nalishlarni HAQIQIY yo'l bo'ylab chizadi. Yo'l kelguncha har biri
/// UZUQ taxminiy chiziq (qoidasi `route_line.dart` da).
class _RoadsLayer extends ConsumerStatefulWidget {
  const _RoadsLayer({required this.legs, required this.color});

  final List<({List<LatLng> points, int trips})> legs;
  final Color color;

  @override
  ConsumerState<_RoadsLayer> createState() => _RoadsLayerState();
}

class _RoadsLayerState extends ConsumerState<_RoadsLayer> {
  final _routes = <int, RoadRoute>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _RoadsLayer old) {
    super.didUpdateWidget(old);
    if (_keyOf(old.legs) != _keyOf(widget.legs)) {
      _routes.clear();
      _load();
    }
  }

  static String _keyOf(List<({List<LatLng> points, int trips})> legs) => legs
      .map((l) => l.points.map((p) => '${p.latitude},${p.longitude}').join(';'))
      .join('|');

  void _load() {
    for (var i = 0; i < widget.legs.length; i++) {
      final pts = widget.legs[i].points;
      final hit = cachedRoadRoute(pts);
      if (hit != null) {
        _routes[i] = hit;
        continue;
      }
      try {
        final key = _keyOf(widget.legs);
        fetchRoadRoute(pts, dio: ref.read(apiClientProvider).dio).then((r) {
          // Kutish orasida yo'nalishlar almashgan bo'lsa — eski javob
          // boshqa chiziqqa tushib qolmasin.
          if (mounted && _keyOf(widget.legs) == key) {
            setState(() => _routes[i] = r);
          }
        });
      } catch (_) {
        // Tarmoq qatlami yo'q muhit (sinov) — uzuq chiziq qoladi.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PolylineLayer(
      polylines: [
        for (var i = 0; i < widget.legs.length; i++)
          ...routePolylines(
            straight: widget.legs[i].points,
            route: _routes[i],
            color: widget.color.withValues(alpha: 0.75),
            // Ko'p yurilgan yo'l ko'zga birinchi tashlansin.
            width: 2.5 + (widget.legs[i].trips.clamp(1, 5) - 1) * 0.75,
          ),
      ],
    );
  }
}
