import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/api/ws_client.dart';

/// Chat WS kontrakti — bu yerdagi hamma narsa jonli xatolardan o'rganilgan.
/// Chat swaggerda UMUMAN yo'q (backend xati №7), shuning uchun yagona
/// mahkamlash usuli — shu testlar.
void main() {
  group('send_message kadri', () {
    test(
      'serverga `receiver_id` ketadi (`recipient_id` ning O\'ZI yetmaydi)',
      () {
        final payload = WsClient.buildSendMessagePayload(
          recipientId: '8b321a5d-1234-5678-90ab-cdef12345678',
          content: 'Salom',
          rideId: '30d7313c-f6a6-4249-af51-8e75b81ed8cb',
        );
        final data = payload['data'] as Map<String, dynamic>;

        // 🔴 Ilgari faqat `recipient_id` yuborilardi: server `receiver_id` ni
        // o'qib bo'sh satr ko'rardi ("invalid UUID length: 0") va xabarni RAD
        // ETARDI — u bazaga umuman tushmasdi.
        expect(payload['event'], 'send_message');
        expect(data['receiver_id'], '8b321a5d-1234-5678-90ab-cdef12345678');
        expect(data['content'], 'Salom');
        expect(data['ride_id'], '30d7313c-f6a6-4249-af51-8e75b81ed8cb');
        // Eski kalit ham qoladi — gateway versiyasini hujjat bilan bilib bo'lmaydi.
        expect(data['recipient_id'], data['receiver_id']);
        // snake_case SHART: camelCase kalitni server ko'rmaydi.
        expect(data.containsKey('receiverId'), isFalse);
      },
    );

    test('ride_id bo\'lmasa kalit umuman yuborilmaydi (bo\'sh satr emas)', () {
      final payload = WsClient.buildSendMessagePayload(
        recipientId: 'peer-1',
        content: 'Salom',
      );
      expect((payload['data'] as Map).containsKey('ride_id'), isFalse);
    });
  });

  group('messages_read kadri (kelган)', () {
    // Backend 2026-08-20: mark_as_read'га javoban jo'natuvchiга keladi.
    test('event taniladi va message_ids o\'qiladi', () {
      final e = WsEvent.tryParse(
        '{"event":"messages_read","data":{"message_ids":["m-1","m-2"]}}',
      );
      expect(e, isNotNull);
      expect(e!.isMessagesRead, isTrue);
      expect(e.readMessageIds, ['m-1', 'm-2']);
    });
  });

  group('typing kadri', () {
    // Server bu kadrni retranslatsiya qilса "yozmoqda" ishlaydi; shakl
    // xat 2026-08-21 da so'ralган. Kalit nomi noto'g'ri bo'lса test tutadi.
    test('event nomi va receiver_id joyi to\'g\'ri', () {
      final p = WsClient.buildTypingPayload('peer-9');
      expect(p['event'], 'typing');
      expect((p['data'] as Map)['receiver_id'], 'peer-9');
    });
  });

  group('mark_as_read kadri', () {
    // 🔴 Shakl backend xatidan (2026-08-19) AYNAN olingan:
    //   {"event":"mark_as_read","data":{"message_ids":[...]}}
    // Kalit nomi noto'g'ri bo'lsa server jim e'tiborsiz qoldiradi (ack yo'q),
    // ya'ni xato QURILMADA ham ko'rinmaydi — faqat shu test tutadi.
    test('event nomi va message_ids joyi to\'g\'ri', () {
      final payload = WsClient.buildMarkAsReadPayload(['id-1', 'id-2']);
      expect(payload['event'], 'mark_as_read');
      expect((payload['data'] as Map)['message_ids'], ['id-1', 'id-2']);
    });
  });

  group('kelgan kadr', () {
    test('eski shakl {type: NEW_MESSAGE, payload}', () {
      final event = WsEvent.tryParse(
        jsonEncode({
          'type': 'NEW_MESSAGE',
          'payload': {'message': 'Salom'},
        }),
      );
      expect(event?.isNewMessage, isTrue);
      expect(event?.displayText, 'Salom');
    });

    test('yangi shakl {event: new_message, data} ham qabul qilinadi', () {
      // 2026-08-12 dan backend shu shaklda va JO'NATUVCHIGA HAM yuboradi.
      // Ilgari faqat `type` o'qilardi -> kadr jim tashlanardi va ochiq
      // suhbatga kelgan xabar ekranda ko'rinmasdi.
      final event = WsEvent.tryParse(
        jsonEncode({
          'event': 'new_message',
          'data': {'content': 'Salom', 'receiver_id': 'peer-1'},
        }),
      );
      expect(event?.isNewMessage, isTrue);
      expect(event?.displayText, 'Salom');
    });

    test('noma\'lum kadr yiqilmaydi', () {
      expect(WsEvent.tryParse('{"foo":1}'), isNull);
      expect(WsEvent.tryParse('yaroqsiz'), isNull);
    });
  });
}
