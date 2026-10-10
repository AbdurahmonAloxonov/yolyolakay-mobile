import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/parcel.dart';

/// Pochta (posilkalar).
///
/// ✅ 2026-08-12: `/parcels/my` va `/parcels/{id}/responses` gateway'da PAYDO
/// BO'LDI (swagger sverkasi — 74 yo'l, md5 98461fc4…). Backend qo'shganini
/// aytmagan, shuning uchun ilova oylab "bunday yo'l yo'q" deb yurdi va
/// yuboruvchiga "ro'yxatni ko'rish imkonsiz" degan uzr chiqarardi.
///
/// ✅ 2026-08-13 jonli o'lchov: qidiruv `driver_id` ni BOSHQA talab qilmaydi
/// (kim qidirayotgani tokendan olinadi) — parametrsiz so'rov 200 qaytardi.
class ParcelsRepository {
  ParcelsRepository(this._client);

  final ApiClient _client;

  Future<Parcel> create(CreateParcelRequest request) async {
    try {
      final res = await _client.dio.post<dynamic>(
        '/parcels',
        data: request.toJson(),
      );
      return Parcel.fromJson(asMap(unwrap(res.data)) ?? const {});
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Yaqin-atrofdagi posilkalar.
  ///
  /// 🔴 `radius` — METRDA (swagger: «Радиус поиска в метрах», default 5000).
  /// Ilgari bu yerga kilometr YUBORILARDI: ekranda "25 km" tursa ham serverga
  /// 25 METR ketardi va haydovchi deyarli hech qachon posilka topmasdi.
  /// 2026-08-13 jonli o'lchov: `radius=25` va `radius=1000` — bo'sh,
  /// `radius=5000` — 4 ta posilka. Shu sabab bu yerda kilometrni metrga
  /// aylantiramiz.
  ///
  /// ⚠️ `/rides/search` esa `radius_km` (KILOMETR) ni oladi — ikki endpoint
  /// ikki xil birlikda ishlaydi, aynan shu chalkashlik xatoga sabab bo'lgan.
  Future<List<Parcel>> search({
    required double lat,
    required double lon,
    double radiusKm = 25,
  }) async {
    try {
      final res = await _client.dio.get<dynamic>(
        '/parcels/search',
        queryParameters: {'lat': lat, 'lon': lon, 'radius': radiusKm * 1000},
      );
      return asList(unwrap(res.data), 'parcels').map(Parcel.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Posilkaga TAKLIF berish (haydovchi narx aytadi, jo'natuvchi tanlaydi).
  ///
  /// 🔴 2026-08-13 gacha ilova buning o'rniga `POST /parcels/{id}/accept` ni
  /// chaqirardi — ya'ni haydovchi posilkani jo'natuvchidan SO'RAMASDAN o'ziga
  /// biriktirib olardi va narx muhokamasi bo'lmasdi. Saytda esa taklif oqimi
  /// edi, ikkala mijoz bir-biriga zid ishlardi. Jo'natuvchi ekrani (ilovada
  /// ham, saytda ham) "haydovchi takliflari" ro'yxatini ko'rsatadi, ya'ni
  /// to'g'ri oqim — shu.
  ///
  /// Jonli o'lchov (2026-08-13): 201 qaytadi, javob `ParcelResponse`.
  Future<ParcelResponse> respond(String parcelId, double offeredPrice) async {
    try {
      final res = await _client.dio.post<dynamic>(
        '/parcels/$parcelId/respond',
        data: {'offered_price': offeredPrice},
      );
      return ParcelResponse.fromJson(asMap(unwrap(res.data)) ?? const {});
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Posilkani TO'G'RIDAN-TO'G'RI olish. `driver_id` tanada emas, QUERY'da.
  ///
  /// ⚠️ Hozir UI'dan chaqirilmaydi (yuqoridagi `respond` ga o'tildi), lekin
  /// endpoint bor va jo'natuvchi taklifni qabul qilganda backend ichida shu
  /// yo'l ishlaydi. Jonli: kvota yetmasa 403 «insufficient parcel quota».
  Future<Parcel> accept(String parcelId, String driverId) async {
    try {
      final res = await _client.dio.post<dynamic>(
        '/parcels/$parcelId/accept',
        queryParameters: {'driver_id': driverId},
      );
      return Parcel.fromJson(asMap(unwrap(res.data)) ?? const {});
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// O'z posilkalarim. `role` — `sender` (standart) yoki `driver`.
  ///
  /// Parametr ATAYIN uzatiladi: `/rides/my` da rolni tushirib qoldirish
  /// butunlay boshqa shakldagi javob berardi, shu sabab bu yerda ham
  /// taxminga tayanmaymiz.
  Future<List<Parcel>> mine({String role = 'sender'}) async {
    try {
      final res = await _client.dio.get<dynamic>(
        '/parcels/my',
        queryParameters: {'role': role},
      );
      return asList(unwrap(res.data), 'parcels').map(Parcel.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Posilkaga kelgan haydovchi takliflari.
  Future<List<ParcelResponse>> responses(String parcelId) async {
    try {
      final res = await _client.dio.get<dynamic>(
        '/parcels/$parcelId/responses',
      );
      return asList(
        unwrap(res.data),
        'responses',
      ).map(ParcelResponse.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Posilkani bekor qilish (yuboruvchi).
  ///
  /// Backend 403 ham qaytarishi mumkin — masalan haydovchi biriktirilgandan
  /// keyin. Xato ekranga chiqadi, jim yutilmaydi.
  Future<void> cancel(String parcelId) async {
    try {
      await _client.dio.post<dynamic>('/parcels/$parcelId/cancel');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Posilkani OLDIM (haydovchi) — holat `picked_up` bo'ladi.
  ///
  /// ✅ Backend 2026-08-16 kechqurun qo'shdi (biz so'ragan edik — xat
  /// `BACKEND_XAT_POSILKA_2026-08-16`). Ungacha posilka `accepted` da
  /// ABADIY qolardi: jo'natuvchi yetkazilganini bilmasdi, ro'yxat
  /// tozalanmasdi, baholash ham ishga tushmasdi.
  ///
  /// ⚠️ Nomi `in_transit` EMAS — `Parcel.isPickedUp` izohiga qarang.
  Future<void> pickup(String parcelId) => _post('/parcels/$parcelId/pickup');

  /// Posilkani YETKAZDIM (haydovchi) — `delivered`.
  Future<void> deliver(String parcelId) => _post('/parcels/$parcelId/deliver');

  /// JO'NATUVCHI posilkani yopadi — `POST /parcels/{id}/confirm-delivery`.
  ///
  /// ✅ Backend 2026-09-04 da qo'shdi (biz so'ragan edik).
  ///
  /// 🔴 Nega kerak edi: yopish tugmasi FAQAT haydovchida edi. Haydovchi
  /// posilkani berib tugmani bosmasa (yoki ilovani o'chirsa), posilka
  /// `picked_up` da abadiy qolardi va jo'natuvchining qo'lidan hech
  /// narsa kelmasdi. Endi ikkala tomon ham yopa oladi.
  ///
  /// ⚠️ Ruxsat serverda qat'iy: faqat jo'natuvchi yoki tayinlangan
  /// haydovchi; begona odam 400 oladi va holat o'zgarmaydi (o'lchandi).
  Future<void> confirmDelivery(String parcelId) =>
      _post('/parcels/$parcelId/confirm-delivery');

  Future<void> _post(String path) async {
    try {
      await _client.dio.post<dynamic>(path);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> acceptResponse(String parcelId, String responseId) =>
      _postResponse(parcelId, responseId, 'accept');

  Future<void> rejectResponse(String parcelId, String responseId) =>
      _postResponse(parcelId, responseId, 'reject');

  Future<void> _postResponse(
    String parcelId,
    String responseId,
    String action,
  ) async {
    try {
      await _client.dio.post<dynamic>(
        '/parcels/$parcelId/responses/$responseId/$action',
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}
