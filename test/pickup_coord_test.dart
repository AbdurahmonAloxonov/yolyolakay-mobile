import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/data/models/ride.dart';

/// Uchrashuv nuqtasining ANIQ koordinatasi (28.09.2026).
///
/// 🔴 Ilova `pickup_lat/pickup_lon` ni umuman o'qimas va yubormas edi —
/// xaritada qo'yilgan nuqta yo'qolar, yo'lovchi esa uni matndan geokod
/// qilingan taxminiy joyda ko'rardi. Backend maydonni saqlaydi va
/// qaytaradi (jonli o'lchandi: «Chorsu metro, 3-chiqish» → 41.3266,
/// 69.2366).
void main() {
  Map<String, dynamic> base() => {
    'id': 'r1',
    'origin_lat': 41.31,
    'origin_lon': 69.28,
    'destination_lat': 39.65,
    'destination_lon': 66.96,
    'pickup_point': 'Chorsu metro, 3-chiqish',
  };

  test('server bergan koordinata o\'qiladi', () {
    final ride = Ride.fromJson({
      ...base(),
      'pickup_lat': 41.3266,
      'pickup_lon': 69.2366,
    });
    expect(ride.hasPickupCoord, isTrue);
    expect(ride.pickupLat, 41.3266);
    expect(ride.pickupLon, 69.2366);
  });

  test('kalit yo\'q yoki nol nuqta — koordinata YO\'Q', () {
    expect(Ride.fromJson(base()).hasPickupCoord, isFalse);
    // Nol nuqta Gvineya ko'rfazida — «qo'yilmagan» deb o'qiladi.
    final zero = Ride.fromJson({...base(), 'pickup_lat': 0, 'pickup_lon': 0});
    expect(zero.hasPickupCoord, isFalse);
  });

  test('e\'lon so\'rovi koordinatani yuboradi, bo\'lmasa kalit YO\'Q', () {
    PublishRideRequest req({double? lat, double? lon}) => PublishRideRequest(
      departureTime: DateTime.utc(2026, 10, 1, 8),
      originAddress: 'Toshkent',
      originLat: 41.31,
      originLon: 69.28,
      destinationAddress: 'Samarqand',
      destinationLat: 39.65,
      destinationLon: 66.96,
      pricePerSeat: 100000,
      totalSeats: 3,
      vehicleId: 'v1',
      pickupPoint: 'Chorsu metro, 3-chiqish',
      pickupLat: lat,
      pickupLon: lon,
    );

    final withCoord = req(lat: 41.3266, lon: 69.2366).toJson();
    expect(withCoord['pickup_lat'], 41.3266);
    expect(withCoord['pickup_lon'], 69.2366);

    final withoutCoord = req().toJson();
    expect(withoutCoord.containsKey('pickup_lat'), isFalse);
    expect(withoutCoord.containsKey('pickup_lon'), isFalse);
  });
}
