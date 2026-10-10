import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/user.dart';
import '../data/repositories/users_repository.dart';

/// MASHINA MODERATSIYASI TUGAGANINI HAYDOVCHIGA AYTADI.
///
/// 🔴 NEGA KERAK (2026-09-07). Haydovchi mashina qo'shadi, «Moderatsiyada»
/// nishonini ko'radi va **qachon tugashini bilmaydi**. Tasdiqlanmaguncha
/// e'lon berib bo'lmaydi (`POST /rides/{id}/activate` → 400 «driver does
/// not have an approved car»). Ya'ni odam ishlay olmaydi va nima
/// kutayotganini ham bilmaydi — amalda u ilovani ochib-yopib turadi yoki
/// butunlay tashlab ketadi.
///
/// Backenddan bu holat uchun push so'ralgan (`BACKEND_XAT_2026-09-07.txt`,
/// 1-band: `car_approved` / `car_rejected`). Javob kelguncha muammoni
/// MIJOZDA yopamiz — backend pushni qo'shganda bu kuzatuvchi ortiqcha
/// bo'ladi va o'chiriladi.
///
/// 🔑 TAYMER YO'Q. Tekshiruv faqat ilovaga QAYTGANDA bo'ladi
/// (`app/lifecycle_refresh.dart`) — `RouteWatcher` bilan aynan bir xil
/// sabab: doimiy taymer batareyani yeydi va Android uni fonda baribir
/// to'xtatadi, ya'ni yolg'on va'da bo'lardi.
///
/// 🔑 SO'ROV FAQAT KERAK BO'LGANDA. Tarmoqqa chiqish faqat eslab
/// qolingan ro'yxatda tasdiqlanmagan mashina bo'lsa sodir bo'ladi.
/// Ya'ni qo'shimcha yuk AYNAN moderatsiyani kutayotgan odamga tushadi,
/// qolgan hammaga emas (backend har chaqiruvga ~0.7 s sarflaydi).
class CarModerationWatcher {
  CarModerationWatcher({
    required this.prefs,
    required this.users,
    required this.notify,
    required this.approvedTitle,
    required this.approvedBody,
    required this.rejectedTitle,
    required this.rejectedBody,
  });

  final SharedPreferences prefs;
  final UsersRepository users;

  /// «Xabar ber» AMALI — butun plagin emas.
  ///
  /// 🔑 Nega shunday: `FlutterLocalNotificationsPlugin` testda ishlamaydi
  /// (platforma ro'yxatga olinmagan — `LateInitializationError`), ya'ni
  /// plaginni to'g'ridan-to'g'ri ushlagan sinfni O'LCHAB BO'LMAYDI. Bu
  /// sinfning ishi esa «qachon xabar berish kerak» degan QAROR — aynan
  /// shuni test qiladi. Haqiqiy yuborish `push.dart` da.
  final Future<void> Function(int id, String title, String body) notify;

  /// Matnlar til qatlamidan uzatiladi — bu sinf `BuildContext` ni bilmaydi
  /// (`RouteWatcher` dagi bilan bir xil qoida).
  final String approvedTitle;
  final String Function(String plate) approvedBody;
  final String rejectedTitle;
  final String Function(String plate) rejectedBody;

  static const _key = 'car_moderation_seen';

  /// «Odam OXIRGI MARTA nimani ko'rgan» — `{carId: status}`.
  Map<String, String> _seen() {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final e in decoded.entries) '${e.key}': '${e.value}',
      };
    } catch (_) {
      return {}; // buzilgan yozuv — noldan boshlaymiz, bu qo'shimcha funksiya
    }
  }

  Future<void> _save(Map<String, String> value) =>
      prefs.setString(_key, jsonEncode(value));

  static String _statusOf(Car car) =>
      (car.moderationStatus ?? 'approved').toLowerCase();

  static bool _isApproved(String s) => s == 'approved';

  /// `user.dart` dagi `kyc` qoidasi bilan bir xil ro'yxat — uch xil nom
  /// bir narsani anglatadi va backend qaysinisini yuborishi noma'lum.
  static bool _isRejected(String s) =>
      s == 'rejected' || s == 'declined' || s == 'failed';

  /// Odam ekranda KO'RGAN holatni eslab qoladi.
  ///
  /// 🔴 Buni yozmasak, birinchi tekshiruvda ALLAQACHON tasdiqlangan
  /// mashina uchun ham «tasdiqlandi» deb bildirishnoma chiqib ketardi:
  /// o'zgarish YO'Q joyda xabar berish — eng tez o'chiriladigan ilova.
  Future<void> remember(List<Car> cars) async {
    final now = {for (final c in cars) c.id: _statusOf(c)};
    if (now.isEmpty) return;
    final seen = _seen()..addAll(now);
    await _save(seen);
  }

  /// Tarmoqqa chiqish KERAKMI — ya'ni kutilayotgan mashina bormi.
  bool get hasPending =>
      _seen().values.any((s) => !_isApproved(s) && !_isRejected(s));

  /// Tekshiradi va holat o'zgargan bo'lsa bildirishnoma beradi.
  ///
  /// Qaytadi: holat o'zgardimi (chaqiruvchi shunga qarab `meProvider` ni
  /// yangilashi mumkin — ekrandagi nishon ham darhol o'zgarsin).
  /// Xato bo'lsa JIM `false` — bu qo'shimcha funksiya va uning yiqilishi
  /// ilovaga qaytishni buzmasligi kerak.
  Future<bool> check() async {
    if (!hasPending) return false;

    final List<Car> cars;
    try {
      cars = (await users.me()).cars;
    } catch (_) {
      return false; // tarmoq yoki server — keyingi qaytishda
    }

    final seen = _seen();
    var changed = false;

    for (final car in cars) {
      final was = seen[car.id];
      final now = _statusOf(car);
      seen[car.id] = now;
      // Eslanmagan mashina — YANGI: xabar bermaymiz, faqat yozib qo'yamiz.
      if (was == null || was == now) continue;
      // Kutilayotgan holatdan chiqqan bo'lsagina xabar beramiz.
      if (_isApproved(was) || _isRejected(was)) continue;

      changed = true;
      // Maydon nomi `gov_number` — `plate_number` yuborilsa backend 400 beradi.
      final plate = car.govNumber;
      if (_isApproved(now)) {
        await _notify(car.id, approvedTitle, approvedBody(plate));
      } else if (_isRejected(now)) {
        await _notify(car.id, rejectedTitle, rejectedBody(plate));
      }
    }

    await _save(seen);
    return changed;
  }

  Future<void> _notify(String carId, String title, String body) {
    // Id — mashina id'sidan: bitta mashina uchun ikkita bildirishnoma
    // yig'ilib qolmasin (odam ilovaga ikki marta qaytsa ham).
    return notify(carId.hashCode & 0x7fffffff, title, body);
  }
}
