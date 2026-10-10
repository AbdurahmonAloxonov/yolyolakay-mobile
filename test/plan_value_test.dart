import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/data/models/billing.dart';
import 'package:yolyolakay/features/billing/tariffs_screen.dart';

/// Tarif kartasidagi REKLAMA raqamlari.
///
/// 🔴 Egasi shart qo'ydi (2026-08-16): "bo'rttirib, lekin TO'G'RISINI".
/// Ya'ni kartadagi har bir gap hisoblab chiqarilgan bo'lishi kerak.
/// Bu testlar aynan shuni qo'riqlaydi — hisob buzilsa, ekranda yolg'on
/// raqam paydo bo'ladi va uni ko'z bilan payqash deyarli imkonsiz.
void main() {
  BillingPlan plan(String name, double price, int quota) =>
      BillingPlan(name: name, price: price, ridesQuota: quota);

  group('perRidePrice', () {
    test('narx paketga bo\'linadi', () {
      expect(perRidePrice(plan('Pro', 60000, 40)), 1500);
      expect(perRidePrice(plan('Plus', 30000, 15)), 2000);
    });

    test('cheksiz tarifda hisoblanmaydi', () {
      // Bo'linadigan son yo'q: "cheksiz" ni nechaga bo'lish kerakligini
      // faqat foydalanuvchining o'zi biladi.
      expect(perRidePrice(plan('Premium', 100000, -1)), isNull);
    });

    test('bepul tarifda hisoblanmaydi', () {
      expect(perRidePrice(plan('Free Trial', 0, 3)), isNull);
    });

    test('paket nolga teng bo\'lsa — nolga bo\'lish YO\'Q', () {
      expect(perRidePrice(plan('Buzuq', 50000, 0)), isNull);
    });
  });

  group('«Eng foydali» nishoni', () {
    test('bitta safar eng arzonga tushadigan tarifga tushadi', () {
      final plans = [
        plan('Free Trial', 0, 3),
        plan('Plus', 30000, 15), // 2000
        plan('Pro', 60000, 40), // 1500 <- eng arzoni
      ];
      expect(bestValueKey(plans), 'pro');
    });

    /// 🔴 Ilgari cheksiz tarif "0 so'm bir safarga" deb hisoblanardi va
    /// DOIM g'olib chiqardi. Bu yolg'on: cheksiz tarif faqat KO'P
    /// yuradigan odam uchun foydali, oyiga ikki marta yuradiganga u eng
    /// qimmat variant.
    test('CHEKSIZ tarif nishonni tortib olmaydi', () {
      final plans = [
        plan('Pro', 60000, 40), // 1500
        plan('Premium', 100000, -1), // cheksiz
      ];
      expect(bestValueKey(plans), 'pro');
    });

    test('sinov tarifi hisobga olinmaydi', () {
      final plans = [plan('Free Trial', 0, 3), plan('Plus', 30000, 15)];
      expect(bestValueKey(plans), 'plus');
    });

    test('solishtiradigan pullik tarif bo\'lmasa — nishon YO\'Q', () {
      expect(bestValueKey([plan('Free Trial', 0, 3)]), isNull);
      expect(bestValueKey(const []), isNull);
    });
  });

  group('cheksiz tarif qachondan foydali', () {
    test('eng arzon safar narxiga bo\'linadi va YUQORIGA yaxlitlanadi', () {
      final plans = [
        plan('Plus', 30000, 15), // 2000
        plan('Pro', 60000, 40), // 1500 <- eng arzoni
      ];
      final premium = plan('Premium', 100000, -1);

      final r = unlimitedBreakEven([...plans, premium], premium);
      // 100000 / 1500 = 66.67 -> 67-safardan boshlab HAQIQATAN arzon.
      expect(r?.rides, 67);
      expect(r?.planName, 'Pro');
    });

    test('solishtiradigan cheklangan tarif bo\'lmasa — gap aytilmaydi', () {
      final premium = plan('Premium', 100000, -1);
      expect(unlimitedBreakEven([premium], premium), isNull);
    });

    test('cheklangan tarifga qo\'llanmaydi', () {
      final pro = plan('Pro', 60000, 40);
      expect(unlimitedBreakEven([pro], pro), isNull);
    });
  });
}
