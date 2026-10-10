import '../../core/json.dart';

/// `POST /rating` tanasi.
///
/// ⚠ Endpoint BIRLIKDA (`/rating`, `/ratings` emas) va `reviewer_id`
/// YUBORILMAYDI — backend uni tokendan oladi.
class SubmitFeedbackRequest {
  const SubmitFeedbackRequest({
    required this.rideId,
    required this.revieweeId,
    required this.score,
    this.comment,
  });

  final String rideId;

  /// Baholanayotgan foydalanuvchi (haydovchi yoki yo'lovchi).
  final String revieweeId;

  /// 1..5
  final int score;
  final String? comment;

  Map<String, dynamic> toJson() => {
    'ride_id': rideId,
    'reviewee_id': revieweeId,
    'score': score,
    if (comment != null && comment!.isNotEmpty) 'comment': comment,
  };
}

/// `rating_domain.Feedback`
class Feedback {
  const Feedback({
    required this.id,
    required this.rideId,
    required this.revieweeId,
    required this.score,
    this.reviewerId,
    this.comment,
    this.createdAt,
  });

  final String id;
  final String rideId;
  final String revieweeId;
  final int score;
  final String? reviewerId;
  final String? comment;
  final DateTime? createdAt;

  factory Feedback.fromJson(Map<String, dynamic> json) => Feedback(
    id: asString(pick(json, ['ID', 'id'])),
    rideId: asString(pick(json, ['RideID', 'ride_id'])),
    revieweeId: asString(pick(json, ['RevieweeID', 'reviewee_id'])),
    score: asInt(pick(json, ['Score', 'score'])),
    reviewerId: asStringOrNull(pick(json, ['ReviewerID', 'reviewer_id'])),
    comment: asStringOrNull(pick(json, ['Comment', 'comment'])),
    createdAt: asDate(pick(json, ['CreatedAt', 'created_at'])),
  );
}

/// Bitta SHARH — `GET /rating` ro'yxatidan.
///
/// 🔴 NEGA ENDI BOR: 27-avgustgacha kontraktda faqat `POST /rating` bor edi.
/// Ya'ni biz odamdan safardan keyin izoh SO'RAYDIK va uni QAYTA O'QISH
/// yo'li umuman yo'q edi — yozilgan gap hech kimga ko'rinmasdi. Backend
/// so'rovimizdan keyin `GET /rating` ni ochdi (o'lchandi: mehmonlarga ham
/// ochiq, ya'ni sayt tokensiz ham ko'rsata oladi).
///
/// ⚠️ `reviewer` — MUALLIF, baholanuvchi emas. `domain.FeedbackItem` da
/// `reviewee_id` YO'Q: kim haqidaligi so'rovning o'zidan ma'lum.
class FeedbackItem {
  const FeedbackItem({
    required this.id,
    required this.score,
    this.comment,
    this.createdAt,
    this.reviewerName,
    this.reviewerAvatar,
    this.reviewerId,
    this.rideId,
  });

  final String id;
  final int score;
  final String? comment;
  final DateTime? createdAt;
  final String? reviewerName;
  final String? reviewerAvatar;
  final String? reviewerId;
  final String? rideId;

  bool get hasComment => (comment ?? '').trim().isNotEmpty;

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    final rv = json['reviewer'];
    final reviewer = rv is Map
        ? rv.cast<String, dynamic>()
        : const <String, dynamic>{};
    return FeedbackItem(
      id: asStringOrNull(pick(json, ['ID', 'id'])) ?? '',
      score: asInt(pick(json, ['Score', 'score'])),
      comment: asStringOrNull(pick(json, ['Comment', 'comment'])),
      createdAt: asDate(pick(json, ['CreatedAt', 'created_at'])),
      reviewerId: asStringOrNull(reviewer['id']),
      reviewerName: asStringOrNull(reviewer['name']),
      reviewerAvatar: asStringOrNull(reviewer['avatar']),
      rideId: asStringOrNull(pick(json, ['RideID', 'ride_id'])),
    );
  }
}

/// `GET /rating` javobi — ro'yxat + jami + o'rtacha.
///
/// 🔑 `total` va `average` javobning O'ZIDA keladi (biz shuni so'ragandik):
/// profil uchun alohida so'rov qilish shart emas.
class FeedbackList {
  const FeedbackList({
    this.items = const [],
    this.total = 0,
    this.average = 0,
  });

  final List<FeedbackItem> items;
  final int total;
  final double average;

  factory FeedbackList.fromJson(Map<String, dynamic> json) => FeedbackList(
    // Bo'sh natijada `[]` keladi (o'lchandi), lekin backendning boshqa
    // ro'yxatlari `null` qaytaradi — shuning uchun `null` ham qabul
    // qilinadi, aks holda bo'sh profil ilovani yiqitardi.
    items: (json['items'] is List ? json['items'] as List : const [])
        .whereType<Map>()
        .map((e) => FeedbackItem.fromJson(e.cast<String, dynamic>()))
        .toList(),
    total: asInt(json['total']),
    average: asDouble(json['average'] ?? 0),
  );
}
