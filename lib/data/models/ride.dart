import '../../core/format.dart';
import '../../core/api/api_client.dart' show asMap;
import '../../core/json.dart';
import 'booking.dart';

/// Haydash uslubi — haydovchi o'zi e'lon qiladi.
enum DrivingSpeed {
  calm('calm'),
  normal('normal'),
  fast('fast');

  const DrivingSpeed(this.wire);
  final String wire;

  static DrivingSpeed? parse(dynamic value) {
    final raw = asStringOrNull(value);
    if (raw == null) return null;
    for (final speed in DrivingSpeed.values) {
      if (speed.wire == raw) return speed;
    }
    return null;
  }
}

/// Safar hayot sikli: draft -> active -> in_progress -> completed (yoki cancelled).
class RideStatus {
  static const draft = 'draft';
  static const active = 'active';
  static const inProgress = 'in_progress';
  static const completed = 'completed';
  static const cancelled = 'cancelled';
}

/// Oraliq shahar — yo'l-yo'lakay kirib o'tiladigan nuqta (maksimum 3 ta).
class RideStop {
  const RideStop({required this.address, required this.lat, required this.lon});

  final String address;
  final double lat;
  final double lon;

  factory RideStop.fromJson(Map<String, dynamic> json) => RideStop(
    address: asString(json['address']),
    lat: asDouble(json['lat']),
    lon: asDouble(json['lon']),
  );

  Map<String, dynamic> toJson() => {'address': address, 'lat': lat, 'lon': lon};
}

class DriverProfile {
  const DriverProfile({
    this.id,
    this.name,
    this.avatar,
    this.rating,
    this.gender,
    this.phone,
    this.kycStatus,
    this.createdAt,
  });

  /// Haydovchi UUID — chat/`recipient_id` uchun kerak. Backend v6 javobida
  /// qo'shilishi e'lon qilingan, jonlida hali kelmasligi mumkin → null'ga tayyor tur.
  final String? id;
  final String? name;
  final String? avatar;
  final double? rating;

  /// Telefon raqami — FAQAT bron tasdiqlangach ko'rsatiladi.
  ///
  /// 🔴 Egasi (2026-08-16): "kelishuvga erishganlar bir-birining nomerini
  /// topolmayapti". Kelishilgandan keyin ikki taraf uchrashish joyini
  /// aniqlashi kerak, chat esa har doim ham yetarli emas (internet yo'q,
  /// odam ilovani ochmagan) — telefon eng ishonchli yo'l.
  ///
  /// ⚠️ Backend buni HOZIRCHA yubormaydi (safar/bron javobida telefon
  /// maydoni umuman yo'q — xat 2026-08-16). Maydon oldindan qo'shildi:
  /// backend qo'shgan kuni ekran o'zi ishlab ketadi, yangi versiya
  /// chiqarish shart emas.
  final String? phone;

  /// `male` | `female` — MA'LUMOT sifatida ko'rsatiladi.
  ///
  /// 🔴 Egasi aniqlashtirdi (2026-08-14): jins bo'yicha CHEKLOV olib
  /// tashlandi (hamma hamma safarni ko'radi va bron qila oladi), lekin
  /// yo'lovchi kim bilan ketayotganini bilishi kerak — shuning uchun jins
  /// safar ma'lumotida qoladi. Bu filtr emas, oddiy ma'lumot.
  final String? gender;

  /// Shaxsni tasdiqlash holati va ro'yxatdan o'tgan sana.
  ///
  /// ✅ 2026-08-27 (kechqurun): backend `PassengerProfile` va
  /// `DriverProfile` ga shu ikki maydonni QO'SHDI — biz aynan shuni
  /// so'ragandik. Ilgari ular faqat `GET /users/{id}` da bor edi, ya'ni
  /// haydovchi ekranida har bron uchun alohida so'rov ketardi.
  ///
  /// ⚠️ Null bo'lishi mumkin: eski keshdagi javoblarda bu maydonlar yo'q.
  /// Shunda `PassengerTrust` avvalgidek alohida so'rovga tushadi.
  final String? kycStatus;
  final DateTime? createdAt;

  bool get isKycApproved {
    final v = (kycStatus ?? '').trim().toLowerCase();
    return v == 'approved' || v == 'verified' || v == 'accepted';
  }

  factory DriverProfile.fromJson(Map<String, dynamic> json) => DriverProfile(
    id: asStringOrNull(json['id']),
    name: asStringOrNull(json['name']),
    // Kalit uch xil uchraydi: safar javobida `avatar`, profil javobida
    // `avatar_url` (`User` modeli shuni o'qiydi). Faqat bittasini o'qish
    // rasmni jimgina yo'qotardi — ikkalasini ham qabul qilamiz.
    avatar:
        asStringOrNull(json['avatar']) ??
        asStringOrNull(json['avatar_url']) ??
        asStringOrNull(json['photo_url']),
    rating: json['rating'] == null ? null : asDouble(json['rating']),
    gender: asStringOrNull(json['gender']),
    phone:
        asStringOrNull(json['phone']) ?? asStringOrNull(json['phone_number']),
    kycStatus: asStringOrNull(json['kyc_status']),
    createdAt: asDate(json['created_at']),
  );
}

/// Safar mashinasi.
///
/// 🔴 NEGA KERAK: yo'lovchi qanaqa mashina kelishini BILMASDI — ilovada bu
/// ma'lumot umuman chizilmasdi (saytda bor). Odam kutayotgan mashinani taniy
/// olishi kerak, bu ishonch masalasi.
///
/// ⚠️ IKKI SXEMA, BIR NARSA (saytdagi `normalizeVehicle` bilan bir xil):
///     domain.Car     -> gov_number
///     domain.Vehicle -> license_plate, color, year
/// `/users/me/cars` birinchisini, `GET /vehicles/{id}` ikkinchisini qaytaradi.
/// Qaysi biri kanonik ekani backenddan so'ralgan (xat 2026-08-07 §6); javob
/// kelmaguncha IKKALASINI ham o'qiymiz.
class RideVehicle {
  const RideVehicle({
    this.brand,
    this.model,
    this.plate,
    this.color,
    this.year,
  });

  final String? brand;
  final String? model;
  final String? plate;
  final String? color;
  final int? year;

  /// "Chevrolet Cobalt" — ikkalasi ham bo'lmasa bo'sh.
  String get title =>
      [brand, model].where((p) => (p ?? '').isNotEmpty).join(' ');

  /// Ko'rsatishga arziydigan biror narsa bormi.
  bool get hasAny => title.isNotEmpty || (plate ?? '').isNotEmpty;

  /// `{car: {...}}` / `{vehicle: {...}}` o'ramidan ham chiqaradi.
  static RideVehicle? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final outer = raw.cast<String, dynamic>();
    final inner = outer['vehicle'] ?? outer['car'];
    final v = inner is Map ? inner.cast<String, dynamic>() : outer;

    String? str(String key) {
      final value = asStringOrNull(v[key]);
      final trimmed = value?.trim();
      return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    }

    final year = v['year'] == null ? 0 : asInt(v['year']);
    final vehicle = RideVehicle(
      brand: str('brand'),
      model: str('model'),
      plate: str('license_plate') ?? str('gov_number') ?? str('plate_number'),
      color: str('color'),
      year: year > 1900 ? year : null,
    );
    return vehicle.hasAny ? vehicle : null;
  }
}

/// GET /rides/search elementi — koordinatalar YASSI (lat/lon), manzillar matn.
class Ride {
  const Ride({
    required this.id,
    required this.originAddress,
    required this.originLat,
    required this.originLon,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLon,
    required this.departureTime,
    required this.totalSeats,
    required this.availableSeats,
    required this.pricePerSeat,
    required this.status,
    this.driver,
    this.genderRestriction,
    this.hasAc = false,
    this.hasLuggage = false,
    this.hasFairPriceBadge = false,
    this.isNegotiable = false,
    this.takesParcels = false,
    this.noSmoking = false,
    this.noPets = false,
    this.maxTwoBack = false,
    this.drivingSpeed,
    this.musicTaste,
    this.pickupPoint,
    this.pickupLat,
    this.pickupLon,
    this.stops = const [],
    this.bookings = const [],
    this.passengers = const [],
    this.vehicleId,
    this.car,
  });

  final String id;
  final String originAddress;
  final double originLat;
  final double originLon;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLon;
  final DateTime? departureTime;
  final int totalSeats;
  final int availableSeats;
  final double pricePerSeat;
  final String status;
  final DriverProfile? driver;
  final String? genderRestriction;
  final bool hasAc;
  final bool hasLuggage;
  final bool hasFairPriceBadge;
  final bool isNegotiable;
  final bool takesParcels;
  final bool noSmoking;
  final bool noPets;
  final bool maxTwoBack;
  final DrivingSpeed? drivingSpeed;

  /// YO'LDA MUSIQA — haydovchi IXTIYORIY belgilaydigan did.
  ///
  /// 🔴 NEGA KERAK (egasi, 2026-08-27): notanish odamlar bilan to'rt soat
  /// mashinada — yo'lovchi nima kutishini bilmaydi. Musiqa baland
  /// bo'ladimi, jim ketamizmi, suhbatlashamizmi. Bu 4 soatlik
  /// noqulaylikning yarmi.
  ///
  /// ⚠️ IXTIYORIY: belgilanmasa safar kartasida UMUMAN ko'rsatilmaydi
  /// (egasining sharti). Majburiy qilish e'lon berishni cho'zadi.
  ///
  /// ⚠️ BACKENDDA HALI YO'Q — `http.PublishRideRequest` da bu maydon
  /// yo'q (jonli sxema 2026-08-27 da tekshirildi). Maydon OLDINDAN
  /// qo'shildi: backend qo'shgan kuni ekran o'zi ishlab ketadi va yangi
  /// versiya chiqarish shart bo'lmaydi. Ayni naqsh `DriverProfile.phone`
  /// da ham ishlatilgan. So'rov: `BACKEND_XAT_MUSIQA_2026-08-27.txt`.
  ///
  /// Kutilayotgan qiymatlar: `quiet` | `loud` | `talk` | `any`.
  final String? musicTaste;
  final String? pickupPoint;

  /// UCHRASHUV NUQTASINING ANIQ KOORDINATASI — haydovchi xaritada qo'ygan.
  ///
  /// 🔴 28.09.2026 gacha ilova buni UMUMAN o'qimasdi va yubormasdi — izohda
  /// «backendda koordinata maydoni yo'q» deb yozilgandi. Maydon bor
  /// (sayt 17.09 da ulagan; 28.09 da jonli o'lchandi: `/rides/my` da
  /// «Chorsu metro, 3-chiqish» → 41.3266, 69.2366). Oqibat: ilovadan
  /// xaritada tanlangan nuqta yo'qolardi, yo'lovchi esa uchrashuv joyini
  /// matndan GEOKOD orqali taxmin qilingan joyda ko'rardi.
  ///
  /// `null` — haydovchi nuqta qo'ymagan (nol nuqta ham shunday o'qiladi).
  final double? pickupLat;
  final double? pickupLon;

  bool get hasPickupCoord => pickupLat != null && pickupLon != null;
  final List<RideStop> stops;

  /// Faqat GET /rides/my?role=driver javobida to'ladi (bron bo'lmasa kalit yo'q).
  final List<Booking> bookings;

  /// TASDIQLANGAN yo'lovchilar — `GET /rides/{id}` javobining O'ZIDA keladi.
  ///
  /// 🔑 Bu ro'yxat HAMMAGA ochiq: mehmonga ham, hali bron qilmagan
  /// begonaga ham (jonli o'lchandi 14.09.2026). Telefon esa faqat
  /// haydovchi va tasdiqlangan yo'lovchiga qo'shiladi — boshqasiga
  /// kalit UMUMAN kelmaydi (bo'sh satr emas).
  ///
  /// ⚠️ `GET /rides/{id}/passengers` bilan adashtirmang: o'sha endpoint
  /// telefon bilan keladi va RBAC ostida — begonaga 403, hatto
  /// TASDIQLANMAGAN (pending) bron egasiga ham 403.
  final List<DriverProfile> passengers;
  final String? vehicleId;

  /// Safar javobiga QO'SHIB berilgan mashina (`RideResponse.car`). Kelmasa
  /// ekran `vehicle_id` bo'yicha alohida so'raydi.
  final RideVehicle? car;

  bool get isActive => status == RideStatus.active;

  /// Kechikish oynasi — jo'nash vaqti o'tsa ham shu muddat ichida safar
  /// hamon bron qilinadi (haydovchi kechikadi, bu normal). Backend ham
  /// aynan shu 3 soatni ishlatadi (`/rides/{id}/book` o'tgan safarni 409
  /// qiladi), shuning uchun mijoz va server bir xil chegarada bo'lsin.
  static const Duration bookingLateGrace = Duration(hours: 3);

  /// Safarni HOZIR bron qilib bo'ladimi — holat va vaqt bo'yicha.
  ///
  /// 🔴 YAGONA MANBA: qidiruv ro'yxati ([SearchFilters.isBookable]) ham,
  /// safar sahifasidagi «Joy band qilish» tugmasi ham SHU yerdan o'qiydi.
  /// Ilgari tugma faqat [isActive] ga qarardi — jo'nab ketgan safar backendда
  /// `active` qolgani uchun tugma faol turar, foydalanuvchi bosganda backend
  /// 409 qaytarardi va u SABABSIZ xato ko'rardi.
  ///
  /// DENYLIST shaklida: notanish «bron qilsa bo'ladigan» status jim
  /// yashirinib qolmasin.
  bool isBookable({DateTime? now}) {
    if (status == RideStatus.completed || status == RideStatus.cancelled) {
      return false;
    }
    final departure = departureTime;
    if (departure != null) {
      final current = now ?? DateTime.now();
      if (current.difference(departure) > bookingLateGrace) return false;
    }
    return true;
  }

  /// Yangi javobni ESKI ma'lumot bilan to'ldiradi (`this` = yangi, ustunlik unda).
  ///
  /// NEGA KERAK: `GET /rides/{id}` javobida `driver` BO'LMASLIGI mumkin (jonli
  /// kuzatilgan 2026-08-12), qidiruv va bron javoblarida esa bor. Yangilangan
  /// safarni eskisining ustiga shundoq qo'ysak, ekranda ism o'rniga "Haydovchi"
  /// paydo bo'ladi va yo'lovchi haydovchini BAHOLAY OLMAY qoladi (baholash
  /// `driver.id` ga tayanadi).
  ///
  /// Faqat "yo'qligi = bo'sh" deb ajratib bo'lmaydigan maydonlar to'ldiriladi.
  /// Holat, o'rindiq va narx HAR DOIM yangisidan olinadi — yangilashning maqsadi
  /// aynan o'sha.
  ///
  /// Belgilar (`has_ac`, `no_smoking`, ...) va `gender_restriction` ATAYIN
  /// to'ldirilmaydi: `false`/`null` "kelmadi" degani ham, "o'chirilgan" degani
  /// ham bo'lishi mumkin. Eskisini saqlab qolsak, haydovchi olib tashlagan
  /// shartni ("faqat ayollar") bor deb ko'rsatib qo'yishimiz mumkin — bu
  /// yo'qolgan belgidan battar.
  Ride mergedWith(Ride? older) {
    if (older == null) return this;
    return Ride(
      id: id,
      originAddress: originAddress.isEmpty
          ? older.originAddress
          : originAddress,
      originLat: originLat == 0 ? older.originLat : originLat,
      originLon: originLon == 0 ? older.originLon : originLon,
      destinationAddress: destinationAddress.isEmpty
          ? older.destinationAddress
          : destinationAddress,
      destinationLat: destinationLat == 0
          ? older.destinationLat
          : destinationLat,
      destinationLon: destinationLon == 0
          ? older.destinationLon
          : destinationLon,
      departureTime: departureTime ?? older.departureTime,
      totalSeats: totalSeats,
      availableSeats: availableSeats,
      pricePerSeat: pricePerSeat == 0 ? older.pricePerSeat : pricePerSeat,
      status: status.isEmpty ? older.status : status,
      driver: _fullerDriver(driver, older.driver),
      genderRestriction: genderRestriction,
      hasAc: hasAc,
      hasLuggage: hasLuggage,
      hasFairPriceBadge: hasFairPriceBadge,
      isNegotiable: isNegotiable,
      takesParcels: takesParcels,
      noSmoking: noSmoking,
      noPets: noPets,
      maxTwoBack: maxTwoBack,
      drivingSpeed: drivingSpeed,
      musicTaste: musicTaste,
      pickupPoint: pickupPoint ?? older.pickupPoint,
      pickupLat: pickupLat ?? older.pickupLat,
      pickupLon: pickupLon ?? older.pickupLon,
      stops: stops.isEmpty ? older.stops : stops,
      bookings: bookings.isEmpty ? older.bookings : bookings,
      passengers: passengers.isEmpty ? older.passengers : passengers,
      vehicleId: vehicleId ?? older.vehicleId,
      car: car ?? older.car,
    );
  }

  /// Ikkita haydovchi ma'lumotidan to'liqrog'i. Maydonma-maydon birlashtiriladi:
  /// yangi javobda `id` kelib, `name` kelmasligi ham mumkin.
  static DriverProfile? _fullerDriver(
    DriverProfile? fresh,
    DriverProfile? old,
  ) {
    if (fresh == null) return old;
    if (old == null) return fresh;
    return DriverProfile(
      id: (fresh.id ?? '').isEmpty ? old.id : fresh.id,
      name: (fresh.name ?? '').isEmpty ? old.name : fresh.name,
      avatar: (fresh.avatar ?? '').isEmpty ? old.avatar : fresh.avatar,
      rating: fresh.rating ?? old.rating,
      // 🔴 `gender` va `phone` bu yerda TUSHIB QOLARDI: safar tafsiloti har
      // 20 soniyada `mergedWith` bilan yangilanadi va `GET /rides/{id}`
      // javobida bu maydonlar bo'lmasa, ekranda ko'rinib turgan ma'lumot
      // birdan yo'qolardi (jins ikonkasi umumiy "odam"ga aylanardi).
      // Maydonma-maydon birlashtirish DEGANI — hammasi, tanlanganlari emas.
      gender: (fresh.gender ?? '').isEmpty ? old.gender : fresh.gender,
      phone: (fresh.phone ?? '').isEmpty ? old.phone : fresh.phone,
    );
  }

  factory Ride.fromJson(Map<String, dynamic> json) {
    final rawDriver = json['driver'];
    // Kalit faqat haydovchi nuqta qo'ygan safarda keladi; nol nuqta —
    // «qo'yilmagan» (u Gvineya ko'rfazida, xaritani okeanga sudrardi).
    final pLat = json['pickup_lat'] == null
        ? 0.0
        : asDouble(json['pickup_lat']);
    final pLon = json['pickup_lon'] == null
        ? 0.0
        : asDouble(json['pickup_lon']);
    final hasPickup = pLat != 0 || pLon != 0;
    return Ride(
      id: asString(json['id']),
      originAddress: asString(json['origin_address']),
      originLat: asDouble(json['origin_lat']),
      originLon: asDouble(json['origin_lon']),
      destinationAddress: asString(json['destination_address']),
      /*
       * 🔴 IKKI XIL NOM (16.09.2026 da o'lchandi va tutildi).
       *
       * `GET /rides/{id}` va `/rides/my` — `destination_lat`.
       * `GET /users/{id}/rides` (haydovchining ochiq safarlari, yangi
       * ruchka) esa — `dest_lat`.
       *
       * Faqat birinchisini o'qisak, begona haydovchi profilidagi
       * «yo'llari» kartasi JIMGINA bo'sh qolardi: koordinata nol
       * bo'lib, hamma safar filtrdan tushib ketardi. Xato ko'rinmasdi
       * — karta shunchaki chizilmasdi.
       */
      destinationLat: asDouble(pick(json, ['destination_lat', 'dest_lat'])),
      destinationLon: asDouble(pick(json, ['destination_lon', 'dest_lon'])),
      departureTime: asDate(json['departure_time']),
      totalSeats: asInt(json['total_seats']),
      availableSeats: asInt(json['available_seats']),
      pricePerSeat: asDouble(json['price_per_seat']),
      status: asString(json['status']),
      driver: rawDriver is Map
          ? DriverProfile.fromJson(rawDriver.cast<String, dynamic>())
          : null,
      genderRestriction: asStringOrNull(json['gender_restriction']),
      hasAc: asBool(json['has_ac']),
      hasLuggage: asBool(json['has_luggage']),
      hasFairPriceBadge: asBool(json['has_fair_price_badge']),
      isNegotiable: asBool(json['is_negotiable']),
      takesParcels: asBool(json['takes_parcels']),
      noSmoking: asBool(json['no_smoking']),
      noPets: asBool(json['no_pets']),
      maxTwoBack: asBool(json['max_two_back']),
      drivingSpeed: DrivingSpeed.parse(json['driving_speed']),
      // Backend hali yubormaydi (izohi maydon ustida) — kelgan kuni
      // o'zi o'qiladi.
      musicTaste: asStringOrNull(
        pick(json, ['music_taste', 'music_preference']),
      ),
      pickupPoint: asStringOrNull(json['pickup_point']),
      pickupLat: hasPickup ? pLat : null,
      pickupLon: hasPickup ? pLon : null,
      stops:
          (json['stops'] as List?)
              ?.whereType<Map>()
              .map((s) => RideStop.fromJson(s.cast<String, dynamic>()))
              .toList() ??
          const [],
      bookings:
          (json['bookings'] as List?)
              ?.whereType<Map>()
              .map((b) => Booking.fromJson(b.cast<String, dynamic>()))
              .toList() ??
          const [],
      passengers:
          (json['passengers'] as List?)
              ?.whereType<Map>()
              .map((p) => DriverProfile.fromJson(p.cast<String, dynamic>()))
              .toList() ??
          const [],
      vehicleId: asStringOrNull(json['vehicle_id']),
      car: RideVehicle.tryParse(json['car'] ?? json['vehicle']),
    );
  }
}

/// GET /rides/search parametrlari.
///
/// `radius_km` origin VA destination ikkalasiga ham qo'llanadi (AND).
///
/// ✅ 2026-08-12: sana va jins endi SERVERDA filtrlanadi. Swagger sverkasida
/// (74 yo'l, md5 98461fc4…) ma'lum bo'ldiki backend `date_from`/`date_to`,
/// `gender_restriction`, `price_min`/`price_max` ni allaqachon qabul qiladi —
/// bizga aytilmagan edi va ilova ularni hamon klientda hisoblab yurgan edi.
///
/// NEGA BU MUHIM: klient faqat backend QAYTARGAN ro'yxatni filtrlaydi. Server
/// natijani cheklab qaytarsa, o'sha bo'lakdan tashqaridagi mos safar telefonga
/// umuman yetib kelmaydi va foydalanuvchi "safar yo'q" deb o'ylaydi. Saytda bu
/// 2026-07-31 da tuzatilgan, ilova ortda qolgan edi.
///
/// ✅ `price_min`/`price_max` 2026-08-16 da QO'SHILDI. Ilgari ilovada narx
/// filtri umuman yo'q edi (faqat saralash), saytda esa bor edi — bitta
/// odam ikki qurilmada boshqacha imkoniyat ko'rardi.
///
/// 🔴 NARX SERVERGA KETADI, klientda hisoblanmaydi. Saytda bu 2026-07-31
/// da aynan shu sabab ko'chirilgan: klient faqat backend QAYTARGAN
/// ro'yxatni kesadi, ya'ni "50 000 gacha" degan odam server bergan
/// bo'lakdan tashqaridagi arzonroq safarni UMUMAN ko'rmaydi va
/// "safar yo'q" deb o'ylaydi.
class RideSearchParams {
  const RideSearchParams({
    required this.originLat,
    required this.originLon,
    required this.destLat,
    required this.destLon,
    this.radiusKm = 25,
    this.minSeats,
    this.date,
    this.priceMin,
    this.priceMax,
    this.womenOnly = false,
    this.originName,
    this.destName,
  });

  /// 🔴 FAQAT KO'RSATISH UCHUN — serverga YUBORILMAYDI (`toQuery` da yo'q).
  ///
  /// NEGA KERAK (2026-09-02): natijalar ekrani «Natijalar» degan umumiy
  /// sarlavha bilan ochilardi va odam QAYSI yo'nalish qidirilganini
  /// ko'rmasdi. Qidiruv parametrlarida esa faqat KOORDINATA bor edi,
  /// shahar nomi yo'q — shuning uchun sarlavhaga yozadigan narsa
  /// topilmasdi. Nomlar shu yerda olib yuriladi.
  final String? originName;
  final String? destName;

  final double originLat;
  final double originLon;
  final double destLat;
  final double destLon;
  final int radiusKm;
  final int? minSeats;

  /// Tanlangan kun. Serverga `date_from` bo'lib ketadi (yuqori chegara YO'Q —
  /// `toQuery` izohiga qarang).
  final DateTime? date;

  /// Narx oralig'i — SERVER filtri (`price_min`/`price_max`).
  final double? priceMin;
  final double? priceMax;

  /// «Ayollar uchun» safarlar — `gender_restriction=female`.
  ///
  /// 🔴 SERVERGA YUBORILISHI SHART, mijozda kesib bo'lmaydi: cheklovli
  /// safar oddiy qidiruv javobiga UMUMAN kirmaydi (08.09.2026 da jonli
  /// o'lchandi — yangi yaratilgan «faqat ayollar» safari ketma-ket
  /// 6 ta so'rovda ham chiqmadi, parametr bilan esa chiqdi).
  ///
  /// ⚠️ Parametrning O'ZI kesmaydi: javobda cheklovsiz safarlar ham
  /// keladi. Yakuniy kesish `SearchFilters.matches` da.
  final bool womenOnly;

  /// [clearPrice] — narx oralig'ini BUTUNLAY olib tashlash uchun.
  /// `null` uzatish yetmaydi: u "o'zgartirma" degani.
  /// [clearDate] — sanani BUTUNLAY olib tashlash ("istalgan kun").
  /// `null` uzatish yetmaydi: u "o'zgartirma" degani.
  RideSearchParams copyWith({
    DateTime? date,
    bool clearDate = false,
    double? priceMin,
    double? priceMax,
    bool clearPrice = false,
    int? radiusKm,
    bool? womenOnly,
  }) => RideSearchParams(
    originLat: originLat,
    originLon: originLon,
    destLat: destLat,
    destLon: destLon,
    radiusKm: radiusKm ?? this.radiusKm,
    minSeats: minSeats,
    date: clearDate ? null : (date ?? this.date),
    priceMin: clearPrice ? null : (priceMin ?? this.priceMin),
    priceMax: clearPrice ? null : (priceMax ?? this.priceMax),
    womenOnly: womenOnly ?? this.womenOnly,
    // ⚠️ Nomlar SAQLANADI: filtr o'zgarganda ham sarlavha o'sha yo'nalishni
    // ko'rsatishi kerak.
    originName: originName,
    destName: destName,
  );

  Map<String, dynamic> toQuery() {
    final query = <String, dynamic>{
      'origin_lat': originLat,
      'origin_lon': originLon,
      'dest_lat': destLat,
      'dest_lon': destLon,
      'radius_km': radiusKm,
      if (minSeats != null) 'min_seats': minSeats,
      // Narx SERVERDA filtrlanadi (sinf izohiga qarang).
      if (priceMin != null) 'price_min': priceMin,
      if (priceMax != null) 'price_max': priceMax,
      // ⚠️ Faqat `female` yuboriladi. Boshqa qiymat (`zzz`) backendda
      // 400 beradi — ya'ni parametr tekshiriladi, ixtiyoriy emas.
      if (womenOnly) 'gender_restriction': 'female',
    };

    final day = date;
    if (day != null) {
      // Kun chegarasi TOSHKENT bo'yicha olinadi, qurilma mintaqasi bo'yicha
      // EMAS: aks holda chet eldagi (yoki mintaqasi noto'g'ri qo'yilgan)
      // telefonda "12-avgust" boshqa sutkani anglatib, safarlar tushib
      // qolardi. Toshkent = UTC+5, ya'ni 00:00 = o'tgan kun 19:00 UTC.
      //
      // To'liq RFC3339 SHART: backend qisqa "2026-08-12" ni qabul qilmaydi
      // (`cannot parse "" as "T"` -> 400). Saytda ham shunday
      // (shared/lib/format.ts -> dateToRangeISO).
      const offset = Duration(hours: 5);
      final from = DateTime.utc(day.year, day.month, day.day).subtract(offset);
      query['date_from'] = from.toIso8601String();

      // 🔴 YUQORI CHEGARA ATAYIN YO'Q (egasi tasdiqladi, 2026-08-16).
      //
      // Ilgari `date_to` ham yuborilardi va qidiruv FAQAT tanlangan kun
      // bilan cheklanardi — sayt esa o'sha kundan BOSHLAB hammasini
      // ko'rsatardi (u bu qarorni 2026-07-31 da qabul qilgan). Ya'ni bitta
      // qidiruv telefonda va saytda BOSHQA-BOSHQA natija berardi.
      //
      // Nega "boshlab" tanlandi: yo'nalishlarda safar kam. Odam 12-avgustni
      // tanlab bo'sh ekran ko'rsa, bu yo'nalishda umuman safar yo'q degan
      // XATO xulosaga keladi va ilovadan chiqib ketadi — holbuki 13-avgustda
      // safar bor. Sana bu yerda "eng erta qachon" degani.
      //
      // Sana tozalansa (`day == null`) `date_from` ham yuborilmaydi —
      // "istalgan sana".
    }

    return query;
  }
}

/// POST /rides/ tanasi.
///
/// ⚠ Yaratilgan safar `draft` bo'ladi va QIDIRUVDA CHIQMAYDI —
/// darhol `activate` chaqirilishi shart (`RidesRepository.createAndActivate`).
class PublishRideRequest {
  const PublishRideRequest({
    required this.departureTime,
    required this.originAddress,
    required this.originLat,
    required this.originLon,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLon,
    required this.pricePerSeat,
    required this.totalSeats,
    required this.vehicleId,
    this.genderRestriction,
    this.hasAc,
    this.hasLuggage,
    this.isNegotiable,
    this.pickupPoint,
    this.pickupLat,
    this.pickupLon,
    this.stops = const [],
    this.takesParcels,
    this.noSmoking,
    this.noPets,
    this.drivingSpeed,
    this.maxTwoBack,
    this.musicTaste,
  });

  final DateTime departureTime;
  final String originAddress;
  final double originLat;
  final double originLon;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLon;
  final double pricePerSeat;
  final int totalSeats;

  /// users/me/cars dagi mashina IDsi — MAJBURIY.
  final String vehicleId;
  final String? genderRestriction;
  final bool? hasAc;
  final bool? hasLuggage;
  final bool? isNegotiable;
  final String? pickupPoint;

  /// Xaritada qo'yilgan uchrashuv nuqtasi (izohi `Ride.pickupLat` da).
  final double? pickupLat;
  final double? pickupLon;
  final List<RideStop> stops;
  final bool? takesParcels;
  final bool? noSmoking;
  final bool? noPets;

  /// `quiet` | `loud` | `talk`. `null` = «farqi yo'q» — YUBORILMAYDI.
  ///
  /// ⚠️ Serverda bu ERKIN MATN ustuni (09.09.2026 o'lchovi: uzun jumla
  /// ham saqlandi va qaytdi). Biz ATAYIN uch qiymat bilan cheklaymiz —
  /// aks holda kartadagi belgilar mos kelmay qoladi.
  final String? musicTaste;
  final DrivingSpeed? drivingSpeed;
  final bool? maxTwoBack;

  Map<String, dynamic> toJson() => {
    // RFC3339 + ANIQ ofset — toIso8601String() lokal vaqtda ofsetni
    // yozmaydi va backend uni UTC deb o'qib, safarni 5 soat siljitadi.
    'departure_time': toRfc3339(departureTime),
    'origin_address': originAddress,
    'origin_lat': originLat,
    'origin_lon': originLon,
    'destination_address': destinationAddress,
    'destination_lat': destinationLat,
    'destination_lon': destinationLon,
    'price_per_seat': pricePerSeat,
    'total_seats': totalSeats,
    'vehicle_id': vehicleId,
    if (genderRestriction != null) 'gender_restriction': genderRestriction,
    if (hasAc != null) 'has_ac': hasAc,
    if (hasLuggage != null) 'has_luggage': hasLuggage,
    if (isNegotiable != null) 'is_negotiable': isNegotiable,
    if (pickupPoint != null) 'pickup_point': pickupPoint,
    if (pickupLat != null && pickupLon != null) ...{
      'pickup_lat': pickupLat,
      'pickup_lon': pickupLon,
    },
    if (stops.isNotEmpty) 'stops': stops.map((s) => s.toJson()).toList(),
    if (takesParcels != null) 'takes_parcels': takesParcels,
    if (noSmoking != null) 'no_smoking': noSmoking,
    if (noPets != null) 'no_pets': noPets,
    if (drivingSpeed != null) 'driving_speed': drivingSpeed!.wire,
    if (maxTwoBack != null) 'max_two_back': maxTwoBack,
    if (musicTaste != null) 'music_taste': musicTaste,
  };
}

/// Haydovchi statistikasi — `GET /rides/earnings`.
///
/// ⚠️ Davr (oy/hafta) filtri backendda YO'Q: raqamlar BUTUN ishlash davri
/// uchun. Ekranda buni ochiq yozamiz, aks holda odam "bu oy" deb o'ylaydi.
///
/// Maydonlar yo'q bo'lsa `null` qoladi va ekran "—" chizadi — 0 EMAS:
/// "0 so'm daromad" va "ma'lumot yo'q" bir xil ko'rinmasligi kerak.
class DriverStatistics {
  const DriverStatistics({
    this.totalEarnings,
    this.totalRides,
    this.completedRides,
    this.cancelledRides,
  });

  final double? totalEarnings;
  final int? totalRides;
  final int? completedRides;
  final int? cancelledRides;

  factory DriverStatistics.fromJson(Map<String, dynamic> json) =>
      DriverStatistics(
        totalEarnings: json['total_earnings'] == null
            ? null
            : asDouble(json['total_earnings']),
        totalRides: json['total_rides'] == null
            ? null
            : asInt(json['total_rides']),
        completedRides: json['completed_rides'] == null
            ? null
            : asInt(json['completed_rides']),
        cancelledRides: json['cancelled_rides'] == null
            ? null
            : asInt(json['cancelled_rides']),
      );
}

/// Tavsiya etilgan yo'nalish — `GET /rides/recommendations`.
///
/// 🔴 DIQQAT: bu ruchka SAFAR emas, YO'NALISH STATISTIKASI qaytaradi.
/// Web'da 2026-08-07 gacha u safar deb o'qilardi va natijada "Siz uchun" bloki
/// HECH QACHON chizilmasdi (parser elementda `id` talab qilardi, bu obyektlarda
/// esa `id` yo'q). Flutter darrov to'g'ri shaklga yoziladi.
///
///   by_your_routes / popular -> RouteStats {from, to, trips_count}
///   new_directions           -> CityStats  {city, lat, lon}
class RecommendedRoute {
  const RecommendedRoute({
    required this.from,
    required this.to,
    this.tripsCount,
  });

  final String from;
  final String to;
  final int? tripsCount;

  static RecommendedRoute? tryParse(dynamic raw) {
    final map = asMap(raw);
    if (map == null) return null;
    final from = asString(map['from']).trim();
    final to = asString(map['to']).trim();
    if (from.isEmpty || to.isEmpty) return null;
    final count = map['trips_count'] == null ? null : asInt(map['trips_count']);
    return RecommendedRoute(
      from: from,
      to: to,
      tripsCount: count != null && count > 0 ? count : null,
    );
  }
}

class RecommendedCity {
  const RecommendedCity({required this.city, this.lat, this.lon});

  final String city;
  final double? lat;
  final double? lon;

  static RecommendedCity? tryParse(dynamic raw) {
    final map = asMap(raw);
    if (map == null) return null;
    final city = asString(map['city']).trim();
    if (city.isEmpty) return null;
    return RecommendedCity(
      city: city,
      lat: map['lat'] == null ? null : asDouble(map['lat']),
      lon: map['lon'] == null ? null : asDouble(map['lon']),
    );
  }
}

class RideRecommendations {
  const RideRecommendations({
    this.byYourRoutes = const [],
    this.popular = const [],
    this.newDirections = const [],
  });

  final List<RecommendedRoute> byYourRoutes;
  final List<RecommendedRoute> popular;
  final List<RecommendedCity> newDirections;

  bool get isEmpty =>
      byYourRoutes.isEmpty && popular.isEmpty && newDirections.isEmpty;

  factory RideRecommendations.fromJson(Map<String, dynamic> json) {
    List<dynamic> arr(String key) {
      final value = json[key];
      return value is List ? value : const [];
    }

    return RideRecommendations(
      byYourRoutes: arr(
        'by_your_routes',
      ).map(RecommendedRoute.tryParse).whereType<RecommendedRoute>().toList(),
      popular: arr(
        'popular',
      ).map(RecommendedRoute.tryParse).whereType<RecommendedRoute>().toList(),
      newDirections: arr(
        'new_directions',
      ).map(RecommendedCity.tryParse).whereType<RecommendedCity>().toList(),
    );
  }
}
