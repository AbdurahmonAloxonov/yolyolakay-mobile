import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/api/ws_client.dart';
import 'package:yolyolakay/core/format.dart';
import 'package:yolyolakay/data/models/chat.dart';

/// Chat Telegram kabi ishlashi kerak (egasi, 2026-08-13).
///
/// Bu yerda ikki qoida qo'riqlanadi:
///   1. O'Z xabaringizga banner chiqmaydi (server aks-sadosi);
///   2. Bir xil matnli ikki xabar BIR-BIRINI yutmaydi.
void main() {
  WsEvent message({required String senderId, String text = 'salom'}) => WsEvent(
    type: 'new_message',
    raw: {
      'event': 'new_message',
      'data': {'sender_id': senderId, 'content': text},
    },
  );

  group('banner', () {
    test('o\'z xabarim aks-sadosi — banner CHIQMAYDI', () {
      final event = message(senderId: 'me-1');
      expect(event.isEchoOf('me-1'), isTrue);
    });

    test('suhbatdoshdan kelgan xabar — banner chiqadi', () {
      final event = message(senderId: 'peer-9');
      expect(event.isEchoOf('me-1'), isFalse);
      expect(event.senderId, 'peer-9');
    });

    test('kim yuborgani noma\'lum bo\'lsa banner to\'silmaydi', () {
      // `sender_id` kelmasa xabarni yashirib qo'yish xavfli: odam
      // suhbatdoshdan kelgan xabarni umuman ko'rmay qolishi mumkin.
      const event = WsEvent(type: 'new_message', raw: {'event': 'new_message'});
      expect(event.senderId, isNull);
      expect(event.isEchoOf('me-1'), isFalse);
    });
  });

  /// Chat ekranidagi "kutayotgan xabar" mantig'i: tarixda o'sha matndan
  /// nechta bo'lsa, shuncha nusxa tasdiqlangan hisoblanadi.
  ///
  /// 🔴 Ilgari mazmun bo'yicha to'plam (`Set`) ishlatilardi va bir xil matnli
  /// IKKINCHI xabar ro'yxatdan yo'qolardi.
  group('bir xil matnli xabarlar', () {
    List<String> visible(List<String> history, List<String> pending) {
      final confirmed = <String, int>{};
      for (final m in history) {
        confirmed[m] = (confirmed[m] ?? 0) + 1;
      }
      final waiting = <String>[];
      for (final p in pending) {
        final left = confirmed[p] ?? 0;
        if (left > 0) {
          confirmed[p] = left - 1;
        } else {
          waiting.add(p);
        }
      }
      return [...history, ...waiting];
    }

    test('ikki marta "ha" yozilsa IKKALASI ham qoladi', () {
      // Tarixda bittasi tasdiqlangan, ikkinchisi hali yo'lda.
      expect(visible(['ha'], ['ha', 'ha']), ['ha', 'ha']);
    });

    test('hammasi tasdiqlangach dublikat qolmaydi', () {
      expect(visible(['ha', 'ha'], ['ha', 'ha']), ['ha', 'ha']);
    });

    test('boshqa matn tegilmaydi', () {
      expect(visible(['ha'], ['yo\'q']), ['ha', 'yo\'q']);
    });
  });

  /// Suhbat ODAM bo'yicha ochiladi (egasi, 2026-08-13: "Telegramda ham
  /// shunaqaku"). Bitta haydovchi bilan uch marta yursangiz ro'yxatda BITTA
  /// qator turishi kerak, uchta emas.
  group('suhbat kaliti', () {
    Conversation conv(String peer, String ride) => Conversation(
      peerId: peer,
      rideId: ride,
      title: 'Toshkent → Andijon',
      subtitle: 'Muxammad',
    );

    test('bir odam, turli safar — BITTA suhbat', () {
      expect(conv('u-1', 'r-1'), conv('u-1', 'r-2'));
      expect(conv('u-1', 'r-1').hashCode, conv('u-1', 'r-2').hashCode);

      final list = {conv('u-1', 'r-1'), conv('u-1', 'r-2')};
      expect(list.length, 1);
    });

    test('turli odam — turli suhbat', () {
      expect(conv('u-1', 'r-1'), isNot(conv('u-2', 'r-1')));
    });
  });

  /// 🔴 Egasi qurilmada ko'rdi (2026-08-13): «chatdan chiqib qaytib kirsam
  /// aralashib, oxirgi xabar 1-chisiga chiqib qolyapti».
  group('xabarlar tartibi', () {
    ChatMessage msg(String id, DateTime? at) => ChatMessage(
      id: id,
      senderId: 'me',
      receiverId: 'peer',
      content: id,
      createdAt: at,
    );
    DateTime t(int h, int m, [int s = 0]) => DateTime(2026, 8, 13, h, m, s);
    List<String> ids(List<ChatMessage> list) => [for (final m in list) m.id];

    test('eskidan yangiga tartiblanadi', () {
      final out = orderChatMessages([
        msg('c', t(9, 0)),
        msg('a', t(7, 0)),
        msg('b', t(8, 0)),
      ]);
      expect(ids(out), ['a', 'b', 'c']);
    });

    test('TENG vaqtli xabarlar server tartibida qoladi', () {
      // Yozishmada bir daqiqada yozilgan xabarlar ko'p — ular har
      // yuklashda joyini almashtirmasligi kerak.
      final raw = [
        msg('1', t(7, 4)),
        msg('2', t(7, 4)),
        msg('3', t(7, 4)),
        msg('4', t(7, 4)),
        msg('5', t(7, 4)),
      ];
      expect(ids(orderChatMessages(raw)), ['1', '2', '3', '4', '5']);
      // Ikki marta chaqirilganda ham AYNAN o'sha natija.
      expect(ids(orderChatMessages(orderChatMessages(raw))), [
        '1',
        '2',
        '3',
        '4',
        '5',
      ]);
    });

    test('vaqti yo\'q xabar o\'z joyida qoladi', () {
      final out = orderChatMessages([
        msg('a', t(7, 0)),
        msg('b', null),
        msg('c', t(9, 0)),
      ]);
      expect(ids(out), ['a', 'b', 'c']);
    });

    test('Go NOL VAQTI xabarni tepaga chiqarib yubormaydi', () {
      // 🔴 Jonli o'lchov (2026-08-20): backend WS `new_message` kadrida
      // `created_at` ni `0001-01-01T00:00:00Z` qilib yuboradi. Bu SANA emas,
      // "qiymat yo'q" degani. `asDate` uni `null` qilmasa, yangi kelgan
      // xabar eng ESKI hisoblanib yozishmaning boshiga sakrardi.
      final zero = ChatMessage.fromJson({
        'id': 'yangi',
        'sender_id': 'me',
        'receiver_id': 'peer',
        'content': 'yangi',
        'created_at': '0001-01-01T00:00:00Z',
      });
      expect(zero.createdAt, isNull, reason: 'nol vaqt sana emas');

      final out = orderChatMessages([msg('a', t(7, 0)), msg('b', t(8, 0)), zero]);
      expect(ids(out), ['a', 'b', 'yangi']);
    });

    test('haqiqiy sana O\'QILADI (chegara hammasini yutmasin)', () {
      final real = ChatMessage.fromJson({
        'id': 'x',
        'sender_id': 'me',
        'receiver_id': 'peer',
        'content': 'x',
        'created_at': '2026-08-20T10:00:00Z',
      });
      expect(real.createdAt, isNotNull);
    });

    test('server yangidan eskiga bersa ham to\'g\'ri chiqadi', () {
      final out = orderChatMessages([
        msg('yangi', t(9, 0)),
        msg('teng2', t(8, 0)),
        msg('teng1', t(8, 0)),
        msg('eski', t(7, 0)),
      ]);
      expect(ids(out), ['eski', 'teng1', 'teng2', 'yangi']);
    });
  });

  /// 🔴 Backend chat matnini HTML kodlab saqlaydi (2026-08-13 jonli o'lchov):
  /// "so'm" -> "so&#39;m". O'zbekchada apostrof deyarli har jumlada bor.
  group('HTML kodlangan matn', () {
    test('apostrof va qo\'shtirnoq asliga qaytadi', () {
      expect(
        unescapeHtml('so&#39;m va &#34;qo&#39;shtirnoq&#34; sinovi'),
        'so\'m va "qo\'shtirnoq" sinovi',
      );
    });

    test('oddiy matn TEGILMAYDI', () {
      expect(unescapeHtml('salom, qalaysan?'), 'salom, qalaysan?');
    });

    test('&amp; oxirida ochiladi — ikki marta ochilib ketmaydi', () {
      // `&amp;#39;` — bu odam YOZGAN matn, apostrof emas.
      expect(unescapeHtml('&amp;#39;'), '&#39;');
    });

    test('o\'n oltilik shakl ham', () {
      expect(unescapeHtml('&#x27;salom&#x27;'), "'salom'");
    });

    /// 🔴 2026-08-19: ochish TRANSPORT qatlamiga ko'chirildi. Backend
    /// FAQAT chatni emas, HAMMA matnni kodlab saqlaydi — ism, manzil,
    /// mashina modeli, posilka izohi. Ilgari `unescapeHtml` faqat chat
    /// modelida chaqirilardi va qolgan ekranlarda `Farg&#39;ona` ko'rinardi.
    group('deepUnescape butun javobni ochadi', () {
      test('ichma-ich Map va List', () {
        final out = deepUnescape({
          'user': {'name': 'Farg&#39;ona'},
          'rides': [
            {'from': 'Qo&#39;qon'},
          ],
        });

        expect((out['user'] as Map)['name'], "Farg'ona");
        expect(((out['rides'] as List).first as Map)['from'], "Qo'qon");
      });

      test('son/bool/null tegilmaydi', () {
        final out = deepUnescape({'n': 5, 'b': true, 'z': null});
        expect(out['n'], 5);
        expect(out['b'], true);
        expect(out['z'], isNull);
      });

      test('oddiy matn tegilmaydi', () {
        expect(deepUnescape('salom'), 'salom');
      });
    });
  });

  /// 🔴 Egasi qurilmada ko'rdi (2026-08-13): suhbat ochilganda ekranda eng
  /// ESKI xabarlar turardi, oxirgisini ko'rish uchun qo'lda surish kerak edi.
  test('suhbat oxirgi xabardan ochiladi', () {
    final src = File('lib/features/chat/chat_screen.dart').readAsStringSync();
    expect(
      src.contains('_didInitialScroll'),
      isTrue,
      reason: 'tarix kelgach bir marta pastga tushish OLIB TASHLANGAN',
    );
  });
}
