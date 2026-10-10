import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/local_cache.dart';
import '../models/chat.dart';

/// Bildirishnomalar va chat tarixi — ikkalasi ham bitta servisda.
///
/// Xabar YUBORISH bu yerda YO'Q: REST endpointi mavjud emas, faqat WS
/// (`core/api/ws_client.dart`).
class NotificationsRepository {
  NotificationsRepository(this._client, [this._cache]);

  final ApiClient _client;

  /// Offline kesh (izohi `core/local_cache.dart` da). `null` — keshsiz.
  final LocalCache? _cache;

  Future<List<NotificationItem>> list() async {
    try {
      final res = await _client.dio.get<dynamic>('/notifications');
      return asList(
        unwrap(res.data),
        'notifications',
      ).map(NotificationItem.fromJson).toList();
    } on DioException catch (e) {
      // "Bildirishnoma yo'q" va "yuklab bo'lmadi" — boshqa-boshqa gap.
      throw ApiException.from(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _client.dio.put<dynamic>('/notifications/$id/read');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Chat tarixi — user JUFTLIGI bo'yicha (ride_id ixtiyoriy).
  Future<List<ChatMessage>> history({
    required String myId,
    required String peerId,
    String? rideId,
  }) async {
    try {
      final res = await _client.dio.get<dynamic>(
        '/notifications/history',
        queryParameters: {
          'user_id_1': myId,
          'user_id_2': peerId,
          'ride_id': ?rideId,
        },
      );
      final messages = asList(
        unwrap(res.data),
        'messages',
      ).map(ChatMessage.fromJson).toList();
      // Tartib `orderChatMessages` da — teng vaqtli xabarlar aralashib
      // ketmasligi uchun (izohi o'sha yerda).
      return orderChatMessages(messages);
    } on DioException catch (e) {
      // Yozishma yuklanmasa "xabar yo'q" deb ko'rsatilmasin — chat ekranida
      // xato holati bor.
      throw ApiException.from(e);
    }
  }

  /// Suhbatlar ro'yxati — oxirgi xabar va o'qilmaganlar soni bilan.
  ///
  /// ✅ Backend 2026-08-16 da qo'shdi (`GET /notifications/chats`). Ilgari
  /// ro'yxatdagi HAR suhbat uchun butun yozishma tarixi alohida so'rov
  /// bilan yuklanardi — faqat oxirgi qatorni chizish uchun. Endi bitta
  /// so'rov yetadi.
  ///
  /// ⚠️ Javobda ism va avatar YO'Q (faqat `partner_id`), shuning uchun bu
  /// suhbatlar ro'yxatini almashtirmaydi — ustiga qo'yiladi.
  ///
  /// Xato YUTILADI: bu ma'lumot bezak, usiz ham ro'yxat ishlaydi. Uzilishda
  /// odam "suhbat yo'q" emas, shunchaki oxirgi xabarsiz ro'yxat ko'radi.
  Future<List<ChatSummary>> chats() async {
    try {
      final res = await _client.dio.get<dynamic>('/notifications/chats');
      final rows = asList(unwrap(res.data), 'chats');
      await _cache?.writeList(CacheKeys.conversations, rows);
      return rows.map(ChatSummary.fromJson).toList();
    } on DioException catch (e) {
      // 🔴 Ilgari bu yerda shartsiz `return const []` turardi — ya'ni
      // internet uzilishi "sizda suhbat yo'q" bo'lib ko'rinardi. Odam
      // yozishmalari o'chib ketgan deb o'ylardi.
      if (isOfflineError(e)) {
        final cached = _cache?.readList(CacheKeys.conversations);
        if (cached != null) return cached.map(ChatSummary.fromJson).toList();
      }
      return const [];
    }
  }

  /// FCM tokenini ro'yxatga olish (o'chirish endpointi YO'Q — eskirganini
  /// backend o'zi tozalaydi).
  Future<void> registerPushToken({
    required String fcmToken,
    String? language,
    String? platform,
  }) async {
    try {
      await _client.dio.post<dynamic>(
        '/notifications/tokens',
        data: {
          'fcm_token': fcmToken,
          'language': ?language,
          'platform': ?platform,
        },
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}
