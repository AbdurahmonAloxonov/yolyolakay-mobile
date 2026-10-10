import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/data/models/chat.dart';

/// `GET /notifications/chats` — backend 2026-08-16 da qo'shdi.
///
/// 🔴 NEGA TEST KERAK: bu javob ro'yxatni ALMASHTIRMAYDI, ustiga
/// qo'yiladi. Ya'ni kalit (`partner_id`) mos kelmasa hech qanday xato
/// chiqmaydi — oxirgi xabar shunchaki KO'RINMAY qoladi va buni faqat
/// qurilmada payqash mumkin.
void main() {
  group('ChatSummary.fromJson', () {
    test('partner_id, oxirgi xabar va vaqti o\'qiladi', () {
      final s = ChatSummary.fromJson({
        'partner_id': 'u-1',
        'unread_count': 3,
        'last_message': {
          'content': 'Salom',
          'created_at': '2026-08-16T10:30:00Z',
          'sender_id': 'u-1',
        },
      });

      expect(s.peerId, 'u-1');
      expect(s.lastMessage, 'Salom');
      expect(s.unreadCount, 3);
      expect(s.lastAt?.toUtc().hour, 10);
    });

    test('HTML kodlarini model OCHMAYDI (transport ochadi)', () {
      // 🔴 2026-08-19: ochish TRANSPORT qatlamiga ko'chirildi
      // (`ApiClient._onResponse` + `WsEvent.tryParse`), chunki backend
      // FAQAT chat matnini emas, HAMMA matnni kodlab saqlaydi —
      // ismni, manzilni, mashina modelini, posilka izohini.
      //
      // Model bu yerda IKKINCHI marta ochmasligi SHART: `&amp;#39;`
      // (odam yozgan matn) ikki marta ochilsa `'` bo'lib buziladi.
      final s = ChatSummary.fromJson({
        'partner_id': 'u-1',
        'last_message': {'content': '5000 so&#39;m'},
      });
      expect(s.lastMessage, '5000 so&#39;m');
    });

    test('xabarsiz suhbat — yiqilmaydi', () {
      final s = ChatSummary.fromJson({'partner_id': 'u-2'});
      expect(s.peerId, 'u-2');
      expect(s.lastMessage, isNull);
      expect(s.lastAt, isNull);
      expect(s.unreadCount, 0);
    });
  });

  group('Conversation.withSummary', () {
    /// Ism va avatar `GET /notifications/chats` javobida YO'Q — ular
    /// bronlardan keladi. Birlashtirishda ular YO'QOLMASLIGI kerak,
    /// aks holda ro'yxatda ism o'rniga "Haydovchi" chiqib qolardi.
    test('ism va avatar SAQLANADI, faqat xabar qo\'shiladi', () {
      const conversation = Conversation(
        rideId: 'r-1',
        peerId: 'u-1',
        title: 'Toshkent → Samarqand',
        subtitle: 'Aziz',
        avatarUrl: '/uploads/a.jpg',
      );

      final merged = conversation.withSummary(
        ChatSummary(
          peerId: 'u-1',
          lastMessage: 'Yetib keldim',
          lastAt: DateTime.utc(2026, 8, 16, 10),
          unreadCount: 2,
        ),
      );

      expect(merged.subtitle, 'Aziz');
      expect(merged.avatarUrl, '/uploads/a.jpg');
      expect(merged.rideId, 'r-1');
      expect(merged.title, 'Toshkent → Samarqand');
      expect(merged.lastMessage, 'Yetib keldim');
      expect(merged.unreadCount, 2);
      // Suhbat kaliti o'zgarmasligi shart (provider family kaliti).
      expect(merged, conversation);
    });
  });

  /// 🔴 Ro'yxatda kim yozgani bilinmasdi: "Xo'p, kelishdik" qatorini ko'rgan
  /// odam suhbatdosh javob berdi deb o'ylab chatni ochardi — u yerda esa
  /// o'zining xabari turardi (egasi tasdiqladi, 2026-08-19).
  group('«Siz:» prefiksi', () {
    ChatSummary summaryFrom(String senderId) => ChatSummary.fromJson({
      'partner_id': 'u-1',
      'last_message': {'content': 'Salom', 'sender_id': senderId},
    });

    const base = Conversation(rideId: 'r-1', peerId: 'u-1', title: '');

    test('oxirgi xabar MENIKI bo\'lsa bayroq yoqiladi', () {
      final c = base.withSummary(summaryFrom('me-1'), myUserId: 'me-1');
      expect(c.lastIsMine, isTrue);
    });

    test('suhbatdosh yozgan bo\'lsa bayroq YOQILMAYDI', () {
      final c = base.withSummary(summaryFrom('u-1'), myUserId: 'me-1');
      expect(c.lastIsMine, isFalse);
    });

    /// Noto'g'ri "Siz:" haqiqiy xabarni o'z xabarimdek ko'rsatib qo'yadi —
    /// bu prefiks umuman bo'lmaganidan YOMONROQ.
    test('foydalanuvchi ID noma\'lum bo\'lsa prefiks YO\'Q', () {
      expect(base.withSummary(summaryFrom('u-1')).lastIsMine, isFalse);
      expect(
        base.withSummary(summaryFrom('u-1'), myUserId: '').lastIsMine,
        isFalse,
      );
    });

    test('sender_id kelmasa ham yiqilmaydi', () {
      final s = ChatSummary.fromJson({
        'partner_id': 'u-1',
        'last_message': {'content': 'Salom'},
      });
      expect(s.lastSenderId, isNull);
      expect(base.withSummary(s, myUserId: 'me-1').lastIsMine, isFalse);
    });
  });

  group('o\'qilmaganlar soni ro\'yxatga yetib boradi', () {
    // 🔴 Server sonni beryapti, lekin 2026-08-17 gacha u ekranda HECH
    // QAYERDA ko'rsatilmasdi: odam qaysi suhbatda yangi xabar borligini
    // ro'yxatga qarab bilolmasdi.
    test('withSummary unreadCount ni ko\'chiradi', () {
      final c = const Conversation(
        rideId: 'r-1',
        peerId: 'u-1',
        title: 'Toshkent - Samarqand',
      ).withSummary(
        ChatSummary.fromJson({'partner_id': 'u-1', 'unread_count': 5}),
      );

      expect(c.unreadCount, 5);
    });

    test('son bo\'lmasa nol — nishon ko\'rinmaydi', () {
      final c = const Conversation(
        rideId: 'r-1',
        peerId: 'u-1',
        title: '',
      ).withSummary(ChatSummary.fromJson({'partner_id': 'u-1'}));

      expect(c.unreadCount, 0);
    });

    test('umumiy nishon = suhbatlar yig\'indisi', () {
      // Pastki paneldagi nishon shu yig'indini ko'rsatadi.
      final chats = [
        ChatSummary.fromJson({'partner_id': 'a', 'unread_count': 2}),
        ChatSummary.fromJson({'partner_id': 'b', 'unread_count': 3}),
        ChatSummary.fromJson({'partner_id': 'c'}),
      ];

      expect(chats.fold<int>(0, (sum, c) => sum + c.unreadCount), 5);
    });
  });
}
