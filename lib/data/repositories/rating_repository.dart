import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/rating.dart';

/// Reyting — FAQAT tugagan (`completed`) safardan keyin, haydovchi <-> yo'lovchi.
///
/// ⚠ Gateway'da "men kimni baholaganman" degan endpoint YO'Q — takroriy baho
/// yuborilsa backend 400 beradi va foydalanuvchi sababini tushunmaydi.
/// Shuning uchun berilgan baholar QURILMADA belgilanadi: mukammal emas
/// (ilova qayta o'rnatilsa unutiladi), lekin odatiy holatda tugma qaytib
/// chiqmasligini ta'minlaydi.
class RatingRepository {
  RatingRepository(this._client, this._prefs);

  final ApiClient _client;
  final SharedPreferences _prefs;

  static const _ratedKey = 'rated_pairs';

  String _pair(String rideId, String revieweeId) => '$rideId:$revieweeId';

  bool hasRated(String rideId, String revieweeId) =>
      (_prefs.getStringList(_ratedKey) ?? const []).contains(
        _pair(rideId, revieweeId),
      );

  /// SHARHLAR RO'YXATI — `GET /rating?reviewee_id=`.
  ///
  /// ✅ 2026-08-27: endpoint bizning so'rovimizdan keyin ochildi. Shu
  /// paytgacha izoh YOZILARDI-yu, hech qayerda ko'rinmasdi.
  ///
  /// 🔑 MEHMONLARGA OCHIQ (o'lchandi: tokensiz 200) — ya'ni ro'yxat
  /// kirmagan odamga ham ko'rsatiladi. Bu muhim: sayt safar sahifasini
  /// mehmon rejimida ochadi va qaror aynan o'sha yerda qabul qilinadi.
  ///
  /// [withComment] — faqat matnli sharhlar. Bo'sh baholar ro'yxatni
  /// suyultiradi: odam "37 ta baho" ni emas, GAPNI o'qigani keladi.
  Future<FeedbackList> list(
    String revieweeId, {
    int limit = 20,
    int offset = 0,
    bool withComment = true,
  }) async {
    try {
      final res = await _client.dio.get<dynamic>(
        '/rating',
        queryParameters: {
          'reviewee_id': revieweeId,
          'limit': limit,
          'offset': offset,
          if (withComment) 'with_comment': true,
        },
      );
      return FeedbackList.fromJson(asMap(unwrap(res.data)) ?? const {});
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Feedback> submit(SubmitFeedbackRequest request) async {
    try {
      final res = await _client.dio.post<dynamic>(
        '/rating',
        data: request.toJson(),
      );
      await _remember(request.rideId, request.revieweeId);
      return Feedback.fromJson(asMap(unwrap(res.data)) ?? const {});
    } on DioException catch (e) {
      final error = ApiException.from(e);
      // "Allaqachon baholangan" — qurilmada belgi yo'qolgan holat. Xato sifatida
      // ko'rsatish o'rniga belgini tiklaymiz, tugma boshqa chiqmaydi.
      if (_isAlreadyRated(error)) {
        await _remember(request.rideId, request.revieweeId);
        return Feedback(
          id: '',
          rideId: request.rideId,
          revieweeId: request.revieweeId,
          score: request.score,
          comment: request.comment,
        );
      }
      throw error;
    }
  }

  bool _isAlreadyRated(ApiException error) {
    final raw = error.backendMessage?.toLowerCase() ?? '';
    return raw.contains('already') &&
        (raw.contains('rat') || raw.contains('feedback'));
  }

  Future<void> _remember(String rideId, String revieweeId) async {
    final saved = _prefs.getStringList(_ratedKey) ?? const [];
    final pair = _pair(rideId, revieweeId);
    if (saved.contains(pair)) return;
    await _prefs.setStringList(_ratedKey, [...saved, pair]);
  }
}
