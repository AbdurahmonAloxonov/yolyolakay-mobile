import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/core/outbox.dart';

/// OFFLINE NAVBAT — internetsiz qilingan ish yo'qolmasligi kerak.
///
/// Bu yerda qulflanadigan va'dalar (`core/outbox.dart` dagi sabablar):
///   1. aloqa yo'qda qo'shilgan ish DISKDA qoladi va ilova qayta ochilganda
///      joyida turadi;
///   2. aloqa tiklanganda o'zi ketadi va navbatdan chiqadi;
///   3. TARTIB saqlanadi — birinchi yozilgan birinchi ketadi;
///   4. qayta urinish tuzatmaydigan xato (`OutboxDrop`) navbatда abadiy
///      aylanmaydi;
///   5. eskirgan yozuv yuborilmaydi.
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('aloqa yo\'qda ish navbatda qoladi', () async {
    final outbox = Outbox(prefs);
    outbox.register(OutboxKind.chatMessage, (_) async => false);

    await outbox.add(
      kind: OutboxKind.chatMessage,
      payload: {'recipient_id': 'u1', 'content': 'salom'},
    );

    expect(outbox.pendingCount, 1);
  });

  test('ilova qayta ochilsa navbat joyida turadi', () async {
    final first = Outbox(prefs);
    first.register(OutboxKind.chatMessage, (_) async => false);
    await first.add(
      kind: OutboxKind.chatMessage,
      payload: {'recipient_id': 'u1', 'content': 'salom'},
    );

    // Yangi nusxa = ilova qayta ishga tushdi.
    final second = Outbox(prefs);
    await second.load();

    expect(second.pendingCount, 1);
    expect(second.items.value.single.payload['content'], 'salom');
  });

  test('aloqa tiklanganda o\'zi ketadi', () async {
    var online = false;
    final sent = <String>[];
    final outbox = Outbox(prefs);
    outbox.register(OutboxKind.chatMessage, (item) async {
      if (!online) return false;
      sent.add('${item.payload['content']}');
      return true;
    });

    await outbox.add(
      kind: OutboxKind.chatMessage,
      payload: {'recipient_id': 'u1', 'content': 'salom'},
    );
    expect(outbox.pendingCount, 1, reason: 'aloqa yo\'q — hali navbatda');

    online = true;
    await outbox.flush();

    expect(sent, ['salom']);
    expect(outbox.pendingCount, 0);
  });

  test('tartib saqlanadi — birinchi yozilgan birinchi ketadi', () async {
    var online = false;
    final sent = <String>[];
    final outbox = Outbox(prefs);
    outbox.register(OutboxKind.chatMessage, (item) async {
      if (!online) return false;
      sent.add('${item.payload['content']}');
      return true;
    });

    for (final text in ['bir', 'ikki', 'uch']) {
      await outbox.add(
        kind: OutboxKind.chatMessage,
        payload: {'recipient_id': 'u1', 'content': text},
      );
    }

    online = true;
    await outbox.flush();

    expect(sent, ['bir', 'ikki', 'uch']);
  });

  test('bitta xabar ketmasa keyingilari KUTADI (tartib buzilmasin)', () async {
    final sent = <String>[];
    final outbox = Outbox(prefs);
    outbox.register(OutboxKind.chatMessage, (item) async {
      if (item.payload['content'] == 'bir') return false;
      sent.add('${item.payload['content']}');
      return true;
    });

    for (final text in ['bir', 'ikki']) {
      await outbox.add(
        kind: OutboxKind.chatMessage,
        payload: {'recipient_id': 'u1', 'content': text},
      );
    }
    await outbox.flush();

    expect(sent, isEmpty, reason: 'birinchisi ketmadi — ikkinchisi kutsin');
    expect(outbox.pendingCount, 2);
  });

  test('qayta urinish tuzatmaydigan xato navbatdan CHIQARILADI', () async {
    final outbox = Outbox(prefs);
    outbox.register(
      OutboxKind.rating,
      (_) async => throw const OutboxDrop('allaqachon baholangan'),
    );

    await outbox.add(
      kind: OutboxKind.rating,
      payload: {'ride_id': 'r1', 'reviewee_id': 'u1', 'score': 5},
    );
    await outbox.flush();

    expect(outbox.pendingCount, 0);
  });

  test('yuboruvchi ulanmagan bo\'lsa yozuv saqlanib turadi', () async {
    final outbox = Outbox(prefs);
    // Hech qanday `register` yo'q — ilova endi ochilyapti.
    await outbox.add(
      kind: OutboxKind.chatMessage,
      payload: {'recipient_id': 'u1', 'content': 'salom'},
    );
    await outbox.flush();

    expect(outbox.pendingCount, 1);
  });

  test('eskirgan yozuv yuborilmaydi va jim tashlanmaydi', () async {
    // 3 kundan eski yozuvni qo'lda yozamiz (navbat `_maxAge` = 3 kun).
    final old = DateTime.now().subtract(const Duration(days: 5));
    await prefs.setString(
      'outbox_v1',
      '[{"id":"ob-1","kind":"chatMessage","payload":{"recipient_id":"u1",'
          '"content":"eski"},"created_at":"${old.toIso8601String()}",'
          '"attempts":0}]',
    );

    final outbox = Outbox(prefs);
    var senderCalled = false;
    outbox.register(OutboxKind.chatMessage, (_) async {
      senderCalled = true;
      return true;
    });
    await outbox.load();

    expect(outbox.pendingCount, 0);
    expect(senderCalled, isFalse, reason: 'kech xabar zarar keltiradi');
    expect(outbox.dropped.value, 1, reason: 'jim yo\'qolmasin — ekran aytadi');
  });

  test('tanilmagan tur tashlanadi (eski versiyadan qolgan yozuv)', () async {
    await prefs.setString(
      'outbox_v1',
      '[{"id":"ob-1","kind":"allaqachonYoq","payload":{},'
          '"created_at":"${DateTime.now().toIso8601String()}","attempts":0}]',
    );
    final outbox = Outbox(prefs);
    await outbox.load();
    expect(outbox.pendingCount, 0);
  });
}
