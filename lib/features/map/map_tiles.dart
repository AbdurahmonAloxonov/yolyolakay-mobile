import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../app/dimens.dart';
import '../../core/env.dart';

/// Xarita plitkalari — OpenStreetMap.
///
/// ⚠ STANDART MANBA — osm.org, va u FAQAT ISHLAB CHIQISH UCHUN: OSM
/// Foundation'ning bepul serveri ommaviy ilovaga ruxsat bermaydi
/// (heavy use).
///
/// ✅ 18.09.2026: manzil endi KODDA QOTIRILGAN EMAS. Provayder
/// `--dart-define=MAP_TILES_URL=...` bilan almashtiriladi va kodning
/// birorta qatori tegilmaydi — batafsil qo'llanma `core/env.dart` da,
/// buyrug'i esa `DEPLOY.md` da. Attributsiya ham AVTOMAT o'zgaradi
/// (`mapAttributionText`), aks holda ilova yangi provayderni ko'rsatib
/// turib eski nomni yozardi.
///
/// `userAgentPackageName` majburiy: UA'siz so'rovlar bloklanadi.
///
/// ═══ OFFLINE XARITA (egasi shartli tanlagan band, 2026-08-25) ═══
///
/// 🔴 EGASINING SHARTI: «agar ortiqcha ovoragarchilik yuklantilmasa».
/// Shuning uchun yo'nalish plitkalarini OLDINDAN YUKLAB QO'YISH
/// QILINMADI — u ikki tomondan noto'g'ri bo'lardi:
///   1. odam so'ramagan holda o'nlab megabayt mobil trafik sarflanardi
///      (O'zbekistonda bu pul);
///   2. OSM'ning bepul plitka serveri qoidasi ommaviy ilovaning
///      ommaviy yuklab olishini TAQIQLAYDI (yuqoridagi ogohlantirish).
///
/// O'rniga: KO'RILGAN plitkalar diskda qoladi. Bu qo'shimcha bitta ham
/// so'rov qo'shmaydi (aksincha, OSM serveriga yuklamani KAMAYTIRADI —
/// ularning qoidasi aynan shuni talab qiladi) va odam uchun butunlay
/// ko'rinmas: bir marta ochilgan xarita tunnelda ham chiziladi.
///
/// ⚠️ HAJM: `flutter_map` 8.3 keshni O'ZI yoqadi, lekin standart chegara
/// 1 GB. Bu bizning foydalanuvchimiz uchun haddan tashqari — arzon
/// telefonda xotira doim tanqis. 80 MB shahar markazlarini va bir necha
/// yo'nalishni saqlashga yetadi.
///
/// ⚠️ SINOVDA KESH O'CHIQ (16.09.2026). `BuiltInMapCachingProvider` diskdagi
/// kesh papkasini `path_provider` orqali so'raydi, sinov muhitida esa u
/// plagin yo'q: `MissingPluginException(getApplicationCacheDirectory)`.
/// Ilgari bu sezilmasdi — xarita faqat pastdan chiqadigan varaqda edi va
/// ekran sinovlarida umuman chizilmasdi. Xarita EKRANLARNING O'ZIGA
/// qo'yilgach (safar detali, haydovchi ekrani, profil) o'nlab sinov shu
/// istisnoga urila boshladi. Sinovda kesh baribir keraksiz: plitka ham
/// yuklanmaydi.
/// Plitka manzili — `{key}` o'rniga provayder kaliti qo'yiladi.
///
/// ⚠️ Kalitsiz shablonga `{key}` yozilgan bo'lsa, u O'CHIRILADI, aks
/// holda so'rov `key={key}` bo'lib ketardi va provayder 403 berardi.
String tileUrlTemplate({required bool dark}) {
  final base = dark && Env.mapTilesDarkUrl.isNotEmpty
      ? Env.mapTilesDarkUrl
      : Env.mapTilesUrl;
  return base.replaceAll('{key}', Env.mapTilesKey);
}

/// Attributsiya matni — YAGONA manba.
///
/// 🔴 NEGA (18.09.2026): bu yozuv beshta faylda QO'LDA takrorlangan edi.
/// Provayder almashsa, ilova yangi xaritani ko'rsatib turib eski nomni
/// yozardi — ya'ni litsenziya talabi buzilardi va buni hech kim sezmasdi.
///
/// OSM yozuvi HAR DOIM qoladi: deyarli barcha provayderlar OSM
/// ma'lumotidan foydalanadi va ODbL buni talab qiladi.
String get mapAttributionText => Env.mapTilesAttribution.isEmpty
    ? '© OpenStreetMap'
    : '${Env.mapTilesAttribution} · © OpenStreetMap';

TileLayer mapTileLayer({bool dark = false}) => TileLayer(
  urlTemplate: tileUrlTemplate(dark: dark),
  userAgentPackageName: 'uz.yolyolakay.mobile',
  maxNativeZoom: 19,
  tileProvider: NetworkTileProvider(
    // ⚠️ `null` YARAMAYDI: `flutter_map` uni «standart keshni ishlat»
    // deb tushunadi va o'sha standart kesh ham diskka murojaat qiladi.
    // O'chirish uchun AYNAN `DisabledMapCachingProvider` kerak.
    cachingProvider: kIsTest
        ? const DisabledMapCachingProvider()
        : BuiltInMapCachingProvider.getOrCreateInstance(
            maxCacheSize: 80 * 1024 * 1024,
          ),
  ),
);

/// Sinov muhitidamizmi. Flutter test yugurtirgichi shu o'zgaruvchini
/// o'rnatadi — boshqa ishonchli belgi yo'q.
final bool kIsTest = Platform.environment.containsKey('FLUTTER_TEST');

/// Tungi rejimda xarita — plitkalarni FILTR bilan qoraytiramiz.
///
/// OSM raster plitkalari faqat yorug' variantda keladi: ilova qorong'i
/// bo'lganda oppoq xarita ko'zni qamashtiradi (jonli tekshiruvda ko'rildi).
///
/// Tayyor tungi provayder (CartoDB dark_matter kabi) chiroyliroq chiqardi,
/// lekin u YANGI xizmat va yangi attributsiya talabi degani — plitka manbasi
/// baribir relizdan oldin almashtiriladi, shuning uchun hozir qo'shimcha
/// bog'liqlik olib kelmaymiz. Filtr yechimi shu bitta joyda yashaydi va
/// provayder almashganda osongina olib tashlanadi.
///
/// Matritsa — `invert(1)` va `hue-rotate(180deg)` ning KO'PAYTMASI (veb
/// xaritalarida qo'llanadigan standart usul).
///
/// Faqat teskarilash yetmaydi: yashil park magentaga aylanadi (jonli
/// tekshiruvda ko'rildi). 180° ton burilishi uni yana yashilga qaytaradi,
/// oq fon esa qora, qora yozuv esa oq bo'lib qolaveradi.
class MapTiles extends StatelessWidget {
  const MapTiles({super.key});

  static const _darkFilter = ColorFilter.matrix(<double>[
    0.574, -1.430, -0.144, 0, 255, //
    -0.426, -0.430, -0.144, 0, 255, //
    -0.426, -1.430, 0.856, 0, 255, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (!dark) return mapTileLayer();

    // Provayderning O'Z tungi uslubi bor — filtr SHART EMAS va
    // qo'pol filtrdan chiroyliroq (yozuvlar o'qilarli qoladi).
    if (Env.mapTilesDarkUrl.isNotEmpty) return mapTileLayer(dark: true);

    return ColorFiltered(colorFilter: _darkFilter, child: mapTileLayer());
  }
}

/// Attributsiya — litsenziya buni TALAB qiladi, olib tashlanmasin.
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm,
        ),
        child: Text(
          mapAttributionText,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }
}

/// Xarita USTIDAGI kichik attributsiya belgisi.
///
/// 🔴 NEGA UMUMIY (18.09.2026): aynan shu belgi TO'RT faylda nusxa
/// bo'lib yotgandi (`route_preview_map`, `point_preview_map`,
/// `my_roads_map`) — o'lchami, foni, shriftigacha qo'lda
/// takrorlangan. Bittasi o'zgarsa qolgani ortda qolardi; matnning
/// o'zi esa allaqachon bir manbadan (`mapAttributionText`).
class MapAttributionBadge extends StatelessWidget {
  const MapAttributionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxs),
        child: Text(
          mapAttributionText,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9,
            color: scheme.outline,
          ),
        ),
      ),
    );
  }
}
