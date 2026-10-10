import 'package:dio/dio.dart';

import '../../l10n/strings.dart';
import '../../l10n/cyrillic.dart';

enum ApiErrorKind {
  /// Internet yo'q yoki server umuman javob bermadi.
  network,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  rateLimit,

  /// 423 — hisob vaqtincha bloklangan (parol bir necha marta xato kiritilgan).
  /// Swaggerda `/auth/login` da hujjatlashtirilgan (2026-08-09).
  accountLocked,

  /// 502/503/504 — origin/tunnel o'chiq. Bu ilova xatosi EMAS.
  serverUnavailable,
  server,
  unknown,
}

/// Dio xatosini UI tushunadigan shaklga keltiradi.
///
/// Xabarlar frontendda jonli o'rganilgan holatlardan ko'chirilgan: eng muhimi
/// 502/503/504 ni umumiy "tizimda xatolik" dan AJRATISH — aks holda
/// foydalanuvchi o'zi noto'g'ri qildim deb o'ylab, qayta urinmay ketadi
/// (2026-07-25/28 `/auth/*` 502 holatida shunday bo'lgan).
class ApiException implements Exception {
  ApiException({required this.kind, this.statusCode, this.backendMessage});

  final ApiErrorKind kind;
  final int? statusCode;
  final String? backendMessage;

  factory ApiException.from(Object error) {
    if (error is ApiException) return error;
    if (error is! DioException) return ApiException(kind: ApiErrorKind.unknown);

    final response = error.response;
    if (response == null) {
      return ApiException(kind: ApiErrorKind.network);
    }

    final data = response.data;
    String? message;
    if (data is Map) {
      message = (data['message'] ?? data['error'])?.toString();
    }

    final status = response.statusCode ?? 0;
    final kind = switch (status) {
      400 => ApiErrorKind.badRequest,
      401 => ApiErrorKind.unauthorized,
      403 => ApiErrorKind.forbidden,
      404 => ApiErrorKind.notFound,
      423 => ApiErrorKind.accountLocked,
      429 => ApiErrorKind.rateLimit,
      // 🔴 520-530 — Cloudflare kodlari: "origin javob bermadi", ya'ni
      // BIZNING server o'chiq. Ilgari ular umumiy `server` ga tushardi va
      // odam "Tizimda xatolik yuz berdi" degan tushunarsiz matnni ko'rardi
      // (telefonda ko'rilgan, 2026-08-13: server 530 qaytarardi).
      502 ||
      503 ||
      504 ||
      520 ||
      521 ||
      522 ||
      523 ||
      524 ||
      530 => ApiErrorKind.serverUnavailable,
      _ => status >= 500 ? ApiErrorKind.server : ApiErrorKind.unknown,
    };

    return ApiException(
      kind: kind,
      statusCode: status,
      backendMessage: message,
    );
  }

  /// Safar paketi tugagan — e'lon berish tarif yangilanmaguncha to'siladi.
  ///
  /// Bunday xatoda oddiy xabar emas, tariflar ekrani ochilishi kerak —
  /// aks holda haydovchi nima qilishni bilmaydi.
  ///
  /// 🔑 **402 ning O'ZI yetarli.** 09.09.2026 da jonli o'lchandi:
  /// `POST /rides/{id}/activate` → `402 {"error":"payment required:
  /// insufficient ride limits"}`. Ilgari bu yerda matn ham TALAB
  /// qilinardi — ya'ni backend jumlani o'zgartirgan kuni paywall
  /// JIMGINA o'chib qolardi va buni hech kim sezmasdi.
  ///
  /// 403 uchun matn tekshiruvi QOLADI: u ko'p narsani bildiradi
  /// (masalan begona safarga tegish) va hammasini paywall deb
  /// hisoblash noto'g'ri bo'lardi.
  bool get isQuotaExceeded {
    if (statusCode == 402) return true;
    if (kind != ApiErrorKind.forbidden) return false;
    final raw = backendMessage?.toLowerCase() ?? '';
    return raw.contains('quota') ||
        raw.contains('limit') ||
        raw.contains('subscription') ||
        raw.contains('rides_left');
  }

  /// Foydalanuvchiga ko'rsatiladigan matn. Backend xabari inglizcha/ruscha xom
  /// matn bo'lgani uchun uni to'g'ridan ko'rsatmaymiz — til aralashib ketadi.
  ///
  /// 🔴 2026-08-16: parametr `bool isUz` dan `Lang` ga o'zgardi. Ilova UCH
  /// tilni qo'llab-quvvatlaydi va profil sozlamasida "English" ochiq turadi,
  /// lekin ikkilik bayroq "o'zbek emas = rus" degani edi — ingliz tilini
  /// tanlagan odam HAR BIR xatoni ruscha ko'rardi. Saytda `isUz` aynan shu
  /// sabab butunlay olib tashlangan (2026-08-03).
  String localized(Lang lang) {
    String pick(String uz, String ru, String en) => switch (lang) {
      Lang.uz => uz,
      Lang.uzCyrl => toCyrillic(uz),
      Lang.ru => ru,
      Lang.en => en,
    };

    switch (kind) {
      case ApiErrorKind.network:
        return pick(
          "Internet aloqasi yo'q yoki server javob bermayapti. Ulanishni tekshirib, qayta urinib ko'ring",
          'Нет соединения с сервером. Проверьте интернет и попробуйте ещё раз',
          'No connection to the server. Check your internet and try again',
        );
      case ApiErrorKind.badRequest:
        // 🔴 Ilgari NOTANISH backend matni jimgina tashlab yuborilardi va
        // odam har xil sabab uchun bitta "Noto'g'ri so'rov yuborildi" ni
        // ko'rardi (2026-08-13, jonli: taklif bilan bron 400 qaytardi va
        // sababini na foydalanuvchi, na biz bila oldik).
        //
        // Endi tarjimasi yo'q matn O'ZI ko'rsatiladi. U inglizcha bo'lishi
        // mumkin, lekin "narx juda past" degan aniq gap tushunarsiz umumiy
        // jumladan foydaliroq — va bizga ham nosozlikni ko'rsatadi.
        return _translateBackend(pick) ??
            _rawBackendMessage ??
            // 🔴 ICHKI XATODA ODAMNI AYBLAMAYMIZ. «Noto'g'ri so'rov» —
            // ya'ni «siz xato kiritdingiz» degani; server jadvalida ustun
            // yetishmasa esa odam nima kiritsa ham o'tmaydi. U formani
            // qayta-qayta to'ldirib, o'zidan xato izlab o'tiraveradi.
            (isInternalError
                ? pick(
                    'Serverda vaqtincha nosozlik — bu sizning xatongiz emas. '
                        'Biroz keyin qayta urinib ko\'ring',
                    'Временный сбой на сервере — это не ваша ошибка. '
                        'Попробуйте немного позже',
                    'A temporary server problem — this is not your fault. '
                        'Please try again a little later',
                  )
                : pick(
                    "Noto'g'ri so'rov yuborildi",
                    'Неверный запрос',
                    'Invalid request',
                  ));
      case ApiErrorKind.unauthorized:
        return pick(
          'Sessiya tugadi, qayta kiring',
          'Сессия истекла, войдите заново',
          'Your session has expired, please sign in again',
        );
      case ApiErrorKind.forbidden:
        return _translateBackend(pick) ??
            pick(
              'Ruxsat etilmagan harakat',
              'Доступ запрещен',
              'This action is not allowed',
            );
      case ApiErrorKind.notFound:
        return pick('Topilmadi', 'Не найдено', 'Not found');
      case ApiErrorKind.accountLocked:
        // Aniq raqamlar backend javobidan (2026-08-09): 5 ta xato urinish
        // (parol VA SMS kodi birga sanaladi) -> rosa 15 daqiqa; blok faqat
        // vaqt bilan yechiladi. "Biroz kuting" deb yozsak odam necha daqiqa
        // ekanini bilmay, qayta-qayta urinib ko'raveradi.
        return pick(
          "Hisob 15 daqiqaga bloklandi — 5 marta xato urinish. Shu vaqt o'tishini kutish kerak",
          'Аккаунт заблокирован на 15 минут — 5 неверных попыток. Нужно дождаться окончания',
          'The account is locked for 15 minutes after 5 failed attempts. You have to wait it out',
        );
      case ApiErrorKind.rateLimit:
        return pick(
          "Ko'p so'rov yuborildi, 1 daqiqadan keyin urinib ko'ring",
          'Слишком много запросов, попробуйте через 1 минуту',
          'Too many requests, try again in a minute',
        );
      case ApiErrorKind.serverUnavailable:
        return pick(
          "Server vaqtincha javob bermayapti. Bir necha daqiqadan so'ng qayta urinib ko'ring",
          'Сервер временно недоступен. Попробуйте через несколько минут',
          'The server is temporarily unavailable. Try again in a few minutes',
        );
      case ApiErrorKind.server:
      case ApiErrorKind.unknown:
        /*
         * 🔴 BU YERDA HAM TARJIMA RO'YXATI O'QILADI (30.08.2026).
         *
         * Ilgari u faqat `badRequest` va `forbidden` da o'qilardi.
         * Backend esa ba'zi tushunarli xatolarni `422` bilan
         * qaytaradi (masalan takrorlangan davlat raqami) va `422`
         * bizda `unknown` ga tushadi — natijada aniq sabab bo'la
         * turib odam «Tizimda xatolik yuz berdi» degan foydasiz
         * jumlani ko'rardi.
         *
         * ⚠️ Bu XOM matnni ochib yubormaydi: `_translateBackend`
         * faqat BIZ TANIGAN xatolarga javob qaytaradi, qolganida
         * `null` beradi va pastdagi umumiy matn ishlaydi.
         */
        return _translateBackend(pick) ??
            pick(
              'Tizimda xatolik yuz berdi',
              'Произошла системная ошибка',
              'Something went wrong',
            );
    }
  }

  /// SERVERNING ICHKI XATOSIMI — baza, ORM, tarmoq darajasidagi.
  ///
  /// 🔴 NEGA KERAK (jonli, 2026-08-27): prodda `cars` jadvalida ustun
  /// yetishmagani uchun backend 400 bilan XOM POSTGRES XATOSINI qaytardi:
  ///
  ///     ERROR: column "tech_passport_front" of relation "cars"
  ///     does not exist (SQLSTATE 42703)
  ///
  /// Bu matn pastdagi eski filtrdan (uzunlik 120, `{` yo'q, qator ko'chishi
  /// yo'q) BEMALOL o'tib ketardi — 86 belgi — va odam mashina qo'shmoqchi
  /// bo'lganda ekranda AYNAN SHUNI ko'rardi. Uch tomonlama zarar: odam hech
  /// nima tushunmaydi, bizning UI orqali backendning jadval va ustun
  /// nomlari oshkor bo'ladi, aybdor esa ilova bo'lib ko'rinadi.
  ///
  /// ⚠️ Bu tekshiruv xom matnni ko'rsatish qoidasini BEKOR QILMAYDI —
  /// «narx juda past» kabi aniq gaplar foydali va ular qolaveradi
  /// (izohi `badRequest` da). Bu faqat ICHKI axlatga to'siq.
  ///
  /// Belgilar ATAYIN keng: yangi ORM yoki drayver boshqacha yozsa ham
  /// tutilsin. Yolg'on ijobiy zarari kichik — odam umumiy xabar ko'radi;
  /// yolg'on salbiyniki esa katta — SQL ekranga chiqadi.
  bool get isInternalError {
    final raw = backendMessage?.toLowerCase();
    if (raw == null || raw.isEmpty) return false;
    const markers = [
      'sqlstate',
      'error: column',
      'error: relation',
      'does not exist',
      'relation "',
      'column "',
      'pq:',
      'sql:',
      'gorm',
      'panic',
      'nil pointer',
      'goroutine',
      'dial tcp',
      'context deadline',
      'connection refused',
      "can't scan",
      'cannot scan',
      'no such table',
      'duplicate key value',
      'syntax error at or near',
    ];
    return markers.any(raw.contains);
  }

  /// Backend matni ko'rsatishga YARAYDIMI.
  ///
  /// Texnik axlat (stack trace, SQL, uzun JSON) ko'rsatilmaydi — u odamga
  /// hech narsa bermaydi va qo'rqitadi.
  String? get _rawBackendMessage {
    final raw = backendMessage?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.length > 120) return null;
    if (raw.contains('{') || raw.contains('\n')) return null;
    // 🔴 Ichki xato — hech qachon ko'rsatilmaydi (izohi `isInternalError` da).
    if (isInternalError) return null;
    return raw;
  }

  /// Ma'lum backend matnlari — ro'yxat frontenddagi `localizeBackendMessage`
  /// bilan bir xil o'sib boradi.
  ///
  /// [pick] — chaqiruvchidan keladi, ya'ni tilni tanlash mantiqi BITTA joyda
  /// (`localized`) turadi.
  String? _translateBackend(String Function(String, String, String) pick) {
    final raw = backendMessage?.toLowerCase();
    if (raw == null || raw.isEmpty) return null;

    if (raw.contains('invalid otp') || raw.contains('wrong code')) {
      return pick("Kod noto'g'ri", 'Неверный код', 'Wrong code');
    }
    if (raw.contains('otp expired')) {
      return pick(
        'Kod muddati tugadi, qaytadan so\'rang',
        'Срок кода истёк, запросите новый',
        'The code has expired, request a new one',
      );
    }
    if (raw.contains('invalid password') || raw.contains('wrong password')) {
      return pick("Parol noto'g'ri", 'Неверный пароль', 'Wrong password');
    }
    // Tartib MUHIM: `new_device_sms_failed` ham `new_device` ni O'Z ICHIGA OLADI,
    // shuning uchun u BIRINCHI tekshiriladi — aks holda "kod yuborildi" degan
    // yolg'on xabar chiqib, odam kelmaydigan kodni kutardi.
    if (raw.contains('new_device_sms_failed')) {
      return pick(
        "Tasdiqlash kodi yuborilmadi. Bir daqiqadan so'ng qayta urinib ko'ring",
        'Код подтверждения не отправлен. Попробуйте через минуту',
        'The verification code was not sent. Try again in a minute',
      );
    }
    if (raw.contains('new_device')) {
      return pick(
        "Yangi qurilmadan kirilyapti — raqamingizga tasdiqlash kodi yuborildi",
        'Вход с нового устройства — на ваш номер отправлен код подтверждения',
        'Signing in from a new device — a verification code was sent to your number',
      );
    }
    if (raw.contains('user not found')) {
      return pick(
        'Bunday foydalanuvchi topilmadi',
        'Пользователь не найден',
        'No such user',
      );
    }
    /*
     * BO'SH O'RIN YETMADI.
     *
     * 🔴 2026-08-30 (egasi: "qabul qilishni bosib qabul qilib bo'lmayapti"):
     * ilgari shart faqat `not enough seats` edi, backend esa AYNAN
     * qabul qilishda boshqacha yozadi:
     *     "not enough available seats to accept this bid"
     * — ichida `available` bo'lgani uchun shart tegmasdi va haydovchi
     * inglizcha xom matnni ko'rardi.
     *
     * Haydovchiga alohida matn kerak: u o'rinni O'ZI bermagan, joyni
     * boshqa bron allaqachon band qilgan (backend `pending` broniga
     * joyni DARHOL beradi, `pending_negotiation` ga esa bermaydi —
     * `BACKEND_XAT_BRON_VA_KUZATUV_2026-08-30.txt` §2). "O'rin yetarli
     * emas" degan quruq jumla unga nima qilishni aytmaydi.
     */
    if (raw.contains('seats') &&
        (raw.contains('not enough') || raw.contains('no seats'))) {
      if (raw.contains('accept')) {
        return pick(
          "Bo'sh o'rin qolmadi: bu o'rinlarni boshqa so'rov band qilgan. "
              "Avval keraksiz so'rovni rad eting yoki safardagi o'rin "
              'sonini oshiring',
          'Свободных мест не осталось: места заняты другой заявкой. '
              'Сначала отклоните ненужную заявку или увеличьте число мест '
              'в поездке',
          'No free seats left: another request is holding them. Decline '
              'the request you do not need, or raise the seat count on the '
              'trip',
        );
      }
      return pick(
        "Bo'sh o'rin yetarli emas",
        'Недостаточно свободных мест',
        'Not enough free seats',
      );
    }
    /*
     * 🔴 DAVLAT RAQAMI ALLAQACHON RO'YXATDAN O'TGAN (30.08.2026 da
     * jonli o'lchandi).
     *
     * `POST /users/upgrade` shu holatda XOM POSTGRES xatosini
     * qaytaradi:
     *     422 ERROR: duplicate key value violates unique constraint
     *     "cars_gov_number_key" (SQLSTATE 23505)
     *
     * Xom matn `isInternalError` bilan to'siladi — ya'ni odam
     * «Tizimda xatolik yuz berdi» degan UMUMIY jumlani ko'radi va
     * NIMA qilishni bilmaydi. U esa oddiy narsani noto'g'ri
     * kiritgan (yoki arizani ikkinchi marta yuborayapti).
     *
     * Bu HAYDOVCHI BO'LISH oqimini butunlay to'sadi: odam qayta-qayta
     * yuboraveradi va hech qachon o'tmaydi.
     */
    if (raw.contains('gov_number') ||
        (raw.contains('duplicate key') && raw.contains('cars'))) {
      return pick(
        'Bu davlat raqami allaqachon ro\'yxatdan o\'tgan. Raqamni '
            'tekshiring — agar mashina sizniki bo\'lsa, arizangiz '
            'allaqachon yuborilgan va ko\'rib chiqilmoqda',
        'Этот госномер уже зарегистрирован. Проверьте номер — если '
            'машина ваша, заявка уже отправлена и рассматривается',
        'This licence plate is already registered. Check the number — '
            'if the car is yours, your application has already been '
            'submitted and is under review',
      );
    }
    /*
     * Bronga ALLAQACHON javob berilgan.
     *
     * Backend: "booking is not in a valid state to be accepted". Bu
     * odatda ikki marta bosishdan yoki eskirgan ro'yxatdan chiqadi —
     * odamga "noto'g'ri so'rov" emas, aynan shuni aytish kerak.
     */
    if (raw.contains('not in a valid state')) {
      return pick(
        "Bu so'rovga allaqachon javob berilgan — ro'yxatni yangilang",
        'На эту заявку уже дан ответ — обновите список',
        'This request has already been answered — refresh the list',
      );
    }
    return null;
  }

  @override
  String toString() =>
      'ApiException($kind, status: $statusCode, msg: $backendMessage)';
}

/// Parol to'g'ri, lekin qurilma backendga notanish: u SMS kodni O'ZI yubordi
/// (`403 {"error":"new_device"}`). Bu XATO EMAS — kirish oqimining davomi.
///
/// Alohida tur qilingan sababi: ekran buni oddiy `forbidden` dan ajratib,
/// qizil xato o'rniga kod ekranini ochishi kerak. `ApiException` dan meros
/// olgani uchun umumiy `catch (ApiException)` bloklari ham buzilmaydi.
class NewDeviceException extends ApiException {
  NewDeviceException()
    : super(
        kind: ApiErrorKind.forbidden,
        statusCode: 403,
        backendMessage: 'new_device',
      );
}

/// Qurilma yangi, LEKIN SMS ketmadi (limit 3/daq yoki shlyuz yiqildi).
/// Backend kontrakti 2026-08-09: `429`/`403` + `error: new_device_sms_failed`.
///
/// [NewDeviceException] dan FARQI: kod ekraniga o'tKAZMAYMIZ — kod yo'q, odam
/// bo'sh ekranda kelmaydigan kodni kutib qolardi.
class SmsNotSentException extends ApiException {
  SmsNotSentException()
    : super(
        kind: ApiErrorKind.rateLimit,
        statusCode: 429,
        backendMessage: 'new_device_sms_failed',
      );
}
