import '../../core/json.dart';

/// Qo'llab-quvvatlash murojaati — `GET /helpdesk/tickets`.
///
/// ✅ Backend 2026-08-16 kechqurun to'ldirdi (biz so'ragan edik, xat
/// `BACKEND_XAT_2026-08-16d`): sxema yozildi va eng muhimi — `resolution`
/// maydoni qo'shildi, ya'ni operator javobi ILOVA ICHIDA ko'rinadi.
/// Ungacha odam murojaat yozardi-yu, javobni faqat Telegramdan olardi.
///
/// ✅ `?user_id=` parametri ham OLIB TASHLANDI — ro'yxat tokendan
/// aniqlanadi, ya'ni birovning murojaatlarini o'qib bo'lmaydi.
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.description,
    required this.status,
    this.resolution,
    this.createdAt,
  });

  final String id;
  final String subject;
  final String description;

  /// `OPEN` | `RESOLVED` — aniq ro'yxat kontraktda yo'q, shuning uchun
  /// solishtirish HAR DOIM kichik harfda va faqat "yopilganmi" uchun.
  final String status;

  /// Operator javobi. Bo'sh — hali javob berilmagan.
  final String? resolution;
  final DateTime? createdAt;

  /// Murojaat yopilganmi.
  ///
  /// Statusga TO'LIQ tayanmaymiz: javob matni kelgan bo'lsa ham yopilgan
  /// deb qaraymiz — odam uchun muhimi javob bor-yo'qligi.
  bool get isResolved =>
      status.toLowerCase() == 'resolved' ||
      (resolution ?? '').trim().isNotEmpty;

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
    id: asString(pick(json, ['id', 'ID'])),
    subject: asString(pick(json, ['subject', 'Subject'])),
    description: asString(pick(json, ['description', 'Description'])),
    status: asString(pick(json, ['status', 'Status'])),
    resolution: asStringOrNull(pick(json, ['resolution', 'Resolution'])),
    createdAt: asDate(pick(json, ['created_at', 'CreatedAt'])),
  );
}
