/// CHATDA JOY ULASHISH — xabar formati.
///
/// 🔴 NEGA KERAK BO'LDI (16.09.2026): uchrashuv nuqtasi AYNAN chatda
/// kelishiladi («Chortoq bozor yonida turing»), lekin ulashishning yagona
/// yo'li MATN edi. Matn esa notanish shaharda foydasiz: «3-mavze» qayerda
/// ekanini kelgan odam bilmaydi. Bu bizda taksidan ham muhimroq — taksida
/// haydovchi eshigingga keladi, bizda esa ikkalangiz UCHRASHISH nuqtasini
/// topishingiz kerak.
///
/// 🔑 BACKEND O'ZGARMAYDI. Chat xabari — oddiy matn (`content`), unda
/// tur maydoni yo'q. Shuning uchun joy MATN sifatida yuboriladi, lekin
/// STANDART `geo:` URI ko'rinishida:
///
///     geo:41.311081,69.240562
///     Toshkent, Amir Temur ko'chasi
///
/// Bu tanlovning uchta sababi bor:
///   1. ESKI mijoz (yangilanmagan ilova, sayt) buni MATN bo'lib ko'radi —
///      va matn baribir foydali: ikkinchi qatorda joy nomi turadi;
///   2. `geo:` — standart URI, Android uni o'zi taniydi va xarita
///      ilovasida ochadi (biz ham shu sxemani navigatorga ishlatamiz);
///   3. pushda ham o'qiladigan ko'rinishda qoladi.
///
/// Emoji ATAYIN yo'q: `scripts/check-emoji.mjs` interfeys matnida emojini
/// taqiqlaydi va bu matn ikkala mijozda ham chiziladi.
library;

/// Chatda ulashilgan joy.
class GeoMessage {
  const GeoMessage({required this.lat, required this.lon, this.label});

  final double lat;
  final double lon;

  /// Joy nomi — teskari geokoderdan. Bo'lmasa `null`.
  final String? label;

  /// Yuboriladigan xabar matni.
  String encode() {
    final head = 'geo:$lat,$lon';
    final name = label?.trim();
    if (name == null || name.isEmpty) return head;
    return '$head\n$name';
  }
}

/// Xabar matnidan joyni ajratadi. Joy bo'lmasa `null` — xabar oddiy matn
/// sifatida chiziladi.
///
/// ⚠️ FAQAT xabar `geo:` bilan BOSHLANSA: odam xabar o'rtasida `geo:` deb
/// yozsa, uni butun boshli xaritaga aylantirish noto'g'ri bo'lardi.
GeoMessage? parseGeoMessage(String content) {
  final text = content.trim();
  if (text.isEmpty) return null;

  /*
   * ESKI FORMAT — saytning OSM havolasi (faqat O'QISH uchun).
   *
   * 🔴 Saytda «joyimni yuborish» ALLAQACHON bor edi va u havola
   * yuborardi: `https://www.openstreetmap.org/?mlat=..&mlon=..#map=..`.
   * Ilovada esa bu oddiy uzun matn bo'lib ko'rinardi va bosilsa OSM
   * sayti ochilib, odam ilovadan chiqib ketardi. Tarixda bunday
   * xabarlar bor — ular ham xarita bo'lib chizilsin.
   *
   * Biz bu formatda YUBORMAYMIZ: yagona format — `geo:`.
   */
  if (text.contains('openstreetmap.org') && text.contains('mlat=')) {
    final lat = double.tryParse(
      RegExp(r'[?&]mlat=(-?[\d.]+)').firstMatch(text)?.group(1) ?? '',
    );
    final lon = double.tryParse(
      RegExp(r'[?&]mlon=(-?[\d.]+)').firstMatch(text)?.group(1) ?? '',
    );
    if (lat == null || lon == null) return null;
    if (lat.abs() > 90 || lon.abs() > 180) return null;
    if (lat == 0 && lon == 0) return null;
    return GeoMessage(lat: lat, lon: lon);
  }

  if (!text.toLowerCase().startsWith('geo:')) return null;

  final newline = text.indexOf('\n');
  final head = (newline == -1 ? text : text.substring(0, newline)).substring(4);
  final label = newline == -1 ? null : text.substring(newline + 1).trim();

  // `geo:lat,lon` — qo'shimcha parametrlar (`;u=`, `?q=`) tashlanadi:
  // biz ularni yubormaymiz, lekin boshqa ilovadan kelishi mumkin.
  final coords = head.split(RegExp(r'[;?]')).first;
  final parts = coords.split(',');
  if (parts.length < 2) return null;

  final lat = double.tryParse(parts[0].trim());
  final lon = double.tryParse(parts[1].trim());
  if (lat == null || lon == null) return null;
  // Yaroqsiz koordinata xaritani okean o'rtasiga sudrab ketardi.
  if (lat.abs() > 90 || lon.abs() > 180) return null;
  if (lat == 0 && lon == 0) return null;

  return GeoMessage(
    lat: lat,
    lon: lon,
    label: (label == null || label.isEmpty) ? null : label,
  );
}
