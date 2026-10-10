import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/device.dart';
import '../../core/env.dart';
import '../models/support.dart';

/// Qo'llab-quvvatlash — `POST /helpdesk/tickets`.
///
/// Backend bu bo'limni ancha oldin qurgan, lekin bizga aytmagan: endpoint
/// swagger sverkasida topildi (2026-08-16). Tavsifi: «жалоба, ДТП,
/// забытые вещи».
///
/// ✅ 2026-08-16 KECHQURUN: backend operator javobi maydonini QO'SHDI
/// (`resolve` ga `resolution`) va ro'yxat sxemasini yozdi — biz so'ragan
/// edik (xat `BACKEND_XAT_2026-08-16d`). Ya'ni javob endi ILOVA ICHIDA
/// ko'rinadi va "javob Telegram orqali keladi" degan vaqtinchalik yozuv
/// keraksiz bo'ldi.
///
/// Telegram havolasi baribir QOLADI: yo'lda hodisa bo'lganda odam forma
/// to'ldirmaydi, tirik odamga yozadi.
class SupportRepository {
  SupportRepository(this._client);

  final ApiClient _client;

  /// Murojaat yuborish.
  ///
  /// [context] — ilova o'zi qo'shadigan texnik ma'lumot (versiya, platforma,
  /// qurilma ID). U matnga QO'SHIB yuboriladi, chunki backend sxemasida
  /// faqat `subject` va `description` bor.
  ///
  /// NEGA KERAK: hozir odam Telegramga yozganda operator "qaysi versiya,
  /// qanaqa telefon?" deb so'rashi kerak va odatda javob ololmaydi.
  /// Ilova buni o'zi biladi — so'ramaslik kerak.
  Future<void> createTicket({
    required String subject,
    required String description,
  }) async {
    try {
      await _client.dio.post<dynamic>(
        '/helpdesk/tickets',
        data: {
          'subject': subject,
          'description': '$description\n\n${await _technicalContext()}',
        },
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Mening murojaatlarim — `GET /helpdesk/tickets`.
  ///
  /// ✅ 2026-08-16 kechqurun ULANDI: backend sxemani yozdi va `resolution`
  /// (operator javobi) maydonini qo'shdi. Ungacha ro'yxat shakli noma'lum
  /// edi va ekranni ko'r-ko'rona chizish aniq xatoga olib borardi.
  ///
  /// ⚠️ `?user_id=` YUBORILMAYDI — backend uni olib tashladi, ro'yxat
  /// tokendan aniqlanadi (birovning murojaatini o'qib bo'lmaydi).
  Future<List<SupportTicket>> tickets() async {
    try {
      final res = await _client.dio.get<dynamic>('/helpdesk/tickets');
      return asList(
        unwrap(res.data),
        'tickets',
      ).map(SupportTicket.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Operator uchun texnik ma'lumot — matn oxiriga qo'shiladi.
  ///
  /// Qurilma ID kiritilgan: aynan shu qiymat push tokeni va sessiyalar
  /// bilan bog'langan, ya'ni operator foydalanuvchini topa oladi.
  Future<String> _technicalContext() async {
    final deviceId = await DeviceInfo.id();
    return [
      '--- texnik ma\'lumot ---',
      'Ilova: ${Env.appVersion} (${DeviceInfo.osType})',
      'Qurilma: $deviceId',
    ].join('\n');
  }
}
