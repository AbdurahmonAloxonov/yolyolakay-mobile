import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/app/router.dart';
import 'package:yolyolakay/core/api/ws_client.dart';
import 'package:yolyolakay/core/push_routes.dart';
import 'package:yolyolakay/data/models/chat.dart';

/// Bosilgan push QAYERGA olib borishi.
///
/// Bu qoidalar qurilmada tekshirish qiyin (haqiqiy push kerak), lekin
/// buzilishi juda oson: backend `type` nomini bir harfga o'zgartirsa
/// foydalanuvchi "bildirishnomalar" ro'yxatiga tushib qolardi va safar
/// arizasini qo'lda qidirardi. Shuning uchun moslash shu yerda qotirilgan.
void main() {
  group('pushTargetFor', () {
    test('chat xabari — suhbatdosh bo\'yicha ochiladi', () {
      final target = pushTargetFor({
        'type': 'new_message',
        'peer_id': 'u-1',
        'peer_name': 'Aziz',
        'ride_id': 'r-9',
      });

      expect(target.location, Routes.chat);
      final conversation = target.extra as Conversation;
      expect(conversation.peerId, 'u-1');
      // 🔴 Ism `subtitle` da: ekran sarlavhasi aynan shuni ko'rsatadi.
      // `title` esa safar yo'nalishi uchun — pushda u kelmaydi.
      expect(conversation.subtitle, 'Aziz');
      expect(conversation.title, '');
      expect(conversation.rideId, 'r-9');
    });

    test('suhbatdosh noma\'lum bo\'lsa — chat ro\'yxati', () {
      expect(pushTargetFor({'type': 'NEW_MESSAGE'}).location, Routes.chats);
    });

    test('type yozilishi (NewMessage/NEW_MESSAGE) farq qilmaydi', () {
      for (final type in ['NewMessage', 'NEW_MESSAGE', 'chat_message']) {
        expect(
          pushTargetFor({'type': type, 'peer_id': 'u-1'}).location,
          Routes.chat,
          reason: type,
        );
      }
    });

    test('bron va safar hodisalari — Safarlarim', () {
      for (final type in [
        'booking_created',
        'booking_confirmed',
        'booking_rejected',
        'ride_started',
        'trip_cancelled',
        'ride_reminder_1h',
        'ride_reminder_15m',
      ]) {
        expect(
          pushTargetFor({'type': type}).location,
          Routes.trips,
          reason: type,
        );
      }
    });

    test('posilka — safar emas, Posilkalar (ichida ride_id bo\'lsa ham)', () {
      expect(
        pushTargetFor({'type': 'parcel_response', 'ride_id': 'r-1'}).location,
        Routes.parcels,
      );
    });

    test('to\'lov va tarif — Tariflar', () {
      for (final type in [
        'payment_success',
        'trial_activated',
        'subscription_expired',
      ]) {
        expect(
          pushTargetFor({'type': type}).location,
          Routes.tariffs,
          reason: type,
        );
      }
    });

    test('noma\'lum tur ham HECH BO\'LMASA ro\'yxatga olib boradi', () {
      expect(pushTargetFor({}).location, Routes.notifications);
      expect(
        pushTargetFor({'type': 'kutilmagan'}).location,
        Routes.notifications,
      );
    });
  });

  group('WsEvent.pushData', () {
    /// Ochiq ilovada kelgan WS hodisasi va yopiq ilovada kelgan push BITTA
    /// manzilga olib borishi kerak — aks holda bitta xabar ilova holatiga
    /// qarab har xil joyni ochardi.
    test('WS xabari push bilan AYNI ekranni ochadi', () {
      final event = WsEvent.tryParse(
        jsonEncode({
          'event': 'new_message',
          'data': {'sender_id': 'u-1', 'ride_id': 'r-9', 'content': 'Salom'},
        }),
      );

      final target = pushTargetFor(event!.pushData);
      expect(target.location, Routes.chat);
      expect((target.extra as Conversation).peerId, 'u-1');
      expect((target.extra as Conversation).rideId, 'r-9');
    });

    test('sender_id bo\'lmasa kalit umuman qo\'shilmaydi', () {
      final event = WsEvent.tryParse(
        jsonEncode({
          'type': 'BOOKING_CREATED',
          'payload': {'ride_id': 'r-1', 'booking_id': 'b-2'},
        }),
      );

      expect(event!.pushData.containsKey('peer_id'), isFalse);
      expect(event.pushData['booking_id'], 'b-2');
      expect(pushTargetFor(event.pushData).location, Routes.trips);
    });
  });
}
