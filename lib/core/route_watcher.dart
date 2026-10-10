import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/models/ride.dart';
import '../data/repositories/rides_repository.dart';
import 'push.dart';
import 'route_watch.dart';

/// KUZATILAYOTGAN YO'NALISHLARNI TEKSHIRADI va yangi safar chiqsa
/// MAHALLIY bildirishnoma beradi.
///
/// Sabab va halol cheklovlar — `route_watch.dart` izohida.
///
/// Chaqiriladi: ilova ochilganda va fondan qaytganda
/// (`lifecycle_refresh.dart`). Alohida taymer YO'Q — u batareyani yeydi
/// va Android baribir uni fon rejimda to'xtatadi, ya'ni yolg'on va'da
/// bo'lardi.
class RouteWatcher {
  RouteWatcher({
    required this.store,
    required this.rides,
    required this.plugin,
    required this.title,
    required this.body,
  });

  final RouteWatchStore store;
  final RidesRepository rides;
  final FlutterLocalNotificationsPlugin plugin;

  /// Bildirishnoma matni — til qatlamidan keladi (bu sinf `BuildContext`
  /// ni bilmaydi).
  final String title;
  final String Function(String from, String to, int count) body;

  /// Manifestdagi kanal bilan bir xil (`push.dart` izohiga qarang).
  /// 🔴 07.09.2026: bu yerda `'yolyolakay_default'` qotirib yozilgandi,
  /// push esa `_v3` kanalini yaratadi — ya'ni bu bildirishnomalar
  /// ALOHIDA, ovozsiz kanalga tushardi va foydalanuvchi asosiy kanalni
  /// jimlatганda ham chiqaverardi. Endi yagona manba `push.dart` da.
  static const _channelId = defaultChannelId;

  /// Hammasini tekshiradi. Xato bo'lsa JIM o'tadi — bu qo'shimcha
  /// funksiya va uning yiqilishi ilovani to'xtatmasligi kerak.
  Future<void> checkAll() async {
    for (final watch in store.read()) {
      try {
        await _check(watch);
      } catch (_) {
        /* tarmoq yoki server — keyingi safar */
      }
    }
  }

  Future<void> _check(RouteWatch watch) async {
    final found = await rides.search(
      RideSearchParams(
        originLat: watch.fromLat,
        originLon: watch.fromLon,
        destLat: watch.toLat,
        destLon: watch.toLon,
      ),
    );

    // Faqat TIRIK va kelajakdagi safarlar sanaladi: tugagan safar uchun
    // xabar berish odamni bekorga chaqirish bo'lardi.
    final now = DateTime.now();
    final count = found
        .where(
          (r) =>
              r.status != RideStatus.cancelled &&
              r.status != RideStatus.completed &&
              (r.departureTime?.isAfter(now) ?? false),
        )
        .length;

    // 🔴 «Bor/yo'q» ga emas, O'SISHGA qarab xabar beriladi: aks holda
    // ro'yxatda bitta safar turgan bo'lsa, har tekshiruvda qayta-qayta
    // xabar kelaverardi va odam bildirishnomalarni o'chirib qo'yardi.
    if (count > watch.lastSeenCount) {
      await _notify(watch, count);
    }
    // Kamaygan bo'lsa ham yozib qo'yamiz — keyingi o'sish yana xabar
    // bersin (safar olindi, keyin yangisi chiqdi).
    if (count != watch.lastSeenCount) {
      await store.updateCount(watch.key, count);
    }
  }

  Future<void> _notify(RouteWatch watch, int count) async {
    try {
      await plugin.show(
        _idFor(watch.key),
        title,
        body(watch.fromName, watch.toName, count),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'YolYolakay',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        // Bosilganda qidiruvga — `push_routes.dart` shu turni biladi.
        payload: '{"type":"ride_found"}',
      );
    } catch (_) {
      /* ruxsat yo'q — bildirishnomasiz davom etamiz */
    }
  }

  /// Yo'nalish uchun BARQAROR id: takror xabar eskisini almashtiradi,
  /// ikkitasi to'planib qolmaydi.
  static int _idFor(String key) {
    var hash = 0;
    for (final unit in key.codeUnits) {
      hash = (hash * 31 + unit) & 0x3fffffff;
    }
    return 900000000 + hash % 90000000;
  }
}
