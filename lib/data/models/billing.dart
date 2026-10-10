import '../../core/json.dart';

/// Tarif nomini SOLISHTIRISH uchun yagona ko'rinishga keltiradi.
///
/// Backend bitta tarifni ikki xil yozadi: `GET /billing/plans` da "Free Trial",
/// `GET /billing/subscription` da esa "free_trial". Bo'shliq, pastki chiziq va
/// registr olib tashlanadi, "freetrial" esa "trial" ga xaritalanadi — obuna
/// jadvalida u shu nom bilan yuritiladi.
String normalizePlanName(String raw) {
  final normalized = raw.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
  // Sinov tarifini backend KAMIDA uch xil yozadi (jonli ko'rilgan):
  // "Free Trial", "free_trial" va "Trial ride". Aniq ro'yxat tuzish o'rniga
  // "trial" bilan boshlanishini tekshiramiz — to'rtinchi variant chiqsa ham
  // o'zi to'g'ri tushadi.
  return normalized.startsWith('trial') || normalized == 'freetrial'
      ? 'trial'
      : normalized;
}

/// Shu tarifda «premium filtrlar» bormi — TARIF KALITI bo'yicha.
///
/// Obunadan alohida turadi, chunki tariflar ro'yxatida ham kerak: odam
/// qimmatroq tarifni NEGA olishini ko'rishi kerak (egasi: "tariflar to'liq
/// yozilmagan", 2026-08-13).
///
/// ✅ Ro'yxat backend xatidan (2026-08-13): filtrlar FAQAT `pro` va `premium`
/// da ochiq.
bool planHasPremiumFilters(String planKey) =>
    const {'pro', 'premium'}.contains(planKey);

/// `GET /billing/plans` elementi.
///
/// Narxlar FAQAT shu endpointdan olinadi — web'da hardcode setka noto'g'ri
/// qiymatlar bilan yashab qolgan edi (premium 200k, pro 150 safar) va o'chirildi.
/// Shu xato mobil tomonda takrorlanmasin: hech qayerda qattiq narx yozilmaydi.
class BillingPlan {
  const BillingPlan({
    required this.name,
    required this.price,
    required this.ridesQuota,
    this.parcelsQuota = 0,
    this.currency,
    this.features = const [],
    this.targetRole,
  });

  /// Backend bergan ko'rsatish nomi: `Free Trial` | `Plus` | `Pro` | `Premium`.
  final String name;
  final double price;

  /// Oylik safar paketi, `-1` = cheksiz.
  final int ridesQuota;
  final int parcelsQuota;
  final String? currency;
  final List<String> features;

  /// `driver` | `passenger` — backend bergan rol belgisi.
  ///
  /// 🔴 NEGA KERAK BO'LDI (2026-09-03): backend `GET /billing/plans`
  /// ga TO'RTTA YO'LOVCHI TARIFI qo'shdi — «Passenger Trial / Plus /
  /// Pro / Premium», 1 000–5 000 so'mdan. Ya'ni yo'lovchidan bron
  /// uchun pul olish taklif qilingan.
  ///
  /// Bizning modelimizda YO'LOVCHI PUL TO'LAMAYDI: to'lov haydovchi
  /// tomonda (safar paketi). Egasi ham shuni tasdiqladi: «oldingi
  /// tariflarimiz Plus, Pro, Premium yaxshi edi, yana 4 ta
  /// qo'shilibdi — olib tashla, kerakmas».
  ///
  /// Backend ularni qaytarishda davom etsa ham, mijoz ko'rsatmaydi.
  final String? targetRole;

  /// Bu tarif YO'LOVCHIGA sotilyaptimi.
  ///
  /// ⚠️ Faqat ANIQ `passenger` bo'lganda rost. Maydon yo'q yoki bo'sh
  /// bo'lsa tarif KO'RSATILADI: backend maydonni olib tashlasa,
  /// hamma tarif yo'qolib ekran bo'sh qolgani — xatoning eng yomon
  /// turi bo'lardi (odam to'lov yo'lini umuman topmaydi).
  bool get isForPassenger => targetRole?.trim().toLowerCase() == 'passenger';

  /// `POST /billing/pay` ga ketadigan qiymat.
  ///
  /// ⚠ MAJBURIY lowercase — UPPERCASE'da backend `invalid plan name` beradi.
  /// "Free Trial" obuna jadvalida `trial` nomi bilan yuritiladi.
  String get planKey => normalizePlanName(name);

  bool get isTrial => planKey == 'trial';
  bool get isUnlimited => ridesQuota < 0;

  factory BillingPlan.fromJson(Map<String, dynamic> json) => BillingPlan(
    name: asString(json['plan_name']),
    price: asDouble(json['price']),
    ridesQuota: asInt(json['rides_quota']),
    parcelsQuota: asInt(json['free_parcels_quota']),
    currency: asStringOrNull(json['currency']),
    targetRole: asStringOrNull(json['target_role']),
    features:
        (json['features'] as List?)
            ?.map(asString)
            .where((f) => f.isNotEmpty)
            .toList() ??
        const [],
  );
}

/// `GET /billing/subscription` — obuna yo'q bo'lsa 404/bo'sh keladi (null).
class Subscription {
  const Subscription({
    required this.planName,
    this.rawPlanKey,
    required this.status,
    this.ridesLeft,
    this.parcelsLeft,
    this.hasUsedTrial = false,
    this.endDate,
  });

  /// lowercase: `free_trial` | `trial` | `plus` | `pro` | `premium`.
  final String planName;

  /// Tarif jadvali bilan SOLISHTIRISH uchun yagona ko'rinish.
  ///
  /// 🔴 Egasi qurilmada topdi (2026-08-13): sotib olingan tarifda "Faol tarif"
  /// nishoni CHIQMASDI. Sabab — ikki manba nomni boshqacha yozadi:
  ///   `GET /billing/subscription` -> plan_name: "free_trial"
  ///   `GET /billing/plans`        -> plan_name: "Free Trial"  (planKey: "trial")
  /// Ularni to'g'ridan solishtirsak sinov tarifi HECH QACHON mos kelmasdi.
  /// Saytda ayni funksiya bor (`normalizePlanName`), ilovada esa yo'q edi.
  /// Backend bergan MASHINA kaliti (`plan_key`) — bo'lsa o'shani
  /// ishlatamiz, aks holda nomdan hisoblaymiz.
  ///
  /// Backend xati (2026-08-14): «Унифицируем: plan_key ("trial", "plus",
  /// "pro", "premium") отдельно от отображаемого имени plan_name».
  /// Kalit kelgan kuni normallashtirish o'z-o'zidan chetga chiqadi, lekin
  /// biz uni OLIB TASHLAMAYMIZ: eski javoblar va sayt keshida hamon eski
  /// shakl bo'lishi mumkin.
  final String? rawPlanKey;

  String get planKey => (rawPlanKey != null && rawPlanKey!.trim().isNotEmpty)
      ? normalizePlanName(rawPlanKey!)
      : normalizePlanName(planName);

  /// `active` | `past_due` | `canceled` | `expired`
  final String status;

  /// `-1` = cheksiz (paket chegarasi yo'q).
  final int? ridesLeft;
  final int? parcelsLeft;
  final bool hasUsedTrial;
  final DateTime? endDate;

  bool get isActive => status == 'active' && !isExpired;

  /// Muddati tugagan obuna.
  ///
  /// 🔴 2026-08-13, backend xati: ilgari muddati o'tgan obunaga `GET
  /// /billing/subscription` 404 qaytarardi va biz uni "obuna yo'q" deb
  /// o'qirdik. Endi backend obunani QAYTARADI, faqat `status` ni `expired`
  /// qilib. Statusga qaramasak, muddati tugagan Pro tirik Pro'dek ko'rinadi.
  ///
  /// 🔴 Egasi qurilmada topdi (2026-08-13): shu kunning O'ZIDA obuna
  /// "Faol · Amal qiladi: 9 avgust" deb turardi — ya'ni to'rt kun oldin
  /// tugagan tarif tirik ko'rinardi. Demak `status` ga TAYANIB bo'lmaydi:
  /// backend uni har doim ham yangilamaydi. Sana o'tgan bo'lsa — tugagan,
  /// status nima deyishidan qat'i nazar.
  bool get isExpired {
    if (status == 'expired') return true;
    final end = endDate;
    return end != null && end.isBefore(DateTime.now());
  }

  /// «Premium filtrlar» (konditsioner, chekilmaydi, orqada maks 2, haydash
  /// uslubi) shu tarifda mavjudmi.
  ///
  /// Backend `POST /rides/{id}/activate` da tekshiradi. Bu ko'rinish bezagi
  /// emas — bloklamasak haydovchi formani to'ldirib, e'lon qilishda 400 oladi.
  ///
  /// ✅ 2026-08-13, backend xati JAVOB BERDI: filtrlar FAQAT `pro` va
  /// `premium` da ochiq; `trial` da ham, obunasiz ham backend o'tkazmaydi.
  /// Shuning uchun qoida endi «rad etish ro'yxati» emas, RUXSAT RO'YXATI:
  /// ilgari `plus` dan boshqa hamma narsa ochiq deb hisoblanardi va sinov
  /// tarifidagi haydovchi belgilarni yoqib, e'lon qilishda xato olardi.
  bool get hasPremiumFilters => !isExpired && planHasPremiumFilters(planKey);

  /// ⚠ ESKIRGAN: manfiy hisoblagichni "cheksiz" deb o'qish NOTO'G'RI.
  ///
  /// Backend cheklangan tarifda ham `rides_left: -1` yuborishi mumkin (jonli
  /// kuzatilgan 2026-08-04): natijada Plus sotib olgan odam "Cheksiz" ko'rardi,
  /// profilda esa "-1" turardi. Cheksizlik — TARIF kvotasining xususiyati
  /// (`BillingPlan.isUnlimited`), hisoblagichniki emas.
  ///
  /// Ko'rsatish uchun `ridesLeftLabel()` ishlating.
  @Deprecated('Cheksizlikni BillingPlan.isUnlimited bo\'yicha aniqlang')
  bool get isUnlimited => (ridesLeft ?? 0) < 0;

  /// Hech qachon manfiy bo'lmaydigan balans (ko'rsatish uchun).
  int get ridesLeftSafe {
    final v = ridesLeft ?? 0;
    return v < 0 ? 0 : v;
  }

  /// Balans yozuvi: cheksizlik FAQAT tarif kvotasidan aniqlanadi.
  /// [plans] — `billingPlansProvider` ro'yxati (bo'sh bo'lsa raqam ko'rsatiladi).
  String ridesLeftLabel(List<BillingPlan> plans, String unlimitedLabel) {
    // `planKey` — obuna jadvalidagi nom bilan bir xil ko'rinishga keltirilgan
    // qiymat ("Free Trial" -> "trial"), shuning uchun solishtirish shu bo'yicha.
    for (final plan in plans) {
      if (plan.planKey == planKey && plan.isUnlimited) return unlimitedLabel;
    }
    return '$ridesLeftSafe';
  }

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    planName: asString(json['plan_name']).toLowerCase(),
    rawPlanKey: asStringOrNull(json['plan_key']),
    status: asString(json['status']),
    ridesLeft: json['rides_left'] == null ? null : asInt(json['rides_left']),
    parcelsLeft: json['free_parcels_quota'] == null
        ? null
        : asInt(json['free_parcels_quota']),
    hasUsedTrial: asBool(json['has_used_trial']),
    endDate: asDate(json['end_date']),
  );
}

/// `POST /billing/pay` javobi.
///
/// Jonli (2026-07-18): `{message: "payment initiated", payment_url: "https://mock.click.uz/..."}`.
/// Eski `checkout_url` nomi zaxira sifatida qoldirilgan.
class PayResult {
  const PayResult({this.url, this.message, this.transactionId});

  final String? url;
  final String? message;

  /// To'lov identifikatori (14.09.2026) — `GET /billing/transactions/{id}`
  /// bilan AYNAN shu to'lov holatini so'rash uchun.
  final String? transactionId;

  /// Mock rejim — backend to'lovni O'ZI o'tkazadi, URL esa mavjud bo'lmagan
  /// domenga ko'rsatadi. Bunga yo'naltirilsa foydalanuvchi bo'sh sahifada
  /// qoladi, shuning uchun brauzer OCHILMAYDI, muvaffaqiyat xabari beriladi.
  bool get isMock {
    final target = '${message ?? ''} ${url ?? ''}';
    return RegExp(r'mock', caseSensitive: false).hasMatch(target);
  }

  bool get canOpen => !isMock && (url?.startsWith('http') ?? false);

  factory PayResult.fromJson(Map<String, dynamic> json) => PayResult(
    url:
        asStringOrNull(json['payment_url']) ??
        asStringOrNull(json['checkout_url']),
    message: asStringOrNull(json['message']),
    transactionId: asStringOrNull(json['transaction_id']),
  );
}

/// `GET /billing/transactions/{id}` javobi (14.09.2026).
///
/// 🔑 NEGA BU MODEL BOR: ilgari to'lov natijasini bilishning yagona
/// yo'li obunani qayta o'qib «o'zgardimi?» deb TAXMIN qilish edi.
/// Click qaytargan `success` ham pul o'tganini bildirmaydi — u faqat
/// «brauzer shu manzilga keldi» degani. Haqiqiy javob shu yerda.
class PaymentStatus {
  const PaymentStatus({
    required this.status,
    this.transactionId,
    this.amount,
    this.currency,
    this.plan,
  });

  /// `pending` | `success` | `failed` | `cancelled`.
  final String status;
  final String? transactionId;
  final double? amount;
  final String? currency;
  final String? plan;

  String get _s => status.toLowerCase();

  /// YAKUNIY holatmi — so'rashni to'xtatsa bo'ladimi.
  bool get isFinal => isPaid || isFailed;
  bool get isPaid =>
      const {'success', 'succeeded', 'paid', 'completed'}.contains(_s);
  bool get isFailed => const {
    'failed',
    'cancelled',
    'canceled',
    'error',
    'declined',
  }.contains(_s);

  factory PaymentStatus.fromJson(Map<String, dynamic> json) => PaymentStatus(
    status: asString(json['status']),
    transactionId: asStringOrNull(json['transaction_id']),
    amount: json['amount'] == null ? null : asDouble(json['amount']),
    currency: asStringOrNull(json['currency']),
    plan: asStringOrNull(json['plan']),
  );
}
