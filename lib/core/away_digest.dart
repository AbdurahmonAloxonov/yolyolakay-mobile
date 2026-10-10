/// «SIZSIZ NIMA BO'LDI» — ilovaga qaytganda o'zgarishlar xulosasi.
///
/// 🔴 NEGA YOZILDI (egasi tanlagan band, 2026-08-25): backend push
/// YUBORMAYDI (mijozda butun zanjir tayyor, o'lchab tekshirilgan). Ya'ni
/// odam ilovadan chiqib ketsa, unga hech qanday belgi kelmaydi: yangi
/// xabar ham, bron javobi ham jimgina yotadi. Qaytib kelganda esa ekran
/// odatdagidek ko'rinadi va u o'zgarishni O'ZI qidirishi kerak — ko'pincha
/// topmaydi ham.
///
/// Bu kamchilikni to'liq yopib bo'lmaydi (telefon jiringlashi uchun push
/// SHART), lekin uni QUROLGA aylantirish mumkin: ilova ochilishi bilan
/// «siz yo'q paytingizda 2 yangi xabar, 1 bron javobi» deb aytadi.
/// Ko'pchilik ilova buni umuman qilmaydi.
///
/// ═══ HALOL CHEKLOV ═══
///
/// Bu «hamma narsa» emas — bu BIZ KO'RA OLADIGAN ro'yxatlardagi farq
/// (o'qilmagan bildirishnoma va chat soni). Shuning uchun matn ham
/// shunday: «yangi xabar bor» deymiz, «hammasi shu» demaymiz.
///
/// Va u faqat ODAM UZOQ YO'Q BO'LGANDA chiqadi ([_minAway]). Ilovaga har
/// qaytganda «0 ta yangilik» deb chiqadigan karta — shovqin, foyda emas.
library;

import 'package:shared_preferences/shared_preferences.dart';

/// Qaytishda ko'rsatiladigan xulosa.
class AwayChanges {
  const AwayChanges({
    required this.newMessages,
    required this.newNotifications,
    required this.away,
  });

  final int newMessages;
  final int newNotifications;

  /// Odam qancha vaqt yo'q bo'lgan — «kecha ertalabdan beri» deyish uchun.
  final Duration away;

  bool get isEmpty => newMessages <= 0 && newNotifications <= 0;
}

class AwayDigest {
  const AwayDigest(this._prefs);

  final SharedPreferences _prefs;

  static const _seenAtKey = 'away_seen_at';
  static const _notifKey = 'away_notif';
  static const _chatsKey = 'away_chats';

  /// Bundan qisqa tanaffusda xulosa CHIQMAYDI: odam telefonni cho'ntagiga
  /// solib qaytargan bo'lishi mumkin, unga «yangilik» ko'rsatish shovqin.
  static const _minAway = Duration(hours: 1);

  /// Odam ilovadan chiqayotganда joriy holatni yozib qo'yamiz.
  ///
  /// ⚠️ O'QILMAGAN SONI saqlanadi, «hammasi» emas: qaytganda farqni
  /// shundan hisoblaymiz va bu server yordamisiz ishlaydi.
  Future<void> remember({
    required int unreadNotifications,
    required int unreadChats,
  }) async {
    await _prefs.setString(_seenAtKey, DateTime.now().toIso8601String());
    await _prefs.setInt(_notifKey, unreadNotifications);
    await _prefs.setInt(_chatsKey, unreadChats);
  }

  /// Qaytganda — nima o'zgargani. Ko'rsatishga arzimasa `null`.
  AwayChanges? changesSince({
    required int unreadNotifications,
    required int unreadChats,
  }) {
    final raw = _prefs.getString(_seenAtKey);
    if (raw == null) return null;
    final seenAt = DateTime.tryParse(raw);
    if (seenAt == null) return null;

    final away = DateTime.now().difference(seenAt);
    if (away < _minAway) return null;

    // MANFIY FARQ = 0. Odam boshqa qurilmada o'qigan bo'lishi mumkin —
    // «-2 ta xabar» degan gap ma'nosiz.
    final newNotifications =
        (unreadNotifications - (_prefs.getInt(_notifKey) ?? 0)).clamp(0, 999);
    final newMessages = (unreadChats - (_prefs.getInt(_chatsKey) ?? 0)).clamp(
      0,
      999,
    );

    final changes = AwayChanges(
      newMessages: newMessages,
      newNotifications: newNotifications,
      away: away,
    );
    return changes.isEmpty ? null : changes;
  }

  /// Xulosa ko'rsatilib bo'ldi — bazani yangilaymiz, u ikkinchi marta
  /// chiqmasin.
  Future<void> acknowledge({
    required int unreadNotifications,
    required int unreadChats,
  }) => remember(
    unreadNotifications: unreadNotifications,
    unreadChats: unreadChats,
  );
}
