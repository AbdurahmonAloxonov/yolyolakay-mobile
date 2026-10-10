import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/core/away_digest.dart';

/// «SIZSIZ NIMA BO'LDI» — backend push yubormagani uchun o'zgarishni
/// ilovaning O'ZI aytadi (`core/away_digest.dart`).
///
/// Bu yerda qulflanadigan va'dalar:
///   1. yangilik bo'lmasa karta CHIQMAYDI (shovqin qilmaymiz);
///   2. qisqa tanaffusda ham chiqmaydi — cho'ntakda qulflangan telefon
///      «yangilik» sababi emas;
///   3. manfiy farq nolga tenglashadi (boshqa qurilmada o'qilgan bo'lishi
///      mumkin, «-2 xabar» degan gap ma'nosiz);
///   4. bir marta ko'rsatilgach qayta chiqmaydi.
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// Odam [ago] oldin chiqib ketgan holatni yasaydi.
  Future<void> leftApp({
    required Duration ago,
    int notifications = 0,
    int chats = 0,
  }) async {
    await prefs.setString(
      'away_seen_at',
      DateTime.now().subtract(ago).toIso8601String(),
    );
    await prefs.setInt('away_notif', notifications);
    await prefs.setInt('away_chats', chats);
  }

  test('birinchi ochilishda hech nima ko\'rsatilmaydi', () {
    final digest = AwayDigest(prefs);
    expect(
      digest.changesSince(unreadNotifications: 3, unreadChats: 2),
      isNull,
      reason: 'taqqoslash uchun baza yo\'q — «3 yangilik» deyish yolg\'on',
    );
  });

  test('uzoq yo\'qlikda yangi xabar KO\'RSATILADI', () async {
    await leftApp(ago: const Duration(hours: 5), notifications: 1, chats: 0);

    final changes = AwayDigest(
      prefs,
    ).changesSince(unreadNotifications: 3, unreadChats: 2);

    expect(changes, isNotNull);
    expect(changes!.newNotifications, 2);
    expect(changes.newMessages, 2);
  });

  test('qisqa tanaffusda CHIQMAYDI', () async {
    await leftApp(ago: const Duration(minutes: 5), notifications: 0, chats: 0);
    expect(
      AwayDigest(prefs).changesSince(unreadNotifications: 5, unreadChats: 5),
      isNull,
    );
  });

  test('yangilik yo\'q bo\'lsa CHIQMAYDI', () async {
    await leftApp(ago: const Duration(hours: 8), notifications: 4, chats: 3);
    expect(
      AwayDigest(prefs).changesSince(unreadNotifications: 4, unreadChats: 3),
      isNull,
    );
  });

  test('boshqa qurilmada o\'qilgan bo\'lsa manfiy son chiqmaydi', () async {
    await leftApp(ago: const Duration(hours: 8), notifications: 9, chats: 9);
    expect(
      AwayDigest(prefs).changesSince(unreadNotifications: 1, unreadChats: 1),
      isNull,
      reason: '«-8 xabar» degan gap yo\'q, ya\'ni ko\'rsatadigan narsa ham yo\'q',
    );
  });

  test('bir marta ko\'rsatilgach qayta chiqmaydi', () async {
    await leftApp(ago: const Duration(hours: 5), notifications: 0, chats: 0);
    final digest = AwayDigest(prefs);

    expect(
      digest.changesSince(unreadNotifications: 2, unreadChats: 0),
      isNotNull,
    );
    await digest.acknowledge(unreadNotifications: 2, unreadChats: 0);

    expect(
      digest.changesSince(unreadNotifications: 2, unreadChats: 0),
      isNull,
      reason: 'tasdiqlangach baza yangilanadi',
    );
  });
}
