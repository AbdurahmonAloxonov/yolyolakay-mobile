import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/json.dart';
import '../../core/local_cache.dart';
import '../models/booking.dart';
import '../models/ride.dart';

/// E'lon berish natijasi — safar yaratildi, lekin faollashmagan bo'lishi mumkin
/// (masalan mashina moderatsiyadan o'tmagan).
class PublishResult {
  const PublishResult({
    required this.rideId,
    required this.activated,
    this.error,
  });

  final String rideId;
  final bool activated;

  /// Faollashtirish nega yiqilgani. Ilgari xato BUTUNLAY yutilardi va ekran
  /// doim "qayta urinib ko'ring" deb ko'rsatardi. Backend 2026-08-12 dan
  /// Plus tarifida premium filtrlar uchun 400 qaytaradi — bunday xatoda
  /// qayta urinish HECH QACHON yordam bermaydi, sababni aytish kerak.
  final ApiException? error;

  /// Paket tugagani sabab faollashmadimi — bunda TARIFLAR ochilishi kerak.
  ///
  /// 🔴 09.09.2026 gacha bu holat HECH QACHON yuzaga chiqmagan: backend
  /// kvotani sanamasdi va `activate` doim 200 berardi. O'sha kuni sanay
  /// boshladi va ma'lum bo'ldiki, ekrandagi paywall kodiga YETIB
  /// BO'LMAYDI — `createAndActivate` xatoni otmaydi, uni shu obyektga
  /// solib qaytaradi. Endi ekran aynan shu bayroqqa qaraydi.
  bool get isQuotaExceeded => error?.isQuotaExceeded ?? false;

  /// Qayta urinish ma'noli bo'ladigan holat (tarmoq, 5xx). 400 — yo'q.
  ///
  /// ⚠️ Paket tugagani ham YO'Q: 402 da qayta urinish hech qachon
  /// yordam bermaydi va «Qayta urinish» tugmasi odamni aldab qo'yadi.
  bool get isRetryable =>
      error?.kind != ApiErrorKind.badRequest && !isQuotaExceeded;
}

/// Rides — safar hayot sikli: draft -> active -> in_progress -> completed.
class RidesRepository {
  RidesRepository(this._client, [this._cache]);

  final ApiClient _client;

  /// Offline kesh — ULANISH uzilganda oxirgi javob shundan beriladi
  /// (izohi `core/local_cache.dart` da). `null` bo'lsa kesh ishlamaydi
  /// va xatti-harakat avvalgidek qoladi.
  final LocalCache? _cache;

  /// Haydovchi statistikasi — `GET /rides/earnings`.
  ///
  /// Fon-o'qish: xatoda ekran o'zi "yuklab bo'lmadi" holatini ko'rsatadi,
  /// shuning uchun ApiException tashlanadi (bo'sh obyekt EMAS — aks holda
  /// tarmoq xatosi "0 so'm daromad" bo'lib ko'rinardi).
  Future<DriverStatistics> earnings() async {
    try {
      final res = await _client.dio.get<dynamic>('/rides/earnings');
      return DriverStatistics.fromJson(asMap(unwrap(res.data)) ?? const {});
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Tavsiyalar — `GET /rides/recommendations`.
  ///
  /// Fon-o'qish: xatoda blok UMUMAN chizilmaydi (foydalanuvchi buni
  /// so'ramagan), shuning uchun bo'sh natija qaytadi — xato tashlanmaydi.
  Future<RideRecommendations> recommendations() async {
    try {
      final res = await _client.dio.get<dynamic>('/rides/recommendations');
      return RideRecommendations.fromJson(asMap(unwrap(res.data)) ?? const {});
    } on DioException {
      return const RideRecommendations();
    }
  }

  /// Radius origin VA destination ikkalasiga qo'llanadi (AND).
  /// Sana va jins SERVERDA filtrlanadi (`RideSearchParams.toQuery`).
  Future<List<Ride>> search(RideSearchParams params) async {
    try {
      var rides = await _searchOnce(params);

      /*
       * 🔴 «AYOLLAR UCHUN» SO'ROVI BEQAROR — BIR MARTA QAYTA URINAMIZ.
       *
       * 08.09.2026 da jonli o'lchandi (5 daqiqa, har 60 soniyada):
       * `gender_restriction=female` bilan javob NAVBATMA-NAVBAT
       * 6 ta va 0 ta bo'lib keldi — bir xil so'rov, bir xil ma'lumot.
       * Ya'ni ikkinchi urinish katta ehtimol bilan to'la ro'yxatni
       * beradi.
       *
       * Bu QIYIN qaror: odatda "qayta urinish" xatoni yashiradi.
       * Lekin bu yerda narx boshqacha — ayol odam "safar yo'q ekan"
       * degan YOLG'ON xulosaga keladi va ilovadan chiqib ketadi.
       * Backenddan tuzatish so'raldi; tuzalgach shu blok o'chadi.
       *
       * ⚠️ FAQAT bo'sh natijada va FAQAT shu filtrda: boshqa
       * holatda bo'sh ro'yxat ROST javob bo'lishi mumkin.
       */
      if (params.womenOnly && rides.isEmpty) {
        rides = await _searchOnce(params);
      }

      rides.sort((a, b) {
        final aTime = a.departureTime;
        final bTime = b.departureTime;
        if (aTime == null || bTime == null) return 0;
        return aTime.compareTo(bTime);
      });
      return rides;
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<Ride>> _searchOnce(RideSearchParams params) async {
    final res = await _client.dio.get<dynamic>(
      '/rides/search',
      queryParameters: params.toQuery(),
    );
    return asList(unwrap(res.data), 'rides').map(Ride.fromJson).toList();
  }

  /// ⚠ `POST /rides/` DRAFT yaratadi va u qidiruvda CHIQMAYDI — shuning uchun
  /// alohida `createRide` emas, shu metod ishlatiladi.
  /// Yo'l oxiridagi slash Swagger'dagidek (`/rides/`) — slashsiz 404/redirect.
  ///
  /// Faollashtirish yiqilsa xato OTILMAYDI: safar allaqachon yaratilgan va
  /// buni yashirish eng yomon holat — haydovchi e'lonim bor deb o'ylab yuradi,
  /// aslida qidiruvda ko'rinmaydi. Natijada `activated: false` qaytadi.
  Future<PublishResult> createAndActivate(PublishRideRequest request) async {
    late final String rideId;
    try {
      final res = await _client.dio.post<dynamic>(
        '/rides/',
        data: request.toJson(),
      );
      rideId = asString(asMap(unwrap(res.data))?['ride_id']);
      if (rideId.isEmpty) throw ApiException(kind: ApiErrorKind.unknown);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }

    try {
      await activate(rideId);
      return PublishResult(rideId: rideId, activated: true);
    } catch (error) {
      return PublishResult(
        rideId: rideId,
        activated: false,
        error: ApiException.from(error),
      );
    }
  }

  /// draft -> active. Busiz safar qidiruvda ko'rinmaydi.
  Future<void> activate(String rideId) async {
    try {
      await _client.dio.post<dynamic>(
        '/rides/$rideId/activate',
        data: const {},
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Bitta safar detali. Gateway'da hali bo'lmasligi mumkin (404) →
  /// chaqiruvchi ro'yxatdagi ma'lumotga qaytadi, shuning uchun null qaytaramiz.
  ///
  /// ⚠️ Javobda `driver` BO'LMASLIGI mumkin (jonli kuzatilgan 2026-08-12) —
  /// shuning uchun bu natija bilan qo'ldagi safarni butunlay ALMASHTIRMANG,
  /// `Ride.mergedWith` ishlating: aks holda qidiruvdan kelgan haydovchi
  /// ma'lumoti yo'qoladi va ekranda ism o'rniga "Haydovchi" chiqib qoladi.
  Future<Ride?> byId(String rideId) async {
    try {
      final res = await _client.dio.get<dynamic>('/rides/$rideId');
      final body = unwrap(res.data);
      final raw = asMap(asMap(body)?['ride']) ?? asMap(body);
      if (raw == null || asString(raw['id']).isEmpty) return null;
      return Ride.fromJson(raw);
    } on DioException {
      return null;
    }
  }

  /// Mashina — `GET /vehicles/{id}` (backend 2026-08-07 da qo'shdi).
  ///
  /// Faqat ZAXIRA: odatda mashina safar javobining o'zida keladi (`car`).
  /// Xato yoki topilmasa `null` — chaqiruvchi mashina qatorini umuman
  /// chizmaydi, ya'ni odam bo'sh joy ham, xato ham ko'rmaydi (saytda ham
  /// shunday: `shared/api/vehicles.ts`).
  Future<RideVehicle?> vehicleById(String vehicleId) async {
    if (vehicleId.isEmpty) return null;
    try {
      final res = await _client.dio.get<dynamic>('/vehicles/$vehicleId');
      final body = unwrap(res.data);
      return RideVehicle.tryParse(asMap(body));
    } on DioException {
      return null;
    }
  }

  Future<void> start(String rideId) => _post('/rides/$rideId/start');
  Future<void> complete(String rideId) => _post('/rides/$rideId/complete');

  Future<void> cancel(String rideId, {String? reason}) async {
    try {
      await _client.dio.post<dynamic>(
        '/rides/$rideId/cancel',
        data: reason == null ? const {} : {'reason': reason},
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// O'z safarlarim (HAYDOVCHI) — `{rides: [...]}`, har ride'da `bookings[]`
  /// bo'lishi mumkin. ⚠ `role=passenger` BUTUNLAY boshqa shakl qaytaradi →
  /// [myBookings] ishlating.
  Future<List<Ride>> myRides({String? status}) async {
    try {
      final res = await _client.dio.get<dynamic>(
        '/rides/my',
        queryParameters: {'role': 'driver', 'status': ?status},
      );
      final rows = asList(unwrap(res.data), 'rides');
      // Filtrlangan so'rov keshni EZMASIN: `status` bilan kelgan javob
      // to'liq ro'yxat emas va uni "hammasi" deb saqlash yolg'on bo'lardi.
      if (status == null) await _cache?.writeList(CacheKeys.myRides, rows);
      return rows.map(Ride.fromJson).toList();
    } on DioException catch (e) {
      // 🔴 Ilgari bu yerda `return const []` turardi va uzilish "safaringiz
      // yo'q" ga aylanardi (telefonda ko'rilgan, 2026-08-13). Haydovchi
      // uchun bu xavfli: e'loni bor-yo'qligini bilmay, ikkinchisini
      // joylashi mumkin. Ekranda xato holati BOR — unga yo'l ochamiz.
      //
      // Internet UZILGAN bo'lsa esa xato emas, oxirgi ma'lumot beriladi
      // (server javob bergan xatolarda BERILMAYDI — `isOfflineError`).
      if (status == null && isOfflineError(e)) {
        final cached = _cache?.readList(CacheKeys.myRides);
        if (cached != null) return cached.map(Ride.fromJson).toList();
      }
      throw ApiException.from(e);
    }
  }

  /// O'z bronlarim (YO'LOVCHI) — GET /rides/my?role=passenger safarlarni EMAS,
  /// `{bookings: [...]}` qaytaradi. Safar detali (marshrut/narx) bu javobda YO'Q.
  Future<List<Booking>> myBookings() async {
    try {
      final res = await _client.dio.get<dynamic>(
        '/rides/my',
        queryParameters: const {'role': 'passenger'},
      );
      final rows = asList(unwrap(res.data), 'bookings');
      await _cache?.writeList(CacheKeys.myBookings, rows);
      return rows.map(Booking.fromJson).toList();
    } on DioException catch (e) {
      // 🔴 Eng xavfli joyi: uzilish "Hali bron yo'q" bo'lib ko'rinardi.
      // Broni bor yo'lovchi uni yo'qolgan deb o'ylaydi va qayta bron
      // qiladi yoki haydovchini bezovta qiladi.
      if (isOfflineError(e)) {
        final cached = _cache?.readList(CacheKeys.myBookings);
        if (cached != null) return cached.map(Booking.fromJson).toList();
      }
      throw ApiException.from(e);
    }
  }

  /// Yo'lovchi bron qiladi. Narx haydovchinikidan farq qilsa status
  /// `pending_negotiation`, aks holda `pending`.
  Future<Booking> book(String rideId, BookRideRequest request) async {
    try {
      final res = await _client.dio.post<dynamic>(
        '/rides/$rideId/book',
        data: request.toJson(),
      );
      final body = unwrap(res.data);
      final raw = asMap(asMap(body)?['booking']) ?? asMap(body);
      if (raw == null) throw ApiException(kind: ApiErrorKind.unknown);
      return Booking.fromJson(raw);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Haydovchi qabul qiladi -> bron statusi `confirmed`.
  Future<void> acceptBooking(String rideId, String bookingId) =>
      _post('/rides/$rideId/bookings/$bookingId/accept');

  Future<void> rejectBooking(String rideId, String bookingId) =>
      _post('/rides/$rideId/bookings/$bookingId/reject');

  Future<void> markNoShow(String rideId, String bookingId) =>
      _post('/rides/$rideId/bookings/$bookingId/no-show');

  /// YO'NALISH OBUNASI — «shu yo'nalishda safar chiqsa xabar ber», SERVERDA.
  ///
  /// 🔴 NEGA MAHALLIY KUZATUVCHI QOLDIRILDI (`core/route_watcher.dart`):
  /// server obunasi push orqali ishlaydi, mahalliy kuzatuvchi esa ilova
  /// ochilganda o'zi tekshiradi. 2026-08-27 xatida push YOQILDI deyilgan,
  /// lekin biz uni JONLI o'lchamadik — ilgari ham «tayyor» deyilib
  /// yuborilmagan payti bo'lgan. Shuning uchun ikkalasi ham ishlaydi:
  /// push kelsa odam darhol biladi, kelmasa ilovaga qaytganda biladi.
  /// Ikki marta xabar chiqmasligini `RouteWatcher` `lastSeenCount` bilan
  /// ta'minlaydi — u faqat SON O'SGANDA xabar beradi.
  ///
  /// ⚠️ Server obunasi FAQAT koordinatani saqlaydi — shahar nomi ham,
  /// radius ham yo'q (jonli sxema: `http.RouteSubscriptionResponse`).
  /// Ro'yxatni ko'rsatish uchun mahalliy yozuv yagona manba bo'lib qoladi.
  ///
  /// Obuna ID'sini qaytaradi; xato bo'lsa `null` — chaqiruvchi uchun bu
  /// «mahalliy kuzatuv baribir ishlaydi» degani, ya'ni to'sar emas.
  Future<String?> createRouteSubscription({
    required double originLat,
    required double originLon,
    required double destLat,
    required double destLon,
    DateTime? departureDate,
  }) async {
    try {
      final res = await _client.dio.post<dynamic>(
        '/rides/route-subscriptions',
        data: {
          'origin_lat': originLat,
          'origin_lon': originLon,
          'dest_lat': destLat,
          'dest_lon': destLon,
          if (departureDate != null)
            'departure_date': departureDate.toUtc().toIso8601String(),
        },
      );
      final body = asMap(unwrap(res.data));
      final id = body?['id'];
      return id is String && id.isNotEmpty ? id : null;
    } on DioException {
      return null;
    }
  }

  Future<void> deleteRouteSubscription(String id) async {
    try {
      await _client.dio.delete<dynamic>('/rides/route-subscriptions/$id');
    } on DioException {
      // Obuna serverda qolib ketsa eng yomoni — ortiqcha push. Odam
      // kuzatuvni o'chirgan bo'lsa, uni xato bilan bezovta qilmaymiz.
    }
  }

  /// YO'LOVCHI o'z bronini bekor qiladi.
  ///
  /// 🔴 UZOQ VAQT BU YO'Q EDI. 2026-08-25 da yo'lovchida bekor qilishning
  /// hech qanday yo'li bo'lmagani uchun biz ATAYIN "so'rov" yasagandik:
  /// haydovchiga tuzilgan chat xabari ketardi va u `reject` bosardi. Amalda
  /// esa odam shunchaki kelmay qo'yardi, haydovchi kutardi, o'rindiq
  /// bo'shamasdi.
  ///
  /// ✅ 2026-08-27: backend ikkala yo'lni ham ochdi (jonli sxema bilan
  /// sverka qilindi, `http.CancelBookingRequest`, `reason` IXTIYORIY):
  ///   `POST /rides/{id}/bookings/{booking_id}/cancel`  ← shu ishlatiladi
  ///   `POST /bookings/{id}/cancel`                     ← gateway proksisi
  /// Safar kontekstidagisini tanladik: qolgan hamma bron amali (`accept`,
  /// `reject`, `no-show`, `counter`) aynan shu shaklda va `rideId` bizda
  /// har doim qo'l ostida.
  Future<void> cancelBooking(
    String rideId,
    String bookingId, {
    String? reason,
  }) async {
    try {
      await _client.dio.post<dynamic>(
        '/rides/$rideId/bookings/$bookingId/cancel',
        data: reason == null || reason.isEmpty ? const {} : {'reason': reason},
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// SAVDOLASHISH — haydovchi O'Z narxini qaytaradi.
  ///
  /// Busiz haydovchida faqat "ha yoki yo'q" bor edi: yo'lovchi past narx
  /// taklif qilsa, u rad etishi yoki rozi bo'lishi kerak edi. Oraliq narxni
  /// faqat chatda aytish mumkin edi va kelishuv hech qayerda qayd etilmasdi.
  ///
  /// ✅ Endpoint 2026-08-13 da backendda paydo bo'ldi, aynan biz taklif qilgan
  /// shaklda (jonli swagger: `http.CounterBookingRequest`, majburiy
  /// maydon `new_price`). Saytda bu funksiya ancha oldin yozilgan-u, bayroq
  /// bilan o'chirilgan edi — endi ikkalasida ham ochiq.
  Future<void> counterOffer(
    String rideId,
    String bookingId,
    double newPrice,
  ) async {
    try {
      await _client.dio.post<dynamic>(
        '/rides/$rideId/bookings/$bookingId/counter',
        data: {'new_price': newPrice},
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  // `GET /rides/{id}/passengers` ATAYIN CHAQIRILMAYDI (14.09.2026).
  //
  // U telefon bilan keladi va shu sababli RBAC ostida: mehmonga 401,
  // begonaga 403, hatto bron qilib TASDIQLANMAGAN odamga ham 403
  // (jonli o'lchandi). Ya'ni safar sahifasida u faqat allaqachon
  // ichkarida bo'lganlarga ishlardi — qaror qilayotgan yo'lovchiga
  // emas. Hamrohlar ro'yxati endi `GET /rides/{id}` javobidagi
  // `passengers[]` dan olinadi (`Ride.passengers`, telefonsiz,
  // hammaga ochiq), haydovchi esa yo'lovchi telefonini bronning
  // o'zidan ko'radi (`Booking.passenger.phone`).

  Future<void> _post(String path) async {
    try {
      await _client.dio.post<dynamic>(path);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// KUZATUV TOKENI — «Safarimni kuzat» havolasi uchun.
  ///
  /// ✅ Backend 16.09.2026 da qo'shdi, biz prodda o'lchadik:
  ///   POST /rides/{id}/watch-token → 201 {token, expires_at}
  ///
  /// Faqat haydovchi yoki TASDIQLANGAN yo'lovchi ola oladi; kutayotgan
  /// bron ham, begona odam ham 403 (o'lchandi). Shuning uchun xato
  /// YUTILMAYDI — chaqiruvchi odamga SABABINI aytadi.
  Future<String?> watchToken(String rideId) async {
    try {
      final res = await _client.dio.post<dynamic>('/rides/$rideId/watch-token');
      final data = unwrap(res.data);
      if (data is! Map<String, dynamic>) return null;
      final token = asStringOrNull(data['token']);
      return (token == null || token.isEmpty) ? null : token;
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// BEGONA HAYDOVCHINING ochiq safarlari — uning profilida ko'rsatish uchun.
  ///
  /// ✅ 16.09.2026 da ochildi (ilgari 404/404/400 edi). Mehmonga ham
  /// 200 qaytadi va javobda faqat marshrut/vaqt/narx/holat bo'ladi —
  /// yo'lovchi, telefon va bron YO'Q (o'lchandi).
  ///
  /// Xato bo'lsa BO'SH ro'yxat: bu profilning bezagi, uning yo'qligi
  /// sahifani buzmasligi kerak.
  Future<List<Ride>> driverRides(String driverId) async {
    Future<List<Ride>> read(String path) async {
      final res = await _client.dio.get<dynamic>(path);
      final data = unwrap(res.data);
      final list = data is List
          ? data
          : (data is Map<String, dynamic>
                ? (data['rides'] as List? ?? const [])
                : const []);
      return [
        for (final row in list)
          if (asMap(row) case final m?) Ride.fromJson(m),
      ];
    }

    try {
      return await read('/users/$driverId/rides');
    } catch (_) {
      // Ikkinchi manzil ZAXIRA: ikkalasi ham bor deb aytilgan, lekin
      // biri o'chsa profil buzilmasin.
      try {
        return await read('/rides/driver/$driverId');
      } catch (_) {
        return const [];
      }
    }
  }
}
