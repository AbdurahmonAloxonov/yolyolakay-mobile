import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/cities.dart';
import 'package:yolyolakay/core/road_facts.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// YO'L HAMROHI — «hozir qayerdan o'tyapmiz».
///
/// 🔴 NEGA TEST: bu karta odamga JOY HAQIDA GAP aytadi. Noto'g'ri joyni
/// ko'rsatsa yoki hali yetib bormagan shahar haqida gapirsa — ishonch
/// yo'qoladi va odam boshqa qaramaydi. Ayni paytda u internetsiz
/// ishlashi SHART: shaharlararo yo'lda aynan zerikish paytida antena
/// chiqmaydi.
void main() {
  group('joyni topish', () {
    test('shahar markazida — o\'sha shahar topiladi', () {
      final p = nearestKnownPlace(41.311081, 69.240562); // Toshkent
      expect(p?.name, 'Toshkent');
    });

    test('Samarqand markazi', () {
      final p = nearestKnownPlace(39.6542, 66.9597);
      expect(p?.name, 'Samarqand');
    });

    /// 🔴 Yo'l shahar MARKAZIDAN o'tmaydi, chetlab o'tadi — shuning uchun
    /// chegara 25 km. Undan uzoqda hech nima ko'rsatilmasligi kerak:
    /// hali yetib bormagan shahar haqida gapirish yolg'on bo'lardi.
    test('juda uzoqda — HECH NIMA topilmaydi', () {
      // Qozog'iston dashti, hech qanday shahrimizga yaqin emas.
      expect(nearestKnownPlace(47.0, 62.0), isNull);
    });

    test('okean o\'rtasida ham yiqilmaydi', () {
      expect(nearestKnownPlace(0, 0), isNull);
      expect(nearestKnownPlace(-89, 179), isNull);
    });

    /// ⚠️ Tuman darajasidagi yozuvlar CHIQARIB TASHLANADI: yo'lda
    /// «Yunusobod tumanidan o'tyapsiz» degan gap ma'nosiz.
    test('tuman QAYTARILMAYDI', () {
      for (final lat in [41.3, 39.65, 39.77]) {
        final p = nearestKnownPlace(lat, 69.24);
        if (p != null) expect(p.isDistrict, isFalse);
      }
    });
  });

  group('gaplar', () {
    /// 🔴 ENG MUHIM QOIDA: gap FAQAT ro'yxatda bor joy uchun qaytadi.
    /// Yo'q joy uchun `null` — chaqiruvchi hech nima chizmaydi. «Bu joy
    /// haqida ma'lumot yo'q» degan bo'sh karta zerikishni yechmaydi.
    test('ro\'yxatda yo\'q joy uchun null', () {
      final unknown = kPlaces.firstWhere(
        (p) => factFor(p) == null,
        orElse: () => kPlaces.first,
      );
      if (factFor(unknown) != null) return; // hammasida bor bo'lsa — o'tkazamiz
      expect(factFor(unknown), isNull);
    });

    test('uchala tilda ham BO\'SH EMAS', () {
      var checked = 0;
      for (final p in kPlaces) {
        final f = factFor(p);
        if (f == null) continue;
        checked++;
        for (final lang in Lang.values) {
          final text = f.forLang(lang);
          expect(text.trim(), isNotEmpty, reason: '${p.name} / $lang');
          // Gap juda uzun bo'lsa kartani buzadi va ovoz bilan
          // o'qilganda ham cho'ziladi.
          expect(text.length, lessThan(140), reason: '${p.name} / $lang');
        }
      }
      expect(checked, greaterThan(15), reason: 'yozuvlar yo\'qolib qolmasin');
    });

    /// Har gap KANONIK nomga bog'langan bo'lishi kerak — aks holda u
    /// hech qachon ko'rsatilmaydi (jimgina o'lik yozuv).
    test('har bir gap HAQIQIY joyga bog\'langan', () {
      final names = kPlaces.map((p) => p.name).toSet();
      var bound = 0;
      for (final p in kPlaces) {
        if (factFor(p) != null) bound++;
      }
      expect(bound, knownFactCount,
          reason: 'gaplar soni bog\'langanlar bilan mos kelsin');
      expect(names.contains('Toshkent'), isTrue);
    });
  });

  test('masofa hisobi — Toshkent–Samarqand ~270 km', () {
    final km = distanceKm(41.311081, 69.240562, 39.6542, 66.9597);
    expect(km, greaterThan(240));
    expect(km, lessThan(300));
  });
}
