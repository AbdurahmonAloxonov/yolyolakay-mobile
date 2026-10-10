import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/env.dart';
import '../../core/local_cache.dart';
import '../models/user.dart';

/// Users — profil, mashinalar, haydovchiga upgrade.
///
/// Mashinalar faqat GET/POST: tahrirlash/o'chirish endpointi gateway'da YO'Q.
class UsersRepository {
  UsersRepository(this._client, [this._cache]);

  final ApiClient _client;

  /// Offline kesh — ULANISH uzilganda oxirgi profil shundan beriladi
  /// (izohi `core/local_cache.dart` da).
  final LocalCache? _cache;

  /// MODERATSIYA — shikoyat va bloklash.
  ///
  /// 🔴 GOOGLE PLAY TALABI: foydalanuvchilar bir-biriga xabar yoza oladigan
  /// ilovada "nomaqbul kontentga shikoyat" va "foydalanuvchini bloklash"
  /// yo'llari BO'LISHI SHART. Web'da ikkalasi ham bor edi, ilovada YO'Q edi —
  /// reliz aynan shu sababdan rad etilishi mumkin.
  ///
  /// Sabab ro'yxati web bilan AYNAN bir xil (`shared/api/moderation.ts`):
  /// harassment | spam | fraud | unsafe | other.
  Future<void> reportUser({
    required String userId,
    required String reason,
    String? rideId,
    String? comment,
  }) async {
    try {
      await _client.dio.post<dynamic>(
        '/users/$userId/report',
        data: {'reason': reason, 'ride_id': ?rideId, 'comment': ?comment},
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      await _client.dio.post<dynamic>('/users/$userId/block', data: const {});
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      await _client.dio.delete<dynamic>('/users/blocked/$userId');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Bloklanganlar ro'yxati.
  ///
  /// ⚠️ Backend 2026-08-07 da javobni BOYITDI: ilgari STRING massivi (faqat
  /// ID'lar) edi, endi `domain.User` obyektlari (ism, avatar bilan). Ikkala
  /// shaklni ham o'qiymiz — eski javob qaytib qolsa ro'yxat bo'sh ko'rinmasin.
  Future<List<User>> blockedUsers() async {
    try {
      final res = await _client.dio.get<dynamic>('/users/blocked');
      final raw = unwrap(res.data);
      // DIQQAT: `asList` bu yerda YARAMAYDI — u `whereType<Map>()` bilan
      // filtrlaydi, ya'ni eski STRING shakli jimgina tashlab yuborilardi va
      // ro'yxat "bo'sh" ko'rinardi. Shuning uchun xom ro'yxat bilan ishlaymiz.
      final dynamic rawList = raw is List
          ? raw
          : (asMap(raw)?['users'] ?? asMap(raw)?['blocked']);
      if (rawList is! List) return const [];
      return rawList
          .map<User?>((item) {
            if (item is String) {
              return item.isEmpty ? null : User(id: item, phoneNumber: '');
            }
            final map = asMap(item);
            return map == null ? null : User.fromJson(map);
          })
          .whereType<User>()
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Hisobni butunlay o'chirish — `DELETE /users/me`.
  ///
  /// Google Play 2024-dan beri ilova ICHIDA o'chirish yo'li bo'lishini MAJBURIY
  /// qildi (va tashqi veb-sahifa ham). Veb-versiyada ikkalasi ham bor edi,
  /// mobil ilovada esa umuman yo'q edi — reliz shu sababdan rad etilishi mumkin.
  /// Boshqa foydalanuvchi profili — `GET /users/{id}`.
  ///
  /// 🔴 NEGA KERAK: suhbatlar ro'yxati `GET /notifications/chats` dan
  /// keladi va u faqat `partner_id` beradi — ism ham, avatar ham yo'q.
  /// Ilgari ro'yxat BRONLARDAN yig'ilardi, ya'ni safar tugab bron
  /// yo'qolgach yozishma ham ro'yxatdan g'oyib bo'lardi, garchi tarix
  /// serverda turgan bo'lsa ham. Endi notanish suhbatdoshning ismini
  /// shu yerdan olamiz.
  ///
  /// Xato YUTILADI: ism topilmasa suhbat baribir ko'rsatiladi, faqat
  /// nomsiz — yo'qotib qo'yishdan ko'ra shunisi yaxshi.
  Future<User?> byId(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final res = await _client.dio.get<dynamic>('/users/$userId');
      final body = asMap(unwrap(res.data));
      final raw = asMap(body?['user']) ?? body;
      return raw == null ? null : User.fromJson(raw);
    } on DioException {
      return null;
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _client.dio.delete<dynamic>('/users/me');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Profil. Uzilishda — oxirgi ma'lum profil (izohi `LocalCache.writeMap` da).
  ///
  /// ⚠️ FAQAT ULANISH xatosida keshdan beriladi. `401`/`403` da BERILMAYDI:
  /// server «sizda ruxsat yo'q» desa, eski profilni ko'rsatish yolg'on
  /// bo'lardi va chiqib ketgan hisob ochiq turgandek ko'rinardi.
  Future<MeResponse> me() async {
    if (Env.mockAuth) return _mockMe();
    try {
      final res = await _client.dio.get<dynamic>('/users/me');
      final body = asMap(unwrap(res.data));
      if (body == null) throw ApiException(kind: ApiErrorKind.unknown);
      await _cache?.writeMap(CacheKeys.me, body);
      return MeResponse.fromJson(body);
    } on DioException catch (e) {
      if (isOfflineError(e)) {
        final cached = _cache?.readMap(CacheKeys.me);
        if (cached != null) return MeResponse.fromJson(cached);
      }
      throw ApiException.from(e);
    }
  }

  // `user(String id)` (`GET /users/{id}`) 2026-08-08 da OLIB TASHLANDI: 0 ta
  // chaqiruv bor edi — boshqa foydalanuvchi profilini ochadigan ekran yo'q.
  //
  // NEGA SAQLANMADI: bugun aynan shunday "turgan, lekin ishlatilmaydigan" metod
  // (`createProfile`) adashib chaqirilib, ro'yxatdan o'tishni butunlay buzgan
  // edi (409 Conflict). Kerak bo'lganda qayta yozish arzonroq.
  //
  // Bloklanganlar ro'yxatida ism yo'q bo'lsa ID ko'rsatiladi — bu ATAYIN
  // (`security_screen.dart` izohiga qarang), N+1 so'rov qilinmaydi.

  /// Yangi hisob profili (`is_new_user == true` oqimida).
  // `createProfile()` (`POST /users`) 2026-08-07 da OLIB TASHLANDI.
  //
  // U ro'yxatdan o'tishni buzardi: `verify-otp` hisobni allaqachon yaratadi,
  // shuning uchun `POST /users` o'sha hisobni qayta yaratmoqchi bo'lib
  // `409 Conflict` olardi va yangi foydalanuvchi ilovaga kira olmasdi.
  // Jonli qurilmada (Samsung SM-E135F) aniqlandi.
  //
  // Metod ATAYIN qaytarilmadi: turgan joyida u yana adashib chaqirilishi mumkin.
  // Profil to'ldirish uchun YAGONA to'g'ri yo'l — quyidagi `updateProfile`
  // (`PUT /users/profile`), web ham aynan shuni ishlatadi.

  Future<User> updateProfile({
    required String firstName,
    required String lastName,
    String? gender,
    String? avatarUrl,
  }) async {
    try {
      final res = await _client.dio.put<dynamic>(
        '/users/profile',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'gender': ?gender,
          'avatar_url': ?avatarUrl,
        },
      );
      return User.fromJson(asMap(unwrap(res.data)) ?? const {});
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Interfeys tilini SERVERGA saqlaydi (`locale`).
  ///
  /// 🔴 NEGA KERAK (2026-08-28): server matnlarni foydalanuvchining
  /// `locale` maydoniga qarab tanlaydi, ilova esa uni HECH QACHON
  /// yubormasdi — faqat push tokeniga `language` qo'shardi. Natijada
  /// yangi hisobning `locale` i `ru` bo'lib qolar va tokendan OLDIN
  /// yaratilgan xabar (masalan «sinov davri boshlandi») ruscha kelardi.
  /// Sayt buni allaqachon qilardi, ilova esa yo'q — ikki mijoz orasidagi
  /// nomuvofiqlik.
  ///
  /// 🔑 FAQAT `locale` yuboriladi. Ilgari ism ham qo'shilardi, chunki
  /// `PUT /users/profile` uni MAJBURIY deb bilardi (400). Backend
  /// 2026-08-28 da qisman yangilashni ochdi va bu jonli o'lchandi:
  /// `{"locale":"ru"}` → 200, ism bazada o'zgarmadi.
  ///
  /// 🔴 Ism ATAYIN yuborilmaydi: bizdagi nusxa eskirgan bo'lishi mumkin
  /// (odam uni boshqa qurilmada o'zgartirgan) va til almashtirish
  /// jimgina eski ismni qaytarib qo'yardi.
  Future<void> saveLocale({required String locale}) async {
    try {
      await _client.dio.put<dynamic>(
        '/users/profile',
        data: {'locale': locale},
      );
    } on DioException {
      // Til — qulaylik, xato bo'lsa ekranda hech nima o'zgarmasin:
      // interfeys tili mahalliy saqlangan va allaqachon almashgan.
    }
  }

  // `myCars()` (`GET /users/me/cars`) 2026-08-08 da OLIB TASHLANDI: 0 ta chaqiruv
  // bor edi. Mashinalar ro'yxati `meProvider` javobidan (`MeResponse.cars`)
  // o'qiladi — alohida so'rov ortiqcha edi (backend har chaqiruvda ~0.7 s).
  // Yangi mashina qo'shilgach `ref.invalidate(meProvider)` yetadi.

  /// ✅ 2026-08-27 (`.com`): `http.CreateCarRequest` HUJJAT MAYDONLARINI
  /// oldi — texpasportning IKKI tomoni va mashina UCH rakursda.
  /// Ilgari faqat bitta umumiy surat bor edi, moderatsiya esa mashinani
  /// bitta kadrdan tasdiqlay olmasdi.
  ///
  /// 🔑 Eski `tech_passport_photo` maydoni ham TO'LDIRILADI (old tomon
  /// bilan): u sxemada saqlanib qolgan va moderatsiya paneli hamon
  /// o'shani o'qiyotgan bo'lishi mumkin. Ikkalasini yuborish arzon,
  /// yo'qotish esa — tasdiqlanmagan mashina.
  Future<Car> addCar({
    required String brand,
    required String model,
    required String govNumber,
    String? techPassportFront,
    String? techPassportBack,
    String? carFrontPhoto,
    String? carBackPhoto,
    String? carSidePhoto,
  }) async {
    try {
      final res = await _client.dio.post<dynamic>(
        '/users/me/cars',
        data: {
          'brand': brand,
          'model': model,
          'gov_number': govNumber,
          'tech_passport_front': ?techPassportFront,
          'tech_passport_back': ?techPassportBack,
          'car_front_photo': ?carFrontPhoto,
          'car_back_photo': ?carBackPhoto,
          'car_side_photo': ?carSidePhoto,
          // Eski maydon — moderatsiya hamon shuni o'qiyotgan bo'lishi mumkin.
          'tech_passport_photo': ?techPassportFront,
        },
      );
      return Car.fromJson(asMap(unwrap(res.data)) ?? const {});
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Haydovchiga upgrade — BITTA so'rovda ariza + birinchi mashina.
  ///
  /// ✅ `myid_code` OLIB TASHLANDI (2026-08-22): backend uni endi talab
  /// qilmaydi — bo'sh tana validatsiyasi faqat marka/model/davlat
  /// raqamini so'raydi (jonli o'lchandi).
  /// ✅ 2026-08-27, `.com` ga ko'chgach: `myid_code` va `redirect_uri`
  /// sxemadan BUTUNLAY yo'qoldi — swagger endi kod bilan mos.
  /// ✅ 2026-08-27 (`.com`): hujjatning IKKI TOMONI va mashina UCH
  /// RAKURSDA yuboriladi. Ilgari har hujjatdan bitta kadr ketardi —
  /// guvohnomaning orqasidagi toifalar va texpasportning orqasidagi
  /// egalik yozuvlari moderatsiyaga UMUMAN yetib bormasdi.
  ///
  /// 🔑 Eski `tech_passport_photo` / `driver_license_photo` maydonlari ham
  /// TO'LDIRILADI (old tomon bilan): ular sxemada saqlanib qolgan va
  /// moderatsiya paneli hamon o'shalarni o'qiyotgan bo'lishi mumkin.
  Future<void> upgradeToDriver({
    required String brand,
    required String model,
    required String govNumber,
    String? techPassportFront,
    String? techPassportBack,
    String? driverLicenseFront,
    String? driverLicenseBack,
    String? carFrontPhoto,
    String? carBackPhoto,
    String? carSidePhoto,
    String? avatarUrl,
  }) async {
    try {
      await _client.dio.post<dynamic>(
        '/users/upgrade',
        data: {
          'brand': brand,
          'model': model,
          'gov_number': govNumber,
          'tech_passport_front': ?techPassportFront,
          'tech_passport_back': ?techPassportBack,
          'driver_license_front': ?driverLicenseFront,
          'driver_license_back': ?driverLicenseBack,
          'car_front_photo': ?carFrontPhoto,
          'car_back_photo': ?carBackPhoto,
          'car_side_photo': ?carSidePhoto,
          // Odamning O'Z surati — pasport/ID o'rniga (egasi, 2026-08-28).
          // `avatar_url` `UpgradeToDriverRequest` sxemasida ALLAQACHON bor,
          // ya'ni bu maydon bugunoq ishlaydi.
          'avatar_url': ?avatarUrl,
          // Eski maydonlar — moderatsiya hamon shularni o'qiyotgan bo'lishi
          // mumkin, shuning uchun old tomon ikkalasiga ham yoziladi.
          'tech_passport_photo': ?techPassportFront,
          'driver_license_photo': ?driverLicenseFront,
        },
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// MOCK_AUTH profili — ATAYIN haydovchi va bitta tasdiqlangan mashina bilan:
  /// aks holda e'lon berish formasi umuman ochilmaydi va uni ko'z bilan
  /// tekshirib bo'lmaydi. Yozish amallari baribir haqiqiy API'ga ketadi.
  MeResponse _mockMe() => const MeResponse(
    user: User(
      id: 'mock-user',
      phoneNumber: '+998990000000',
      firstName: 'Test',
      lastName: 'Foydalanuvchi',
      role: 'driver',
      gender: 'male',
    ),
    cars: [
      Car(
        id: 'mock-car',
        brand: 'Chevrolet',
        model: 'Cobalt',
        govNumber: '01 A 123 BC',
        moderationStatus: 'approved',
      ),
    ],
  );
}
