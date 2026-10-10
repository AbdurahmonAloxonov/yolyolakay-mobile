import '../app/router.dart';
import '../data/models/chat.dart';

/// Push bosilganda ilova QAYERGA ochilishi kerakligi.
///
/// 🔴 NEGA ALOHIDA FAYL: bu yagona joy `RemoteMessage`ga ham, Firebase'ga ham
/// bog'liq EMAS — faqat oddiy `Map`. Shuning uchun uni testda mock'siz
/// tekshirib bo'ladi (`test/push_routes_test.dart`), push oqimining qolgan
/// qismi esa faqat qurilmada sinaladi.
class PushTarget {
  const PushTarget(this.location, {this.extra});

  final String location;

  /// GoRoute `state.extra` — ba'zi ekranlar (chat, safar) obyekt kutadi.
  final Object? extra;

  @override
  bool operator ==(Object other) =>
      other is PushTarget && other.location == location && other.extra == extra;

  @override
  int get hashCode => Object.hash(location, extra);

  @override
  String toString() => 'PushTarget($location)';
}

/// Kalitni normallaymiz: 'NEW_MESSAGE' | 'new_message' | 'NewMessage'
/// -> 'newmessage'. Backend uch xil yozuvni ham ishlatgan (sayt tomonda ham
/// aynan shu normallash bor: `shared/lib/notifications.ts`).
String _norm(Object? value) =>
    '$value'.toLowerCase().replaceAll(RegExp('[^a-z]'), '');

String? _pick(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value != null && '$value'.isNotEmpty) return '$value';
  }
  return null;
}

/// Push ma'lumotidan manzil yasaydi. `null` qaytmaydi — noma'lum turdagi
/// xabar ham hech bo'lmasa bildirishnomalar ro'yxatiga olib boradi, chunki
/// bosilgan push HECH NIMA qilmasligi eng yomon variant.
PushTarget pushTargetFor(Map<String, dynamic> data) {
  final type = _norm(_pick(data, ['type', 'event', 'kind']));

  // ===== Chat =====
  // Suhbat kaliti — SUHBATDOSH (2026-08-13 qarori, `Conversation` izohiga
  // qarang). `peer_id` bo'lmasa aniq suhbatni ocholmaymiz: ro'yxatga tushamiz,
  // u yerdan bir bosishda kiriladi.
  if (type.contains('message') || type.contains('chat')) {
    final peerId = _pick(data, [
      'peer_id',
      'sender_id',
      'from_user_id',
      'user_id',
    ]);
    if (peerId == null) return const PushTarget(Routes.chats);
    return PushTarget(
      Routes.chat,
      extra: Conversation(
        rideId: _pick(data, ['ride_id', 'trip_id']) ?? '',
        peerId: peerId,
        /*
         * 🔴 ISM `subtitle` DA, `title` DA EMAS.
         *
         * Modelda `title` = safar yo'nalishi, `subtitle` = ODAM ismi.
         * Ilgari push ismni `title` ga qo'yardi va natijada pushdan
         * ochilgan suhbatda sarlavhada "Suhbatlar" degan umumiy so'z
         * turardi, ism esa pastdagi kichkina yo'nalish qatoriga
         * tushardi. Ya'ni odam kim yozganini sarlavhada KO'RMASDI.
         *
         * Yo'nalish pushda kelmaydi — bo'sh qoladi va ekran uni
         * ko'rsatmaydi.
         */
        title: '',
        subtitle: _pick(data, ['peer_name', 'sender_name', 'title']),
      ),
    );
  }

  // ===== Posilka =====
  // Safar tekshiruvidan OLDIN: posilka xabarlarida ham `ride_id` uchraydi.
  if (type.contains('parcel')) return const PushTarget(Routes.parcels);

  // ===== To'lov / tarif =====
  if (type.contains('payment') ||
      type.contains('subscription') ||
      type.contains('trial') ||
      type.contains('tariff') ||
      type.contains('plan')) {
    return const PushTarget(Routes.tariffs);
  }

  // ===== Bron va safar (eslatmalar shu yerda) =====
  // `/ride` ekrani `extra: Ride` kutadi, pushda esa faqat `ride_id` bor —
  // safarni oldindan yuklab bo'lmaydi, shuning uchun "Safarlarim" ochiladi:
  // ariza ham, eslatma ham o'sha ro'yxatda ko'rinadi.
  if (type.contains('booking') ||
      type.contains('ride') ||
      type.contains('trip') ||
      type.contains('reminder')) {
    return const PushTarget(Routes.trips);
  }

  return const PushTarget(Routes.notifications);
}
