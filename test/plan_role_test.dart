import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/data/models/billing.dart';

/// YO'LOVCHI TARIFLARI KO'RSATILMAYDI.
///
/// 🔴 O'LCHOVDAN (2026-09-03): backend `GET /billing/plans` ga to'rtta
/// yangi tarif qo'shdi — «Passenger Trial / Plus / Pro / Premium»,
/// 1 000–5 000 so'mdan, ya'ni yo'lovchidan bron uchun pul olish.
///
/// Bizning modelimizda yo'lovchi PUL TO'LAMAYDI. Egasi: «oldingi
/// tariflarimiz Plus, Pro, Premium yaxshi edi — qo'shilganlarini olib
/// tashla, kerakmas».
///
/// ⚠️ ENG MUHIM SHART pastda: roli NOMA'LUM tarif YASHIRILMAYDI.
/// Backend maydonni olib tashlasa, hamma tarif yo'qolib ekran bo'sh
/// qolgani xatoning eng yomon turi bo'lardi — odam to'lov yo'lini
/// umuman topmaydi.
void main() {
  BillingPlan plan(String? role, {String name = 'Plus'}) =>
      BillingPlan.fromJson({
        'plan_name': name,
        'price': 5000,
        'rides_quota': 2,
        'target_role': ?role,
      });

  test("yo'lovchi tarifi ko'rsatilmaydi", () {
    expect(plan('passenger').isForPassenger, isTrue);
    expect(plan('PASSENGER').isForPassenger, isTrue);
    expect(plan(' passenger ').isForPassenger, isTrue);
  });

  test('haydovchi tarifi ko\'rsatiladi', () {
    expect(plan('driver').isForPassenger, isFalse);
  });

  test('roli NOMA\'LUM tarif KO\'RSATILADI (ekran bo\'sh qolmasin)', () {
    expect(plan(null).isForPassenger, isFalse);
    expect(plan('').isForPassenger, isFalse);
    expect(plan('   ').isForPassenger, isFalse);
  });

  test('jonli javobdagi yettitadan uchtasi qoladi', () {
    // 03.09 da o'lchangan haqiqiy ro'yxat.
    final live = [
      plan('driver', name: 'Plus'),
      plan('driver', name: 'Pro'),
      plan('driver', name: 'Premium'),
      plan('passenger', name: 'Passenger Trial'),
      plan('passenger', name: 'Passenger Plus'),
      plan('passenger', name: 'Passenger Pro'),
      plan('passenger', name: 'Passenger Premium'),
    ];
    final shown = live.where((p) => !p.isForPassenger).toList();
    expect(shown.map((p) => p.name), ['Plus', 'Pro', 'Premium']);
  });
}
