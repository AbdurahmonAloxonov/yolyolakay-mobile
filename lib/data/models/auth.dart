import '../../core/json.dart';

/// `auth_usecase.TokenResponse`
class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    this.isNewUser = false,
  });

  final String accessToken;
  final String refreshToken;

  /// `true` — verify-otp yangi hisob YARATDI (ism/jins to'ldirish kerak).
  /// OTP oqimi login va register'ni bitta qiladi, alohida register yo'q.
  final bool isNewUser;

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
    accessToken: asString(json['access_token']),
    refreshToken: asString(json['refresh_token']),
    isNewUser: asBool(json['is_new_user']),
  );
}

/// `auth_domain.Session` — GET /auth/sessions
class Session {
  const Session({
    required this.sessionId,
    required this.deviceId,
    this.osType,
    this.deviceIp,
    this.userAgent,
    this.createdAt,
    this.expiresAt,
  });

  final String sessionId;
  final String deviceId;
  final String? osType;
  final String? deviceIp;
  final String? userAgent;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    sessionId: asString(json['session_id']),
    deviceId: asString(json['device_id']),
    osType: asStringOrNull(json['os_type']),
    deviceIp: asStringOrNull(json['device_ip']),
    userAgent: asStringOrNull(json['user_agent']),
    createdAt: asDate(json['created_at']),
    expiresAt: asDate(json['expires_at']),
  );
}
