/// ISHONCH NARVONI — «bu odamga ishonsam bo'ladimi?» degan savolga
/// BITTA javob.
///
/// 🔴 NEGA YOZILDI (egasi tanlagan band, 2026-08-25): ishonch dalillari
/// ilovaga TARQOQ holda sochilgan edi — reyting bir joyda, baholar soni
/// boshqa joyda, hisob yoshi uchinchi qatorda, mashina tasdig'i esa
/// umuman boshqa ekranda. Odam ularni o'zi yig'ib xulosa chiqarishi
/// kerak edi va amalda hech kim buni qilmaydi: u faqat reytingga qaraydi,
/// reyting esa BITTA baho bilan ham «5.0» bo'lib turadi.
///
/// ═══ IKKI QAT'IY QOIDA ═══
///
///  1. **Ma'lumot yo'qligi — QIZIL BELGI EMAS.** Backend `created_at` yoki
///     `rating_count` yubormasa, o'sha bosqich UMUMAN ko'rsatilmaydi.
///     Uni «bajarilmagan» deb chizish odamni asossiz ayblash bo'lardi —
///     va bu bizning ma'lumotimiz yo'qligidan kelib chiqadi, uning
///     aybidan emas.
///
///  2. **Reyting YOLG'IZ ishonch bermaydi.** Bitta besh ballik baho ham
///     «5.0» bo'lib ko'rinadi. Shuning uchun [TrustStep.rating] faqat
///     yetarlicha baho bo'lgandagina hisobga olinadi.
library;

import '../data/models/user.dart';

/// Ishonch bosqichlari — og'irligi bo'yicha EMAS, ishonch qurilish
/// tartibida: telefon → vaqt → odamlar fikri → mashina.
enum TrustStep {
  /// Telefon OTP bilan tasdiqlangan.
  ///
  /// HAR DOIM bajarilgan: hisob faqat SMS kodidan keyin yaratiladi, ya'ni
  /// tasdiqlanmagan telefonli foydalanuvchi umuman mavjud emas.
  phone,

  /// Hisob yetarlicha eski.
  tenure,

  /// Yetarlicha odam baho bergan.
  reviews,

  /// Baho yuqori.
  rating,

  /// Mashina moderatsiyadan o'tgan (faqat haydovchida).
  car,
}

/// Hisob shuncha kundan eski bo'lsa — «yangi hisob» emas.
///
/// 30 kun ATAYIN: firibgar hisob odatda tez ochilib tez tashlanadi, halol
/// foydalanuvchi esa oyiga bir-ikki marta yo'lga chiqadi.
const _tenureDays = 30;

/// Reyting ishonchli bo'lishi uchun kerakli eng kam baho soni.
const _ratingNeedsReviews = 3;

/// «Yetarlicha odam baho bergan» chegarasi.
const _reviewsEnough = 5;

/// Yuqori reyting chegarasi.
const _goodRating = 4.5;

class TrustSummary {
  const TrustSummary({required this.done, required this.shown});

  /// Bajarilgan bosqichlar.
  final Set<TrustStep> done;

  /// EKRANDA ko'rsatiladigan bosqichlar (ma'lumoti bor bo'lganlari).
  final List<TrustStep> shown;

  int get earned => shown.where(done.contains).length;
  int get total => shown.length;

  /// Hammasi bajarilganmi — kartada bitta «ishonchli» belgisi uchun.
  bool get isComplete => total > 0 && earned == total;
}

/// [user] uchun ishonch xulosasi.
///
/// [cars] — FAQAT o'z profilida ma'lum (`/users/{id}` mashinalarni
/// qaytarmaydi). Berilmasa mashina bosqichi umuman ko'rsatilmaydi:
/// «mashina tasdiqlanmagan» deb yozish yolg'on bo'lardi, biz shunchaki
/// bilmaymiz.
TrustSummary computeTrust(User user, {List<Car>? cars}) {
  final shown = <TrustStep>[TrustStep.phone];
  final done = <TrustStep>{TrustStep.phone};

  final createdAt = user.createdAt;
  if (createdAt != null) {
    shown.add(TrustStep.tenure);
    if (DateTime.now().difference(createdAt).inDays >= _tenureDays) {
      done.add(TrustStep.tenure);
    }
  }

  final count = user.ratingCount;
  if (count != null) {
    shown.add(TrustStep.reviews);
    if (count >= _reviewsEnough) done.add(TrustStep.reviews);
  }

  final rating = user.rating;
  // Reyting bosqichi FAQAT baho soni ma'lum va yetarli bo'lganda ko'rinadi.
  if (rating != null && rating > 0 && (count ?? 0) >= _ratingNeedsReviews) {
    shown.add(TrustStep.rating);
    if (rating >= _goodRating) done.add(TrustStep.rating);
  }

  if (cars != null && user.isDriver) {
    shown.add(TrustStep.car);
    final approved = cars.any(
      (c) => (c.moderationStatus ?? '').toLowerCase() == 'approved',
    );
    if (approved) done.add(TrustStep.car);
  }

  return TrustSummary(done: done, shown: shown);
}
