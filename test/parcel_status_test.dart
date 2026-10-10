import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/data/models/parcel.dart';

/// 🔴 NEGA YOZILDI (2026-09-04): `pickup` dan keyingi holat backendda
/// `picked_up`, mijozlarda esa `in_transit` deb kutilardi. Natijada
/// «Yetkazdim» tugmasi HECH QACHON chiqmasdi va posilka oxirgi qadamda
/// qotib qolardi — 16-avgustdan beri quvib yurgan muammoning qolgan
/// yarmi aynan shu edi. Xato hech qanday testni yiqitmagandi, chunki
/// holat nomi shunchaki MOS KELMASDI.
///
/// Saytdagi juftligi — `isParcelPickedUp` (`src/shared/api/parcels.ts`).
void main() {
  Parcel p(String? status) => Parcel.fromJson({'id': 'x', 'status': ?status});

  test('picked_up — haydovchi olgan holat', () {
    expect(p('picked_up').isPickedUp, isTrue);
    expect(p('PICKED_UP').isPickedUp, isTrue);
  });

  test('in_transit — eski nom, baribir tushuniladi', () {
    expect(p('in_transit').isPickedUp, isTrue);
  });

  test('boshqa holatlar «olingan» emas', () {
    for (final s in ['pending', 'accepted', 'delivered', 'cancelled', null]) {
      expect(p(s).isPickedUp, isFalse, reason: s ?? 'null');
    }
  });

  test('delivered alohida tanilaydi', () {
    expect(p('delivered').isDelivered, isTrue);
    expect(p('picked_up').isDelivered, isFalse);
  });
}
