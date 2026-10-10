import 'dart:async';

import 'package:dio/dio.dart';

import 'cities.dart';

/// Geokoder — ro'yxatda yo'q manzillar uchun (Nominatim / OpenStreetMap).
///
/// `core/cities.dart` ro'yxati asosiy manba bo'lib qoladi: u web bilan
/// koordinata pariteti kafolatlangan yagona joy. Geokoder faqat ro'yxatda
/// topilmagan so'rovda ishlaydi — mahalla, ko'cha, orientir kabi nomlar uchun.
///
/// ⚠ Nominatim foydalanish qoidasi: soniyasiga 1 so'rov va aniq `User-Agent`.
/// Shuning uchun so'rovlar debounce bilan yuboriladi va o'z klientimiz
/// ishlatiladi (gateway `ApiClient` emas — u `Authorization` qo'shadi va
/// begona xostga token yuborish mumkin emas).
///
/// ─────────────────────────────────────────────────────────────────
/// 🔴 ZAXIRA: BIZNING O'Z GEOKODERIMIZ (18.09.2026)
/// ─────────────────────────────────────────────────────────────────
///
/// Manzil qidiruvi shu paytgacha BUTUNLAY Nominatim'ning jamoat
/// serveriga bog'liq edi: u bepul, soniyasiga bitta so'rovga ruxsat
/// beradi va istagan paytda bloklashi mumkin. Bloklansa — ikkala
/// mijozda ham manzil kiritish O'LADI. (Xuddi shu xavf xarita
/// plitkalarida ham bor edi, u 18.09 da yopildi.)
///
/// Backendda esa `GET /routing/geocode` va `/routing/reverse-geocode`
/// BOR va ishlatilmasdan yotardi. Jonli o'lchandi (18.09.2026,
/// tokensiz — mehmonga ochiq):
///     geocode?q=Samarqand → 200
///       [{display_name, coordinate:{latitude, longitude}}]
///     reverse-geocode?lat&lon → 200 {display_name, coordinate}
/// Lotin, kirill va `Fargʻona` kabi apostrofli so'rovni ham tushunadi,
/// ko'cha darajasigacha topadi.
///
/// 🔴 LEKIN JAVOB HAR DOIM RUSCHA: «Самарканд, Самаркандская область».
/// Til parametri YO'Q — `accept-language`, `lang`, `locale` uchalasi
/// ham JIM YUTILADI (o'lchandi). Nominatim esa `accept-language=uz`
/// bilan «Samarqand shahri, Samarqand viloyati» beradi.
///
/// Shuning uchun almashtirish EMAS, ZAXIRA: birinchi navbatda
/// Nominatim (o'zbekcha), u yiqilsa yoki bo'sh qaytarsa — o'zimizniki
/// (ruscha, lekin ISHLAYDI). Til parametri qo'shilsa tartib
/// almashtiriladi — backendga xat yozildi.
class Geocoder {
  Geocoder({Dio? api})
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'https://nominatim.openstreetmap.org',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'User-Agent': 'YolYolakay/1.0 (uz.yolyolakay.mobile)'},
        ),
      ) {
    // ⚠️ Tanadan berilади: Dart nomli parametrni `_api` deb atashga
    // ruxsat bermaydi, ya'ni `this._api` qisqartmasi bu yerda mumkin emas.
    _api = api;
  }

  final Dio _dio;

  /// Gateway mijozi — zaxira geokoder uchun. `null` bo'lsa zaxira yo'q
  /// (sinovlarda va geokoder tashqi manbasiz yaratilganda).
  Dio? _api;

  /// Nominatim qoidasiga rioya qilish uchun so'rovlar orasidagi eng kam vaqt.
  static const _minInterval = Duration(milliseconds: 1100);
  DateTime _lastCall = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _throttle() async {
    final since = DateTime.now().difference(_lastCall);
    if (since < _minInterval) await Future<void>.delayed(_minInterval - since);
    _lastCall = DateTime.now();
  }

  /// Nom bo'yicha qidiruv — faqat O'zbekiston ichida.
  ///
  /// Xato/timeout holatida BO'SH ro'yxat qaytadi: geokoder yordamchi vosita,
  /// uning yiqilishi joy tanlashni to'sib qo'ymasligi kerak.
  Future<List<GeoResult>> search(String query) async {
    if (query.trim().length < 3) return const [];
    try {
      await _throttle();
      final res = await _dio.get<dynamic>(
        '/search',
        queryParameters: {
          'q': query,
          'countrycodes': 'uz',
          'format': 'jsonv2',
          'limit': 8,
          'accept-language': 'uz',
        },
      );
      final data = res.data;
      if (data is List) {
        final rows = data
            .whereType<Map>()
            .map((e) => GeoResult.fromJson(e.cast<String, dynamic>()))
            .where((r) => r != null)
            .cast<GeoResult>()
            .toList();
        if (rows.isNotEmpty) return rows;
      }
    } catch (_) {
      // jim — pastdagi zaxiraga tushamiz
    }
    // Nominatim yiqildi yoki hech nima topmadi — O'ZIMIZNIKI.
    return _searchOurs(query);
  }

  /// Zaxira qidiruv — `GET /routing/geocode` (bizning backend).
  ///
  /// ⚠️ Natija RUSCHA keladi (til parametri yo'q — izohi yuqorida).
  /// Ruscha nom «hech nima yo'q» dan yaxshi: odam joyni tanlay oladi va
  /// safar yaratish to'xtab qolmaydi.
  Future<List<GeoResult>> _searchOurs(String query) async {
    final api = _api;
    if (api == null) return const [];
    try {
      final res = await api.get<dynamic>(
        '/routing/geocode',
        queryParameters: {'q': query, 'limit': 8},
      );
      final data = res.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => GeoResult.fromOurs(e.cast<String, dynamic>()))
          .whereType<GeoResult>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Koordinatadan manzil nomi (xaritadan nuqta tanlanganda).
  ///
  /// Topilmasa — eng yaqin ma'lum joy nomi, u ham bo'lmasa `null`.
  Future<String?> reverse(double lat, double lon) async {
    // 🔴 CURATED RO'YXAT USTUN (2026-08-20, egasi qurilmada: "Chortoq
    // baynalni Koroskon ko'rsatvoryapti"). Nominatim shahar markazidagi
    // nuqtada ham eng mayda birlikni — mahalla/qishloqni — qaytaradi:
    // Chortoqda `village: Короскон` keladi, garchi odam "Chortoq" ni
    // kutsa. Bizning curated ro'yxatimiz aniq va ishonchli, shuning uchun
    // nuqta ma'lum shaharga YAQIN bo'lsa (~12 km), Nominatim'ga umuman
    // bormaymiz. Faqat ro'yxatda yo'q joyda tashqi manbaga tayanamiz.
    final near = nearestPlace(lat, lon, maxKm: 12);
    if (near != null) return near.name;

    try {
      await _throttle();
      final res = await _dio.get<dynamic>(
        '/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          // zoom 12 = shahar/tuman darajasi (14 mahallagacha tushardi).
          'zoom': 12,
          'format': 'jsonv2',
          'accept-language': 'uz',
        },
      );
      final data = res.data;
      if (data is Map) {
        final name = _shortName(data.cast<String, dynamic>());
        if (name != null) return name;
      }
    } catch (_) {
      // jim — pastdagi zaxiraga tushamiz
    }

    // ZAXIRA: bizning `GET /routing/reverse-geocode` (ruscha, lekin bor).
    final api = _api;
    if (api != null) {
      try {
        final res = await api.get<dynamic>(
          '/routing/reverse-geocode',
          queryParameters: {'lat': lat, 'lon': lon},
        );
        final data = res.data;
        if (data is Map) {
          final display = '${data['display_name'] ?? ''}';
          if (display.isNotEmpty) {
            // To'liq manzil uzun («Сеульская улица, Бешагач махалля,
            // …, Ташкент, 100000, Узбекистан») — kartaga sig'adigan
            // birinchi bo'lagi olinadi, xuddi Nominatim'dagidek.
            return normalizeApostrophe(display.split(',').first.trim());
          }
        }
      } catch (_) {
        // jim — oxirgi zaxira pastda
      }
    }

    return nearestPlace(lat, lon, maxKm: 60)?.name;
  }

  /// Nominatim to'liq manzilni juda uzun beradi ("Chilonzor tumani, Toshkent,
  /// 100115, O'zbekiston") — kartaga sig'adigan qismini olamiz.
  static String? _shortName(Map<String, dynamic> json) {
    final address = json['address'];
    if (address is Map) {
      // 🔴 TARTIB MUHIM (2026-08-20). Ilgari `suburb`/`village` (mahalla)
      // `city`/`county` (aholi punkti/tuman) dan OLDIN turardi va Chortoqda
      // "Короскон" chiqardi. Odam "qayerga" deganda aholi punktini/tumanni
      // tushunadi, mahallani emas — shuning uchun avval kattaroq birlik.
      // Mahalla (`suburb`/`village`) faqat kattaroq nom umuman bo'lmasa.
      for (final key in [
        'city',
        'town',
        'municipality',
        'county', // "Chortoq tumani"
        'village',
        'suburb',
        'city_district',
      ]) {
        final value = address[key];
        if (value is String && value.isNotEmpty) {
          // "Chortoq tumani" -> "Chortoq": ma'muriy qo'shimcha kesiladi,
          // aks holda kartada "... tumani" bo'lib joy egallaydi.
          return normalizeApostrophe(stripAdminSuffix(value));
        }
      }
    }
    final display = json['display_name'];
    if (display is String && display.isNotEmpty) {
      return normalizeApostrophe(display.split(',').first.trim());
    }
    return null;
  }
}

/// Geokoder natijasi — `Place` bilan bir xil ishlatiladi, lekin ro'yxatdan
/// emas, tashqi manbadan kelgani bilinib tursin uchun alohida tur.
class GeoResult {
  const GeoResult({
    required this.name,
    required this.lat,
    required this.lon,
    this.detail,
  });

  final String name;
  final double lat;
  final double lon;

  /// To'liq manzil — ro'yxatda ikkinchi qator sifatida.
  final String? detail;

  /// Ilova ichida joy sifatida ishlatish uchun.
  Place toPlace() =>
      Place(name: name, lat: lat, lon: lon, region: detail ?? '');

  /// BIZNING backend javobi — Nominatim'dan BOSHQA shakl:
  /// `{display_name, coordinate: {latitude, longitude}}`.
  ///
  /// ⚠️ Koordinata ICHKI obyektda. Nominatim'dagi `lat`/`lon` ni
  /// o'qiydigan kod bu yerda jimgina `null` qaytarardi — ya'ni zaxira
  /// «ishladi» deb ko'rinib, ro'yxat BO'SH chiqardi.
  static GeoResult? fromOurs(Map<String, dynamic> json) {
    final coord = json['coordinate'];
    if (coord is! Map) return null;
    final lat = double.tryParse('${coord['latitude']}');
    final lon = double.tryParse('${coord['longitude']}');
    if (lat == null || lon == null) return null;
    final display = '${json['display_name'] ?? ''}'.trim();
    if (display.isEmpty) return null;
    return GeoResult(
      name: normalizeApostrophe(display.split(',').first.trim()),
      lat: lat,
      lon: lon,
      detail: normalizeApostrophe(display),
    );
  }

  static GeoResult? fromJson(Map<String, dynamic> json) {
    final lat = double.tryParse('${json['lat']}');
    final lon = double.tryParse('${json['lon']}');
    if (lat == null || lon == null) return null;

    final display = '${json['display_name'] ?? ''}';
    final rawName = '${json['name'] ?? ''}'.isNotEmpty
        ? '${json['name']}'
        : display.split(',').first.trim();
    if (rawName.isEmpty) return null;

    // Apostrof standartlashtiriladi (izoh `normalizeApostrophe` da) — aks
    // holda geocoderdan kelgan `Fargʻona` curated `Farg'ona` dan farq
    // qilib, ekranda begona belgi bo'lib ko'rinadi.
    return GeoResult(
      name: normalizeApostrophe(rawName),
      lat: lat,
      lon: lon,
      detail: normalizeApostrophe(display),
    );
  }
}
