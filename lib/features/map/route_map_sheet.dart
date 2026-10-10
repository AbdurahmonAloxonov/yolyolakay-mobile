import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/format.dart';
import '../../data/models/telematics.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';
import '../rides/journey_view.dart';
import 'live_point.dart';
import 'map_tiles.dart';
import 'my_location.dart';
import 'road_route.dart';
import 'route_decor.dart';
import 'route_line.dart';
import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/motion.dart';

/// Safar marshruti xaritada.
///
/// Ilova ICHIDA ochiladi (BottomSheet) — web'da ham shu qaror qabul qilingan:
/// tashqi navigator ilovasiga otib yuborish foydalanuvchini YolYolakay'dan
/// chiqarib yuborardi va u qaytib kelmasdi.
///
/// ✅ 2026-08-13: chiziq endi YO'L BO'YLAB (`road_route.dart`). Ilgari u
/// to'g'ri kesmalardan iborat edi va Toshkent–Samarqand chizig'i tog' ustidan
/// o'tib ketardi. Marshrut yuklanguncha eski to'g'ri chiziq ko'rinadi, ya'ni
/// xarita hech qachon bo'sh turmaydi.
Future<void> showRouteMapSheet(BuildContext context, Ride ride) {
  return showModalBottomSheet<void>(
    context: context,
    // `useSafeArea` SHART (Android 15+ / targetSdk 36): tizim
    // "edge-to-edge" ni MAJBURIY qiladi va opt-out endi ishlamaydi.
    // Usiz varaqning eng pastki tugmasi imo-ishora paneli ostida
    // qolib, bosib bo'lmaydigan bo'lardi.
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => _RouteMapSheet(ride: ride),
  );
}

class _RouteMapSheet extends ConsumerStatefulWidget {
  const _RouteMapSheet({required this.ride});

  final Ride ride;

  @override
  ConsumerState<_RouteMapSheet> createState() => _RouteMapSheetState();
}

class _RouteMapSheetState extends ConsumerState<_RouteMapSheet>
    with SingleTickerProviderStateMixin {
  // Keshda bo'lsa DARHOL — kichik kartada yuklangan yo'l varaq ochilganda
  // qayta kutilmaydi (izohi `road_route.dart` da).
  late RoadRoute? _route = cachedRoadRoute(_waypoints);

  List<LatLng> get _waypoints => [
    LatLng(ride.originLat, ride.originLon),
    for (final s in ride.stops) LatLng(s.lat, s.lon),
    LatLng(ride.destinationLat, ride.destinationLon),
  ];

  /*
   * ─────────────────────────────────────────────────────────────
   * «MEN QAYERDAMAN» — 2026-08-30 (egasi: «Yandexda o'zi qayerda
   * ketayotganini ko'rish mumkin, bizda mumkin emas, hatto haydovchi
   * bo'lsa ham»).
   *
   * Xaritada faqat MARSHRUT chizilardi: boshlanish, oraliq bekatlar,
   * manzil. O'z nuqtangiz UMUMAN yo'q edi — ya'ni xaritaga qarab
   * "qayergacha keldim" degan savolga javob topib bo'lmasdi va odam
   * tashqi navigatorga chiqib ketardi.
   *
   * Uch holat (Google Maps odati — odam buni allaqachon biladi):
   *   o'chiq              → nuqta yo'q, GPS ishlamaydi
   *   yoniq + kuzatyapti  → nuqta bor, kamera nuqta ortidan yuradi
   *   yoniq + qo'yib yuborilgan → nuqta bor, kamera qimirlamaydi
   *
   * Xaritani qo'l bilan surish kuzatuvni to'xtatadi (`hasGesture`) —
   * aks holda odam boshqa joyga qarayotganda kamera uni doim
   * o'ziga tortib qaytarardi.
   */
  /*
   * «MENING JOYIM» — mantiq UMUMIY faylda (`my_location.dart`).
   *
   * 🔴 NEGA KO'CHIRILDI (18.09.2026): aynan shu uch holatli mantiq
   * bosh ekrandagi xaritaga ham kerak bo'ldi. Ikkinchi nusxa yozish
   * loyihada allaqachon zarar keltirgan (belgilar beshta xaritada
   * beshta joyda yasalib, o'lchamlari har xil bo'lib ketgandi).
   */
  late final MyLocationController _loc = MyLocationController(
    onPosition: _onMyPosition,
  );

  /// Marshrutning oldinda qolgan qismi — `null` bo'lsa ko'rsatilmaydi
  /// (joylashuv o'chiq, marshrut yo'q yoki odam yo'ldan chiqib ketgan).
  RouteRemainder? _remaining;

  final MapController _map = MapController();

  /// Odam xaritani O'ZI surgan/kattalashtirganmi. Surgan bo'lsa, kechikib
  /// kelgan yo'l uchun kadr qayta moslanmaydi — uning qarashini tortib
  /// olmaymiz.
  bool _userMoved = false;

  /// Kadr chekkasi. Yon tomonda — shahar yorlig'ining yarim kengligi,
  /// tepada — yorliq va uning ustidagi holat chipi sig'adigan joy
  /// (aks holda chetdagi shahar nomi kesilardi).
  static const _fitPadding = EdgeInsets.fromLTRB(72, 96, 72, 56);
  bool _mapReady = false;

  // Neon "yo'l izi" — marshrut bo'ylab yuguruvchi porlоq kometa (faqat neon
  // uslubда). Egasi (2026-08-20): xarita "jonli" ko'rinsin.
  //
  // 🔴 `late final` EMAS (2026-08-30 da test ochdi). U DANGASA edi:
  // neon uslub yoqilmagan bo'lsa kontroller `build` da hech qachon
  // o'qilmasdi, `dispose` dagi `_trail.dispose()` esa uni AYNAN
  // O'SHANDA birinchi marta YARATARDI. Yaratish `createTicker` ni
  // chaqiradi, u esa allaqachon o'chirilgan elementda `TickerMode` ni
  // qidiradi:
  //     «Looking up a deactivated widget's ancestor is unsafe»
  // Ya'ni oddiy (neon bo'lmagan) uslubda xaritani YOPISH debug
  // build'da xato tashlardi; relizda esa bekorga kontroller yaratilib,
  // darhol tashlab yuborilardi.
  //
  // Dangasalikning o'zi TO'G'RI qaror: neon yoqilmagan bo'lsa tikker
  // umuman kerak emas va u har kadrda batareya yeydi. Shuning uchun
  // dangasalik saqlanadi, faqat `dispose` endi YARATMAYDI.
  AnimationController? _trailController;

  AnimationController get _trail => _trailController ??= AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  Ride get ride => widget.ride;

  @override
  void initState() {
    super.initState();
    // Nuqta va ergashish holati o'zgarganda xarita qayta chizilsin.
    _loc.addListener(_onLocChanged);
    _load();
  }

  void _onLocChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // ⚠️ `_trail` EMAS, `_trailController` — getter uni yaratib
    // yuborardi (izohi yuqorida).
    _trailController?.dispose();
    // Xarita yopilishi bilan GPS QO'YIB YUBORILADI: bu ekran kuzatuv
    // xizmati emas, u `LivePing` da va safar holatiga bog'liq.
    _loc.removeListener(_onLocChanged);
    _loc.dispose();
    super.dispose();
  }

  /// Har yangi GPS javobida — «marshrutdan qancha qoldi» qayta hisoblanadi.
  ///
  /// ⚠️ Odam yo'ldan chiqib ketgan bo'lsa `remainingOnRoute` `null`
  /// qaytaradi va panel KO'RSATILMAYDI: noto'g'ri raqamdan ko'ra
  /// raqamsiz xarita yaxshi.
  void _onMyPosition(Position position) {
    final route = _route;
    if (route == null || !mounted) return;
    setState(
      () => _remaining = remainingOnRoute(
        route,
        LatLng(position.latitude, position.longitude),
      ),
    );
  }

  Future<void> _load() async {
    final RoadRoute route;
    try {
      route = await fetchRoadRoute(
        _waypoints,
        dio: ref.read(apiClientProvider).dio,
      );
    } catch (_) {
      // `apiClientProvider` ni o'qish tarmoq qatlami yo'q muhitda
      // tashlaydi — chiziq bezak, varaq baribir ochilsin.
      return;
    }
    if (!mounted) return;
    final me = _loc.point;
    setState(() {
      _route = route;
      // Marshrut joylashuvdan KEYIN kelishi mumkin — o'shanda ham
      // «qancha qoldi» darhol chiqsin, keyingi GPS nuqtasini kutmasin.
      _remaining = me == null ? null : remainingOnRoute(route, me);
    });
    /*
     * 🔴 KADR YO'LNI KO'RMASDI (28.09.2026, egasi qurilmasida:
     * Samarqand → Buxoro). Kamera faqat shahar nuqtalariga moslanardi;
     * yo'l esa Qashqadaryo tomonga egilib, varaqning pastki yarmiga
     * siqilib qolardi. Yo'l kelgach kadr butun chiziqqa moslanadi.
     */
    if (route.isRealRoad && _mapReady && !_userMoved) {
      final pts = [
        ...route.points,
        ..._waypoints.where((p) => p.latitude != 0 || p.longitude != 0),
      ];
      try {
        _map.fitCamera(
          CameraFit.coordinates(coordinates: pts, padding: _fitPadding),
        );
      } catch (_) {
        // Kadr — bezak: moslab bo'lmasa eski kadr qoladi.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    // Reduce-motion: kometa harakati o'chади (dekorativ).
    final neon =
        ref.watch(themeStyleProvider) == ThemeStyle.neon &&
        AppMotion.on(context);

    final origin = LatLng(ride.originLat, ride.originLon);
    final destination = LatLng(ride.destinationLat, ride.destinationLon);
    final stops = ride.stops
        .map((s) => LatLng(s.lat, s.lon))
        .toList(growable: false);
    final straight = [origin, ...stops, destination];
    // Yo'l geometriyasi kelmaguncha to'g'ri chiziq ko'rsatiladi.
    final points = _route?.points ?? straight;

    /*
     * 🔴 BIR NUQTADA TURGAN MARSHRUT VARAQNI YIQITARDI (28.09.2026).
     * Hamma nuqta bitta joyda bo'lsa (jo'nash = manzil yoki
     * koordinatasiz safar — ikkala uchi 0,0) `CameraFit` zumni CHEKSIZ
     * hisoblaydi: «Camera `zoom` must be finite». Izohi va o'sha himoya
     * `results_map.dart` da — bu varaqqa u qo'yilmagan edi.
     *
     * Nol nuqta ham hisobga olinmaydi: u Gvineya ko'rfazida, xaritani
     * okeanga sudrab ketardi. Yaroqli nuqta umuman bo'lmasa —
     * O'zbekiston ko'rinadi, bo'sh ko'k maydon emas.
     */
    final real = straight
        .where((p) => p.latitude != 0 || p.longitude != 0)
        .toList(growable: false);
    final distinct = real
        .map((p) => '${p.latitude},${p.longitude}')
        .toSet()
        .length;

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Column(
        children: [
          AppBar(
            title: Text('${ride.originAddress} → ${ride.destinationAddress}'),
            titleTextStyle: theme.textTheme.titleSmall,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: t.close,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    // Barcha nuqtalar ko'rinadigan qilib joylashtiramiz.
                    initialCameraFit: distinct > 1
                        ? CameraFit.coordinates(
                            // Yo'l keshda bo'lsa — birinchi kadrdayoq
                            // uning butun chizig'i kiradi.
                            coordinates: [
                              ...real,
                              if (_route?.isRealRoad ?? false)
                                ..._route!.points,
                            ],
                            padding: _fitPadding,
                          )
                        : null,
                    initialCenter: real.isEmpty
                        ? const LatLng(41.3, 64.6)
                        : real.first,
                    initialZoom: real.isEmpty ? 5 : 13,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    // Xaritani QO'L bilan surish kuzatuvni to'xtatadi.
                    // `hasGesture` shart: `_map.move` ning o'zi ham shu
                    // callback'ni chaqiradi va usiz kuzatuv birinchi
                    // nuqtadayoq o'zini o'chirib qo'yardi.
                    onPositionChanged: (_, hasGesture) {
                      if (!hasGesture) return;
                      _userMoved = true;
                      _loc.releaseCamera();
                    },
                    onMapReady: () => _mapReady = true,
                  ),
                  children: [
                    const MapTiles(),
                    // Haqiqiy yo'l — yaxlit; kelguncha UZUQ taxminiy
                    // chiziq (qoidasi `route_line.dart` da).
                    PolylineLayer(
                      polylines: routePolylines(
                        straight: straight,
                        route: _route,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    // NEON YO'L IZI — porlоq kometa marshrut bo'ylab yuguradi.
                    if (neon &&
                        (_route?.isRealRoad ?? false) &&
                        points.length > 2)
                      AnimatedBuilder(
                        animation: _trail,
                        builder: (context, _) {
                          final seg = _cometSegment(points, _trail.value);
                          if (seg.length < 2) return const SizedBox.shrink();
                          return PolylineLayer(
                            polylines: [
                              // Tashqi "porlash" — keng, xira cyan.
                              Polyline(
                                points: seg,
                                strokeWidth: 12,
                                color: BrandColors.neonAqua.withValues(
                                  alpha: 0.20,
                                ),
                              ),
                              // Ichki yorug' o'zak.
                              Polyline(
                                points: seg,
                                strokeWidth: 4,
                                color: BrandColors.neonAqua,
                              ),
                            ],
                          );
                        },
                      ),
                    /*
                     * HAYDOVCHINING OXIRGI MA'LUM JOYI — safar boshlangach.
                     *
                     * 🔴 Bu 2026-08-22 gacha MUMKIN EMAS edi: backend
                     * faqat masofani berardi, koordinata bermasdi va biz
                     * taxminiy nuqta chizishdan ATAYIN bosh tortgandik.
                     *
                     * ⚠️ "Jonli kuzatuv" DEB ATALMAYDI: haydovchi ilovani
                     * yopsa ping to'xtaydi va nuqta eskiradi. Shuning uchun
                     * u boshqa BELGI bilan (strelka) chiziladi.
                     *
                     * 🔴 ALOHIDA QATLAM (18.09.2026): nuqta endi ikki ping
                     * ORASIDA suriladi (`SmoothPoint`) va kadrlar
                     * soniyasiga o'nlab marta keladi. Agar u umumiy
                     * `MarkerLayer` ichida qolsa, HAR KADRDA marshrutning
                     * hamma belgisi qayta qurilardi. Qatlam ostida turgani
                     * ham to'g'ri: jo'nash/manzil belgilari ustida qolsin.
                     */
                    ...() {
                      final driver = ref
                          .watch(driverPositionProvider(widget.ride))
                          .valueOrNull;
                      if (driver == null || !driver.hasPosition) {
                        return <Widget>[];
                      }
                      final age = driver.ageAt(DateTime.now());
                      // ESKIRGAN NUQTA SO'NIQ: yozuvni o'qimagan odam
                      // ham «bu jonli emas» deb ko'rsin.
                      final stale = isStalePing(age);
                      return [
                        SmoothPoint(
                          point: LatLng(driver.lat!, driver.lon!),
                          // Ishonchsiz qiymatda BURILMAYDI: noto'g'ri
                          // yo'nalishdan ko'ra yo'qligi yaxshi
                          // (izohi `NearbyDriver.hasHeading` da).
                          heading: driver.hasHeading ? driver.heading : null,
                          // Eskirgan ping SURILMAYDI — harakat «aloqa
                          // bor» degan signal (izohi `live_point.dart` da).
                          age: age,
                          builder: (context, point, heading) => MarkerLayer(
                            markers: [
                              _marker(
                                point,
                                Icons.navigation,
                                stale
                                    ? theme.colorScheme.outline
                                    : theme.colorScheme.secondary,
                                size: 30,
                                headingDegrees: heading,
                              ),
                            ],
                          ),
                        ),
                      ];
                    }(),
                    /*
                     * UCHRASHUV NUQTASI — haydovchi xaritada qo'ygan aniq
                     * joy (izohi `Ride.pickupLat` da).
                     *
                     * Faqat YAQINDAN (zoom ≥ 11): mamlakat miqyosida u
                     * jo'nash shahri bilan bir nuqtaga tushib, shahar
                     * nomini yopardi (rasmda ko'rildi). Yaqinlashtirilganda
                     * esa aynan u kerak — «qaysi ko'chada kutaman».
                     */
                    if (ride.hasPickupCoord)
                      Builder(
                        builder: (context) {
                          if (MapCamera.of(context).zoom < 11) {
                            return const SizedBox.shrink();
                          }
                          return MarkerLayer(
                            markers: [
                              _marker(
                                LatLng(ride.pickupLat!, ride.pickupLon!),
                                Icons.hail,
                                theme.colorScheme.primary,
                              ),
                            ],
                          );
                        },
                      ),
                    MarkerLayer(
                      markers: [
                        for (final stop in stops)
                          _marker(
                            stop,
                            Icons.circle,
                            theme.colorScheme.tertiary,
                            size: 16,
                          ),
                        // Uchlar — nom yorlig'i bilan (izohi
                        // `route_decor.dart` da). Oxirida chiziladi:
                        // yorliq bekat belgisi ostida qolmasin.
                        routeEndMarker(
                          point: origin,
                          name: ride.originAddress,
                          color: theme.colorScheme.primary,
                        ),
                        routeEndMarker(
                          point: destination,
                          name: ride.destinationAddress,
                          color: theme.colorScheme.secondary,
                        ),
                      ],
                    ),

                    /* MEN — eng oxirida, ya'ni barcha belgilarning
                       USTIDA: odam o'zini marshrut nuqtalari ostida
                       qidirmasin. Aniqlik doirasi va belgi shakli
                       `my_location.dart` da (bosh ekrandagi xarita ham
                       AYNAN shuni chizadi). */
                    ...myLocationLayers(context, _loc),
                  ],
                ),
                // «QANCHA QOLDI» — marshrutning oldinda qolgan qismi.
                //
                // 🔴 Bu raqam MIJOZDA hisoblanadi, serverdan olinmaydi:
                // `GET /telematics/eta` har doim 0 qaytaradi (jonli
                // o'lchandi). Izohi `remainingOnRoute` da.
                //
                // Faqat «mening joyim» yoqilganda va odam marshrutda
                // turganda chiziladi — aks holda raqam yolg'on bo'lardi.
                //
                // Yoniga SAFAR HOLATI qo'yildi (2026-09-08). Xaritada
                // odam «hozir nima bo'lyapti» degan savolga javob
                // topolmasdi: marshrut chizilgan, mashina ko'rinadi,
                // lekin safar boshlanganmi yoki hali kutilyaptimi —
                // bilinmasdi. Buni raqobatchining ilovasida ko'rdim va
                // e'tirof etaman: u yerda holat xaritaning eng tepasida
                // doim turadi va bu TO'G'RI qaror.
                Positioned(
                  left: AppSpace.md,
                  right: AppSpace.md,
                  top: AppSpace.md,
                  child: Column(
                    children: [
                      // Ilovaning boshqa joylaridagi AYNI belgi
                      // (`StatusPill`) — odam uni qayta o'rganmaydi.
                      // Xaritada o'qilishi uchun soya bilan.
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: StatusPill(
                          tone: StatusTone.forRide(
                            theme.colorScheme,
                            ride.status,
                          ),
                          label: t.rideStatus(ride.status),
                        ),
                      ),
                      if (_remaining != null) ...[
                        const SizedBox(height: AppSpace.sm),
                        _RemainingPill(remaining: _remaining!),
                      ] else if (_route?.distanceMeters != null) ...[
                        // Joylashuv yo'q — «qancha qoldi» o'rniga butun
                        // yo'lning masofasi va vaqti (xarita ustida
                        // ortiqcha bezak emas: shu bitta chip).
                        const SizedBox(height: AppSpace.sm),
                        _RemainingPill(
                          remaining: RouteRemainder(
                            meters: _route!.distanceMeters!,
                            duration: _route!.seconds == null
                                ? null
                                : Duration(seconds: _route!.seconds!),
                          ),
                          total: true,
                        ),
                      ],
                      /*
                       * MA'LUMOT TIRIKMI — eng muhim qator.
                       *
                       * 🔴 Usiz xarita JIM TURIB YOLG'ON GAPIRADI:
                       * haydovchi ilovani yopsa nuqta o'sha joyda
                       * qotib qoladi va jonli nuqtadan farq qilmaydi.
                       * Saytda bu qator bor edi, ilovada yo'q edi
                       * (17.09.2026 da solishtirildi).
                       *
                       * Faqat SAFAR KETAYOTGANDA: safar boshlanmagan
                       * bo'lsa ping ham kutilmaydi va qator ortiqcha
                       * tashvish bo'lardi.
                       */
                      if (ride.status == RideStatus.inProgress) ...[
                        const SizedBox(height: AppSpace.sm),
                        /*
                         * ⚠️ YUKLANISH HOLATI ALOHIDA (kod ko'rigi,
                         * 18.09.2026): birinchi so'rov ketayotganda
                         * `valueOrNull` NULL bo'ladi va panel bir
                         * zumga «mashina joyi ko'rinmayapti» deb
                         * YOLG'ON aytardi — javob esa hali yo'lda
                         * edi. Endi javob KELGUNCHA panel jim turadi.
                         */
                        _PingAgePill(
                          state: ref.watch(driverPositionProvider(ride)),
                        ),
                      ],
                    ],
                  ),
                ),

                // «MENING JOYIM» tugmasi — xaritaning ustida.
                Positioned(
                  right: AppSpace.md,
                  bottom: AppSpace.md,
                  child: _MyLocationButton(
                    on: _loc.tracking,
                    following: _loc.following,
                    onPressed: () => _loc.toggle(context, map: _map),
                  ),
                ),
              ],
            ),
          ),
          const OsmAttribution(),
        ],
      ),
    );
  }

  /// Marshrut nuqtalaridan yuguruvchi kometaning JORIY qismini qaytaradi:
  /// bosh `t` ulushida, orqasида qisqa dum (~12% nuqta). Dumasi bilan birga
  /// harakatlanadi — yo'l "oqяпти" hissи beradi.
  List<LatLng> _cometSegment(List<LatLng> pts, double t) {
    final n = pts.length;
    final head = (t * (n - 1)).round().clamp(0, n - 1);
    final tail = (n * 0.12).round().clamp(2, n);
    final start = (head - tail).clamp(0, n - 1);
    return pts.sublist(start, head + 1);
  }

  Marker _marker(
    LatLng point,
    IconData icon,
    Color color, {
    double size = 28,
    double? headingDegrees,

    /// To'ldirilgan doira foni — «mening joyim» belgisi uchun. Marshrut
    /// belgilaridan SHAKLI bilan ajralib tursin: rang yetarli emas,
    /// xaritada fon rangi har xil bo'ladi.
    Color? halo,
  }) {
    Widget glyph = Icon(icon, color: color, size: size);
    if (halo != null) {
      glyph = Container(
        padding: const EdgeInsets.all(AppSpace.xs),
        decoration: BoxDecoration(
          color: halo,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: glyph,
      );
      size += AppSpace.xs * 2 + 4;
    }
    return Marker(
      point: point,
      width: size + 8,
      height: size + 8,
      // Nuqta belgining PASTKI uchida bo'lsin (joy belgisi odati).
      // ⚠️ Buriladigan belgi ISTISNO: u nuqtaning O'ZIDA turishi kerak,
      // aks holda burilganda uchi joyidan siljib ketadi.
      alignment: headingDegrees == null
          ? Alignment.topCenter
          : Alignment.center,
      child: headingDegrees == null
          ? glyph
          : Transform.rotate(
              // `Icons.navigation` YUQORIGA qaraydi, ya'ni 0° = shimol —
              // `heading` bilan bir xil boshlanish nuqtasi. Radianga
              // o'tkazamiz.
              angle: headingDegrees * math.pi / 180,
              child: glyph,
            ),
    );
  }
}

/// «Mening joyim» tugmasi — uch holatni BIR qarashda ko'rsatadi.
///
/// Ikonka o'zgaradi, rang emas: rang kо'r odam uchun ham, quyoshda
/// ham ishonchsiz belgi.
class _MyLocationButton extends StatelessWidget {
  const _MyLocationButton({
    required this.on,
    required this.following,
    required this.onPressed,
  });

  final bool on;
  final bool following;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final active = on && following;

    return Tooltip(
      message: active ? t.myLocationStop : t.myLocation,
      child: FloatingActionButton.small(
        heroTag: 'route-map-my-location',
        onPressed: onPressed,
        backgroundColor: active
            ? theme.colorScheme.primary
            : theme.colorScheme.surface,
        foregroundColor: active
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
        child: Icon(
          on
              ? (following ? Icons.gps_fixed : Icons.gps_not_fixed)
              : Icons.my_location,
        ),
      ),
    );
  }
}

/// Undan eski ping — «ma'lumot eskirgan».
///
/// 🔑 10 daqiqa — saytdagi `TripLive` bilan AYNAN bir xil chegara
/// (`STALE_MIN`). Ikki mijozda ikki xil bo'lsa, bir xil safar ikki
/// joyda ikki xil hikoya aytardi.
const Duration kStalePing = Duration(minutes: 10);

bool isStalePing(Duration? age) => age != null && age > kStalePing;

/// «Yangilandi: 2 daqiqa oldin» — mashina nuqtasi TIRIKMI degan javob.
class _PingAgePill extends StatelessWidget {
  const _PingAgePill({required this.state});

  final AsyncValue<NearbyDriver?> state;

  @override
  Widget build(BuildContext context) {
    // Javob kelmagunicha HECH NIMA aytilmaydi.
    if (state.isLoading && !state.hasValue) return const SizedBox.shrink();
    final driver = state.valueOrNull;
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final age = driver?.hasPosition == true
        ? driver!.ageAt(DateTime.now())
        : null;
    final stale = isStalePing(age);
    final minutes = age?.inMinutes;

    final text = switch ((driver?.hasPosition, minutes)) {
      (true, final int m) when m > kStalePing.inMinutes => t.locationStale(m),
      (true, final int m) when m >= 1 => t.locationUpdatedAgo(m),
      // Nuqta bor, lekin vaqt kelmadi (eski gateway javobi) — YOSH
      // O'YLAB TOPILMAYDI, shunchaki jim qolamiz.
      (true, _) => age == null ? null : t.locationJustNow,
      _ => t.locationUnavailable,
    };
    if (text == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            stale || driver?.hasPosition != true
                ? Icons.cloud_off
                : Icons.sensors,
            size: 14,
            color: stale || driver?.hasPosition != true
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpace.xs),
          Flexible(
            child: Text(
              text,
              // ⚠️ IKKI QATOR: «Ma'lumot 14 daqiqa oldingi — haydovchi
              // aloqadan chiqqan bo'lishi mumkin» bir qatorga sig'maydi
              // va SABABI kesilib qolardi (aynan shu xato kecha
              // `HomeMap` da tutilgan edi).
              maxLines: 2,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: stale
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «Qoldi: 128 km · 1 soat 40 daqiqa» — xaritaning tepasidagi tasma.
///
/// Marshrut chizig'i ustida turadi, shuning uchun foni QATTIQ: shaffof
/// bo'lsa raqamlar chiziq va yo'l nomlari ustida o'qilmay qoladi.
class _RemainingPill extends StatelessWidget {
  const _RemainingPill({required this.remaining, this.total = false});

  final RouteRemainder remaining;

  /// Butun yo'l (joylashuv yo'q) — «Qoldi:» so'zisiz, faqat raqamlar.
  final bool total;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final left = remaining.duration;

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.straighten, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpace.sm),
            Flexible(
              child: Text(
                [
                  total
                      ? formatDistance(remaining.km)
                      : '${t.routeLeft}: ${formatDistance(remaining.km)}',
                  if (left != null) formatDuration(left, t.lang),
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
