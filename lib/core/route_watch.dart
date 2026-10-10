import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// KUZATILAYOTGAN YO'NALISH — «shu yo'nalishda safar chiqsa xabar ber».
///
/// 🔴 NEGA YOZILDI (2026-08-25): hozirgi eng katta muammo texnik emas —
/// bazada safar KAM. Odam qidiradi, bo'sh ekran ko'radi va KETADI. U
/// qaytib kelishi uchun sabab yo'q, biz esa uni chaqira olmaymiz: push
/// backendda hali yuborilmaydi (xat §2).
///
/// Yechim pushni KUTMAYDI. Ilova o'zi vaqti-vaqti bilan tekshiradi va
/// MAHALLIY bildirishnoma chiqaradi. Bu naqsh loyihada allaqachon
/// ishlaydi — safar eslatmalari ham shunday (`trip_reminders.dart`).
///
/// ⚠️ HALOL CHEKLOV, foydalanuvchiga AYTILADI: ilova butunlay yopiq
/// bo'lsa Android tekshiruvni kechiktiradi yoki umuman o'tkazib yuboradi.
/// Ya'ni bu push O'RNINI BOSMAYDI — u faqat «ilovaga qaytganda darhol
/// bilasiz» degan va'da. Push chiqqach bu mexanizm olib tashlanadi.
class RouteWatch {
  const RouteWatch({
    required this.fromName,
    required this.fromLat,
    required this.fromLon,
    required this.toName,
    required this.toLat,
    required this.toLon,
    required this.createdAt,
    this.lastSeenCount = 0,
    this.serverId,
  });

  final String fromName;
  final double fromLat;
  final double fromLon;
  final String toName;
  final double toLat;
  final double toLon;
  final DateTime createdAt;

  /// Oxirgi tekshiruvda nechta safar bor edi.
  ///
  /// 🔴 SHUNGA QARAB xabar beriladi, «bor/yo'q» ga emas: aks holda
  /// ro'yxatda bitta safar turgan bo'lsa, har tekshiruvda qayta-qayta
  /// xabar kelaverardi.
  final int lastSeenCount;

  /// SERVERDAGI obuna ID'si (`/rides/route-subscriptions`), bo'lsa.
  ///
  /// ✅ 2026-08-27: backend yo'nalish obunasini ochdi, ya'ni endi push ham
  /// kelishi mumkin. Mahalliy kuzatuv OLIB TASHLANMADI (izohi
  /// `RidesRepository.createRouteSubscription` da) — bu maydon shunchaki
  /// «serverda ham ro'yxatga olindi» degani va kuzatuv o'chirilganda
  /// obunani ham o'chirish uchun kerak.
  ///
  /// `null` bo'lishi mumkin: obuna so'rovi aloqa yo'qligida yiqilgan
  /// bo'lsa ham mahalliy kuzatuv ISHLAYVERADI.
  final String? serverId;

  String get key => '$fromName>$toName';

  RouteWatch withCount(int count) => RouteWatch(
    fromName: fromName,
    fromLat: fromLat,
    fromLon: fromLon,
    toName: toName,
    toLat: toLat,
    toLon: toLon,
    createdAt: createdAt,
    lastSeenCount: count,
    serverId: serverId,
  );

  RouteWatch withServerId(String? id) => RouteWatch(
    fromName: fromName,
    fromLat: fromLat,
    fromLon: fromLon,
    toName: toName,
    toLat: toLat,
    toLon: toLon,
    createdAt: createdAt,
    lastSeenCount: lastSeenCount,
    serverId: id,
  );

  Map<String, dynamic> toJson() => {
    'from': fromName,
    'from_lat': fromLat,
    'from_lon': fromLon,
    'to': toName,
    'to_lat': toLat,
    'to_lon': toLon,
    'created_at': createdAt.toIso8601String(),
    'seen': lastSeenCount,
    if (serverId != null) 'server_id': serverId,
  };

  static RouteWatch? fromJson(Map<String, dynamic> json) {
    final from = json['from'];
    final to = json['to'];
    if (from is! String || to is! String || from.isEmpty || to.isEmpty) {
      return null;
    }
    // Nom `num` bo'lsa Dart'ning O'Z turini soyalab qo'yadi.
    double? asCoord(Object? value) =>
        value is num ? value.toDouble() : null;
    final fromLat = asCoord(json['from_lat']);
    final fromLon = asCoord(json['from_lon']);
    final toLat = asCoord(json['to_lat']);
    final toLon = asCoord(json['to_lon']);
    if (fromLat == null || fromLon == null || toLat == null || toLon == null) {
      return null;
    }
    return RouteWatch(
      fromName: from,
      fromLat: fromLat,
      fromLon: fromLon,
      toName: to,
      toLat: toLat,
      toLon: toLon,
      createdAt:
          DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
      lastSeenCount: json['seen'] is int ? json['seen'] as int : 0,
      serverId: json['server_id'] is String && (json['server_id'] as String).isNotEmpty
          ? json['server_id'] as String
          : null,
    );
  }
}

/// Kuzatuvlar ro'yxatini qurilmada saqlaydi.
class RouteWatchStore {
  const RouteWatchStore(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'route_watches';

  /// Ko'pi bilan uchta. Ko'proq kuzatuv — ko'proq fon so'rovi va ko'proq
  /// bildirishnoma; ikkalasi ham ilovani bezorilikka aylantiradi.
  static const maxWatches = 3;

  List<RouteWatch> read() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => RouteWatch.fromJson(e.cast<String, dynamic>()))
          .whereType<RouteWatch>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _save(List<RouteWatch> watches) => _prefs.setString(
    _key,
    jsonEncode(watches.map((w) => w.toJson()).toList()),
  );

  bool contains(String fromName, String toName) =>
      read().any((w) => w.key == '$fromName>$toName');

  /// Qo'shadi yoki (allaqachon bo'lsa) OLIB TASHLAYDI — bitta tugma.
  Future<bool> toggle(RouteWatch watch) async {
    final current = read();
    final exists = current.any((w) => w.key == watch.key);
    if (exists) {
      await _save(current.where((w) => w.key != watch.key).toList());
      return false;
    }
    // Eng eskisi tushib qoladi — yangi kuzatuv odamga hozir kerakroq.
    final next = [watch, ...current].take(maxWatches).toList();
    await _save(next);
    return true;
  }

  /// Serverdagi obuna ID'sini yozadi (obuna kuzatuvdan KEYIN yaratiladi:
  /// tugma darhol javob berishi kerak, tarmoq esa kutdirishi mumkin).
  Future<void> setServerId(String key, String? id) async {
    final next = read()
        .map((w) => w.key == key ? w.withServerId(id) : w)
        .toList();
    await _save(next);
  }

  /// Kalit bo'yicha topadi — o'chirishda serverdagi obunani ham o'chirish
  /// uchun kerak.
  RouteWatch? find(String key) {
    for (final w in read()) {
      if (w.key == key) return w;
    }
    return null;
  }

  Future<void> updateCount(String key, int count) async {
    final next = read()
        .map((w) => w.key == key ? w.withCount(count) : w)
        .toList();
    await _save(next);
  }

  Future<void> remove(String key) async =>
      _save(read().where((w) => w.key != key).toList());
}
