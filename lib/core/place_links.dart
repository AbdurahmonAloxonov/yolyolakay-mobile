import 'package:url_launcher/url_launcher.dart';

/// Joyni TASHQI xarita ilovasida ochish.
///
/// 🔴 NEGA KERAK: uchrashuv nuqtasi ilovada matn va xarita nuqtasi bo'lib
/// turardi, lekin odam u yerga YETIB BORISHI kerak. Ilovada birorta ham
/// navigator havolasi yo'q edi (Yandex tozalanganda ketgan), ya'ni odam
/// manzilni qo'lda boshqa ilovaga ko'chirardi.
///
/// 🔴 NEGA `geo:` VA MUAYYAN ILOVA EMAS: `geo:` — Android standarti,
/// foydalanuvchining O'ZIDA o'rnatilgan xarita ilovasini ochadi (OsmAnd,
/// Organic Maps, nima bo'lsa). Bu bizni Google yoki Yandex'ga bog'lamaydi
/// — egasi (2026-08-20) Yandex'ni ataylab olib tashlagan edi.
///
/// ⚠️ OSM'ning O'ZI navigator EMAS, u xarita MA'LUMOTI. Shuning uchun
/// zaxira — openstreetmap.org sahifasi: u nuqtani ko'rsatadi, lekin
/// yo'l ko'rsatmaydi. Buni yashirmaymiz.
///
/// Qaytadi: ochildimi. Chaqiruvchi `false` da xabar ko'rsatadi —
/// tugmaning jim o'lishi eng yomon variant.
Future<bool> openInMaps({
  required double lat,
  required double lon,
  String? label,
}) async {
  final name = (label ?? '').trim();

  // 1) Qurilmadagi xarita ilovasi. `q=` — nuqta ustidagi yozuv.
  final geo = Uri.parse(
    name.isEmpty
        ? 'geo:$lat,$lon?q=$lat,$lon'
        : 'geo:$lat,$lon?q=$lat,$lon(${Uri.encodeComponent(name)})',
  );
  try {
    if (await launchUrl(geo, mode: LaunchMode.externalApplication)) return true;
  } catch (_) {
    // Xarita ilovasi yo'q — pastdagi zaxiraga tushamiz.
  }

  // 2) Zaxira: OSM sahifasi brauzerda (belgili nuqta bilan).
  final web = Uri.parse(
    'https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=17/$lat/$lon',
  );
  try {
    return await launchUrl(web, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
