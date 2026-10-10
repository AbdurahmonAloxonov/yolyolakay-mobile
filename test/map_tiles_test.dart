import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/env.dart';
import 'package:yolyolakay/features/map/map_tiles.dart';

/// XARITA PLITKALARI — PROVAYDERNI ALMASHTIRISH YO'LI.
///
/// 🔴 NEGA (18.09.2026): plitka manzili kodga QOTIRILGAN edi va u
/// osm.org ga ketardi — OSM Foundation'ning qoidasi esa ommaviy
/// ilovaga ruxsat bermaydi. Ya'ni provayderni almashtirish kodni
/// o'zgartirish degani bo'lardi, bloklanish esa istalgan kuni.
///
/// 🔑 BU SINOV IKKI MARTA YUGURADI:
///   1. oddiy   — standart (osm.org, kalitsiz);
///   2. kalit bilan:
///      flutter test test/map_tiles_test.dart \
///        --dart-define=MAP_TILES_URL='https://x.tiles/{z}/{x}/{y}.png?key={key}' \
///        --dart-define=MAP_TILES_KEY=abc123 \
///        --dart-define=MAP_TILES_ATTRIBUTION='© MapTiler'
/// Ikkala holat ham shu yerda tekshiriladi — «almashtirsa ishlaydi»
/// degan da'vo O'LCHANGAN bo'lsin.
void main() {
  test('manzil tayyor: shablon o\'rni qolmaydi', () {
    for (final dark in [false, true]) {
      final url = tileUrlTemplate(dark: dark);
      expect(url, startsWith('https://'));
      // 🔴 Kalit qo'yilmasa `key={key}` bo'lib ketardi → provayder 403.
      expect(url.contains('{key}'), isFalse, reason: url);
      // Xarita plitkasi shablonining o'zi esa JOYIDA qolsin.
      for (final part in ['{z}', '{x}', '{y}']) {
        expect(url, contains(part));
      }
    }
  });

  test('kalit berilgan bo\'lsa manzilga tushadi', () {
    if (Env.mapTilesKey.isEmpty) return; // standart yig'ilish
    expect(tileUrlTemplate(dark: false), contains(Env.mapTilesKey));
  });

  /// ODbL: ma'lumot OSM'niki, shuning uchun bu yozuv HAR DOIM qoladi.
  test('attributsiyada OSM DOIM bor', () {
    expect(mapAttributionText, contains('OpenStreetMap'));
  });

  /// 🔴 Ilgari bu yozuv 5 faylda QO'LDA takrorlangan edi: provayder
  /// almashsa, ilova yangi xaritani ko'rsatib turib eski nomni yozardi.
  test('provayder nomi berilsa attributsiyaga qo\'shiladi', () {
    if (Env.mapTilesAttribution.isEmpty) {
      expect(mapAttributionText, '© OpenStreetMap');
    } else {
      expect(mapAttributionText, startsWith(Env.mapTilesAttribution));
      expect(mapAttributionText, contains('OpenStreetMap'));
    }
  });
}
