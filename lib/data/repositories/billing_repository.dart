import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/billing.dart';

/// Billing — tariflar va obuna.
///
/// Eski `/billing/subscribe`, `/billing/trial`, `/billing/promo` endpointlari
/// YO'Q: hammasi bitta `POST /billing/pay` ichida (promokod ham shu so'rovda).
class BillingRepository {
  BillingRepository(this._client);

  final ApiClient _client;

  Future<List<BillingPlan>> plans() async {
    try {
      final res = await _client.dio.get<dynamic>('/billing/plans');
      return asList(
        unwrap(res.data),
        'plans',
      ).map(BillingPlan.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Obuna yo'qligi XATO emas — 404/bo'sh javob `null` bo'lib qaytadi.
  /// Joriy obuna. Obuna YO'Q bo'lsa `null` — bu xato emas.
  ///
  /// Backend xati (2026-08-14): ilgari obunasi yo'q foydalanuvchiga 404
  /// qaytarilardi, endi **200 + bo'sh tana** keladi. Ikkala shakl ham
  /// qo'llab-quvvatlanadi: eski javob keshda yoki eski gateway'da qolishi
  /// mumkin.
  ///
  /// 🔴 Boshqa xatolar (502, 401, tarmoq) YUTILMAYDI. Ilgari hammasi
  /// `null` ga aylanardi, ya'ni uzilish "sizda tarif yo'q" bo'lib
  /// ko'rinardi — odam ikkinchi marta to'lab yuborishi mumkin edi.
  Future<Subscription?> subscription() async {
    try {
      final res = await _client.dio.get<dynamic>('/billing/subscription');
      final body = asMap(unwrap(res.data));
      if (body == null || body.isEmpty) return null;
      return Subscription.fromJson(body);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.from(e);
    }
  }

  /// Click to'lovdan keyin ilovaga qaytaradigan manzil.
  ///
  /// Manifestда shu sxema ro'yxatga olingan (`AndroidManifest.xml`) va
  /// `deep_links.dart` uni o'qiydi. Backend 14.09.2026 dan `return_url`
  /// ni so'rovdan oladi; standart qiymati ham shu, lekin O'ZIMIZ
  /// aytganimiz ma'qul — backend standarti o'zgarsa ham oqim buzilmaydi.
  static const String returnUrl = 'uz.yolyolakay.mobile://payment/success';

  /// Tarif sotib olish. `planKey` lowercase bo'lishi shart (model shuni beradi).
  Future<PayResult> pay(
    String planKey, {
    String? promoCode,
    String? paymentTokenId,
  }) async {
    try {
      final res = await _client.dio.post<dynamic>(
        '/billing/pay',
        data: {
          'plan_name': planKey.toLowerCase(),
          'promo_code': ?promoCode,
          'payment_token_id': ?paymentTokenId,
          'return_url': returnUrl,
        },
      );
      return PayResult.fromJson(asMap(unwrap(res.data)) ?? const {});
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// BITTA to'lov holati — `GET /billing/transactions/{id}` (14.09.2026).
  ///
  /// 🔑 NEGA KERAK: ilgari to'lov o'tganini bilishning yagona yo'li
  /// obunani qayta-qayta o'qib «o'zgardimi?» deb taxmin qilish edi.
  /// Endi AYNAN shu to'lovni so'raymiz.
  ///
  /// ⚠️ Noma'lum id'da backend 404 emas, **500** qaytaradi (o'lchandi
  /// 14.09.2026) — shuning uchun har qanday xato `null` ga aylanadi va
  /// chaqiruvchi eski yo'lga (obunani o'qish) tushadi.
  Future<PaymentStatus?> transactionStatus(String id) async {
    try {
      final res = await _client.dio.get<dynamic>('/billing/transactions/$id');
      final body = asMap(unwrap(res.data));
      if (body == null || body.isEmpty) return null;
      return PaymentStatus.fromJson(body);
    } on DioException {
      return null;
    }
  }
}
