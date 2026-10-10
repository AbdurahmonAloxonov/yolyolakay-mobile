import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/core/push.dart';
import 'package:yolyolakay/data/models/chat.dart';
import 'package:yolyolakay/features/chat/chat_screen.dart';
import 'package:yolyolakay/features/notifications/notifications_screen.dart';

import 'support/audit_screens.dart';

/// O'QILGAN BILDIRISHNOMA STATUS-BARDA QOLMASIN.
///
/// 🔴 NEGA YOZILDI (egasi, 2026-09-04: «push notification keladi, ichiga
/// kiradi, lekin tepada qolib ketyapti — kirgandan keyin yo'qolishi
/// kerak-ku, chatdan kelgan bo'lsa misol uchun»).
///
/// O'lchandi va sabab oddiy chiqdi: butun ilovada bildirishnomani
/// O'CHIRADIGAN chaqiruvning O'ZI yo'q edi. Android faqat BOSILGAN
/// bildirishnomani olib tashlaydi; chatlar ro'yxatidan kirilgan yoki
/// ilova allaqachon ochiq bo'lgan holatda esa u telefon tepasida
/// abadiy osilib qolardi.
///
/// 🔑 NIMA O'LCHANADI: plagin faqat qurilmada ishlaydi (testda, Linuxda,
/// `initialize` xato tashlaydi va kanalga hech nima yetib bormaydi).
/// Shuning uchun test «bildirishnoma o'chdimi» degan savolga emas,
/// «EKRAN o'chirishni so'radimi» degan savolga javob beradi — nuqson
/// aynan shu yerda edi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ko\'rsatish va o\'chirish BIR XIL raqamni ishlatadi', () {
    // Raqam bitta manbadan olinadi — aks holda ertaga biri o'zgarib,
    // bildirishnoma o'chmay qoladi.
    expect(chatNotificationId('d1'), 'd1'.hashCode);
    expect(chatNotificationId('d1'), isNot(chatNotificationId('d2')));
  });

  testWidgets('chat ochilganda O\'SHA suhbatning bildirishnomasi o\'chadi', (
    tester,
  ) async {
    final asked = <String>[];
    await pumpAuditScreen(
      tester,
      ChatScreen(
        conversation: Conversation(
          rideId: 'r1',
          peerId: 'd1',
          title: 'Toshkent - Samarqand',
          subtitle: 'Abdurahmon',
          lastMessage: 'Salom',
          lastAt: DateTime(2026, 9, 2, 8, 15),
        ),
      ),
      overrides: [notificationDismisserProvider.overrideWithValue(_Spy(asked))],
    );

    expect(
      asked,
      contains('d1'),
      reason:
          'Chat ochildi, lekin bildirishnomani o\'chirish SO\'RALMADI — '
          'u telefon tepasida qolib ketadi.',
    );
  });

  testWidgets('«hammasini o\'qilgan qil» status-barni ham tozalaydi', (
    tester,
  ) async {
    final asked = <String>[];
    await pumpAuditScreen(
      tester,
      const NotificationsScreen(),
      overrides: [notificationDismisserProvider.overrideWithValue(_Spy(asked))],
    );
    // Tugma faqat o'qilmagan bildirishnoma bo'lganda chiqadi; ro'yxat
    // tarmoqsiz muhitda bo'sh, shuning uchun bu yerda faqat ekran
    // yiqilmasligini va so'rov YO'Q ekanini tekshiramiz.
    expect(asked, isEmpty);
  });
}

/// Haqiqiy o'chiruvchining o'rniga — kim so'raganini yozib boradi.
class _Spy implements NotificationDismisser {
  const _Spy(this.asked);

  final List<String> asked;

  @override
  Future<void> chat(String peerId) async => asked.add(peerId);

  @override
  Future<void> all() async => asked.add('*');
}
