import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:yolyolakay/features/map/road_route.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// «QANCHA QOLDI» MIJOZDA hisoblanadi.
///
/// 🔴 NEGA: serverning `GET /telematics/eta` endpointi HAR DOIM `0`
/// qaytaradi — 6 km uchun ham, 280 km uchun ham (30.08.2026 da jonli
/// o'lchandi, `probe.py tracking`). Backend uni tuzatguncha kutib
/// o'tirmaymiz: marshrut geometriyasi va joriy joylashuv bizda bor.
void main() {
  // Toshkent → Samarqand yo'nalishida SODDA to'g'ri "marshrut":
  // 41.30 dan 39.65 gacha, teng oraliqlarda 100 nuqta.
  RoadRoute route({double? meters, int? seconds}) {
    const from = 41.30, to = 39.65, lon = 68.0;
    return RoadRoute(
      points: [
        for (var i = 0; i < 100; i++)
          LatLng(from + (to - from) * (i / 99), lon),
      ],
      distanceMeters: meters,
      seconds: seconds,
    );
  }

  test('boshida turganda deyarli HAMMASI qoladi', () {
    final r = remainingOnRoute(route(meters: 300000, seconds: 18000),
        const LatLng(41.30, 68.0));

    expect(r, isNotNull);
    expect(r!.km, closeTo(300, 3));
    expect(r.duration!.inMinutes, closeTo(300, 5));
  });

  test('yarmiga yetganda YARMI qoladi', () {
    final r = remainingOnRoute(route(meters: 300000, seconds: 18000),
        LatLng((41.30 + 39.65) / 2, 68.0));

    expect(r!.km, closeTo(150, 5));
    expect(r.duration!.inMinutes, closeTo(150, 6));
  });

  test('oxirida deyarli HECH NIMA qolmaydi', () {
    final r = remainingOnRoute(route(meters: 300000, seconds: 18000),
        const LatLng(39.65, 68.0));

    expect(r!.km, lessThan(5));
  });

  /// 🔴 ENG MUHIM QOIDA: odam marshrutdan uzoqda bo'lsa raqam
  /// KO'RSATILMAYDI. U boshqa yo'ldan ketyapti va «qoldi» soni
  /// YOLG'ON bo'lardi — raqamsizlik noto'g'ri raqamdan yaxshi.
  test('marshrutdan uzoqda — null (yolg\'on raqam berilmaydi)', () {
    // Nukus — marshrutdan yuzlab kilometr narida.
    final r = remainingOnRoute(
        route(meters: 300000, seconds: 18000), const LatLng(42.45, 59.61));

    expect(r, isNull);
  });

  test('server davomiylik bermasa — masofa bor, vaqt YO\'Q', () {
    // Taxminiy vaqt O'YLAB TOPILMAYDI: odam uni haqiqat deb qabul qiladi.
    final r = remainingOnRoute(route(meters: 300000), const LatLng(41.30, 68.0));

    expect(r!.km, closeTo(300, 3));
    expect(r.duration, isNull);
  });

  test('geometriya yo\'q bo\'lsa — null', () {
    final r = remainingOnRoute(
      const RoadRoute(points: [LatLng(41.3, 69.2)]),
      const LatLng(41.3, 69.2),
    );

    expect(r, isNull);
  });

  test('«Qoldi» yorlig\'i uchala tilda bor', () {
    for (final lang in Lang.values) {
      expect(AppStrings(lang).routeLeft, isNotEmpty, reason: '$lang');
    }
  });

  test('o\'rin balansi matni uchala tilda to\'g\'ri', () {
    for (final lang in Lang.values) {
      final s = AppStrings(lang);
      expect(s.seatBalance(7, 4), contains('7'), reason: '$lang');
      expect(s.seatBalance(7, 4), contains('4'), reason: '$lang');
      expect(s.seatBalanceHint, isNotEmpty, reason: '$lang');
    }
  });
}
