import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/trust.dart';
import 'package:yolyolakay/data/models/user.dart';

/// ISHONCH NARVONI — `core/trust.dart` dagi ikki qat'iy qoida shu yerda
/// qulflanadi:
///   1. ma'lumot yo'qligi QIZIL BELGI EMAS — bosqich umuman ko'rsatilmaydi;
///   2. reyting YOLG'IZ ishonch bermaydi — bitta besh ballik baho ham
///      «5.0» bo'lib ko'rinadi.
void main() {
  User user({
    double? rating,
    int? ratingCount,
    DateTime? createdAt,
    String role = 'passenger',
  }) => User(
    id: 'u-1',
    phoneNumber: '+998900000000',
    firstName: 'Test',
    role: role,
    rating: rating,
    ratingCount: ratingCount,
    createdAt: createdAt,
  );

  test('telefon HAR DOIM bajarilgan — hisob OTP siz yaratilmaydi', () {
    final summary = computeTrust(user());
    expect(summary.shown, contains(TrustStep.phone));
    expect(summary.done, contains(TrustStep.phone));
  });

  test('ma\'lumot yo\'q bosqich KO\'RSATILMAYDI (yiqilgan deb emas)', () {
    final summary = computeTrust(user());
    expect(summary.shown, isNot(contains(TrustStep.tenure)));
    expect(summary.shown, isNot(contains(TrustStep.reviews)));
    expect(summary.shown, isNot(contains(TrustStep.rating)));
    expect(summary.total, 1, reason: 'faqat telefon ma\'lum');
  });

  test('yangi hisob — bosqich ko\'rinadi, lekin bajarilmagan', () {
    final summary = computeTrust(
      user(createdAt: DateTime.now().subtract(const Duration(days: 3))),
    );
    expect(summary.shown, contains(TrustStep.tenure));
    expect(summary.done, isNot(contains(TrustStep.tenure)));
  });

  test('eski hisob — bajarilgan', () {
    final summary = computeTrust(
      user(createdAt: DateTime.now().subtract(const Duration(days: 90))),
    );
    expect(summary.done, contains(TrustStep.tenure));
  });

  /// 🔴 ENG MUHIM: bitta besh ballik baho reyting bosqichini OCHMASIN.
  test('bitta baho bilan reyting bosqichi umuman ko\'rinmaydi', () {
    final summary = computeTrust(user(rating: 5, ratingCount: 1));
    expect(summary.shown, isNot(contains(TrustStep.rating)));
  });

  test('yetarli baho bo\'lsa reyting hisobga olinadi', () {
    final good = computeTrust(user(rating: 4.8, ratingCount: 12));
    expect(good.shown, contains(TrustStep.rating));
    expect(good.done, contains(TrustStep.rating));
    expect(good.done, contains(TrustStep.reviews));

    final weak = computeTrust(user(rating: 3.9, ratingCount: 12));
    expect(weak.shown, contains(TrustStep.rating));
    expect(weak.done, isNot(contains(TrustStep.rating)));
  });

  test('mashina bosqichi FAQAT ma\'lumot berilganda', () {
    final unknown = computeTrust(user(role: 'driver'));
    expect(
      unknown.shown,
      isNot(contains(TrustStep.car)),
      reason: '`/users/{id}` mashinalarni qaytarmaydi — bilmaymiz',
    );

    final approved = computeTrust(
      user(role: 'driver'),
      cars: [
        Car(
          id: 'c-1',
          brand: 'Chevrolet',
          model: 'Cobalt',
          govNumber: '01A111AA',
          moderationStatus: 'approved',
        ),
      ],
    );
    expect(approved.done, contains(TrustStep.car));

    final pending = computeTrust(
      user(role: 'driver'),
      cars: [
        Car(
          id: 'c-1',
          brand: 'Chevrolet',
          model: 'Cobalt',
          govNumber: '01A111AA',
          moderationStatus: 'pending',
        ),
      ],
    );
    expect(pending.shown, contains(TrustStep.car));
    expect(pending.done, isNot(contains(TrustStep.car)));
  });

  test('yo\'lovchida mashina bosqichi yo\'q', () {
    final summary = computeTrust(user(), cars: const []);
    expect(summary.shown, isNot(contains(TrustStep.car)));
  });
}
