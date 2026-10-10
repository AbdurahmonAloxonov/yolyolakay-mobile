import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/data/models/billing.dart';

/// Tarif/to'lov kontraktining nozik joylari.
void main() {
  _premiumFiltersTests();
  _planKeyTests();
  _expiryTests();
  _paymentStatusTests();
  group('BillingPlan.planKey', () {
    // Backend `plan_name` ni lowercase kutadi — UPPERCASE'da
    // "invalid plan name" qaytaradi.
    test('ko\'rsatish nomini pay uchun kalitga aylantiradi', () {
      expect(BillingPlan.fromJson(const {'plan_name': 'Plus'}).planKey, 'plus');
      expect(
        BillingPlan.fromJson(const {'plan_name': 'PREMIUM'}).planKey,
        'premium',
      );
    });

    test('"Free Trial" obuna jadvalidagi "trial" ga xaritalanadi', () {
      final plan = BillingPlan.fromJson(const {'plan_name': 'Free Trial'});
      expect(plan.planKey, 'trial');
      expect(plan.isTrial, isTrue);
    });
  });

  group('BillingPlan.fromJson', () {
    test('jonli javob shaklini o\'qiydi', () {
      final plan = BillingPlan.fromJson(const {
        'plan_name': 'Pro',
        'price': 100000,
        'rides_quota': -1,
        'free_parcels_quota': 5,
        'currency': 'UZS',
        'features': ['Cheksiz safar', 'Ustuvor qo\'llab-quvvatlash'],
      });

      expect(plan.price, 100000);
      expect(plan.isUnlimited, isTrue, reason: '-1 = cheksiz');
      expect(plan.parcelsQuota, 5);
      expect(plan.features, hasLength(2));
    });

    test('maydonlar yetishmasa yiqilmaydi', () {
      final plan = BillingPlan.fromJson(const {'plan_name': 'Plus'});
      expect(plan.price, 0);
      expect(plan.features, isEmpty);
      expect(plan.isUnlimited, isFalse);
    });
  });

  group('PayResult', () {
    // ⚠ Mock rejimda backend to'lovni O'ZI o'tkazadi va mavjud bo'lmagan
    // domenga URL beradi — unga yo'naltirilsa foydalanuvchi bo'sh sahifada
    // qoladi. Shuning uchun brauzer OCHILMASLIGI kerak.
    test('mock.click.uz URL — brauzer ochilmaydi', () {
      final result = PayResult.fromJson(const {
        'message': 'payment initiated',
        'payment_url': 'https://mock.click.uz/checkout/123',
      });
      expect(result.isMock, isTrue);
      expect(result.canOpen, isFalse);
    });

    test('xabarda "mock" bo\'lsa ham test rejimi deb qaraladi', () {
      final result = PayResult.fromJson(const {
        'message': 'Payment automatically processed in mock mode',
      });
      expect(result.isMock, isTrue);
      expect(result.canOpen, isFalse);
    });

    test('haqiqiy provayder URL\'i ochiladi', () {
      final result = PayResult.fromJson(const {
        'message': 'payment initiated',
        'payment_url': 'https://my.click.uz/services/pay?id=42',
      });
      expect(result.isMock, isFalse);
      expect(result.canOpen, isTrue);
    });

    test('eski checkout_url nomi ham qabul qilinadi', () {
      final result = PayResult.fromJson(const {
        'checkout_url': 'https://my.click.uz/pay',
      });
      expect(result.url, 'https://my.click.uz/pay');
    });

    test('URL umuman bo\'lmasa ochilmaydi', () {
      final result = PayResult.fromJson(const {
        'message': 'subscription updated',
      });
      expect(result.canOpen, isFalse);
      expect(result.isMock, isFalse);
    });
  });

  group('Subscription', () {
    test('cheksiz paketni tanaydi', () {
      final subscription = Subscription.fromJson(const {
        'plan_name': 'Pro',
        'status': 'active',
        'rides_left': -1,
      });
      expect(
        subscription.planName,
        'pro',
        reason: 'taqqoslash uchun lowercase',
      );
      expect(subscription.isActive, isTrue);
      expect(subscription.isUnlimited, isTrue);
    });

    test('trial ishlatilganini eslab qoladi', () {
      final subscription = Subscription.fromJson(const {
        'plan_name': 'trial',
        'status': 'expired',
        'has_used_trial': true,
      });
      expect(subscription.hasUsedTrial, isTrue);
      expect(subscription.isActive, isFalse);
    });
  });
}

/// Tarif bo'yicha premium filtrlar (backend xati 2026-08-12).
///
/// Backend `POST /rides/{id}/activate` da Plus tarifida konditsioner,
/// chekilmaydi, orqada maks 2 va haydash uslubini rad etadi (400). Klient
/// buni oldindan bilishi kerak, aks holda haydovchi formani to'ldirib,
/// e'lon qilishda xato oladi.
void _premiumFiltersTests() {
  Subscription sub(String plan) =>
      Subscription(planName: plan, status: 'active');

  group('Subscription.hasPremiumFilters', () {
    test('Plus — YO\'Q', () {
      expect(sub('plus').hasPremiumFilters, isFalse);
      expect(sub('PLUS').hasPremiumFilters, isFalse, reason: 'katta harf ham');
    });

    test('Pro va Premium — bor', () {
      expect(sub('pro').hasPremiumFilters, isTrue);
      expect(sub('premium').hasPremiumFilters, isTrue);
    });

    /// ✅ 2026-08-13 backend javob berdi: filtrlar FAQAT Pro va Premium'da.
    /// Ilgari bu yerda "trial cheklanmaydi" deb yozilgandi — javob kelguncha
    /// qilingan ehtiyotkor taxmin edi va u NOTO'G'RI bo'lib chiqdi.
    test('trial — YO\'Q', () {
      expect(sub('trial').hasPremiumFilters, isFalse);
      expect(sub('free_trial').hasPremiumFilters, isFalse);
    });

    /// Muddati tugagan Pro tirik Pro'dek ko'rinmasligi kerak. Backend endi
    /// 404 o'rniga obunani `status: expired` bilan qaytaradi (xat 2026-08-13).
    test('muddati tugagan Pro — YO\'Q', () {
      expect(
        const Subscription(
          planName: 'pro',
          status: 'expired',
        ).hasPremiumFilters,
        isFalse,
      );
    });
  });
}

/// 🔴 Egasi qurilmada topdi (2026-08-13): sotib olingan tarifda "Faol tarif"
/// nishoni chiqmasdi — ikki endpoint tarif nomini boshqacha yozadi.
void _planKeyTests() {
  group('tarif nomi ikki manbada mos keladi', () {
    test('"Free Trial" va "free_trial" — BIR XIL kalit', () {
      final plan = BillingPlan.fromJson(const {'plan_name': 'Free Trial'});
      final subscription = Subscription.fromJson(const {
        'plan_name': 'free_trial',
        'status': 'active',
      });
      expect(plan.planKey, 'trial');
      expect(subscription.planKey, 'trial');
      expect(
        subscription.planKey,
        plan.planKey,
        reason: 'aks holda sinov tarifida nishon HECH QACHON chiqmaydi',
      );
    });

    test('pullik tariflar ham mos keladi', () {
      for (final pair in const [
        ('Pro', 'pro'),
        ('Premium', 'PREMIUM'),
        ('Plus', ' plus '),
      ]) {
        final plan = BillingPlan.fromJson({'plan_name': pair.$1});
        final subscription = Subscription.fromJson({
          'plan_name': pair.$2,
          'status': 'active',
        });
        expect(subscription.planKey, plan.planKey, reason: pair.$1);
      }
    });
  });
}

/// Qurilmada topilgan ikki xato (2026-08-13).
void _expiryTests() {
  group('muddati o\'tgan obuna', () {
    test('sana o\'tgan bo\'lsa FAOL emas — status "active" bo\'lsa ham', () {
      // Telefonda aynan shunday edi: "Faol · Amal qiladi: 9 avgust",
      // o'sha kuni esa 13 avgust edi.
      final subscription = Subscription.fromJson({
        'plan_name': 'pro',
        'status': 'active',
        'end_date': DateTime.now()
            .subtract(const Duration(days: 4))
            .toIso8601String(),
      });
      expect(subscription.isExpired, isTrue);
      expect(subscription.isActive, isFalse);
      expect(
        subscription.hasPremiumFilters,
        isFalse,
        reason: 'tugagan tarifda premium belgilar ochiq qolmasin',
      );
    });

    test('sanasi kelajakda — faol', () {
      final subscription = Subscription.fromJson({
        'plan_name': 'pro',
        'status': 'active',
        'end_date': DateTime.now()
            .add(const Duration(days: 10))
            .toIso8601String(),
      });
      expect(subscription.isActive, isTrue);
      expect(subscription.hasPremiumFilters, isTrue);
    });
  });

  test('sinov tarifi qanday yozilishidan qat\'i nazar tanaladi', () {
    // Backend jonli uch xil yozadi — uchalasi ham bitta kalitga tushsin.
    for (final raw in const ['Free Trial', 'free_trial', 'Trial ride']) {
      expect(
        Subscription.fromJson({'plan_name': raw, 'status': 'active'}).planKey,
        'trial',
        reason: raw,
      );
    }
  });
}


/// TO'LOV NATIJASI — «hali ma'lum emas» ni «o'tdi» deb o'qimasin.
///
/// 🔴 NEGA QO'RIQLANADI (14.09.2026): ilgari to'lovdan keyin ilova ham,
/// sayt ham bir necha soniya kutib HAR DOIM «to'lov qabul qilindi» derdi.
/// Karta rad etilgan odam ham yashil belgi ko'rardi. Endi javob
/// `GET /billing/transactions/{id}` dan keladi va uchta holat ANIQ
/// ajratiladi: o'tdi / o'tmadi / hali noma'lum.
void _paymentStatusTests() {
  group('PaymentStatus', () {
    test('pending YAKUNIY emas — kutishda davom etamiz', () {
      final s = PaymentStatus.fromJson(const {'status': 'pending'});
      expect(s.isFinal, isFalse);
      expect(s.isPaid, isFalse);
      expect(s.isFailed, isFalse);
    });

    test('success — to\'landi', () {
      final s = PaymentStatus.fromJson(const {
        'status': 'success',
        'amount': 5000,
        'currency': 'UZS',
        'plan': 'plus',
      });
      expect(s.isPaid, isTrue);
      expect(s.isFinal, isTrue);
      expect(s.amount, 5000);
      expect(s.plan, 'plus');
    });

    test('failed va cancelled — ikkalasi ham RAD ETILGAN', () {
      for (final v in ['failed', 'cancelled', 'canceled', 'declined']) {
        final s = PaymentStatus.fromJson({'status': v});
        expect(s.isFailed, isTrue, reason: v);
        expect(s.isPaid, isFalse, reason: v);
      }
    });

    test('KATTA harf ham tushuniladi', () {
      expect(PaymentStatus.fromJson(const {'status': 'SUCCESS'}).isPaid, isTrue);
    });

    test('notanish holat — YAKUNIY EMAS (xushxabar aytilmaydi)', () {
      // Backend yangi holat qo'shsa, biz uni "to'landi" deb o'qimaymiz:
      // bilmaganni bilgandek ko'rsatish eng qimmat xato.
      final s = PaymentStatus.fromJson(const {'status': 'on_hold'});
      expect(s.isPaid, isFalse);
      expect(s.isFinal, isFalse);
    });
  });

  group('PayResult', () {
    test('transaction_id o\'qiladi', () {
      final r = PayResult.fromJson(const {
        'message': 'payment initiated',
        'payment_url': 'https://my.click.uz/services/pay?x=1',
        'transaction_id': 'c9a4b882-749e-4b71-9f93-167812938123',
      });
      expect(r.transactionId, 'c9a4b882-749e-4b71-9f93-167812938123');
      expect(r.canOpen, isTrue);
    });

    test('id kelmasa null — eski oqim buzilmaydi', () {
      final r = PayResult.fromJson(const {
        'payment_url': 'https://my.click.uz/services/pay?x=1',
      });
      expect(r.transactionId, isNull);
      expect(r.canOpen, isTrue);
    });
  });
}
