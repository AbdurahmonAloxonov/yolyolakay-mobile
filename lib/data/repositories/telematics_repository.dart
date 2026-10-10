import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/telematics.dart';

/// Joylashuv va marshrut — gateway'ning TELEMATIKA qismi.
///
/// 🔴 2026-08-14 jonli o'lchov: bu uchala endpoint ALLAQACHON ishlaydi, lekin
/// ilova ham, sayt ham ularni umuman chaqirmasdi:
///   POST /telematics/ping   -> 202 {"status":"accepted"}
///   GET  /telematics/nearby -> [{"driver_id": "...", "distance": 0.2}]
///   GET  /routing/route     -> {"distance":285452.6,"duration":17076.5,
///                               "geometry":[{latitude,longitude}, ...]}
///
/// Ya'ni safar masofasi va davomiyligini serverdan olish mumkin edi, biz esa
/// ularni umuman ko'rsatmasdik.
class TelematicsRepository {
  TelematicsRepository(this._client);

  final ApiClient _client;

  /// Haydovchining joylashuvi (safar davomida).
  ///
  /// Javob 202 — server qabul qildi. Xato bo'lsa ham safar buzilmaydi:
  /// chaqiruvchi buni jimgina yutadi (yo'lda tarmoq uzilishi odatiy).
  Future<void> ping({
    required double lat,
    required double lon,
    double? speed,
    double? heading,
  }) async {
    try {
      await _client.dio.post<dynamic>(
        '/telematics/ping',
        data: {
          'latitude': lat,
          'longitude': lon,
          'speed': ?speed,
          'heading': ?heading,
        },
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// SAFAR BO'YICHA haydovchining joyi — `GET /rides/{id}/location`.
  ///
  /// 🔴 NEGA `nearby` EMAS (2026-09-04): biz backenddan `nearby` ni
  /// yopishni so'ragandik va u YOPILDI — endi u faqat HAYDOVCHIGA
  /// ochiq, yo'lovchi 403 oladi:
  ///   «nearby driver telemetry is restricted to drivers.
  ///    Passengers must use /api/v1/rides/{id}/location»
  /// Ya'ni eski chaqiruv jimgina bo'sh ro'yxat qaytarib, xaritada
  /// mashina UMUMAN chizilmay qolardi.
  ///
  /// 🔑 Yangi manzil to'g'ri narsani ham qiladi: AYNAN shu safarning
  /// haydovchisini beradi (ilgari butun ro'yxatdan `driver_id` bo'yicha
  /// izlardik) va ruxsatni serverning O'ZI tekshiradi — tasdiqlanmagan
  /// bron ham, begona odam ham 403 oladi (o'lchandi 03.09 va 04.09).
  ///
  /// ⚠️ Javobda `distance` YO'Q — u faqat `nearby` da bor edi.
  ///
  /// [watchToken] — KUZATUV TOKENI (16.09.2026). Berilsa so'rov
  /// autentifikatsiyasiz ham ishlaydi: server ruxsatni shu token
  /// bo'yicha tekshiradi (izohi `ride_share.dart` da).
  ///
  /// ⚠️ Javob SHAKLI ikki xil (prodda o'lchandi):
  ///   tokenli     → {driver_id, latitude, longitude, speed, heading}
  ///   watch_token → {lat, lon, heading}      ← PII kamaytirilgan
  /// `NearbyDriver.fromJson` ikkala nomni ham o'qiydi, shuning uchun
  /// bu yerda qo'shimcha ish kerak emas.
  Future<NearbyDriver?> rideLocation(
    String rideId, {
    String? watchToken,
  }) async {
    try {
      final res = await _client.dio.get<dynamic>(
        '/rides/$rideId/location',
        queryParameters: watchToken == null
            ? null
            : {'watch_token': watchToken},
      );
      final data = unwrap(res.data);
      if (data is! Map<String, dynamic>) return null;
      final d = NearbyDriver.fromJson(data);
      return d.hasPosition ? d : null;
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Yaqin-atrofdagi haydovchilar (masofa METRDA qaytadi).
  ///
  /// ⚠️ 2026-09-04 dan FAQAT HAYDOVCHIGA ochiq — yo'lovchi 403 oladi.
  /// Yo'lovchi uchun [rideLocation] ishlatiladi.
  Future<List<NearbyDriver>> nearby({
    required double lat,
    required double lon,
    double radiusMeters = 5000,
  }) async {
    try {
      final res = await _client.dio.get<dynamic>(
        '/telematics/nearby',
        queryParameters: {'lat': lat, 'lon': lon, 'radius': radiusMeters},
      );
      return asList(
        unwrap(res.data),
        'drivers',
      ).map(NearbyDriver.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Haydovchining berilgan nuqtaga yetib kelish vaqti.
  Future<EtaInfo?> eta({
    required String driverId,
    required double targetLat,
    required double targetLon,
  }) async {
    try {
      final res = await _client.dio.get<dynamic>(
        '/telematics/eta',
        queryParameters: {
          'driver_id': driverId,
          'target_lat': targetLat,
          'target_lon': targetLon,
        },
      );
      final map = asMap(unwrap(res.data));
      return map == null ? null : EtaInfo.fromJson(map);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Marshrut: masofa, davomiylik va chiziq nuqtalari.
  Future<RouteInfo?> route({
    required double originLat,
    required double originLon,
    required double destLat,
    required double destLon,
  }) async {
    try {
      final res = await _client.dio.get<dynamic>(
        '/routing/route',
        queryParameters: {
          'origin_lat': originLat,
          'origin_lon': originLon,
          'dest_lat': destLat,
          'dest_lon': destLon,
        },
      );
      final map = asMap(unwrap(res.data));
      return map == null ? null : RouteInfo.fromJson(map);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}
