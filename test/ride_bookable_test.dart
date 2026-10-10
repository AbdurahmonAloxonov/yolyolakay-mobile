import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/features/search/search_filters.dart';

/// 🔴 12.09.2026: «Joy band qilish» tugmasi ILGARI faqat `isActive` ga
/// qarardi. Jo'nab ketgan safar backendда `active` qolgani uchun tugma
/// faol turar, bosilganda backend 409 qaytarar — foydalanuvchi SABABSIZ
/// xato ko'rardi. Endi tugma ham, qidiruv ham [Ride.isBookable] ga
/// bo'ysunadi. Bu test o'sha yagona manbani qo'riqlaydi.
Ride _ride({String status = 'active', DateTime? departureTime}) => Ride(
  id: 'r-1',
  originAddress: 'Toshkent',
  originLat: 41.2995,
  originLon: 69.2401,
  destinationAddress: 'Samarqand',
  destinationLat: 39.6542,
  destinationLon: 66.9597,
  departureTime: departureTime ?? DateTime.now().add(const Duration(days: 1)),
  totalSeats: 4,
  availableSeats: 3,
  pricePerSeat: 150000,
  status: status,
);

void main() {
  final now = DateTime(2026, 9, 12, 12);

  group('Ride.isBookable', () {
    test('kelajakdagi faol safar — bron qilsa bo\'ladi', () {
      expect(
        _ride(departureTime: now.add(const Duration(days: 1))).isBookable(now: now),
        isTrue,
      );
    });

    test('tugagan / bekor qilingan safar — bo\'lmaydi', () {
      expect(
        _ride(status: RideStatus.completed).isBookable(now: now),
        isFalse,
      );
      expect(
        _ride(status: RideStatus.cancelled).isBookable(now: now),
        isFalse,
      );
    });

    test('20 daqiqa kechikdi — hali bo\'ladi (haydovchi kechikadi)', () {
      expect(
        _ride(departureTime: now.subtract(const Duration(minutes: 20)))
            .isBookable(now: now),
        isTrue,
      );
    });

    test('3 soatlik oynaning naq o\'zi — hali bo\'ladi', () {
      expect(
        _ride(departureTime: now.subtract(Ride.bookingLateGrace))
            .isBookable(now: now),
        isTrue,
      );
    });

    test('oynadan bir daqiqa keyin — endi BO\'LMAYDI', () {
      expect(
        _ride(
          departureTime: now.subtract(
            Ride.bookingLateGrace + const Duration(minutes: 1),
          ),
        ).isBookable(now: now),
        isFalse,
      );
    });

    test('5 soat oldin jo\'nagan — bo\'lmaydi (ulashilgan havola holati)', () {
      expect(
        _ride(departureTime: now.subtract(const Duration(hours: 5)))
            .isBookable(now: now),
        isFalse,
      );
    });
  });

  group('SearchFilters.isBookable — Ride.isBookable ga delegatsiya', () {
    test('ikkalasi bir xil chegarani beradi (yagona manba)', () {
      final departed = _ride(
        departureTime: now.subtract(const Duration(hours: 4)),
      );
      final live = _ride(departureTime: now.add(const Duration(hours: 4)));
      expect(SearchFilters.isBookable(departed, now: now), departed.isBookable(now: now));
      expect(SearchFilters.isBookable(live, now: now), live.isBookable(now: now));
      // Chegara qiymati ham modeldan olinadi.
      expect(SearchFilters.lateGrace, Ride.bookingLateGrace);
    });
  });
}
