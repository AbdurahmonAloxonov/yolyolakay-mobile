import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/data/models/ride.dart';

/// HAMROHLAR — safar javobining O'ZIDAGI `passengers[]`.
///
/// 🔴 NEGA BU SINOV BOR (14.09.2026): ro'yxat ilgari
/// `GET /rides/{id}/passengers` dan olinardi, u esa RBAC ostida —
/// begonaga 403 va hatto bron qilib TASDIQLANMAGAN odamga ham 403.
/// Ya'ni «kim bilan ketaman» degan javobni aynan QAROR QILAYOTGAN
/// odam ololmasdi, xato esa ekranda ko'rinmasdi (403 → bo'sh ro'yxat
/// → bo'lim chizilmaydi). Shuning uchun manba almashtirildi.
///
/// Sinov shu almashtirishni qo'riqlaydi: ro'yxat safar javobidan
/// O'QILISHI, telefon esa kelmasa `null` QOLISHI kerak.
void main() {
  Map<String, dynamic> ride(Object? passengers) => {
    'id': 'r1',
    'origin_address': 'Toshkent',
    'destination_address': 'Samarqand',
    'departure_time': '2026-09-20T08:00:00Z',
    'total_seats': 4,
    'available_seats': 2,
    'price_per_seat': 100000,
    'status': 'active',
    'passengers': ?passengers,
  };

  test('safar javobidagi passengers[] o\'qiladi', () {
    final r = Ride.fromJson(
      ride([
        {'id': 'u1', 'name': 'Ali', 'rating': 4.8, 'gender': 'male'},
        {'id': 'u2', 'name': 'Vali', 'rating': 5, 'gender': 'female'},
      ]),
    );

    expect(r.passengers.length, 2);
    expect(r.passengers.first.name, 'Ali');
    expect(r.passengers[1].gender, 'female');
  });

  test('telefon kalitisiz javobda `phone` null qoladi', () {
    // Begonaga backend `phone_number` ni UMUMAN yubormaydi (bo'sh satr
    // emas — kalit yo'q). Jonli o'lchandi 14.09.2026.
    final r = Ride.fromJson(
      ride([
        {'id': 'u1', 'name': 'Ali', 'rating': 4.8},
      ]),
    );

    expect(r.passengers.single.phone, isNull);
  });

  test('kalit yo\'q bo\'lsa bo\'sh ro\'yxat — xato OTILMAYDI', () {
    expect(Ride.fromJson(ride(null)).passengers, isEmpty);
  });

  test('yangi javobda ro\'yxat bo\'lmasa ESKISI saqlanadi', () {
    // `GET /rides/{id}` javobi qidiruv elementidan kambag'alroq
    // bo'lishi mumkin — `mergedWith` shuning uchun bor.
    final older = Ride.fromJson(
      ride([
        {'id': 'u1', 'name': 'Ali'},
      ]),
    );
    final fresh = Ride.fromJson(ride(null));

    expect(fresh.mergedWith(older).passengers.single.name, 'Ali');
  });
}
