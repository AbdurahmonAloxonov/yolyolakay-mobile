/// Muhit sozlamalari — build vaqtida `--dart-define` bilan almashtiriladi.
///
/// Masalan lokal backend bilan:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8090
/// (10.0.2.2 = Android emulyatordan xost mashinaning localhost'i)
class Env {
  const Env._();

  /// Gateway domeni.
  ///
  /// MUHIM: native ilovada CORS YO'Q. Web frontend `X-Device-ID`/`X-OS-Type`
  /// preflight'da bloklangani uchun `/api-proxy` (same-origin rewrite) orqali
  /// boradi — bu yerda u kerak emas, to'g'ridan-to'g'ri domenga chiqamiz.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.yolyolakay.com',
  );

  /// Barcha route'lar shu prefiks ostida.
  static String get apiRoot => '$apiBaseUrl/api/v1';

  /// Real-time WebSocket.
  ///
  /// ⚠ Yo'l gateway ILDIZIDA: `/ws` (eski `/api/v1/ws` EMAS).
  /// Auth query orqali: `?token=<access_jwt>` — backend user id'ni tokendan
  /// oladi, `user_id` YUBORILMAYDI.
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://api.yolyolakay.com/ws',
  );

  /*
   * ═══ XARITA PLITKALARI — PROVAYDER ALMASHTIRISH YAGONA JOYI ═══
   *
   * 🔴 NEGA SOZLANADIGAN (18.09.2026): plitkalar OSM Foundation'ning
   * BEPUL serveridan kelardi va ularning qoidasi ommaviy ilovaga
   * ruxsat bermaydi (heavy use). Manzil esa kodga qotirilgan edi —
   * ya'ni provayderni almashtirish RELIZ chiqarish degani bo'lardi,
   * bloklanish esa aynan reliz kunida bo'lishi mumkin.
   *
   * Endi almashtirish uchun QAYTA YIG'ISH shart, lekin KOD tegilmaydi:
   *
   *   flutter build appbundle \
   *     --dart-define=MAP_TILES_URL=https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key={key} \
   *     --dart-define=MAP_TILES_KEY=<kalit> \
   *     --dart-define=MAP_TILES_ATTRIBUTION=© MapTiler \
   *     --dart-define=MAP_TILES_DARK_URL=https://api.maptiler.com/maps/streets-v2-dark/{z}/{x}/{y}.png?key={key}
   *
   * ⚠️ KALIT MANZILGA QO'YILADI (`{key}`), ya'ni u SIR EMAS: har qanday
   * mijoz uni ko'ra oladi. Provayder panelida kalitni paket nomi/
   * referer bo'yicha CHEKLASH shart — bu plitka xizmatlarida odatiy yo'l.
   */
  static const String mapTilesUrl = String.fromEnvironment(
    'MAP_TILES_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// Provayderning TUNGI uslubi. Berilsa, ilova o'zining rang filtrini
  /// ISHLATMAYDI — tayyor tungi xarita har doim chiroyliroq chiqadi.
  static const String mapTilesDarkUrl = String.fromEnvironment(
    'MAP_TILES_DARK_URL',
  );

  static const String mapTilesKey = String.fromEnvironment('MAP_TILES_KEY');

  /// Provayder nomi attributsiyada. OSM yozuvi undan QAT'I NAZAR
  /// qoladi: ma'lumot baribir OpenStreetMap'niki (ODbL talabi).
  static const String mapTilesAttribution = String.fromEnvironment(
    'MAP_TILES_ATTRIBUTION',
  );

  /// Backend `/auth/*` 502 qaytarayotgan davrda UI'ni oxirigacha bosib ko'rish uchun.
  ///   flutter run --dart-define=MOCK_AUTH=true
  /// Har qanday telefon + kod `11111` token qaytaradi (tarmoqqa chiqmaydi).
  static const bool mockAuth = bool.fromEnvironment('MOCK_AUTH');

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Sayt manzili — huquqiy sahifalar shu yerdan ochiladi.
  ///
  /// Matn ilovada TAKRORLANMAYDI: shartlar o'zgarsa ikki joyda yangilash
  /// unutiladi va ilovadagi eskisi qolib ketardi. Do'kon talabi (Play /
  /// App Store) havola bilan qondiriladi.
  ///
  /// Kanonik domen — `yolyolakay.co.uz` (2026-07-30 qarori). `yolyolakayco.uz`
  /// unga 308 bilan yo'naltiriladi, ya'ni eski qiymat ham "ishlardi", lekin
  /// har havolada ortiqcha redirect va do'kon tekshiruvida chalkashlik berardi.
  static const String siteUrl = 'https://yolyolakay.co.uz';

  /// Sayt til prefiksi bilan ishlaydi (`/uz/privacy`, `/ru/terms`, `/en/terms`).
  static String legalUrl(String page, String langCode) =>
      '$siteUrl/$langCode/$page';

  /// Qo'llab-quvvatlash boti — ✅ 2026-08-07 da tekshirildi, ishlaydi.
  ///
  /// NEGA TELEGRAM: saytdagi `info@yolyolakay.co.uz` HOZIRCHA ishlamaydi (domen
  /// MX yozuvi haqiqiy pochta provayderini ko'rsatmaydi). Ya'ni bugun bu bot —
  /// foydalanuvchi biz bilan bog'lana oladigan YAGONA haqiqiy kanal. Play
  /// hisob o'chirish talabida ishlaydigan aloqa kanali SHART.
  ///
  /// Web bilan bir xil manba: `src/shared/config/contacts.ts`.
  /// Ilova versiyasi — qo'llab-quvvatlash murojaatiga qo'shiladi.
  ///
  /// 🔴 QO'LDA yozilgan, `package_info_plus` ATAYIN qo'shilmagan: bitta
  /// satr uchun butun paket (va uning platforma kodi) reliz hajmiga
  /// qo'shilishi arzimaydi. `pubspec.yaml` bilan mos turishini
  /// `test/app_version_test.dart` qo'riqlaydi — u ayri ketsa test yiqiladi.
  /// SENTRY — qurilmadagi yiqilishlarni ko'rish uchun.
  ///
  /// 🔴 NEGA KERAK (2026-08-25): saytda Sentry allaqachon jonli, ilovada
  /// esa UMUMAN yo'q edi. Ya'ni foydalanuvchi telefonida ilova yiqilsa,
  /// biz bundan XABAR TOPMAYMIZ — egasi aytmaguncha. 1020 da ko'p yangi
  /// kod bor, aynan hozir kerak.
  ///
  /// Bo'sh bo'lsa Sentry UMUMAN ishga tushmaydi (yig'ish ham buzilmaydi):
  /// `--dart-define=SENTRY_DSN=...` bilan beriladi.
  ///
  /// ⚠️ Hozircha SAYT bilan bir xil loyihaga yuboriladi. Bu ishlaydi,
  /// lekin ideal emas: Android va web hisobotlari aralashadi. Sentry'da
  /// alohida loyiha ochilsa, faqat shu qiymat almashtiriladi.
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  static const String appVersion = '1.0.0+1046';

  static const String supportTelegram = '@yolyolakay_support_bot';
  static const String supportTelegramUrl =
      'https://t.me/yolyolakay_support_bot';
}
