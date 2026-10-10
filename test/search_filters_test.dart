import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/geo.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/features/search/search_filters.dart';

/// 🔴 JO'NASH VAQTI KELAJAKDA (10.09.2026): ilgari bu yerda qotirilgan
/// `DateTime(2026, 7, 30, 9)` turardi. `matches` vaqtga qaramagani uchun
/// testlar yashil edi — endi qaraydi, va o'sha sana ALLAQACHON o'tib
/// ketgan. Ya'ni qotirilgan sana testni sekin-asta yolg'onga aylantiradi.
Ride _ride({
  String id = 'r-1',
  String status = 'active',
  bool noSmoking = false,
  bool takesParcels = false,
  bool hasAc = false,
  String? genderRestriction,
  DrivingSpeed? drivingSpeed,
  DateTime? departureTime,
}) => Ride(
  id: id,
  originAddress: 'Toshkent',
  originLat: 41.2995,
  originLon: 69.2401,
  destinationAddress: 'Samarqand',
  destinationLat: 39.6542,
  destinationLon: 66.9597,
  departureTime:
      departureTime ?? DateTime.now().add(const Duration(days: 1)),
  totalSeats: 4,
  availableSeats: 3,
  pricePerSeat: 150000,
  status: status,
  noSmoking: noSmoking,
  takesParcels: takesParcels,
  hasAc: hasAc,
  genderRestriction: genderRestriction,
  drivingSpeed: drivingSpeed,
);

void main() {
  group('SearchFilters', () {
    test('filtr yo\'q — hamma faol safar o\'tadi', () {
      const filters = SearchFilters();
      expect(filters.isEmpty, isTrue);
      expect(filters.matches(_ride()), isTrue);
    });

    test('qulaylik filtri belgisiz safarni chiqarib tashlaydi', () {
      const filters = SearchFilters(noSmoking: true);
      expect(filters.matches(_ride(noSmoking: false)), isFalse);
      expect(filters.matches(_ride(noSmoking: true)), isTrue);
    });

    /// 🔴 Filtr YOQILMAGAN bo'lsa jins cheklovi natijaga TA'SIR QILMAYDI.
    ///
    /// 13.08.2026 dagi qaror shu qismi bilan KUCHIDA qoladi: «erkaklar ham
    /// uni qidira olsin» — ya'ni belgi hech kimdan hech narsani yashirmaydi.
    /// Filtrni yoqish esa endi HAMMAGA ochiq (08.09.2026).
    test('filtr yoqilmagan — jins cheklovi natijaga TA\'SIR QILMAYDI', () {
      const filters = SearchFilters(noSmoking: true);
      expect(
        filters.matches(_ride(noSmoking: true, genderRestriction: 'female')),
        isTrue,
      );
      expect(
        filters.matches(_ride(noSmoking: true, genderRestriction: 'male')),
        isTrue,
      );
    });

    /// «Faqat ayollar» — haydovchining SALON haqidagi e'loni: erkak
    /// haydovchi ham qo'ya oladi (egasi, 08.09.2026). Shuning uchun
    /// tekshiruv AYNAN `gender_restriction` bo'yicha, haydovchining
    /// jinsi bo'yicha EMAS.
    test('«Faqat ayollar» filtri belgisiz safarni kesadi', () {
      const filters = SearchFilters(womenOnly: true);
      expect(filters.isEmpty, isFalse);
      expect(filters.activeCount, 1);
      expect(filters.matches(_ride()), isFalse);
      expect(filters.matches(_ride(genderRestriction: 'male')), isFalse);
      expect(filters.matches(_ride(genderRestriction: 'female')), isTrue);
    });

    /// 🔴 Server ARALASH ro'yxat qaytaradi (08.09.2026 o'lchovi: parametr
    /// bilan kelgan 6 ta safarning 5 tasi cheklovsiz edi). Mijozda
    /// kesmasak, filtr yoqilgani bilan ro'yxat o'zgarmasdi.
    test('server aralash ro\'yxat bersa ham faqat ayollarniki qoladi', () {
      const filters = SearchFilters(womenOnly: true);
      final mixed = [
        _ride(id: 'a'),
        _ride(id: 'b', genderRestriction: 'female'),
        _ride(id: 'c', genderRestriction: ''),
      ];
      expect(
        mixed.where(filters.matches).map((r) => r.id).toList(),
        ['b'],
      );
    });

    test('«Faqat ayollar» saqlanadi va qayta o\'qiladi', () {
      const filters = SearchFilters(womenOnly: true, noSmoking: true);
      final restored = SearchFilters.fromJson(filters.toJson());
      expect(restored.womenOnly, isTrue);
      expect(restored.noSmoking, isTrue);
    });

    test('haydash uslubi aniq mos kelishi kerak', () {
      const filters = SearchFilters(drivingSpeed: DrivingSpeed.calm);
      expect(filters.matches(_ride(drivingSpeed: DrivingSpeed.fast)), isFalse);
      expect(filters.matches(_ride(drivingSpeed: DrivingSpeed.calm)), isTrue);
    });

    test('tugagan/bekor qilingan safar filtrlarsiz ham ko\'rinmaydi', () {
      const filters = SearchFilters();
      expect(filters.matches(_ride(status: 'completed')), isFalse);
      expect(filters.matches(_ride(status: 'cancelled')), isFalse);
      expect(filters.matches(_ride(status: 'active')), isTrue);
    });

    test('jo\'nab ketgan safar natijada TURMAYDI', () {
      const filters = SearchFilters();
      final now = DateTime(2026, 9, 10, 12);

      // Jonli holat (10.09.2026): backend 4-sentabrda jo'nagan safarni
      // hamon `active` deb qaytaryapti. Kartada u «Kechikmoqda —
      // 139 soat» bo'lib chiqardi.
      final oldRide = _ride(departureTime: DateTime(2026, 9, 4, 16, 58));
      expect(filters.matches(oldRide, now: now), isFalse);

      // Yo'ldagi mashinaga ham qidiruvdan o'tirib bo'lmaydi.
      final moving = _ride(
        status: 'in_progress',
        departureTime: DateTime(2026, 9, 10, 6),
      );
      expect(filters.matches(moving, now: now), isFalse);
    });

    test('KECHIKAYOTGAN safar natijada QOLADI (uch soatgacha)', () {
      const filters = SearchFilters();
      final now = DateTime(2026, 9, 10, 12);

      // 20 daqiqa kechikdi — haydovchi hali uchrashuv nuqtasida
      // bo'lishi mumkin, yo'lovchi yetib borsa o'tiradi.
      expect(
        filters.matches(
          _ride(departureTime: now.subtract(const Duration(minutes: 20))),
          now: now,
        ),
        isTrue,
      );
      // Chegaraning naq o'zi — hali qoladi.
      expect(
        filters.matches(
          _ride(departureTime: now.subtract(SearchFilters.lateGrace)),
          now: now,
        ),
        isTrue,
      );
      // Chegaradan bir daqiqa keyin — yo'q.
      expect(
        filters.matches(
          _ride(
            departureTime: now.subtract(
              SearchFilters.lateGrace + const Duration(minutes: 1),
            ),
          ),
          now: now,
        ),
        isFalse,
      );
    });

    test('bir nechta filtr VA shartida ishlaydi', () {
      const filters = SearchFilters(noSmoking: true, hasAc: true);
      expect(filters.activeCount, 2);
      expect(filters.matches(_ride(noSmoking: true, hasAc: false)), isFalse);
      expect(filters.matches(_ride(noSmoking: true, hasAc: true)), isTrue);
    });

    test('copyWith haydash uslubini alohida tozalaydi', () {
      const filters = SearchFilters(drivingSpeed: DrivingSpeed.fast);
      expect(filters.copyWith(clearDrivingSpeed: true).drivingSpeed, isNull);
      // clearDrivingSpeed'siz null uzatish qiymatni O'CHIRMAYDI (copyWith odati).
      expect(filters.copyWith(hasAc: true).drivingSpeed, DrivingSpeed.fast);
    });
  });

  group('distanceKm', () {
    test('Toshkent — Samarqand ~270 km', () {
      final km = distanceKm(
        fromLat: 41.2995,
        fromLon: 69.2401,
        toLat: 39.6542,
        toLon: 66.9597,
      );
      expect(km, greaterThan(250));
      expect(km, lessThan(290));
    });

    test('bir xil nuqta — 0', () {
      final km = distanceKm(
        fromLat: 41.2995,
        fromLon: 69.2401,
        toLat: 41.2995,
        toLon: 69.2401,
      );
      expect(km, closeTo(0, 0.001));
    });
  });

  /// SERVER filtrlari (2026-08-12). Bu qiymatlar tarmoqqa chiqadi, ya'ni
  /// xatosi jim kechadi: noto'g'ri sana oynasi "safar yo'q" bo'lib ko'rinadi
  /// va uni ilovaga qarab payqab bo'lmaydi.
  group('RideSearchParams.toQuery', () {
    RideSearchParams params({DateTime? date}) => RideSearchParams(
      originLat: 41.2995,
      originLon: 69.2401,
      destLat: 39.6542,
      destLon: 66.9597,
      minSeats: 2,
      date: date,
    );

    /// 🔴 08.09.2026 da jonli o'lchandi: «faqat ayollar» safari
    /// parametrsiz qidiruv javobiga UMUMAN kirmaydi (ketma-ket 6 ta
    /// so'rovda ham chiqmadi). Ya'ni bu bayroq serverga yetmasa,
    /// mijozdagi filtr HECH QACHON natija bermaydi.
    test('«Faqat ayollar» serverga gender_restriction bo\'lib ketadi', () {
      expect(params().toQuery().containsKey('gender_restriction'), isFalse);
      final q = RideSearchParams(
        originLat: 41.2995,
        originLon: 69.2401,
        destLat: 39.6542,
        destLon: 66.9597,
        womenOnly: true,
      ).toQuery();
      // ⚠️ AYNAN `female`: boshqa qiymatda backend 400 qaytaradi.
      expect(q['gender_restriction'], 'female');
    });

    test('sanasiz — date_from/date_to umuman yuborilmaydi', () {
      final q = params().toQuery();
      expect(q.containsKey('date_from'), isFalse);
      expect(q.containsKey('date_to'), isFalse);
      expect(q['min_seats'], 2);
    });

    test(
      'sana Toshkent sutkasiga aylanadi (UTC+5), qurilma mintaqasiga EMAS',
      () {
        final q = params(date: DateTime(2026, 8, 12)).toQuery();
        // Toshkentda 12-avgust 00:00 = 11-avgust 19:00 UTC.
        expect(q['date_from'], '2026-08-11T19:00:00.000Z');
      },
    );

    /// 🔴 SAYT BILAN BIR XIL BO'LISHI SHART (egasi tasdiqladi, 2026-08-16).
    ///
    /// Ilgari `date_to` ham yuborilardi va telefon FAQAT tanlangan kunni
    /// ko'rsatardi, sayt esa o'sha kundan BOSHLAB hammasini — bitta qidiruv
    /// ikki qurilmada boshqa-boshqa javob berardi. Safar kam bo'lgan
    /// yo'nalishda bu "bu yerda umuman safar yo'q" degan xato xulosaga
    /// olib kelardi.
    test('yuqori chegara YO\'Q — tanlangan kundan BOSHLAB qidiriladi', () {
      final q = params(date: DateTime(2026, 8, 12)).toQuery();
      expect(
        q.containsKey('date_to'),
        isFalse,
        reason: 'date_to qidiruvni bitta kun bilan cheklab qo\'yadi',
      );
    });

    test('sana to\'liq RFC3339 — backend qisqa formatni 400 qiladi', () {
      final from =
          params(date: DateTime(2026, 1, 1)).toQuery()['date_from'] as String;
      expect(from, contains('T'));
      expect(from, endsWith('Z'));
    });

    /// Filtr YOQILMAGANDA `gender_restriction` yuborilmaydi.
    ///
    /// 🔴 Bu qat'iy shart: parametr yuborilishining O'ZI natijani
    /// o'zgartiradi (08.09.2026 o'lchovi — u cheklovli safarlarni
    /// ro'yxatga QO'SHADI). Ya'ni uni "har ehtimolga qarshi" yuborib
    /// qo'ysak, filtrni yoqmagan odam ham boshqa ro'yxat ko'rardi.
    test('filtr yoqilmasa gender_restriction so\'rovda YO\'Q', () {
      expect(params().toQuery().containsKey('gender_restriction'), isFalse);
      expect(
        params(
          date: DateTime(2026, 8, 12),
        ).toQuery().containsKey('gender_restriction'),
        isFalse,
      );
    });

    test('copyWith boshqa maydonlarni saqlaydi', () {
      final base = params(date: DateTime(2026, 8, 12));
      final next = base.copyWith(date: DateTime(2026, 8, 15));
      expect(next.minSeats, 2);
      expect(next.originLat, base.originLat);
    });
  });

  /// 🔴 NARX SERVERGA KETADI, klientda kesilmaydi (2026-08-16).
  ///
  /// Saytda bu 2026-07-31 da tuzatilgan: klient faqat backend QAYTARGAN
  /// ro'yxatni filtrlaydi, ya'ni "50 000 gacha" degan odam server bergan
  /// bo'lakdan tashqaridagi ARZONROQ safarni umuman ko'rmaydi va
  /// "safar yo'q" deb o'ylaydi. Ilova ortda qolgan edi — endi bir xil.
  group('narx filtri', () {
    RideSearchParams params({double? min, double? max}) => RideSearchParams(
      originLat: 41.2995,
      originLon: 69.2401,
      destLat: 39.6542,
      destLon: 66.9597,
      priceMin: min,
      priceMax: max,
    );

    test('so\'rovga `price_min`/`price_max` bo\'lib ketadi', () {
      final q = params(min: 30000, max: 90000).toQuery();
      expect(q['price_min'], 30000);
      expect(q['price_max'], 90000);
    });

    test('narx tanlanmasa kalitlar UMUMAN yuborilmaydi', () {
      final q = params().toQuery();
      expect(q.containsKey('price_min'), isFalse);
      expect(q.containsKey('price_max'), isFalse);
    });

    test('faqat bittasi berilsa ikkinchisi yuborilmaydi', () {
      final q = params(max: 50000).toQuery();
      expect(q.containsKey('price_min'), isFalse);
      expect(q['price_max'], 50000);
    });

    test('`clearPrice` oralig\'ni butunlay olib tashlaydi', () {
      final cleared = params(min: 30000, max: 90000).copyWith(clearPrice: true);
      expect(cleared.toQuery().containsKey('price_min'), isFalse);
      expect(cleared.toQuery().containsKey('price_max'), isFalse);
    });

    /// Narx KLIENTDA kesilmasligi shart — aks holda natija ikki marta
    /// filtrlanadi va server bergan ro'yxat yana qisqaradi.
    test('SearchFilters.matches narxga TEGMAYDI', () {
      const filters = SearchFilters(priceMin: 100000);
      final cheap = Ride(
        id: 'r-1',
        originAddress: 'A',
        originLat: 1,
        originLon: 1,
        destinationAddress: 'B',
        destinationLat: 2,
        destinationLon: 2,
        departureTime: DateTime.now().add(const Duration(days: 1)),
        totalSeats: 4,
        availableSeats: 3,
        pricePerSeat: 10000,
        status: RideStatus.active,
      );
      expect(filters.matches(cheap), isTrue);
    });
  });
}
