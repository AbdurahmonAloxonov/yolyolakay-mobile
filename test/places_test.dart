import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/cities.dart';

void main() {
  group('Web bilan koordinata mosligi', () {
    // ⚠ Bu qiymatlar web'dagi shared/data/uzCities.ts dan. Ular ajralib ketsa
    // saytda yaratilgan e'lon mobil qidiruv radiusidan chiqib, umuman
    // topilmaydi — shuning uchun eng muhim shaharlar test bilan qotirilgan.
    const webCoords = {
      'Toshkent': (41.311081, 69.240562),
      'Samarqand': (39.6542, 66.9597),
      'Buxoro': (39.7681, 64.4210),
      'Andijon': (40.7821, 72.3442),
      'Namangan': (41.0058, 71.6436),
      'Nukus': (42.4611, 59.6111),
    };

    for (final entry in webCoords.entries) {
      test('${entry.key} koordinatasi web bilan bir xil', () {
        final place = resolvePlace(entry.key);
        expect(place, isNotNull);
        expect(place!.lat, entry.value.$1);
        expect(place.lon, entry.value.$2);
      });
    }
  });

  group('resolvePlace', () {
    test('apostrofni e\'tiborsiz qoldiradi', () {
      expect(resolvePlace("Farg'ona")?.name, "Farg'ona");
      expect(resolvePlace('Fargona')?.name, "Farg'ona");
    });

    test('ruscha kirill yozuvni topadi', () {
      expect(resolvePlace('Ташкент')?.name, 'Toshkent');
      expect(resolvePlace('коканд')?.name, "Qo'qon");
    });

    test('o\'zbekcha kelishik qo\'shimchasini tushunadi', () {
      expect(resolvePlace('Toshkentdan')?.name, 'Toshkent');
      expect(resolvePlace('Samarqandga')?.name, 'Samarqand');
    });

    test('ma\'muriy qo\'shimchani olib tashlaydi', () {
      expect(resolvePlace('Chilonzor tumani')?.name, 'Chilonzor');
      expect(resolvePlace('Toshkent shahri')?.name, 'Toshkent');
    });

    test('noma\'lum joy uchun null', () {
      expect(resolvePlace('Parij'), isNull);
      expect(resolvePlace(''), isNull);
    });
  });

  group('searchPlaces', () {
    test('nomi bilan boshlanadiganlar birinchi keladi', () {
      final results = searchPlaces('nam');
      expect(results.first.name, 'Namangan');
    });

    test('bo\'sh so\'rovda ham ro\'yxat qaytadi', () {
      expect(searchPlaces('').isNotEmpty, isTrue);
    });

    test('limit hurmat qilinadi', () {
      expect(searchPlaces('', limit: 5).length, 5);
    });
  });

  group('Tumanlar', () {
    test('Toshkent shahri tumanlari mavjud', () {
      final districts = kPlaces
          .where((p) => p.isDistrict && p.region == 'Toshkent shahri')
          .map((p) => p.name)
          .toList();

      expect(districts, contains('Chilonzor'));
      expect(districts, contains('Yunusobod'));
      expect(districts, contains('Sergeli'));
      expect(districts.length, greaterThanOrEqualTo(10));
    });

    test('tuman shahardan ajratilgan', () {
      expect(resolvePlace('Chilonzor')?.isDistrict, isTrue);
      expect(resolvePlace('Toshkent')?.isDistrict, isFalse);
    });
  });

  group('Ma\'lumotnoma yaxlitligi', () {
    test('takror nom yo\'q', () {
      final names = kPlaces.map((p) => p.name).toList();
      expect(names.toSet().length, names.length);
    });

    test('barcha koordinatalar O\'zbekiston chegarasida', () {
      for (final place in kPlaces) {
        expect(place.lat, inInclusiveRange(37.0, 46.0), reason: place.name);
        expect(place.lon, inInclusiveRange(55.0, 74.0), reason: place.name);
      }
    });

    // OSM'da `admin_level=6` deb noto'g'ri belgilangan obyektlar uchraydi
    // (ko'cha, hokimiyat binosi) — `build_districts.py` ularni filtrlaydi.
    test('ro\'yxatda ko\'cha/hokimiyat kabi shovqin yo\'q', () {
      for (final place in kPlaces) {
        expect(
          place.name.toLowerCase(),
          isNot(matches(r"ko['ʻʼ`]?chasi|hokimiyat|mahallasi")),
        );
      }
    });

    // "Buxoro shahri" tumani OSM'da alohida obyekt, lekin bizda Buxoro
    // SHAHAR sifatida bor — dublikat ro'yxatda ikkita bir xil joyni
    // ko'rsatib chalkashtirardi.
    test('shahar nomi tuman sifatida takrorlanmaydi', () {
      final cities = kPlaces
          .where((p) => !p.isDistrict)
          .map((p) => p.name.toLowerCase())
          .toSet();
      final districts = kPlaces
          .where((p) => p.isDistrict)
          .map((p) => p.name.toLowerCase());

      for (final district in districts) {
        expect(cities, isNot(contains(district)));
      }
    });
  });

  group('Viloyat tumanlari', () {
    test('barcha viloyatlar qamrab olingan', () {
      final regions = kPlaces
          .where((p) => p.isDistrict && p.region != 'Toshkent shahri')
          .map((p) => p.region)
          .toSet();

      // 12 viloyat + Qoraqalpog'iston (Toshkent shahri alohida hisoblangan).
      expect(regions.length, greaterThanOrEqualTo(13), reason: '$regions');
      expect(regions, contains("Qoraqalpog'iston"));
      expect(regions, contains('Surxondaryo'));
    });

    // Hozir 149 (191 generatsiya - nomi shahar bilan ustma-ust tushgani
    // tashlangan + Toshkent shahrining 12 tumani). Chegara pastroq: bir-ikki
    // tuman qo'shilishi/o'chishi normal, generatsiya BUZILISHI esa yo'q.
    test('ro\'yxatda 140 dan ortiq tuman bor', () {
      final districts = kPlaces.where((p) => p.isDistrict);
      expect(districts.length, greaterThan(140));
    });

    test('tuman nomlari qidiruvda topiladi', () {
      // Turli viloyatlardan namunalar — generatsiya buzilsa yiqiladi.
      expect(resolvePlace('Baliqchi')?.isDistrict, isTrue);
      expect(resolvePlace('Buloqboshi')?.isDistrict, isTrue);
    });
  });

  /// 🔴 EGASI, 2026-08-25. O'ZBEK KIRILLI umuman qo'llab-quvvatlanmasdi:
  /// ro'yxatda lotin va RUSCHA nomlar bor edi, o'zbek kirilli yo'q.
  /// Ishlagandek ko'ringani uchun xato uzoq payqalmadi — «Самарканд»,
  /// «Наманган», «Нукус» ruscha yozilishi bilan ustma-ust tushadi va
  /// topilardi, «Тошкент» va «Бухоро» esa yo'q edi.
  ///
  /// Bu ikki joyni birdan buzardi: ovozli qidiruv (Android `uz` tilida
  /// kirill qaytaradi) va kirill klaviaturada yozadigan odam.
  group('o\'zbek kirilli', () {
    test('shaharlar topiladi', () {
      const expected = {
        'Тошкент': 'Toshkent',
        'Самарқанд': 'Samarqand',
        'Бухоро': 'Buxoro',
        'Андижон': 'Andijon',
        'Фарғона': "Farg'ona",
        'Қўқон': "Qo'qon",
        'Урганч': 'Urganch',
        'Қарши': 'Qarshi',
        'Термиз': 'Termiz',
        'Жиззах': 'Jizzax',
        'Гулистон': 'Guliston',
        'Навоий': 'Navoiy',
        'Чирчиқ': 'Chirchiq',
        'Олмалиқ': 'Olmaliq',
        'Бекобод': 'Bekobod',
      };
      expected.forEach((cyrillic, latin) {
        expect(resolvePlace(cyrillic)?.name, latin, reason: cyrillic);
      });
    });

    test('kelishik qo\'shimchasi bilan ham', () {
      expect(resolvePlace('Тошкентдан')?.name, 'Toshkent');
      expect(resolvePlace('Самарқандга')?.name, 'Samarqand');
      expect(resolvePlace('Бухорога')?.name, 'Buxoro');
    });

    test('ro\'yxat filtri kirillda ishlaydi', () {
      expect(searchPlaces('тошкент').first.name, 'Toshkent');
      expect(searchPlaces('чирчиқ').first.name, 'Chirchiq');
      expect(searchPlaces('фарғона').first.name, "Farg'ona");
    });

    /// RUSCHA nomlar avvalgidek ishlashi SHART — o'girish ular ishlamay
    /// qolgandan keyin chaqiriladi, ustidan bosmaydi.
    test('ruscha nomlar buzilmadi', () {
      expect(resolvePlace('Ташкент')?.name, 'Toshkent');
      expect(resolvePlace('Ташкента')?.name, 'Toshkent');
      expect(resolvePlace('Самарканд')?.name, 'Samarqand');
      expect(resolvePlace('Наманган')?.name, 'Namangan');
    });
  });
}
