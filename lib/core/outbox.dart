/// OFFLINE NAVBAT — internetsiz qilingan ish YO'QOLMAYDI.
///
/// 🔴 NEGA YOZILDI (egasi tanlagan band, 2026-08-25): ilova aynan YO'LDA
/// ishlatiladi — tunnel, dovon, qishloq yo'li, metro. Ilgari uzilishda:
///
///   • chatда xabar yozib "Yuborish" bosilsa — ekranга «aloqa yo'q» degan
///     xabar chiqib, matn shundoq QOLARDI. Odam ekranni yopsa yozgani
///     yo'qolardi;
///   • yiqilgan xabar faqat CHAT EKRANI OCHIQ turganда qayta urinardi
///     (`_pending` — ekran holati). Ekrandan chiqsa yoki ilova o'chsa —
///     xabar butunlay yo'q bo'lardi;
///   • baho (reyting) uzilishда shunchaki xato berardi va odam ikkinchi
///     marta qaytib kelmasdi.
///
/// Endi bunday ishlar DISKKA yoziladi va aloqa tiklanganда o'zi yuboriladi.
/// Ilova qayta ishga tushsa ham navbat joyida turadi.
///
/// ═══ NIMA NAVBATGA TUSHADI VA NIMA TUSHMAYDI ═══
///
/// Navbatga FAQAT keyinroq bajarilishi ZARARSIZ bo'lgan ish tushadi.
///
/// 🔴 BRON NAVBATGA TUSHMAYDI — bu ataylab. Bron "keyinroq" bajarilsa:
/// o'rindiq allaqachon boshqa odamга ketgan bo'lishi, safar jo'nab
/// ketgan bo'lishi yoki odam fikridan qaytgan bo'lishi mumkin. Uch soatdan
/// keyin jimgina bron qilingan safar — foydalanuvchi so'ramagan ish, ya'ni
/// eng yomon xil xato. Bron uzilishда OCHIQ yiqiladi va odam qayta bosadi.
///
/// ═══ MUDDAT ═══
///
/// [_maxAge] dan eski yozuv TASHLANADI. Kech yetkazilgan xabar foyda emas,
/// zarar keltiradi: «qayerdasiz?» degan savol safar tugagandan ikki kun
/// keyin borsa, odam chalkashadi. Tashlanganда jim qolmaymiz — [dropped]
/// oshadi va ekran buni ayta oladi.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Navbatdagi ish turi.
///
/// Har bir tur uchun yuboruvchi [Outbox.register] orqali ulanadi: navbatning
/// o'zi HTTP ham, WebSocket ham bilmaydi — u faqat saqlaydi va tartibni
/// ushlab turadi.
enum OutboxKind {
  /// Chat xabari (WebSocket orqali ketadi).
  chatMessage,

  /// Safardan keyingi baho (`POST /rating`).
  rating,
}

/// Navbatdagi bitta ish.
@immutable
class OutboxItem {
  const OutboxItem({
    required this.id,
    required this.kind,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
  });

  /// Mahalliy ID — chat ekranidagi lokal pufak bilan bog'lanadi, shuning
  /// uchun yuborilgach o'sha pufakni topib almashtirish mumkin.
  final String id;
  final OutboxKind kind;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  /// Nechta urinish bo'ldi — ekranда "3-marta urinilmoqda" deb ko'rsatish
  /// uchun emas, DIAGNOSTIKA uchun: bir xil yozuv abadiy aylanmasin.
  final int attempts;

  OutboxItem copyWith({int? attempts}) => OutboxItem(
    id: id,
    kind: kind,
    payload: payload,
    createdAt: createdAt,
    attempts: attempts ?? this.attempts,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'payload': payload,
    'created_at': createdAt.toIso8601String(),
    'attempts': attempts,
  };

  static OutboxItem? fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'];
    final kind = OutboxKind.values.where((k) => k.name == kindName).firstOrNull;
    // Turi tanilmasa (eski versiyadan qolgan yozuv) — tashlaymiz. Nomsiz
    // ishni yuborishga urinish undan ko'ra xavfli.
    if (kind == null) return null;
    final payload = json['payload'];
    if (payload is! Map) return null;
    final created = DateTime.tryParse('${json['created_at']}');
    if (created == null) return null;
    return OutboxItem(
      id: '${json['id']}',
      kind: kind,
      payload: payload.cast<String, dynamic>(),
      createdAt: created,
      attempts: json['attempts'] is int ? json['attempts'] as int : 0,
    );
  }
}

/// Yuboruvchi: muvaffaqiyatli bo'lsa `true`.
///
/// `false` — "hozir bo'lmadi, keyin urinamiz". Xato TASHLASH (`throw`) ham
/// shunday qabul qilinadi. Ish BAJARILMASLIGI kerak bo'lsa (masalan server
/// "bunday safar yo'q" desa) yuboruvchi [OutboxDrop] tashlaydi — shundagina
/// yozuv navbatdan olib tashlanadi.
typedef OutboxSender = Future<bool> Function(OutboxItem item);

/// "Bu ishni boshqa urinmang" — yuboruvchi shuni tashlasa yozuv o'chiriladi.
///
/// 🔴 NEGA KERAK: `false` qaytarish "keyin urinamiz" degani. Lekin ba'zi
/// xato QAYTA URINISHDAN tuzalmaydi: safar o'chirilgan, baho allaqachon
/// berilgan, huquq yo'q. Bunday yozuv navbatда abadiy aylanib, boshqa
/// ishlarni ham to'sib turardi.
class OutboxDrop implements Exception {
  const OutboxDrop(this.reason);
  final String reason;

  @override
  String toString() => 'OutboxDrop: $reason';
}

class Outbox {
  Outbox(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'outbox_v1';

  /// Bundan eski yozuv yuborilmaydi (izoh fayl boshida).
  static const _maxAge = Duration(days: 3);

  /// Ekran tinglashi uchun. `ValueNotifier` — Riverpod'siz ham ishlaydi,
  /// `LocalCache`/`ApiClient.connected` bilan bir uslub.
  final ValueNotifier<List<OutboxItem>> items = ValueNotifier(const []);

  /// Muddati o'tgani uchun tashlangan yozuvlar soni — ekran buni aytadi.
  final ValueNotifier<int> dropped = ValueNotifier(0);

  final Map<OutboxKind, OutboxSender> _senders = {};

  /// Yuborish sikllari NAVBAT bilan bajariladi.
  ///
  /// 🔴 NEGA ZANJIR, oddiy `bool _flushing` EMAS (test bilan topildi,
  /// 2026-08-25): bayroq bilan yozilganda, sikl ishlab turgan paytda kelgan
  /// ikkinchi chaqiruv JIMGINA tashlanardi. Amalда bu shunday ko'rinardi:
  /// xabar qo'shilishi bilan yuborishga urinish boshlanadi (aloqa yo'q,
  /// sekin tugaydi), o'sha payt aloqa tiklanib `flush` chaqiriladi — va u
  /// hech nima qilmay qaytadi. Xabar esa keyingi turtkigacha yotardi.
  ///
  /// Endi har chaqiruv o'z navbatini KUTADI: hech qanday signal yo'qolmaydi
  /// va ikkita sikl bir vaqtда ishlamaydi.
  Future<void>? _chain;

  int get pendingCount => items.value.length;

  void register(OutboxKind kind, OutboxSender sender) {
    _senders[kind] = sender;
  }

  /// Diskdan o'qiydi. Ilova ishga tushganда bir marta.
  Future<void> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final loaded = <OutboxItem>[];
      for (final row in decoded) {
        if (row is! Map) continue;
        final item = OutboxItem.fromJson(row.cast<String, dynamic>());
        if (item != null) loaded.add(item);
      }
      items.value = _withoutExpired(loaded);
      await _persist();
    } catch (error) {
      // Buzilgan navbat — butun ilovani yiqitmasin.
      debugPrint('Navbatni o\'qib bo\'lmadi: $error');
    }
  }

  /// Navbatga qo'shadi va DARHOL yuborishga urinadi.
  ///
  /// Aloqa bor bo'lsa odam navbat borligini sezmaydi ham — bu to'g'ri: navbat
  /// ko'rinadigan funksiya emas, YO'QOTMASLIK kafolati.
  Future<OutboxItem> add({
    required OutboxKind kind,
    required Map<String, dynamic> payload,
    String? id,
  }) async {
    final item = OutboxItem(
      id: id ?? 'ob-${DateTime.now().microsecondsSinceEpoch}',
      kind: kind,
      payload: payload,
      createdAt: DateTime.now(),
    );
    items.value = [...items.value, item];
    await _persist();
    unawaited(flush());
    return item;
  }

  Future<void> remove(String id) async {
    items.value = items.value.where((i) => i.id != id).toList();
    await _persist();
  }

  /// Navbatni boshdan yuboradi.
  ///
  /// TARTIB SAQLANADI: xabarlar yozilish tartibida ketishi kerak, aks holda
  /// suhbat chalkashadi. Shuning uchun ketma-ket (parallel emas), va bitta
  /// yozuv yuborilmasa O'SHA TURDAGI qolganlari kutadi.
  Future<void> flush() {
    final next = (_chain ?? Future<void>.value())
        .then((_) => _runFlush())
        // Bitta sikl yiqilsa zanjir uzilmasin — keyingilari baribir ketsin.
        .catchError((Object error) {
          debugPrint('Navbat sikli yiqildi: $error');
        });
    _chain = next;
    return next;
  }

  Future<void> _runFlush() async {
    final expiredRemoved = _withoutExpired(items.value);
    if (expiredRemoved.length != items.value.length) {
      items.value = expiredRemoved;
      await _persist();
    }

    // Turi bo'yicha to'silganlar: bittasi yiqilsa o'sha turdagi keyingilari
    // urinilmaydi (tartib buzilmasin).
    final blocked = <OutboxKind>{};

    for (final item in [...items.value]) {
      if (blocked.contains(item.kind)) continue;
      final sender = _senders[item.kind];
      // Yuboruvchi hali ulanmagan (ilova endi ochilyapti) — keyingi
      // urinishда bo'ladi.
      if (sender == null) continue;

      var sent = false;
      var drop = false;
      try {
        sent = await sender(item);
      } on OutboxDrop catch (e) {
        drop = true;
        debugPrint('Navbatdan tashlandi (${item.kind.name}): ${e.reason}');
      } catch (error) {
        debugPrint('Navbat yuborilmadi (${item.kind.name}): $error');
      }

      if (sent || drop) {
        await remove(item.id);
      } else {
        blocked.add(item.kind);
        final i = items.value.indexWhere((x) => x.id == item.id);
        if (i != -1) {
          final next = [...items.value];
          next[i] = item.copyWith(attempts: item.attempts + 1);
          items.value = next;
          await _persist();
        }
      }
    }
  }

  List<OutboxItem> _withoutExpired(List<OutboxItem> source) {
    final now = DateTime.now();
    final kept = source
        .where((i) => now.difference(i.createdAt) < _maxAge)
        .toList();
    final removed = source.length - kept.length;
    if (removed > 0) dropped.value += removed;
    return kept;
  }

  Future<void> _persist() async {
    try {
      await _prefs.setString(
        _key,
        jsonEncode(items.value.map((i) => i.toJson()).toList()),
      );
    } catch (error) {
      debugPrint('Navbat saqlanmadi: $error');
    }
  }
}
