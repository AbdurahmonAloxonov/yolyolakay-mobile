import '../../core/format.dart';
import '../../core/json.dart';

/// `user_domain.User`
class User {
  const User({
    required this.id,
    required this.phoneNumber,
    this.firstName,
    this.lastName,
    this.gender,
    this.role,
    this.status,
    this.rating,
    this.ratingCount,
    this.avatarUrl,
    this.createdAt,
    this.kycStatus,
    this.kycRejectionReason,
  });

  final String id;
  final String phoneNumber;
  final String? firstName;
  final String? lastName;

  /// `male` | `female`
  final String? gender;

  /// `passenger` | `driver`
  final String? role;
  final String? status;

  /// Shaxsni tasdiqlash holati — `none` | `pending` | `approved` |
  /// `rejected` (backend `http.User.kyc_status`).
  ///
  /// 🔴 Bu maydon backendda ANCHADAN BERI bor edi, lekin ikkala mijozda
  /// ham UMUMAN o'qilmasdi (2026-08-27 sverkasi). Ya'ni haydovchi
  /// hujjatlarini yuborardi va keyin hech qanday javob ko'rmasdi:
  /// mashinaning `moderation_status` i ko'rsatilardi, ODAMNING o'zi
  /// tekshiruvdan o'tdimi — yo'q.
  final String? kycStatus;

  /// Modarator yozgan RAD ETISH SABABI (`kyc_rejection_reason`).
  ///
  /// 🔑 Ixtiyoriy: 09.09.2026 o'lchovida biz uni jonli KO'RA OLMADIK
  /// (sinov akkauntimiz `approved`). Shuning uchun bo'lmasligi ODDIY
  /// hol — o'shanda profil eski umumiy maslahatni ko'rsatadi, ya'ni
  /// hech nima sinmaydi.
  final String? kycRejectionReason;

  /// Sabab KO'RSATISHGA yaroqlimi — bo'sh satr ham "yo'q" demakdir.
  String? get kycReasonText {
    final r = (kycRejectionReason ?? '').trim();
    return r.isEmpty ? null : r;
  }

  final double? rating;
  final int? ratingCount;


  /// Profil rasmi (`media/upload` qaytargan URL). Bo'sh bo'lsa ismning
  /// birinchi harfi ko'rsatiladi.
  final String? avatarUrl;

  /// Ro'yxatdan o'tgan sana — begona profilda "qachondan beri shu yerda"
  /// degan savolga javob. Ishonch signali: kecha ochilgan hisob bilan bir
  /// yillik hisob bir xil ko'rinmasligi kerak.
  final DateTime? createdAt;

  bool get hasAvatar => avatarUrl != null && avatarUrl!.trim().isNotEmpty;

  bool get isDriver => role == 'driver';

  /// Tekshiruv holati — KO'RSATISHGA arziydimi.
  ///
  /// 🔑 RUXSAT ro'yxati YOZILMAYDI (loyiha qoidasi): backend yangi holat
  /// nomi qo'shsa, oq ro'yxat uni jimgina yashirib qo'yardi. Shuning
  /// uchun teskarisi: faqat "hech narsa yo'q" holatlari yashiriladi,
  /// qolgani KO'RSATILADI.
  bool get hasKycState {
    final s = (kycStatus ?? '').trim().toLowerCase();
    return s.isNotEmpty && s != 'none' && s != 'not_started';
  }

  bool get isKycApproved {
    final s = (kycStatus ?? '').trim().toLowerCase();
    return s == 'approved' || s == 'verified' || s == 'accepted';
  }

  bool get isKycRejected {
    final s = (kycStatus ?? '').trim().toLowerCase();
    return s == 'rejected' || s == 'declined' || s == 'failed';
  }

  /// Ko'rsatish uchun ism.
  ///
  /// `prettyName` — pasportdan kelgan BOSH HARFLI yozuvni yumshatadi
  /// ("MUXAMMAD" -> "Muxammad"). Bitta joyda qilinadi, shunda hamma ekran
  /// bir xil ko'rsatadi (format.dart izohiga qarang).
  String get displayName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    if (parts.isEmpty) return phoneNumber;
    return prettyName(parts.join(' ')) ?? parts.join(' ');
  }

  /// Ism kiritilmagan — profilda telefon raqami IKKI MARTA chiqmasligi uchun
  /// (sarlavha ham, ostki yozuv ham `displayName` ga tushib qolardi).
  bool get hasName => displayName != phoneNumber;

  /// Reytingni ko'rsatish mumkinmi.
  ///
  /// ⚠ Backend yangi hisobga ham `rating: 5.0` beradi. Hech kim baholamagan
  /// foydalanuvchini "5.0" deb ko'rsatish yo'lovchini chalg'itadi — sharh
  /// soni ANIQ nol bo'lsa yashiramiz. Soni noma'lum bo'lsa (`null`)
  /// ko'rsatamiz: web ham shunday qiladi va boshqacha qilish ma'lumot
  /// yo'qligini xatoga aylantirardi.
  bool get showRating => rating != null && rating! > 0 && ratingCount != 0;

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: asString(json['id']),
    phoneNumber: asString(json['phone_number']),
    firstName: asStringOrNull(json['first_name']),
    lastName: asStringOrNull(json['last_name']),
    gender: asStringOrNull(json['gender']),
    role: asStringOrNull(json['role']),
    status: asStringOrNull(json['status']),
    rating: json['rating'] == null ? null : asDouble(json['rating']),
    ratingCount: json['rating_count'] == null
        ? null
        : asInt(json['rating_count']),
    avatarUrl: asStringOrNull(json['avatar_url']),
    createdAt: asDate(json['created_at']),
    kycStatus: asStringOrNull(json['kyc_status']),
    kycRejectionReason: asStringOrNull(json['kyc_rejection_reason']),
  );
}

/// `user_domain.Car`
class Car {
  const Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.govNumber,
    this.moderationStatus,
  });

  final String id;
  final String brand;
  final String model;

  /// Backend maydoni `gov_number` — `plate_number` yuborilsa 400 (jonli tasdiqlangan).
  final String govNumber;

  /// Moderatsiyadan o'tmagan mashina bilan safarni faollashtirib bo'lmaydi.
  final String? moderationStatus;

  bool get isApproved =>
      moderationStatus == 'approved' || moderationStatus == null;

  String get title => '$brand $model';

  factory Car.fromJson(Map<String, dynamic> json) => Car(
    id: asString(json['id']),
    brand: asString(json['brand']),
    model: asString(json['model']),
    govNumber: asString(json['gov_number']),
    moderationStatus: asStringOrNull(json['moderation_status']),
  );
}

/// GET /users/me — jonli tasdiqlangan shakl: `{user, cars}`
class MeResponse {
  const MeResponse({required this.user, required this.cars});

  final User user;
  final List<Car> cars;

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    return MeResponse(
      user: User.fromJson(
        rawUser is Map ? rawUser.cast<String, dynamic>() : json,
      ),
      cars:
          (json['cars'] as List?)
              ?.whereType<Map>()
              .map((c) => Car.fromJson(c.cast<String, dynamic>()))
              .toList() ??
          const [],
    );
  }
}
