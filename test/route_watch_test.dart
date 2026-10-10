import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/core/route_watch.dart';

/// YO'NALISH KUZATUVCHISI.
///
/// 🔴 NEGA TEST: bu funksiya BILDIRISHNOMA yuboradi. Xato qilsa odam
/// bezovta qilinadi va u bildirishnomalarni butunlay o'chirib qo'yadi —
/// keyin biz uni HECH QACHON chaqira olmaymiz. Ya'ni noto'g'ri kuzatuv
/// kuzatuvsizlikdan yomonroq.
///
/// Eng muhim qoida: xabar «bor/yo'q» ga emas, SONNING O'SISHIGA qarab
/// beriladi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RouteWatchStore store;

  RouteWatch watch(String from, String to) => RouteWatch(
    fromName: from,
    fromLat: 41.3,
    fromLon: 69.2,
    toName: to,
    toLat: 39.6,
    toLon: 66.9,
    createdAt: DateTime.now(),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = RouteWatchStore(await SharedPreferences.getInstance());
  });

  test('qo\'shiladi va saqlanadi', () async {
    final added = await store.toggle(watch('Toshkent', 'Samarqand'));
    expect(added, isTrue);
    expect(store.contains('Toshkent', 'Samarqand'), isTrue);
    expect(store.read(), hasLength(1));
  });

  test('qayta bosilsa OLIB TASHLANADI', () async {
    await store.toggle(watch('Toshkent', 'Samarqand'));
    final added = await store.toggle(watch('Toshkent', 'Samarqand'));

    expect(added, isFalse);
    expect(store.contains('Toshkent', 'Samarqand'), isFalse);
    expect(store.read(), isEmpty);
  });

  test('yo\'nalish YO\'NALTIRILGAN — teskarisi boshqa kuzatuv', () async {
    await store.toggle(watch('Toshkent', 'Samarqand'));
    expect(store.contains('Samarqand', 'Toshkent'), isFalse);
  });

  /// Ko'p kuzatuv — ko'p fon so'rovi va ko'p bildirishnoma.
  test('uchtadan oshmaydi, eng eskisi tushadi', () async {
    for (final city in ['A', 'B', 'C', 'D']) {
      await store.toggle(watch('Toshkent', city));
    }
    final all = store.read();
    expect(all, hasLength(3));
    // Eng yangisi birinchi, eng eskisi (A) tushib qolgan.
    expect(all.first.toName, 'D');
    expect(store.contains('Toshkent', 'A'), isFalse);
  });

  test('sanoq yangilanadi va saqlanadi', () async {
    final w = watch('Toshkent', 'Samarqand');
    await store.toggle(w);
    await store.updateCount(w.key, 4);

    expect(store.read().single.lastSeenCount, 4);
  });

  test('buzuq yozuv butun ro\'yxatni yiqitmaydi', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('route_watches', '[{"from":"A"},{"buzuq":true}]');
    // Yaroqsizlari tashlanadi, ilova yiqilmaydi.
    expect(store.read(), isEmpty);
  });

  test('buzuq JSON — bo\'sh ro\'yxat', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('route_watches', 'bu JSON emas {{{');
    expect(store.read(), isEmpty);
  });

  test('o\'chirish', () async {
    final w = watch('Toshkent', 'Samarqand');
    await store.toggle(w);
    await store.remove(w.key);
    expect(store.read(), isEmpty);
  });

  /// 🔴 SERVER OBUNASI ID'si DISKDA QOLISHI SHART (2026-08-27).
  ///
  /// Kuzatuv qo'shilganda serverda ham obuna yaratiladi
  /// (`/rides/route-subscriptions`) va uning ID'si shu yerga yoziladi.
  /// Agar u saqlanmasa, odam kuzatuvni o'chirganda obunani O'CHIRA
  /// olmaymiz — u serverda yetim qoladi va odamga kerak bo'lmagan push
  /// kelaveradi. Aynan shu «bezovta qilish» bildirishnomalarni butunlay
  /// o'chirtiradi.
  group('server obunasi ID\'si', () {
    test('yoziladi va QAYTA O\'QILADI', () async {
      final w = watch('Toshkent', 'Samarqand');
      await store.toggle(w);
      await store.setServerId(w.key, 'sub-1');

      // Yangi do'kon — ya'ni diskdan o'qiladi, xotiradan emas.
      final reread = RouteWatchStore(await SharedPreferences.getInstance());
      expect(reread.find(w.key)?.serverId, 'sub-1');
    });

    test('sonni yangilash ID ni YO\'QOTMAYDI', () async {
      final w = watch('Toshkent', 'Samarqand');
      await store.toggle(w);
      await store.setServerId(w.key, 'sub-1');
      // `updateCount` har tekshiruvda chaqiriladi — u yozuvni QAYTA
      // quradi, ya'ni ID ni tushirib qoldirish eng oson xato shu yerda.
      await store.updateCount(w.key, 3);

      final found = store.find(w.key);
      expect(found?.serverId, 'sub-1');
      expect(found?.lastSeenCount, 3);
    });

    test('ID yo\'q kuzatuv ham yaroqli — mahalliy kuzatuv ishlayveradi',
        () async {
      final w = watch('Toshkent', 'Samarqand');
      await store.toggle(w);
      expect(store.find(w.key), isNotNull);
      expect(store.find(w.key)?.serverId, isNull);
    });
  });
}
