import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../../core/geo.dart';

/// Yo'l bo'ylab marshrut geometriyasi.
///
/// 🔴 Nima buzilgan edi (egasi qurilmada, 2026-08-13): xaritada marshrut
/// o'rniga shunchaki TO'G'RI CHIZIQ tortilgan edi — Toshkentdan Samarqandga
/// chiziq tog' ustidan o'tib ketardi. Yo'lovchi uchun bu ma'lumot emas.
///
/// ✅ 2026-08-20 (egasi): marshrut endi BIZNING BACKEND orqali olinadi —
/// `GET /api/v1/routing/route` (OSM dvigateli, ichki). Ilgari OSRM DEMO
/// serveri (`router.project-osrm.org`) to'g'ridan chaqirilardi — u ommaviy
/// ilovaga ruxsat bermasdi. Endi kalit/limit backend tomonda, biz faqat
/// autentifikatsiyali `dio` bilan so'raymiz. Yandex O'RNIGA ham shu (sayt
/// bilan bir manba).
///
/// 🔴 Endpoint FAQAT origin->dest oladi (oraliq bekatlarsiz). Shuning uchun
/// bir necha nuqtali marshrutда ketма-кет juftlар so'raladi va geometriya
/// ULANADI. Xato/tarmoq bo'lса — kirish nuqtalarining o'zi (to'g'ri chiziq),
/// xarita hech qachon bo'sh qolmaydi.
class RoadRoute {
  const RoadRoute({required this.points, this.distanceMeters, this.seconds});

  final List<LatLng> points;

  /// Haqiqiy yo'l masofasi va vaqti. Xizmat javob bermasa `null` — TAXMINIY
  /// qiymat ko'rsatmaymiz, uni odam haqiqat deb qabul qiladi.
  final double? distanceMeters;
  final int? seconds;

  bool get isRealRoad => distanceMeters != null;
}

/// [waypoints] bo'ylab haydash marshrutini BIZNING backenddan oladi.
///
/// [dio] — autentifikatsiyali app klienti (`ApiClient.dio`), chunki endpoint
/// BearerAuth talab qiladi. Hech qachon xato tashlamaydi.
///
/// 🔴 KESH (28.09.2026, egasi: «xaritada to'g'ri chiziqlar, rasvo»).
/// Javob 2–4 soniya keladi (jonli o'lchandi: Toshkent–Samarqand 2.4 s,
/// Namangan–Toshkent 4.1 s) va shu vaqt ichida xaritada TO'G'RI CHIZIQ
/// turardi. Keshsiz bu HAR OCHILISHDA takrorlanardi: safar detalidagi
/// kichik karta va uning to'liq varag'i bir safarni ikki marta so'rardi.
/// Endi bir yo'nalish ilova yashagan davomida BIR MARTA so'raladi,
/// hatto ikki xarita bir vaqtda so'rasa ham (kesh `Future` ni saqlaydi).
/// Faqat HAQIQIY yo'l saqlanadi — xato keyingi safar qayta uriniladi.
Future<RoadRoute> fetchRoadRoute(
  List<LatLng> waypoints, {
  required Dio dio,
}) {
  if (waypoints.length < 2) return Future.value(RoadRoute(points: waypoints));
  final key = _routeKey(waypoints);
  final hit = _routeCache[key];
  if (hit != null) return hit;

  final future = _fetch(waypoints, dio);
  _routeCache[key] = future;
  future.then((route) {
    if (!route.isRealRoad) _routeCache.remove(key);
  });
  // Cheksiz o'smasin: eng eski yozuv chiqariladi (Map qo'shilish
  // tartibini saqlaydi).
  if (_routeCache.length > _routeCacheMax) {
    final oldest = _routeCache.keys.first;
    _routeCache.remove(oldest);
    // Tayyor nusxa ham birga chiqsin — aks holda `_resolved` cheksiz o'sardi.
    _resolved.remove(oldest);
  }
  return future;
}

/// Keshdagi TAYYOR yo'l — kutmasdan. Xarita birinchi kadrdayoq haqiqiy
/// yo'lni chizishi uchun (aks holda bir kadr to'g'ri chiziq «miltillaydi»).
RoadRoute? cachedRoadRoute(List<LatLng> waypoints) =>
    _resolved[_routeKey(waypoints)];

const _routeCacheMax = 200;
final _routeCache = <String, Future<RoadRoute>>{};
final _resolved = <String, RoadRoute>{};

/// ~11 m aniqlik: bir shahar markazidan chiqqan safarlar bitta yozuvga
/// tushadi, lekin boshqa ko'chadan chiqqan safar alohida qoladi.
String _routeKey(List<LatLng> pts) => pts
    .map((p) => '${p.latitude.toStringAsFixed(4)},'
        '${p.longitude.toStringAsFixed(4)}')
    .join('|');

/// Sinovlar uchun — har sinov toza keshdan boshlansin.
void clearRoadRouteCache() {
  _routeCache.clear();
  _resolved.clear();
}

Future<RoadRoute> _fetch(List<LatLng> waypoints, Dio dio) async {
  try {
    /*
     * Endpoint faqat IKKI nuqta oladi — bekatli marshrut bo'laklarga
     * bo'linadi. Bo'laklar endi PARALLEL so'raladi: ilgari ketma-ket
     * edi va uch bekatli safarda to'g'ri chiziq 10 soniyadan ortiq
     * turardi.
     */
    final segments = await Future.wait([
      for (var i = 0; i < waypoints.length - 1; i++)
        _segment(dio, waypoints[i], waypoints[i + 1]),
    ]);

    final all = <LatLng>[];
    double distance = 0;
    double duration = 0;
    var allReal = true;
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (seg == null) {
        // Bu bo'lakda yo'l topilmadi — to'g'ri chiziq bilan ulaymiz.
        allReal = false;
        if (all.isEmpty) all.add(waypoints[i]);
        all.add(waypoints[i + 1]);
        continue;
      }
      // Ulanishda takroriy nuqta bo'lmasin (oldingi bo'lak oxiri = bu boshi).
      all.addAll(all.isEmpty ? seg.points : seg.points.skip(1));
      distance += seg.distanceMeters ?? 0;
      duration += seg.seconds ?? 0;
    }

    // Biror bo'lak to'g'ri chiziq bo'lsa, marshrut HAQIQIY YO'L emas —
    // masofa/vaqt ham chala bo'ladi, ya'ni ko'rsatilmaydi.
    if (all.length < 2 || !allReal) return RoadRoute(points: waypoints);
    final route = RoadRoute(
      points: all,
      distanceMeters: distance > 0 ? distance : null,
      seconds: duration > 0 ? duration.round() : null,
    );
    if (route.isRealRoad) _resolved[_routeKey(waypoints)] = route;
    return route;
  } catch (_) {
    // Marshrut — bezak, ekranning asosiy mazmuni emas. Xato ko'rsatib
    // xaritani yopib qo'yish foydalanuvchiga zarar qiladi.
    return RoadRoute(points: waypoints);
  }
}

/// Bitta bo'lak. `null` — yo'l topilmadi (xato ham shu).
Future<RoadRoute?> _segment(Dio dio, LatLng a, LatLng b) async {
  try {
    final res = await dio.get<Map<String, dynamic>>(
      '/routing/route',
      queryParameters: {
        'origin_lat': a.latitude,
        'origin_lon': a.longitude,
        'dest_lat': b.latitude,
        'dest_lon': b.longitude,
      },
    );
    final data = res.data;
    final geometry = data?['geometry'];
    if (geometry is! List || geometry.length < 2) return null;
    final seg = <LatLng>[];
    for (final pt in geometry) {
      if (pt is Map) {
        final lat = (pt['latitude'] as num?)?.toDouble();
        final lon = (pt['longitude'] as num?)?.toDouble();
        if (lat != null && lon != null) seg.add(LatLng(lat, lon));
      }
    }
    if (seg.length < 2) return null;
    return RoadRoute(
      points: seg,
      distanceMeters: (data?['distance'] as num?)?.toDouble(),
      seconds: (data?['duration'] as num?)?.round(),
    );
  } catch (_) {
    return null;
  }
}

/// MARSHRUTNING QOLGAN QISMI — «qancha qoldi» degan savolga javob.
class RouteRemainder {
  const RouteRemainder({required this.meters, this.duration});

  final double meters;

  /// Taxminiy qolgan vaqt. Marshrut xizmati davomiylik bermasa `null` —
  /// o'zimiz o'ylab topmaymiz.
  final Duration? duration;

  double get km => meters / 1000;
}

/// Haydovchi marshrutning QAYSI joyida turganini topib, oldinda qancha
/// qolganini hisoblaydi.
///
/// 🔴 NEGA MIJOZDA HISOBLANADI (2026-08-30): serverning
/// `GET /telematics/eta` endpointi HAR DOIM `0` qaytaradi — 6 km uchun
/// ham, 280 km uchun ham (jonli o'lchandi, `probe.py tracking`).
/// Ya'ni «qancha qoldi» degan raqamni undan olib bo'lmaydi.
///
/// Lekin bizda hamma ma'lumot BOR: `GET /routing/route` haqiqiy yo'l
/// geometriyasini, masofasini va davomiyligini beradi (Toshkent–
/// Samarqand: 307 km, 3037 nuqta), joriy joylashuv esa qurilmadan.
/// Shuning uchun hisobni o'zimiz qilamiz va backendni kutmaymiz.
///
/// Qanday: [me] ga eng yaqin marshrut nuqtasi topiladi, undan oxirigacha
/// bo'lgan bo'laklar yig'iladi va bu ULUSH serverning haqiqiy masofa va
/// davomiyligiga qo'llaniladi. Ya'ni raqamlar to'g'ri chiziqniki emas,
/// HAQIQIY YO'LNIKI.
///
/// `null` qaytadi, agar:
///   • marshrut geometriyasi yo'q (ikkitadan kam nuqta), yoki
///   • odam marshrutdan [maxOffRouteKm] dan uzoqda — u boshqa yo'ldan
///     ketyapti va «qoldi» raqami YOLG'ON bo'lardi. Noto'g'ri raqamdan
///     ko'ra raqamsizlik yaxshi.
RouteRemainder? remainingOnRoute(
  RoadRoute route,
  LatLng me, {
  double maxOffRouteKm = 5,
}) {
  final pts = route.points;
  if (pts.length < 2) return null;

  var nearest = 0;
  var nearestKm = double.infinity;
  for (var i = 0; i < pts.length; i++) {
    final d = distanceKm(
      fromLat: me.latitude,
      fromLon: me.longitude,
      toLat: pts[i].latitude,
      toLon: pts[i].longitude,
    );
    if (d < nearestKm) {
      nearestKm = d;
      nearest = i;
    }
  }
  if (nearestKm > maxOffRouteKm) return null;

  double lengthFrom(int start) {
    var sum = 0.0;
    for (var i = start; i < pts.length - 1; i++) {
      sum += distanceKm(
        fromLat: pts[i].latitude,
        fromLon: pts[i].longitude,
        toLat: pts[i + 1].latitude,
        toLon: pts[i + 1].longitude,
      );
    }
    return sum;
  }

  final total = lengthFrom(0);
  final left = lengthFrom(nearest);
  if (total <= 0) return null;

  // Ulushni serverning HAQIQIY masofasiga qo'llaymiz: nuqtalar bo'yicha
  // yig'indi to'g'ri chiziqlardan iborat va haqiqiy yo'ldan bir oz
  // qisqaroq chiqadi.
  final ratio = (left / total).clamp(0.0, 1.0);
  final meters = (route.distanceMeters ?? total * 1000) * ratio;
  final seconds = route.seconds;

  return RouteRemainder(
    meters: meters,
    duration: seconds == null
        ? null
        : Duration(seconds: (seconds * ratio).round()),
  );
}
