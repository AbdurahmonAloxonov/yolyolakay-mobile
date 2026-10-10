import '../../core/api/api_client.dart';
import '../../core/json.dart';

/// `GET /routing/route` javobi.
///
/// Jonli shakl (2026-08-14):
/// `{"distance":285452.6,"duration":17076.5,"geometry":[{latitude,longitude}...]}`
/// — masofa METRDA, davomiylik SONIYADA.
class RouteInfo {
  const RouteInfo({
    required this.distanceMeters,
    required this.durationSeconds,
    this.points = const [],
  });

  final double distanceMeters;
  final double durationSeconds;
  final List<RoutePoint> points;

  double get distanceKm => distanceMeters / 1000;
  Duration get duration => Duration(seconds: durationSeconds.round());

  factory RouteInfo.fromJson(Map<String, dynamic> json) => RouteInfo(
    distanceMeters: asDouble(pick(json, ['distance', 'distance_meters']) ?? 0),
    durationSeconds: asDouble(
      pick(json, ['duration', 'duration_seconds']) ?? 0,
    ),
    points: asList(json, 'geometry').map(RoutePoint.fromJson).toList(),
  );
}

class RoutePoint {
  const RoutePoint(this.lat, this.lon);

  final double lat;
  final double lon;

  factory RoutePoint.fromJson(Map<String, dynamic> json) => RoutePoint(
    asDouble(pick(json, ['latitude', 'lat']) ?? 0),
    asDouble(pick(json, ['longitude', 'lon', 'lng']) ?? 0),
  );
}

/// `GET /telematics/nearby` elementi.
///
/// 🔴 `distance` — METRDA, kilometrda EMAS (30.08 da o'lchandi:
/// ping nuqtasidan 1 km shimolga so'ralganda javob `1000.99` keldi,
/// 10 km da `10010.4`). Ilgari bu maydon `distanceKm` deb o'qilardi va
/// qiymat 1000 barobar katta chiqardi. Xato ekranda ko'rinmagan edi —
/// hozircha faqat koordinata ishlatilyapti — lekin masofani birinchi
/// marta chizgan joyda "1000 km qoldi" bo'lib chiqardi.
class NearbyDriver {
  const NearbyDriver({
    required this.driverId,
    this.distanceMeters,
    this.lat,
    this.lon,
    this.heading,
    this.updatedAt,
  });

  final String driverId;
  final double? distanceMeters;

  double? get distanceKm =>
      distanceMeters == null ? null : distanceMeters! / 1000;

  /// Haydovchining OXIRGI ma'lum joylashuvi.
  ///
  /// 🔴 Bu maydonlar 2026-08-22 da PAYDO BO'LDI: ilgari javobda faqat
  /// `distance` bor edi va shu sabab mashinani xaritada ko'rsatib
  /// bo'lmasdi — taxminiy nuqta chizish yolg'on bo'lardi. Backenddan
  /// so'ralgan edi (xat §9), qo'shildi va jonli tasdiqlandi.
  ///
  /// ⚠️ Baribir `null` bo'lishi mumkin (eski javob keshda, boshqa
  /// gateway) — chaqiruvchi shunda mashinani CHIZMAYDI.
  final double? lat;
  final double? lon;

  /// Ping QACHON kelgani — ma'lumot tirikmi yoki eskirganmi.
  ///
  /// 🔴 NEGA KERAK (17.09.2026): bu maydon serverdan KELARDI
  /// (`updated_at`), sayt uni ko'rsatardi, ilova esa O'QIMASDI. Natija:
  /// haydovchi ilovani yopgan bo'lsa ham mashina nuqtasi xaritada
  /// o'sha joyda qotib turardi va JONLI nuqtadan farq qilmasdi —
  /// ya'ni xarita «hammasi joyida» deb yolg'on gapirardi. Backend
  /// oxirgi pingni cheklangan vaqt saqlaydi va ~40 daqiqadan keyin
  /// `404 driver location not available or offline` qaytaradi.
  ///
  /// ⚠️ `null` bo'lishi mumkin (eski gateway javobi) — shunda yosh
  /// KO'RSATILMAYDI, «0 daqiqa oldin» deb taxmin qilinmaydi.
  final DateTime? updatedAt;

  /// Ping YOSHI. Kelajakdagi vaqt (soat farqi) nolga qisiladi.
  Duration? ageAt(DateTime now) {
    final at = updatedAt;
    if (at == null) return null;
    final age = now.difference(at);
    return age.isNegative ? Duration.zero : age;
  }

  /// Harakat yo'nalishi — SHIMOLDAN soat strelkasi bo'yicha, gradusda.
  ///
  /// 🔴 Bu maydon `.com` gateway'ida paydo bo'ldi (2026-08-27 sverkasi).
  /// Qizig'i: ilova uni ALLAQACHON yuborardi (`live_ping.dart` →
  /// `POST /telematics/ping`), lekin hech kim qaytib o'qimasdi — ya'ni
  /// ma'lumot bor edi-yu, ishlatilmasdi.
  ///
  /// ⚠️ `null` yoki mantiqsiz qiymat bo'lishi mumkin (qurilma kompasi
  /// bermasa Android `-1` beradi), shuning uchun `hasHeading` tekshiradi.
  final double? heading;

  bool get hasPosition => lat != null && lon != null;

  /// Yo'nalish ISHONCHLIMI. 0–360 oralig'idan tashqarisi — chalkash
  /// ma'lumot; mashinani noto'g'ri burgandan ko'ra burmagan yaxshi.
  bool get hasHeading => heading != null && heading! >= 0 && heading! <= 360;

  factory NearbyDriver.fromJson(Map<String, dynamic> json) => NearbyDriver(
    driverId: asString(pick(json, ['driver_id', 'driverId'])),
    distanceMeters: () {
      // `distance_km` nomi kelsa u ROSTDAN kilometr — metrga o'giramiz.
      final km = pick(json, ['distance_km']);
      if (km != null) return asDouble(km) * 1000;
      final raw = pick(json, ['distance', 'distance_meters']);
      return raw == null ? null : asDouble(raw);
    }(),
    lat: () {
      final raw = pick(json, ['latitude', 'lat']);
      return raw == null ? null : asDouble(raw);
    }(),
    heading: () {
      final raw = pick(json, ['heading', 'bearing', 'course']);
      return raw == null ? null : asDouble(raw);
    }(),
    // ⚠️ `asDate` — Go'ning NOL VAQTI (`0001-01-01`) shu yerda
    // to'siladi, aks holda ping yoshi «1 060 000 daqiqa» bo'lib
    // chiqardi (izohi `core/json.dart` da).
    updatedAt: asDate(pick(json, ['updated_at', 'updatedAt', 'timestamp'])),
    lon: () {
      final raw = pick(json, ['longitude', 'lon', 'lng']);
      return raw == null ? null : asDouble(raw);
    }(),
  );
}

/// `GET /telematics/eta` javobi — maydon nomlari hali tekshirilmagan,
/// shuning uchun bir nechta nom qabul qilinadi.
class EtaInfo {
  const EtaInfo({this.seconds, this.distanceKm});

  final double? seconds;
  final double? distanceKm;

  Duration? get duration =>
      seconds == null ? null : Duration(seconds: seconds!.round());

  factory EtaInfo.fromJson(Map<String, dynamic> json) => EtaInfo(
    seconds: () {
      final raw = pick(json, ['eta_seconds', 'duration', 'seconds', 'eta']);
      return raw == null ? null : asDouble(raw);
    }(),
    distanceKm: () {
      final raw = pick(json, ['distance_km', 'distance']);
      return raw == null ? null : asDouble(raw);
    }(),
  );
}
